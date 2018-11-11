#!python3
import re
from pathlib import Path
import math
from enum import Enum
# Commonly used project paths constants
PROJECT_ROOT_ABS_PATH = Path(".").resolve()
PART_ANIMATIONS_PATH = Path("./Part Animations")
BASE_CHAR_ANIMS_PATH = Path("./Base Character Animations")
TEST_ANIM_PATH = Path(BASE_CHAR_ANIMS_PATH / "Testing")
CHAR_PARTS_PATH = Path("./Char Parts")
TEXTURES_PATH = Path("./Textures")
CHARACTER_PARTS_TEXTURE_PATH = TEXTURES_PATH / "Character Parts"
TEXTURE_CGROUP_PATH = TEXTURES_PATH / "Color Groups.txt"
CREATION_INFO_STR = "Creation Info"
CREATION_INFO_PATH = BASE_CHAR_ANIMS_PATH / CREATION_INFO_STR


class MASKING(Enum):
    normal = -1
    mask = 0
    masked = 1
    
    
def SplitAnimationName(origStr, maxSplits=1):
    variantSplitList = re.split("(-|_)", origStr, maxsplit=maxSplits)
    return variantSplitList


def GetCharPartSections(partName):
    partSections = SplitAnimationName(partName, 0)
    sectionDict = {"name": "", "variant": "", "side": ""}
    if len(partSections) > 0:
        sectionDict["name"] = partSections[0]
    if len(partSections) >= 3:
            if "-" in partSections[1]:
                sectionDict["variant"] = partSections[2]
            elif "_" in partSections[1]:
                sectionDict["side"] = partSections[2]
            if len(partSections) == 5:
                if "_" in partSections[3]:
                    sectionDict["side"] = partSections[4]
    return sectionDict


Z_INDEX_PADDING = int(50)


def loadColorGroups():
    colorDict = {}
    if TEXTURE_CGROUP_PATH.exists():
        oldCGroupContents = TEXTURE_CGROUP_PATH.read_text()
        for line in oldCGroupContents.split('\n'):
            lineParts = line.split(',', 2)
            if len(lineParts) > 1 and len(lineParts[1]) > 0:
                colorDict[lineParts[0]] = lineParts[1]
    return colorDict

                
def analyzeCreationInfo(animationName):
    # Returns a dictionary with a key of the node name (part name + side flag)
    # and a tuple for the value, with the tuple's contents being
    # the z index, char part variant tag, mask type, and the mask id.
    ciText = ""
    ciFile = CREATION_INFO_PATH / "{:s}.txt".format(animationName)
    data = {}
    if ciFile.exists() and ciFile.is_file:
        ciText = ciFile.read_text().rstrip()
        layers = ciText.split("\n")
        maskID = 0
        # Godot has a range of -4096 to 4096 for z index.
        # In order for leeway every layer will have a difference of
        # 50 and all the z indexes averaged should be as close to 0
        # as possible.
        z_size = (len(layers) * Z_INDEX_PADDING) / 2
        z_size = math.floor(z_size / Z_INDEX_PADDING) * Z_INDEX_PADDING
        z_index = 0 + int(z_size)
        for layer in layers:
            info = layer.split(",")
            #print(info)
            partSections = SplitAnimationName(info[0], 0)
            partName = partSections[0]
            sideFlag = ""
            variantTag = ""

            if len(partSections) >= 3:
                if "-" in partSections[1]:
                    variantTag = partSections[2]
                elif "_" in partSections[1]:
                    sideFlag = partSections[2]
                if len(partSections) == 5:
                    if "_" in partSections[3]:
                        sideFlag = partSections[4]
            nodeName = partName
            if len(sideFlag) > 0:
                nodeName += " ({:s})".format(sideFlag)
            if info[1] == "mask":
                maskID += 1
            data[nodeName] = {"z_index": z_index, "variant": variantTag,
                              "mask_type": MASKING[info[1]].value,
                              "mask_layer": maskID if info[1] != "normal" else -1}

            z_index -= Z_INDEX_PADDING
    return data


def VerifyProjectFolderStructure():
    if not PART_ANIMATIONS_PATH.exists():
        PART_ANIMATIONS_PATH.mkdir()
    if not BASE_CHAR_ANIMS_PATH.exists():
        BASE_CHAR_ANIMS_PATH.mkdir()
    if not TEST_ANIM_PATH.exists():
        TEST_ANIM_PATH.mkdir()
    if not CHAR_PARTS_PATH.exists():
        CHAR_PARTS_PATH.mkdir()
    if not TEXTURES_PATH.exists():
        TEXTURES_PATH.mkdir()
    if not CREATION_INFO_PATH.exists():
        CREATION_INFO_PATH.mkdir()
    if not CHARACTER_PARTS_TEXTURE_PATH.exists():
        CHARACTER_PARTS_TEXTURE_PATH.mkdir()
