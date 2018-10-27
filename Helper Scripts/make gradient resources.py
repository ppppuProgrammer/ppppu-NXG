#!python3

from pathlib import Path
from bs4 import BeautifulSoup
import multiprocessing
import re
import subprocess
import hashlib
import os
#import pudb; pu.db

CPU_CORES = multiprocessing.cpu_count()
TRES_OUTPUT_PATH = Path("color presets")
COLOR_HOWTO_PATH = Path("Coloring Data")
COLOR_STR = '''[gd_resource type="Gradient" format=2]

[resource]

offsets = PoolRealArray( {:s} )
colors = PoolColorArray( {:s} )'''


def convertHexToRGB(hexColor):
    cleanedHex = hexColor.strip("#")
    value = int(cleanedHex, 16)
    rgb = (((value >> 16) & 255) / 255.0, ((value >> 8) & 255) / 255.0, (value & 255) / 255.0)
    return rgb


def parseColor(hexColor, alpha):
    stopStrings = ["", ""]
    stopStrings[0] = "0.0"
    color = convertHexToRGB(hexColor)
    stopStrings[1] = "{:f}, {:f}, {:f}, {:s}".format(*color, alpha)
    return stopStrings


def validateColor(hexColor):
    shortFormMatch = re.match("^#([A-F|0-9])([A-F|0-9])([A-F|0-9])$", str(hexColor))
    if shortFormMatch:
        return "#{0:s}{0:s}{1:s}{1:s}{2:s}{2:s}".format(
            shortFormMatch[1], shortFormMatch[2], shortFormMatch[3])
    else:
        return hexColor

    
def parseGradient(gradientStopList):
    #first is offset, second is colors
    stopStrings = ["", ""]
    for stop in gradientStopList:
        color = validateColor(convertHexToRGB(stop["stop-color"]))
        alpha = stop["stop-opacity"]
        offset = stop["offset"]
        if len(stopStrings[0]) > 0:
            stopStrings[0] += ", "
        stopStrings[0] += offset
        if len(stopStrings[1]) > 0:
            stopStrings[1] += ", "
        stopStrings[1] += "{:f}, {:f}, {:f}, {:s}".format(*color, alpha)
    return stopStrings

        
def parseXmlFiles(workload):
    output = ""
    #output = ""
    for svgPath in workload:
        #print(svgPath)
        xml = BeautifulSoup(svgPath.read_text(), "xml")
        drawPaths = xml.find_all("path")
        pathParentsUsed = []
        writeFileDict = {}
        defs = None
        if xml.find("defs") is not None:
            defs = xml.defs.find_all(name=re.compile("Gradient"))
        #print(xml.defs.find_all(name=re.compile("Gradient")))
        for dPath in drawPaths:
            gradStrings = []
            #Find the name of the parent for this draw path
            currentParent = dPath.parent
            pathParentName = None
            while(currentParent != None and pathParentName == None):
                if currentParent.has_attr("id"):
                    pathParentName = currentParent['id']
                else:
                    currentParent = currentParent.parent

            
            #There should only be one direct child, multiple mean there are many draw paths that are to be affected the same way. 
            if pathParentName in pathParentsUsed or pathParentName == None:
                continue
            pathParentsUsed.append(pathParentName)
            #writeFileDict[pathParentName] = []
            #output += "\n{:s}".format(pathParentName)
            #print(pathParentName)
            #Only fill or stroke. Prioritize fill first
            drawColor = None
            drawType = None
            if dPath.has_attr("fill") and dPath["fill"] != "none":
                drawColor = validateColor(dPath["fill"])
                drawType = "fill"
            elif dPath.has_attr("stroke"):
                drawColor = validateColor(dPath["stroke"])
                drawType = "stroke"
            else:
                styleParts = re.split(":|;", dPath["style"])
                styleData = {}
                for idx in range(0, len(styleParts), 2):
                    styleData[styleParts[idx]] = styleParts[idx+1]

                if "fill" in styleData and styleData["fill"] != "none":
                    drawColor = validateColor(styleData["fill"])
                    drawType = 'fill'
                elif "stroke" in styleData:
                    drawType = "stroke"
                    drawColor = validateColor(styleData["stroke"])

            if "url(#" in str(drawColor):
                if defs is None:
                    output += '''\n({:s}) gradient definitions were not found. Unable to write data for {:s}'''.format(svgPath.name, str(drawColor))
                    continue
                gradientName = str(drawColor)[5:-1]
                gradientStops = None
                
                for gradDef in defs:
                    #print(gradDef)
                    if gradDef["id"] == gradientName:
                        gradientStops = gradDef.find_all("stop")
                        break
                if gradientStops:
                    gradStrings = parseGradient(gradientStops)
            else:
                if "undefined" in drawColor:
                    output += '''"{:s}" for a child element of {:s} is undefined. Unable to create color file for this element'''.format(drawType, pathParentName) 
                    continue
                drawAlpha = "1.0"
                if drawType is "stroke":
                    if dPath.has_attr("stroke-opacity"):
                        drawAlpha = dPath["stroke-opacity"]
                elif drawType is "fill":
                    if dPath.has_attr("fill-opacity"):
                        drawAlpha = dPath["fill-opacity"]
                gradStrings = parseColor(drawColor, drawAlpha)
            writeFileDict[pathParentName] = gradStrings

        #output += "\n\t{:s}".format(drawColor)
        #Write to tres files here
        for outName, dataList in writeFileDict.items():
            if len(dataList) == 0:
                continue
            fileName = TRES_OUTPUT_PATH / "{:s}_color.tres".format(outName)
            Path(fileName).write_text(COLOR_STR.format(dataList[0], dataList[1]))
    print(output)

def main():
    if not TRES_OUTPUT_PATH.exists():
        TRES_OUTPUT_PATH.mkdir()
    svgFiles = Path(".").glob("*.svg")
    workloads = []
    for core in range(CPU_CORES):
        workloads.append([])
    targetWorkerNum = 0
    for svg in svgFiles:
        workloads[targetWorkerNum].append(Path(svg))
        targetWorkerNum += 1
        if targetWorkerNum >= CPU_CORES:
            targetWorkerNum = 0

    workers = []
    for cpu in range(CPU_CORES):
        proc = multiprocessing.Process(
            target=parseXmlFiles, args=(workloads[cpu],))
        workers.append(proc)
        proc.start()

    for worker in workers:
        worker.join()

    #Do a duplicate gradient test, Use sha256 sum checks to find matching file contents.
    tresSumChecks = {}
    tresFiles = TRES_OUTPUT_PATH.glob("*.tres")
    duplicateTresFiles = {}
    for tres in tresFiles:
        hasher = hashlib.sha256()
        hasher.update(tres.read_bytes())
        shaSum = hasher.hexdigest()
        if shaSum in tresSumChecks:
            if os.path.isfile(tres):
                print("\nRemoved {:s} due to using the same color values as {:s}".format(tres.name, tresSumChecks[shaSum][0]))
                tresSumChecks[shaSum].append(tres.name)
                os.remove(tres)
        else:
            tresSumChecks[shaSum] = [tres.name]
    duplicateTxtFile = TRES_OUTPUT_PATH / "Duplicate color matches.txt"
    dupText = ""
    for sumcheck in tresSumChecks:
        matches = tresSumChecks[sumcheck]
        if len(matches) > 1:
            dupText += "\n" + matches[0] + " : \n\t"
            for x in range(1, len(matches)):
                dupText += matches[x] + ", "
            dupText = dupText[:-2] + "\n"
    duplicateTxtFile.write_text(dupText)
    # The default output file names are bad so they'll likely be changed.

if __name__ == "__main__":
    main()
