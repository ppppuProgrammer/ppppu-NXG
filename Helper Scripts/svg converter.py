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
from PIL import Image, ImageColor
import numpy.matlib
import numpy
# Run this script from the folder with the svg files you want to convert

charStripper = re.compile("[^0-9]")
LAYER_ORDER_FNAME = "LayerOrder.txt"
COLORING_FNAME = "ColoringInfo.txt"
CPU_CORES = multiprocessing.cpu_count()
DEBUG_PRINT = not False
# Passed in system arguments

flr = math.floor
ceil = math.ceil
args = None
colors = ["#1A1A1A", "#333333", "#4D4D4D", "#666666",
          "#808080", "#999999", "#B3B3B3", "#CCCCCC"]


def getColorSection(colorStr):
    # Convert #RGB to #RRGGBB
    shortFormMatch = re.match(
        "#([A-F|0-9])([A-F|0-9])([A-F|0-9])$", str(colorStr))
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
    x, y, w, h = sizeTuple
    x = flr(x)
    y = flr(y)
    w = ceil(w) + 1
    h = ceil(h) + 1
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
        return (x, y, w, h)
    return None


#iSize and cSize must be tuples with 4 values (x,y,w,h)
def calculateArea(iSize, cSize):
    dbgPrint("CalculateArea()- i: {:s}; c: {:s}".format(
        str(iSize), str(cSize)))
    x0 = cSize[0] + iSize[0]
    x1 = x0 + iSize[2]
    y0 = cSize[1] + cSize[3] - iSize[1]
    y1 = y0 - iSize[3]
    dbgPrint("CalculateArea() final dimensions: {},{},{},{}".format(
        x0, y0, x1, y1))
    return (x0, y0, x1, y1)


def exportLayersToPng(svg, layers, exportLayers, outDir):
    #Need to get the image size for the drawings. The first layer has all the info we need.
    imageSize = calculateImageSize(layers[0][1])
    dbgPrint(imageSize)
    #Need to get the canvas size for the file.
    canvasSize = getCanvasSize(svg)
    areaSize = calculateArea(imageSize, canvasSize)
    #Calculate the area that will be exported.
    imageSizeArg = "{:f}:{:f}:{:f}:{:f}".format(*areaSize)
    exportedImagePaths = {}
    #dbgPrint("Printing Layers: {:s}".format(str(layers)))
    foundRoot = False
    #Go through the layers list and export the layers. Skip the first layer since it is for the svg as a whole.
    if args.i or args.a:
        for layer in layers:
            id = layer[0]
            if id in exportLayers:
                pngFileName = "{:s}/{:s}.png".format(str(outDir), id)
                #dbgPrint("Exporting layer {:s}".format(id))
                subprocess.call(
                    ['inkscape',
                     '--export-area={:s}'.format(imageSizeArg),
                     '--export-id={:s}'.format(id),
                     '--export-id-only',
                     '--export-png={:s}'.format(pngFileName),
                     '{:s}'.format(svg)])
                exportedImagePaths[id] = pngFileName
    return exportedImagePaths


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


def getShiftedPoint(point, imgSize):
    # Shift position by imgSize's x and y to have the origin be 0,0
    dbgPrint(point)
    dbgPrint("imgSize: {}".format(imgSize))
    shiftedPoint = [point[0] - imgSize[0], point[1] - imgSize[1]]
    dbgPrint("shifted: {}".format(shiftedPoint))
    return (shiftedPoint[0], shiftedPoint[1])

def translatePointForLayer(point, layerSize):
    #Need to start from left (for x) and bottom (for y)
    pass

def getTransformedPoint(point2, matrix3):
    if len(point2) == 2:
        point3 = numpy.array([point2[0], point2[1], 1])
        transformedPoint = point3.dot(matrix3.T)
        return (transformedPoint.item(0), transformedPoint.item(1))
    else:
        return None

    
def getRadiusNormalized(radius, imgSize):
    return radius / min(imgSize[2], imgSize[3])


def getColoringData(svgXml, layer, imgSize, layerSize):
    dbgPrint(layer)
    dbgPrint("layer: {:f},{:f},{:f},{:f}".format(*layerSize))
    layerElement = svgXml.find(id=layer)
    #elementTransform = layerElement["transform"] if layerElement.has_attr("transform") else None
    # Only care about the first child. If multiple draw paths are used, assume
    # that all children are like each other in terms of fill and/or stroke
    
    elementChild = layerElement.find(name="path")
    # Find the concatenated transform for the layer.
    # Start the matrix with an indentiy matrix
    elementConcatMatrix = numpy.identity(3)
    traverseLayer = layerElement
    while traverseLayer.name != "svg":
        if traverseLayer.has_attr("transform"):
            matrixResults = re.findall(
                "([+-]?[0-9]*[.]?[0-9]+)",
                traverseLayer["transform"])
            if len(matrixResults) == 6:
                elementConcatMatrix = numpy.matrix(
                    "{} {} {}; {} {} {}; 0 0 1".format(
                        matrixResults[0], matrixResults[2],
                        matrixResults[4], matrixResults[1],
                        matrixResults[3], matrixResults[5])) * elementConcatMatrix
        traverseLayer = traverseLayer.parent
    #print(elementChild)
    gradientUrl = None
    gradientMatrixText = None
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
        grMatrix = numpy.identity(3)
        gradientUniqueSections = []
        for stop in gradient.find_all("stop"):
            colorSectResult = getColorSection(stop["stop-color"])
            if colorSectResult > 0 and colorSectResult not in gradientUniqueSections:
                gradientUniqueSections.append(colorSectResult)
                colorSections += "{:d},".format(colorSectResult)
        #print(flatConcatMatrix)
        trScaleX = elementConcatMatrix.item((0, 0))
        trScaleY = elementConcatMatrix.item((1, 1))
        #trPosX = elementConcatMatrix.item((0, 2))
        #trPosY = elementConcatMatrix.item((1, 2))
        #print("{}, {}, {}, {}".format(trScaleX, trScaleY, trPosX, trPosY))
        if gradient.has_attr("gradientTransform"):
            grMatrixResults = re.findall(
                "([+-]?[0-9]*[.]?[0-9]+)",
                gradient["gradientTransform"])
            if len(grMatrixResults) == 6:
                grMatrix = numpy.matrix(
                    "{} {} {}; {} {} {}; 0 0 1".format(
                        grMatrixResults[0], grMatrixResults[2],
                        grMatrixResults[4], grMatrixResults[1],
                        grMatrixResults[3], grMatrixResults[5]))
                #grMat2 = grMatrix * elementConcatMatrix
                #grMat3 = elementConcatMatrix * grMatrix
                #print(layer)
                #print(elementConcatMatrix)
                #print(grMatrix)
                #print(grMat2)
                #print(grMat3)
                # Need to convert a b c d tx ty to 
                # a c tx    uses   1 4 7
                # b d ty    uses   2 5 8
                # ? ? ?     uses   3 6 9
                # uses indicates order to use for Godot Basis construction
                gradientMatrixText = "({}, {}, 0, {}, {}, 0, {}, {}, 1)".format(
                    grMatrixResults[0], grMatrixResults[1],
                    grMatrixResults[2], grMatrixResults[3],
                    grMatrixResults[4], grMatrixResults[5])
        if gradient.name == "radialGradient":
            grRadius = float(gradient['r']) * max(trScaleX, trScaleY)
            grCenter = getTransformedPoint(
                [float(gradient['cx']), float(gradient['cy'])],
                grMatrix)
            #[(float(gradient['cx']) * trScaleX) + trPosX,
            #            (float(gradient['cy']) * trScaleY) + trPosY]
            grFocus = getTransformedPoint(
                [float(gradient['fx']), float(gradient['fy'])],
                grMatrix)
            #[(float(gradient['fx']) * trScaleX) + trPosX,
            #           (float(gradient['fy']) * trScaleY) + trPosY]
            return ["Radial", colorSections,
                    getShiftedPoint(grCenter, layerSize),
                    getShiftedPoint(grFocus, layerSize),
                    grRadius,
                    #getRadiusNormalized(grRadius, layerSize),
                    gradientMatrixText if gradientMatrixText else "null"]
        elif gradient.name == "linearGradient":
            grStart = getTransformedPoint(
                [float(gradient['x1']), float(gradient['y1'])],
                grMatrix)
            #[(float(gradient['x1']) * trScaleX) + trPosX,
            #           (float(gradient['y1']) * trScaleY) + trPosY]
            grEnd = getTransformedPoint(
                [float(gradient['x2']), float(gradient['y2'])],
                grMatrix)
            #[(float(gradient['x2']) * trScaleX) + trPosX,
            #         (float(gradient['y2']) * trScaleY) + trPosY]
        # Those points are relative to the top left corner of the layer's object, which are offset from the overall image dimensions.
            return ["Linear", colorSections,
                    getShiftedPoint(grStart, layerSize),
                    getShiftedPoint(grEnd, layerSize),
                    gradientMatrixText if gradientMatrixText else "null"]
    else:
        colorTarget = None
        if elementChild.has_attr("fill"):
            if elementChild["fill"] is not "none":
                colorTarget = elementChild["fill"]
        elif elementChild.has_attr("stroke"):
            if elementChild["stroke"] is not "none":
                colorTarget = elementChild["stroke"]
        elif elementChild.has_attr("style"):
            styleAttrs = re.split(":|;", str(elementChild["style"]))
            for x in range(len(styleAttrs), 2):
                attr = styleAttrs[x]
                if ((attr == "fill" or attr == "stroke") and styleAttrs[x+1] is not "none"):
                    colorTarget = styleAttrs[x+1]

        if colorTarget:
            colorSectResult = getColorSection(colorTarget)
            if colorSectResult > 0:
                colorSections += "{:d},".format(colorSectResult)
        return ["Solid", colorSections]


def isRGBcolorsClose(color1, color2):
    if abs(color1[0] - color2[0]) < 10 and abs(
            color1[1] - color2[1]) < 10 and abs(
                color1[2] - color2[2]) < 10:
        return True
    else:
        return False

    
def fixPngColorSections(pngPath, sectionsToFix):
    modifiedPixels = []
    if Path(pngPath).exists():
        png = Image.open(pngPath)
        for pixel in png.getdata():
            for x in sectionsToFix.split(","):
                if x == '':
                    continue
                sectionColor = ImageColor.getrgb(colors[int(x)-1])
                #print(sectionColor)
                #if isRGBcolorsClose(
                #        pixel, sectionColor):
                if pixel[3] > 0:
                    pixel = (int(sectionColor[0]),
                             int(sectionColor[1]),
                             int(sectionColor[2]), pixel[3])
                    #print(pixel)
                # Only supports 1 color change
                break
            #print(str(type(pixel[0])) + str(type(pixel[1])) + str(type(pixel[2])) + str(type(pixel[3])))
            modifiedPixels.append(pixel)
        png.putdata(modifiedPixels)
        #print(png.filename)
        png.save(png.filename, png.format)


def convertSvgToPng(jobsList):
    for job in jobsList:
        svg, exportList, svgFolder = job
        layers = transformLayerList(subprocess.check_output(['inkscape', '-S', '{:s}'.format(svg)]).split(b'\n'))
        #print(layers)
        pngFilePaths = {}
        if args.a or args.i:
            pngFilePaths = exportLayersToPng(
                svg, layers, exportList, svgFolder)
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
            coloringData = getColoringData(
                    svgXml, layer, layers[0][1],
                    layers[layerIdx][1])
            coloringDataString = ""
            for colorData in coloringData:
                if len(coloringDataString) > 0:
                    coloringDataString += ";"
                coloringDataString += str(colorData)
            if args.nofix is False and len(pngFilePaths) > 0:
                fixPngColorSections(
                    pngFilePaths[layer], coloringData[1])
            coloringText += "{:s}:{:s}\n".format(
                layer, coloringDataString)
                
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
            endPoint = (taskCount * (cpuNum+1)) - 1
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
    argParser.add_argument("--nofix", help="Disables fixing section color inaccuracies caused by how inkscape handles transparency when exporting a png", action="store_true", default=False)
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

