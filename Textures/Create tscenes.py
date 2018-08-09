#!python3
from pathlib import Path
import math

#This script should be run from the folder containing images/textures used for character parts

#The upscale factor applied to the original vector graphics before they were converted to pngs.
#Used as reference to know how big the original graphics were intended to be.
UPSCALE_FACTOR = 5.0
PROJECT_ROOT_DIR = Path("..").resolve()

RES_STR = "[ext_resource path=\"res://{:s}\" type=\"Texture\" id={:d}]\n"
def createResourceText(imgList):
    resBlock = ""
    for x in range(0,len(imgList)):
        resourcePath = imgList[x].resolve().relative_to(PROJECT_ROOT_DIR)
        resBlock += RES_STR.format(str(resourcePath), x+1)
    #print(resBlock)
    return resBlock

NODE_STR = "[node name=\"{:s}\" type=\"Node2D\" index=\"0\"]\n"
NODE_CHILD_STR = '''[node name=\"{0:s}\" type=\"Sprite\" parent=\".\" index=\"{1:d}\"]
scale = Vector2( {2:f}, {2:f} )
texture = ExtResource( {3:d} )\n'''
OFF_STR = "offset = Vector2( {:f}, {:f} )\n"

def createNodeText(objectName, imgList, offsets=None):
    nodeBlock = NODE_STR.format(objectName)
    for x in range(0, len(imgList)):
        nodeBlock += NODE_CHILD_STR.format(str(imgList[x].stem), x, 1.0/UPSCALE_FACTOR, x+1)
        if offsets:
            nodeBlock += OFF_STR.format(offsets[0], offsets[1])
    return nodeBlock

def createSceneFileText(resText, nodeText):
    nodeCount = nodeText.count("[node name=\"")
    return '''[gd_scene load_steps={:d} format=2]

{:s}
{:s}\n'''.format(nodeCount, resText, nodeText)

def correctPngListOrder(imgList, orderList):
    #for orderedLayer in orderList:
    #    for unorderedLayer in imgList:
    #        if str(unorderedLayer).find(orderedLayer) > -1:
    #            tmpList.append(unorderedLayer)
    return [unorderedLayer for orderedLayer in orderList for unorderedLayer in imgList if str(unorderedLayer).find(orderedLayer) > -1]

#Grab all the folders in the cwd and put them in a list
folders = [folder for folder in Path(".").iterdir() if folder.is_dir()]

#Find project root folder.


for folder in folders:
    #Do a lazy check and see that the folder doesn't have a tscn.
    #if len(list(folder.glob('*.tscn'))) == 0:
        #Need to create a tscn.
    pngList = list(folder.glob('*.png'))
    #Need to rearrange the png list to match the proper order for the layers
    orderFile = Path(folder / 'LayerOrder.txt')
    if orderFile.exists() and orderFile.stat().st_size > 0:
        layerOrder = orderFile.read_text()
        #print(correctPngListOrder(pngList, layerOrder.splitlines()))
        pngList = correctPngListOrder(pngList, layerOrder.splitlines())
    
    resText = createResourceText(pngList)
    #Check if the file for the image offsets exists
    offsetFile = Path(folder / 'Offsets.txt')
    print("Reading {:s}".format(str(offsetFile)))
    offsets = None
    if offsetFile.exists() and offsetFile.stat().st_size > 0:
        offsetParts = offsetFile.read_text().split(',')
        if len(offsetParts) >= 2:
            offsets = [float(offsetParts[0]), float(offsetParts[1])]
            if offsets.count(math.nan) > 0:
                offsets = None
            #print(offsets)
    nodeText = createNodeText(folder.name, pngList, offsets)
    output = createSceneFileText(resText, nodeText)
    #print(Path(folder / str(folder.name + ".tscn")))
    tscn = Path(folder / str(folder.name + ".tscn"))
    tscn.write_text(output)
