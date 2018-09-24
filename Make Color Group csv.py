#!python3

import pyUtils
from pathlib import Path

CGroupFile = "Color Groups.txt"


# For once a python script won't be completely destructive and
# overwrite everything
#CGroupPath = (pyUtils.TEXTURES_PATH / CGroupFile)
colorGroups = pyUtils.loadColorGroups()

output = ""
print(colorGroups)
for texture in pyUtils.TEXTURES_PATH.rglob("*.png"):
    if texture.parent != pyUtils.TEXTURES_PATH:
        texturePath = str(texture.relative_to(pyUtils.TEXTURES_PATH))[:-4]
        print(texturePath)
        print(texturePath in colorGroups)
        if texturePath in colorGroups:
            output += "{:s},{:s}\n".format(texturePath, colorGroups[texturePath])
            del colorGroups[texturePath]
        else:
            # Try to find the best guess for the color group.
            # This is usually what follows the last underscore
            # but on script reruns this behavior can be stop by
            # "setting" the group to "UNUSED".
            splitPath = texturePath.split("_")
            groupGuess = ""
            if len(splitPath) > 1:
                groupGuess = splitPath.pop()
            output += "{:s},{:s}\n".format(texturePath, groupGuess)

if len(colorGroups) > 0:
    output += '''\n#The following textures were not found within the texture folders\n'''
    for unusedPath in colorGroups:
        output += "#{:s},{:s}".format(unusedPath, colorGroups[unusedPath])
    

CGroupPath.write_text(output)
