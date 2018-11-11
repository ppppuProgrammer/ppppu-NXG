#!python3
from pathlib import Path
import math
import pyUtils
import re
import enum
# The upscale factor applied to the original vector graphics before they were converted to pngs.
# Used as reference to know how big the original graphics were intended to be.
UPSCALE_FACTOR = 5.0
sub_res_dict = {}
res_dict = {}
RES_STR = "[ext_resource path=\"res://{:s}\" type=\"{:s}\" id={:d}]\n"

def createResourceText(imgList):
    resBlock = ""
    for x in range(0, len(imgList)):
        resourcePath = imgList[x].resolve().relative_to(
            pyUtils.PROJECT_ROOT_ABS_PATH)
        res_dict["res://{:s}".format(str(imgList[x]))] = len(res_dict) + 1
        resBlock += RES_STR.format(
            str(resourcePath), "Texture", len(res_dict))
    #print(resBlock)
    return resBlock

def createColorShaderResources():
    res_CS_num = len(res_dict) + 1
    res_dict["ColorShader"] = res_CS_num
    res_LT_num = len(res_dict) + 1
    res_dict["LookupTex"] = res_LT_num
    return '''[ext_resource path="res://Shaders/Apply Color Group.shader" type="Shader" id={:d}]
[ext_resource path="res://Textures/Color Lookup.png" type="Texture" id={:d}]'''.format(
        res_CS_num, res_LT_num)


COLOR_PREFIX = "Color Shader_{}"


def createColorShaderBaseBlock(nodeName, colorType, priority=0):
    shaderDictName = COLOR_PREFIX.format(nodeName)
    sub_res_num = len(sub_res_dict) + 1
    sub_res_dict[shaderDictName] = sub_res_num
    return '''
[sub_resource type="ShaderMaterial" id={:d}]

render_priority = {:d}
shader = ExtResource( {:d} )
shader_param/color_method = {:d}
shader_param/sectionReferenceTex = ExtResource( {:d} )
'''.format(sub_res_num, priority, res_dict["ColorShader"],
           colorType, res_dict["LookupTex"])


def createColorShaderParamBlock(sectionNum, paramsList):
    return '''shader_param/s{0:s}_UV1 = {1:s}
shader_param/s{0:s}_UV2 = {2:s}
shader_param/s{0:s}_radius = {3:s}
shader_param/s{0:s}_use_focus_point = {4:s}
shader_param/s{0:s}_gradient_transform = {5:s}'''.format(
        sectionNum,
        "Vector2{}".format(paramsList[0]) if paramsList[0] != "null" else paramsList[0],
        "Vector2{}".format(paramsList[1]) if paramsList[1] != "null" else paramsList[1],
        paramsList[2], paramsList[3],
        "Basis{}".format(paramsList[4]) if paramsList[4] != "null" else paramsList[4])


NODE_STR = '''[node name="{:s}" index="0" instance=ExtResource( 1 )]
use_parent_material = true
variantName = "{:s}"

'''
NODE_CHILD_STR = '''[node name=\"{0:s}\" type=\"Sprite\" parent=\".\" index=\"{1:d}\" {4:s}]
script = ExtResource( 2 )
use_parent_material = false
scale = Vector2( {2:f}, {2:f} )
texture = ExtResource( {3:d} )\n'''
OFF_STR = "offset = Vector2( {:f}, {:f} )\n"
GROUP_STRING = '''groups=["ColorGrp_{:s}",]'''
colorGroupDict = pyUtils.loadColorGroups()


def createNodeText(objectName, imgList, offsets=None):
    variantName = pyUtils.GetCharPartSections(objectName)["variant"]
    if variantName == "":
        variantName = "Default"
    nodeBlock = NODE_STR.format(objectName, variantName)
    for x in range(0, len(imgList)):
        clrGroup = ""
        imgRelPath = str(imgList[x].relative_to(
            pyUtils.CHARACTER_PARTS_TEXTURE_PATH).with_suffix(""))
        if imgRelPath in colorGroupDict:
            group = colorGroupDict[imgRelPath]
            if group is not "UNUSED":
                clrGroup = GROUP_STRING.format(group)
        # res_dict[len(res_dict) + 1] = "res://{:s}".format(str(imgList[x]))
        nodeBlock += NODE_CHILD_STR.format(
            str(imgList[x].stem), x, 1.0 / UPSCALE_FACTOR,
            res_dict["res://{:s}".format(str(imgList[x]))], clrGroup)
        if offsets:
            nodeBlock += OFF_STR.format(offsets[0], offsets[1])
        shader_sub_res_name = COLOR_PREFIX.format(imgList[x].stem)
        if shader_sub_res_name in sub_res_dict:
            nodeBlock += "material = SubResource( {:d} )\n".format(
                sub_res_dict[shader_sub_res_name])
        #Finished with current sub node
        nodeBlock += "\n"
    return nodeBlock


def createSceneHeader(loadSteps):
    return "[gd_scene load_steps={:d} format=2]\n".format(loadSteps)


def createMainResText():
    res_dict["res://Textures/SpriteContainer.tscn"] = 1
    res_dict["res://Textures/CharPartSprite.gd"] = 2
    return '''[ext_resource path="res://Textures/SpriteContainer.tscn" type="PackedScene" id=1]
[ext_resource path="res://Textures/CharPartSprite.gd" type="Script" id=2]
'''

def correctPngListOrder(imgList, orderList):
    #for orderedLayer in orderList:
    #    for unorderedLayer in imgList:
    #        if str(unorderedLayer).find(orderedLayer) > -1:
    #            tmpList.append(unorderedLayer)
    return [unorderedLayer for orderedLayer in orderList for unorderedLayer in imgList if str(unorderedLayer).find(orderedLayer) > -1]


def main():
    pyUtils.VerifyProjectFolderStructure()
    #print(colorGroupDict)
    #Grab all the folders in the cwd and put them in a list
    folders = [folder for folder in pyUtils.CHARACTER_PARTS_TEXTURE_PATH.iterdir() if folder.is_dir()]
    
    for folder in folders:
        res_dict.clear()
        sub_res_dict.clear()
        created_shader_resources = False
        resources_text = createMainResText()
        subresources_text = ""
        # Do a lazy check and see that the folder doesn't have a tscn.
        # if len(list(folder.glob('*.tscn'))) == 0:
            #Need to create a tscn.
        pngList = list(folder.glob('*.png'))
        # Need to rearrange the png list to match the proper order for the layers
        orderFile = Path(folder / 'LayerOrder.txt')
        if orderFile.exists() and orderFile.stat().st_size > 0:
            layerOrder = orderFile.read_text()
            #print(correctPngListOrder(pngList, layerOrder.splitlines()))
            pngList = correctPngListOrder(pngList, layerOrder.splitlines())

        resources_text += createResourceText(pngList)
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
        coloringFile = Path(folder / 'ColoringInfo.txt')
        if coloringFile.exists() and coloringFile.stat().st_size > 0:
            print("Reading {:s}".format(str(coloringFile)))
            colorLayers = coloringFile.read_text().splitlines()
            for colorLayer in colorLayers:
                colorLayerParts = re.split(";|:", colorLayer)
                #print(colorLayerParts)
                if len(colorLayerParts) < 3:
                    continue
                colorLayerName = colorLayerParts[0]
                colorLayerMethod = colorLayerParts[1]
                #print(colorLayerMethod)
                colorLayerSections = [section.strip() for section in colorLayerParts[2].split(",") if section != ""]
                if len(colorLayerSections) == 0:
                    continue
                print(colorLayerSections)
                if created_shader_resources is False:
                    resources_text += createColorShaderResources()
                    created_shader_resources = True

                if colorLayerMethod == "Solid":
                    subresources_text += createColorShaderBaseBlock(
                        colorLayerName, 0)
                    for colorSect in colorLayerSections:
                        subresources_text += createColorShaderParamBlock(
                            colorSect, ["null", "null", "null", "null", "null"]) + "\n"
                elif colorLayerMethod == "Linear" or colorLayerMethod == "Radial":
                    subresources_text += createColorShaderBaseBlock(
                        colorLayerName,
                        1 if colorLayerMethod == "Linear" else 2)
                    colorLayerUV1 = colorLayerParts[3]
                    colorLayerUV2 = colorLayerParts[4]
                    colorLayerRadius = colorLayerParts[5] if colorLayerMethod == "Radial" else "null"
                    colorTransform = colorLayerParts[6] if colorLayerMethod == "Radial" else colorLayerParts[5]
                    if colorTransform != "null":
                        colorTransformParts = re.split(", ", colorTransform[1:-1])
                    for colorSect in colorLayerSections:
                        subresources_text += createColorShaderParamBlock(
                            colorSect,
                            [colorLayerUV1, colorLayerUV2, colorLayerRadius,
                             str(colorLayerUV1 != colorLayerUV2).lower() if colorLayerMethod == "Radial" else "null",
                             colorTransform])  + "\n"
                #print("sections: {}".format(colorLayerSections))
        nodeText = createNodeText(folder.name, pngList, offsets)
        fileHeader = createSceneHeader(len(res_dict) + 1)
        output = fileHeader + resources_text + "\n" + subresources_text + "\n" + nodeText
        #print(Path(folder / str(folder.name + ".tscn")))
        tscn = Path(folder / str("Sprite_" + folder.name + ".tscn"))
        tscn.write_text(output)

if __name__ == "__main__":
    # execute only if run as a script
    main()
