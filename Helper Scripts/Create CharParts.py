#!python3

from pathlib import Path
import re
import os
import pyUtils


pyUtils.VerifyProjectFolderStructure()
#Animation folder contains the various unique names that will be used for the char parts.
animFolder = pyUtils.PART_ANIMATIONS_PATH
partNameList = [partAnimDir.stem for partAnimDir in animFolder.iterdir() if partAnimDir.is_dir()]
#print(partNameList)
#Remove L/R versions. CharParts will not use 2 distinct instances for animations. Instead of LegL and LegR objects it will just be 2 instances of a Leg object which has 2 animation resources, one for the Left and one for the Right.
#LR_re = re.compile('(L|R)$')
cleanPartsList = []
for partName in partNameList:
    #Remove variant and directional "tags"
    strippedName = re.sub('(-.*|_.*)', "", partName)
    if strippedName not in cleanPartsList:
        cleanPartsList.append(strippedName)
#print(cleanPartsList)
#Texture folder contains the image textures for a char part. While it may be a bit redundant to have the textures in their own tscn to be placed into another tscn this will be done to ease future going plans (such as consolidating multiple unique versions for a char part into 1, an example of which is the Arm char part, which has 3 versions. Instead of having Arm1, Arm2, and Arm3, just have Arm which can switch the texture used between any of the 3.)
texFolder = pyUtils.CHARACTER_PARTS_TEXTURE_PATH
partTextureDirList = [texDir.stem for texDir in texFolder.iterdir() if texDir.is_dir()]
#print(partTextureDirList)
#Go into the char parts folder and create the tscn for the char part.
TSCN_HEADER_STR = '''[gd_scene load_steps={:d} format=2]

[ext_resource path="res://Char Parts/BaseCharPart.tscn" type="PackedScene" id=1]
{:s}
'''
EXT_RES_STR = '''[ext_resource path="res://{:s}" type="{:s}" id={:d}]\n'''
#ANIM_PLAYER_EXTRES_STR = '''"anims/{:s}" = ExtResource( {:d} )\n'''
BASE_NODE_STR = '''[node name="{:s}" index="0" instance=ExtResource( 1 )]
initLoadTextures = PoolStringArray( {:s} )
initLoadOverTextures = PoolStringArray(  )
initLoadUnderTextures = PoolStringArray(  )
mainTexId = -1
overTexId = -1
underTexId = -1

'''
#[node name="AnimationPlayer" parent="." index="0"]
#root_node = NodePath("..")
#autoplay = ""
#playback_process_mode = 1
#playback_default_blend_time = 0.0
#playback_speed = 1.0
#{:s}blend_times = [  ]

#'''#.format(name, textureTscnPaths, animation resources)


#Format for animations are partGroup-variant_L/R
chPartsFolder = pyUtils.CHAR_PARTS_PATH
for charPart in cleanPartsList:
    #Get animation resources
    #currentPartFolders = animFolder.glob(charPart + '-.*|_.*')
    #
    currentPartFolders = [folder for folder in os.listdir(animFolder) if re.search(charPart + '($|-.*|_.*)', folder)]
    #print(list(currentPartFolders))
    animResourceString = ""
    animPlayerAnimsString = ""
    resCounter = 2
    #Do animation related stuff
    #for folderName in currentPartFolders:
        #animResList = Path(animFolder / folderName).glob("*.tres")
        #for animRes in animResList:
        #    animResourceString += EXT_RES_STR.format(str(animRes.resolve().relative_to(pyUtils.PROJECT_ROOT_ABS_PATH)), "Animation", resCounter)
        #    animResName = str(animRes.stem)
        #    animPlayerAnimsString += ANIM_PLAYER_EXTRES_STR.format(animResName, resCounter)
        #    resCounter += 1
    #Do texture related stuff now
    texturePathStrings = ""
    currentPartTexFolders = sorted([folder for folder in os.listdir(texFolder) if re.search('^' + charPart + '($|-.*|_.*)', folder)])
    for texFolderName in currentPartTexFolders:
        texTscns = Path(texFolder / texFolderName).glob("*.tscn")
        for texTscn in texTscns:
            if len(texturePathStrings) > 0:
                texturePathStrings += ", "
            texturePathStrings += '\"' + str(texTscn.resolve().relative_to(pyUtils.PROJECT_ROOT_ABS_PATH)) + '\"'
    #print(charPart + ": " + str(list(currentPartTexFolders)))
    #print(animResourceString)
    #print(animPlayerAnimsString)
    allExtResString = animResourceString
    outputStr = TSCN_HEADER_STR.format(3,allExtResString) + BASE_NODE_STR.format(charPart, texturePathStrings, animPlayerAnimsString)
    #print(outputStr)
    fileName = charPart + ".tscn"
    chPartFilePath = Path(chPartsFolder / fileName)
    chPartFilePath.write_text(outputStr)
    
