#!python3
import pyUtils
from pathlib import Path
import math
CHAR_PARTS_PATH = Path("./Char Parts")
BASE_CHAR_ANIMS_PATH = Path("./Base Character Animations")
CREATION_INFO_STR = "Creation Info"
Z_INDEX_PADDING = int(50)
TSCN_STR = '''[gd_scene load_steps={:d} format=2]

{:s}
[node name="{:s}" type="Node2D" index="0"]

{:s}'''

EXT_RES_STR = '''[ext_resource path="res://{:s}" type="PackedScene" id={:d}]
'''

CHILD_NODE_STR = '''[node name="{:s}" parent="." index="{:d}" instance=ExtResource( {:d} )]
{:s}
'''

#Get a list of paths for the character parts that can be used
charPartsDict = {}
partsGlobResult = CHAR_PARTS_PATH.glob("*.tscn")
for partPath in partsGlobResult:
    charPartsDict[partPath.stem] = partPath
#Go into anims path and read each txt file in the Creation Info subfolder.
#Then create a tscn using the layer information that was in the txt.

creationTxtList = Path(BASE_CHAR_ANIMS_PATH / CREATION_INFO_STR).glob("*.txt")
for txt in creationTxtList:
    extResCounter = 1
    childIndex = 0
    contents = txt.read_text()
    layers = contents.split("\n")
    extResourcesText = ""
    childNodesText = ""
    #Godot has a range of -4096 to 4096 for z index. In order for leeway every layer will have a difference of 50 and all the z indexes averaged should be as close to 0 as possible.
    z_size = (len(layers) * Z_INDEX_PADDING) / 2
    z_size = math.floor(z_size / Z_INDEX_PADDING) * Z_INDEX_PADDING
    z_index = 0 + int(z_size)
    #print("{:d}, {:d}".format(z_size, z_index))
    #Do an initial scan of the char parts list and see if the file name was used for a layer.
    for layer in layers:
        info = layer.split(",")
        partSections = pyUtils.SplitAnimationName(info[0], 0)
        partName = partSections[0]
        sideFlag = ""
        variantTag = ""
        propertiesText = ""
        print(partSections)
        if len(partSections) >= 3:
            if "-" in partSections[1]:
                variantTag = partSections[2]
            elif "_" in partSections[1]:
                sideFlag = partSections[2]
            if len(partSections) == 5:
                if "_" in partSections[3]:
                    sideFlag = partSections[4]
        #print(variantTag + ", " + sideFlag)
        if partName in charPartsDict:
            relPath = charPartsDict[partName].resolve().relative_to(pyUtils.PROJECT_ROOT_ABS_PATH)
            extResourcesText += EXT_RES_STR.format(str(relPath), extResCounter)
            nodeName = partName
            if len(sideFlag) > 0:
                nodeName += " ({:s})".format(sideFlag)
            propertiesText += "z_index = {:d}".format(z_index)
            childNodesText += CHILD_NODE_STR.format(nodeName, childIndex, extResCounter, propertiesText)
            extResCounter += 1
            childIndex += 1
        z_index -= Z_INDEX_PADDING
    animationName = txt.stem[:txt.stem.find(" ")]
    output = TSCN_STR.format(extResCounter+1, extResourcesText, animationName, childNodesText)
    writePath = Path(BASE_CHAR_ANIMS_PATH / (animationName + ".tscn"))
    writePath.write_text(output)
