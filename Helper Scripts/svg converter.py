#!python3

import glob
from pathlib import Path
import math
import subprocess
# import shutil
import multiprocessing
import re
import argparse
from bs4 import BeautifulSoup
# Run this script from the folder with the svg files you want to convert

charStripper = re.compile("[^0-9]")
LAYER_ORDER_FNAME = "LayerOrder.txt"
COLORING_FNAME = "ColoringInfo.txt"
CPU_CORES = multiprocessing.cpu_count()
DEBUG_PRINT = False
# Passed in system arguments


args = None
colors = ["#1A1A1A", "#333333", "#4D4D4D", "#666666",
          "#808080", "#999999", "#B3B3B3", "#CCCCCC"]


def getColorSection(colorStr):
    # Convert #RGB to #RRGGBB
    shortFormMatch = re.match(
        "^#([A-F|0-9])([A-F|0-9])([A-F|0-9])$", str(colorStr))
    if shortFormMatch:
        colorStr = "#{0:s}{0:s}{1:s}{1:s}{2:s}{2:s}".format(
            shortFormMatch[1], shortFormMatch[2],
            shortFormMatch[3])
    for section in range(len(colors)):
        if colors[section] == colorStr:
            return section + 1

    return 0


def dbgPrint(text):
    if DEBUG_PRINT:
        print(text)

# Takes a list of object information from the svg and converts it
def transformLayerList(list):
    newList = []
    for layer in list:
        if len(layer) == 0:
            list.remove(layer)
            continue
        #Create a tuple for layer information (name, x, y, width, height)
        parts = layer.split(b',')
        id = str(parts[0])
        id = id.split('\'')[1]
        newList.append([id, (float(parts[1]), float(parts[2]),
                             float(parts[3]), float(parts[4]))])
    return newList


def calculateImageSize(sizeTuple):
    flr = math.floor
    cei = math.ceil
    x, y, w, h = sizeTuple
    x = flr(x)
    y = flr(y)
    w = cei(w)
    h = cei(h)
    return (x, y, w, h)


def getCanvasSize(svg):
    file = Path(svg).open()
    if file:
        xml = BeautifulSoup(str(file.readlines()), "lxml")
        #print(xml.svg)
        x = float(charStripper.sub("", xml.svg["x"]))
        y = float(charStripper.sub("", xml.svg["y"]))
        w = float(charStripper.sub("", xml.svg["width"]))
        h = float(charStripper.sub("", xml.svg["height"]))
        return (x,y,w,h)
    return None


#iSize and cSize must be tuples with 4 values (x,y,w,h)
def calculateArea(iSize, cSize):
    dbgPrint("CalculateArea()- i: {:s}; c: {:s}".format(str(iSize), str(cSize)))
    x0 = cSize[0] +  iSize[0]
    x1 = x0 + iSize[2]
    y0 = cSize[1] + cSize[3] - iSize[1]
    y1 = y0 - iSize[3]
    return (x0,y0,x1,y1)


def exportLayersToPng(svg, layers, exportLayers, outDir):
    #Need to get the image size for the drawings. The first layer has all the info we need.
    imageSize = calculateImageSize(layers[0][1])
    dbgPrint(imageSize)
    #Need to get the canvas size for the file.
    canvasSize = getCanvasSize(svg)
    areaSize = calculateArea(imageSize, canvasSize)
    #Calculate the area that will be exported.
    imageSizeArg = "{:f}:{:f}:{:f}:{:f}".format(*areaSize)
    exportedRecord = []
    #dbgPrint("Printing Layers: {:s}".format(str(layers)))
    foundRoot = False
    #Go through the layers list and export the layers. Skip the first layer since it is for the svg as a whole.
    if args.i or args.a:
        for layer in layers:
            id = layer[0]

            if id in exportLayers:
                #dbgPrint("Exporting layer {:s}".format(id))
                subprocess.call(['inkscape', '--export-area={:s}'.format(imageSizeArg), '--export-id={:s}'.format(id), '--export-id-only', '--export-png={:s}/{:s}.png'.format(str(outDir), id), '{:s}'.format(svg)])


def debug_printLayerList(list):
    output = ""
    for layer in list:
        output += "id: {:s}; x,y,w,h: {:s}\n".format(str(layer[0]), str(layer[1]))
    #dbgPrint(output)

#xml should be xml data starting at the svg element
def findRootLayer(xml):
    result = xml.find_all('g', id=True)
    if len(result) > 0:
        firstResult = result[0]
        if len(firstResult.find_all('g', id=True, recursive=False)) > 1:
            return firstResult
        else:
            return findRootLayer(firstResult)
    else:
        return xml.parent

    
def getNormalizedPoint(point, imgSize):
    # Shift position by imgSize's x and y to have the origin be 0,0
    dbgPrint(point)
    dbgPrint("imgSize: {}".format(imgSize))
    shiftedPoint = [point[0] - imgSize[0], point[1] - imgSize[1]]
    dbgPrint("shifted: {}".format(shiftedPoint))
    normalizedX = shiftedPoint[0] / imgSize[2]
    normalizedY = shiftedPoint[1] / imgSize[3]
    dbgPrint((normalizedX, normalizedY))
    return (normalizedX, normalizedY)


def getRadiusNormalized(radius, imgSize):
    return radius / min(imgSize[2], imgSize[3])


def getColoringData(svgXml, layer, imgSize, layerSize):
    dbgPrint(layer)
    dbgPrint("layer: {:f},{:f},{:f},{:f}".format(*layerSize))
    layerElement = svgXml.find(id=layer)
    elementTransform = layerElement["transform"] if layerElement.has_attr("transform") else None
    # Only care about the first child. If multiple draw paths are used, assume
    # that all children are like each other in terms of fill and/or stroke
    
    elementChild = layerElement.find(name="path")
    #print(elementChild)
    gradientUrl = None
    #grType = None
    if elementChild.has_attr("fill") and "url(#" in str(elementChild["fill"]):
        gradientUrl = str(elementChild["fill"])[5:-1]
        #grType = "Linear"
    elif elementChild.has_attr("stroke") and "url(#" in str(elementChild["stroke"]):
        gradientUrl = str(elementChild.attr["fill"])[5:-1]
        #grType = "Radial"
    elif elementChild.has_attr("style") and "url(#" in str(elementChild["style"]):
        style = str(elementChild["style"])
        urlStartPos = style.find("url(#") + 5
        gradientUrl = style[urlStartPos:style.find(")", urlStartPos)]
    colorSections = ""
    #print(gradientUrl)
    if gradientUrl is not None:
        gradient = svgXml.defs.find(id=gradientUrl)
        trScaleX = 1.0
        trScaleY = 1.0
        trPosX = 0.0
        trPosY = 0.0

        gradientUniqueSections = []
        for stop in gradient.find_all("stop"):
            colorSectResult = getColorSection(stop["stop-color"])
            if colorSectResult > 0 and colorSectResult not in gradientUniqueSections:
                gradientUniqueSections.append(colorSectResult)
                colorSections += "{:d},".format(colorSectResult)
                
        if elementTransform:
            transformParts = re.split(" |,", str(elementTransform)[7:-1])
            trScaleX = float(transformParts[0])
            trScaleY = float(transformParts[3])
            trPosX = float(transformParts[4])
            trPosY = float(transformParts[5])
        
        #layerDiffX = imgSize[0] - layerSize[0]
        #print("layerDiffX: {}".format(layerDiffX))
        #layerDiffY = imgSize[1] - layerSize[1]
        if gradient.name == "radialGradient":
            grCenter = [(float(gradient['cx']) * trScaleX) + trPosX,
                        (float(gradient['cy']) * trScaleY) + trPosY]
            grFocus = [(float(gradient['fx']) * trScaleX) + trPosX,
                       (float(gradient['fy']) * trScaleY) + trPosY]
            if gradient.has_attr("gradientTransform"):
                grTransform = re.split(
                    " |,", str(gradient.gradientTransform)[7:-1])
            grRadius = float(gradient['r']) * min(trScaleX, trScaleY)
            
            return "Radial;{};{};{};{}".format(
                colorSections,
                getNormalizedPoint(grCenter, layerSize),
                getNormalizedPoint(grFocus, layerSize),
                getRadiusNormalized(grRadius, imgSize))
        elif gradient.name == "linearGradient":
            grStart = [(float(gradient['x1']) * trScaleX) + trPosX,
                       (float(gradient['y1']) * trScaleY) + trPosY]
            grEnd = [(float(gradient['x2']) * trScaleX) + trPosX,
                     (float(gradient['y2']) * trScaleY) + trPosY]
        # Those points are relative to the top left corner of the layer's object, which are offset from the overall image dimensions.
        return "Linear;{};{};{}".format(
            colorSections, getNormalizedPoint(grStart, layerSize),
            getNormalizedPoint(grEnd, layerSize))
    else:
        if elementChild.has_attr("fill"):
            if elementChild["fill"] is not "none":
                colorSectResult = getColorSection(elementChild["fill"])
                if colorSectResult > 0:
                    colorSections += "{:d},".format(colorSectResult)
        elif elementChild.has_attr("stroke"):
            if elementChild["stroke"] is not "none":
                colorSectResult = getColorSection(elementChild["stroke"])
                if colorSectResult > 0:
                    colorSections += "{:d},".format(colorSectResult)
        elif elementChild.has_attr("style"):
            styleAttrs = re.split(":|;", str(elementChild["style"]))
            #print(styleAttrs)
            for x in range(len(styleAttrs), 2):
                attr = styleAttrs[x]
                #print(attr)
                if ((attr == "fill" or attr == "stroke") and styleAttrs[x+1] is not "none"):
                    colorSectResult = getColorSection(styleAttrs[x+1])
                    if colorSectResult > 0:
                        colorSections += "{:d},".format(colorSectResult)
                    
        return "Solid;{}".format(colorSections)

def convertSvgToPng(jobsList):
    for job in jobsList:
        svg, exportList, svgFolder = job
        layers = transformLayerList(subprocess.check_output(['inkscape', '-S', '{:s}'.format(svg)]).split(b'\n'))
        #print(layers)
        exportLayersToPng(svg, layers, exportList, svgFolder)
        #Need to write out layer order so other programs know how the sprite should be reassembled
        orderText = ""
        coloringText = ""
        svgXml = BeautifulSoup(Path(svg).read_text(), "xml")
        layerIdx = -1
        for layer in exportList:
            orderText += layer + '\n'
            for x in range(len(layers)):
                if layers[x][0] == layer:
                    layerIdx = x
            coloringText += "{:s}:{:s}\n".format(
                layer,
                getColoringData(
                    svgXml, layer, layers[0][1],
                    layers[layerIdx][1]))
        if args.o or args.a:
            dbgPrint("Writing order layer file to {:s} with the following text:\n{:s}".format(str(Path(svgFolder / LAYER_ORDER_FNAME)), orderText))
            Path(svgFolder / LAYER_ORDER_FNAME).write_text(orderText)
        if args.c or args.a:
            Path(svgFolder / COLORING_FNAME).write_text(coloringText)


def prepareConversions(workload):
    #Split the workload
    initStartPoint = 0
    workLoadCount = len(workload)
    #dbgPrint("Workload count is {:d}".format(workLoadCount))
    taskCount = math.floor(workLoadCount / CPU_CORES)
    workers = []
    for cpuNum in range(CPU_CORES):
        #dbgPrint("Setting up worker {:d}".format(cpuNum))
        startPoint = taskCount * cpuNum
        if cpuNum == CPU_CORES - 1:
            endPoint = workLoadCount - 1
        else:
            endPoint = (taskCount * (cpuNum+1)) -1
        #dbgPrint("start: {:d}, end: {:d}".format(startPoint, endPoint))
        procWorkload = workload[startPoint:endPoint+1]
        dbgPrint(str(procWorkload) + " ({:d})".format(len(procWorkload)))
        proc = multiprocessing.Process(target=convertSvgToPng, args=(procWorkload,))
        workers.append(proc)
        proc.start()

    for worker in workers:
        worker.join()


        
if __name__ == '__main__':
    argParser = argparse.ArgumentParser(description="Converts svgs to pngs and writes text files containing information to help create a replication of the svg image.")
    argParser.add_argument("--a", help=argparse.SUPPRESS, default=True)
    argParser.add_argument("--i", help="Create png files", action="store_true")
    argParser.add_argument("--o", help="Create offset position files", action="store_true")
    argParser.add_argument("--c", help="Create coloring instruction files", action="store_true")
    argParser.add_argument("--d", help="Print debugging information", action="store_true")
    
    args = argParser.parse_args()
    if args.c or args.i or args.o:
        args.a = False
    if args.d:
        DEBUG_PRINT = True
    svgList = glob.glob("*.svg")
    #dbgPrint(svgList)

    errorList = []
    svgWorkload = []
    for svg in svgList:
        #Make a sub folder for the layers of the current svg
        svgFolder = Path(Path(svg).stem)
        if svgFolder.exists() == False:
            svgFolder.mkdir()
        #file = ).open()
        svgFile = Path(svg)
        if svgFile.exists():
            #dbgPrint("Working on {:s}".format(svg))
            xml = BeautifulSoup(svgFile.read_text(), "xml")
            #Need to find the root layer. To
            rootLayer = findRootLayer(xml.svg)
            dbgPrint("Root Layer is: {:s}".format(str(rootLayer)))
            #With the rootLayer, we can get the next depth of layers which will be exported. Only supporting a depth of 2 (root and its children) for simplicity.
            exportList = []
            for child in rootLayer:
                if child.name == 'g':
                    try:
                        exportList.append(child['id'])
                    except():
                        errorList.append([svg, child.parent['id']])
                        #print("Unable to convert {:s}, make sure that the children of layer {:s} are all valid".format(svg, child.parent['id']))
            dbgPrint(exportList)
            svgWorkload.append((svg, exportList, svgFolder))
        else:
            print("Unable to open svg file {:s}".format(svg))
    prepareConversions(svgWorkload)
    #convertSvgToPng(svgWorkload)
    print("Finished converting svg to pngs")
    if len(errorList) > 0:
       print("The following files could not be converted:")
       print("File name (Layer used as the start point)\n")
       for error in errorList:
           print("{:s} ({:s})".format(error[0], error[1]))
    #Side note: Normally the maximum scaling for a sprite is about x3. Therefore scaling up svgs by at least x5 should be done. x10 is excessive but would allow for scaling up the animation by ~x2.5 in the program without worrying about artifacting. x12 allows x3.5 scaling. x15 is too much but would allow x4.4 scaling.

