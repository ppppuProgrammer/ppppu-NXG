#!python3
import re
from pathlib import Path

#Commonly used project paths constants
PROJECT_ROOT_ABS_PATH = Path(".").resolve()
BASE_CHAR_ANIMS_PATH = Path("./Base Character Animations")
CHAR_PARTS_PATH = Path("./Char Parts")
CREATION_INFO_STR = "Creation Info"

def SplitAnimationName(origStr, maxSplits=1):
    variantSplitList = re.split("(-|_)", origStr, maxsplit=maxSplits)
    return variantSplitList

def GetCharPartSections(partName):
    partSections = SplitAnimationName(partName, 0)
    sectionDict = {"name": "","variant": "", "side": ""}
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
