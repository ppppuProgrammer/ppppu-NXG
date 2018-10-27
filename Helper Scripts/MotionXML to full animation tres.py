#!python3
from bs4 import BeautifulSoup
from pathlib import Path
import pyUtils
from distutils import util
import math
# import pudb; pu.db
# Like motionXML to animation tres but exports all the track to one file instead of one for each char part
# Animation String
ANIM_HEADER='''[gd_resource type=\"Animation\" format=2]

[resource]

resource_name = \"{:s}\"
length = {:f}
loop = true
step = {:f}
'''#.format(Animation Name) (Don't actually uncomment this)

VALUE_TRACK_STR='''
tracks/{0:d}/type = "value"
tracks/{0:d}/path = NodePath(\"{1:s}\")
tracks/{0:d}/interp = 1
tracks/{0:d}/loop_wrap = true
tracks/{0:d}/imported = false
tracks/{0:d}/enabled = true
tracks/{0:d}/keys = {{
\"times\": PoolRealArray( {2:s} ),
\"transitions\": PoolRealArray( {3:s} ),
\"update\": {4:d},
\"values\": [ {5:s} ]
}}
'''

METHOD_TRACK_STR='''
tracks/{0:d}/type = "method"
tracks/{0:d}/path = NodePath("{1:s}")
tracks/{0:d}/interp = 1
tracks/{0:d}/loop_wrap = true
tracks/{0:d}/imported = false
tracks/{0:d}/enabled = true
tracks/{0:d}/keys = {{
"times": PoolRealArray( {2:s} ),
"transitions": PoolRealArray( {3:s} ),
"values": [ {{
"args": {4:s},
"method": "{5:s}"
}} ]
}}
'''

Vec2fStr = "Vector2( {:.4f}, {:.4f} )"
timeFormatStr = "{:.3f}"
propertyTypeFormat = {"pos": Vec2fStr, "skew": Vec2fStr,
                      "scale": Vec2fStr, "masking": "[ {:d}, {:d} ]", "variant": "[ 0, \"{:s}\" ]"}
propertyAnimPath = {"skew": ":exnSkew", "scale": ":exnScale", "pos": ":exnPos"}
propertyUpdateNum = {"skew": 4, "scale": 0, "pos": 0, "visible": 1, "z_index": 1}
propertyInterpolateMode = {"skew": 1}
methodProperties = ["masking", "variant"]
methodPropNames = {"masking": "setupMasking", "variant": "setVariantByName"}

cma = ", "
str2bool = util.strtobool
#trackNameFixes = {"": ""}
def createTrackStrings(trackDataDict, startTrackNum, nodeName="."):
    trackNum = startTrackNum
    trackStrList = []
    methodTrackCounter = 0
    #latestValue = None
    #A dictionary of lists for various properties. Property is the key, the list is the value. The lists are to contain tuples (time, value)
    propertyListDict = {}
    for time, propDict in trackDataDict.items():
        for prop, value in propDict.items():
            if prop not in propertyListDict:
                propertyListDict[prop] = []
            propertyListDict[prop].append((time, value))

    #Create the string for each track
    for prop, l in propertyListDict.items():
        latestValue = None
        #print(prop)
        propStr = ""
        transStr = ""
        timeStr = ""
        
        trackType = "method" if prop in methodProperties else "value"
        if trackType == "method":
            methodName = methodPropNames[prop] if prop in methodPropNames else "none"
            
        for valTuple in l:
            time = valTuple[0]
            value = valTuple[1]
            if prop == "variant" and value == "":
                value = "Default"
            if value == latestValue:
                continue
            else:
                latestValue = value
            #if prop in propertyTypeFormat:
            if len(propStr) > 0:
                propStr += cma
                transStr += cma
                timeStr += cma
            if isinstance(value, tuple):
                propStr += propertyTypeFormat[prop].format(*value) if prop in propertyTypeFormat else "{}".format(*value)
            else:
                propStr += propertyTypeFormat[prop].format(value) if prop in propertyTypeFormat else "{}".format(value)
            timeStr += timeFormatStr.format(time)
            transStr += "1"
        if len(propStr) == 0:
            continue
        if prop in boolUsingAttrs:
            propStr = propStr.lower()
        propPath = propertyAnimPath[prop] if prop in propertyAnimPath else ":{}".format(prop)
        #if prop in trackNameFixes:
        #    propPath = propPath.replace(prop, trackNameFixes[prop], 1)
        if trackType == "value":
            trackString = VALUE_TRACK_STR.format(trackNum, nodeName + propPath, timeStr, transStr, propertyUpdateNum[prop] if prop in propertyUpdateNum else 0, propStr)
        elif trackType == "method":
            trackString = METHOD_TRACK_STR.format(trackNum, nodeName + ":Func{:d}".format(methodTrackCounter), timeStr, transStr, propStr, methodName)
            methodTrackCounter += 1
        trackStrList.append(trackString)
        trackNum += 1
    return trackStrList

def processTrackData(trackDataDict, time, keyframeData):
    propDict = {}
    #Check if the key is to be part of a tuple
    resultList = [(tupProp, tupleAttrPairs[tupProp]) for tupProp in tupleAttrPairs if set(tupleAttrPairs[tupProp]) < set(keyframeData.keys())]
    ignoreProps = []
    #print(resultList)
    for result in resultList:
        pairName = result[0]
        props = result[1]
        if pairName not in propDict:
            values = []
            for prop in props:
                values.append(keyframeData[prop])
                ignoreProps.append(prop)
            values = tuple(values)
            propDict[pairName] = values
            
    for k, v in keyframeData.items():
        if k == "time":
            continue
        if k not in ignoreProps:
            if k not in boolUsingAttrs:
                propDict[k] = v
            else:
                propDict[k] = bool(v)
                
    #print(propDict)
    trackDataDict[time] = propDict

    
tupleAttrPairs = {"pos": ["x", "y"], "skew": ["skewX", "skewY"],
                  "scale": ["scaleX", "scaleY"],
                  "masking": ["mask_type", "mask_layer"]}
additiveAttrs = ["x", "y", "skewX", "skewY", "rotation"]
multiplictiveAttrs = ["scaleX", "scaleY"]
floatUsingAttrs = ["x", "y", "skewX", "skewY", "rotation", "scaleX", "scaleY"]
boolUsingAttrs = ["visible"]
intUsingAttrs = ["z_index", "mask_layer", "mask_type"]
strUsingAttrs = ["variant"]

#Only need to care about attributes found in the kfValue dictionary
def calculateKeyframeAttr(baseValues, kfValues, latestValues):
    calculatedValues = {}
    for bAttr, bVal in baseValues.items():
        if bAttr in floatUsingAttrs:
            if bAttr in kfValues:
                calculatedValues[bAttr] = float(bVal)
            elif bAttr not in kfValues:
                calculatedValues[bAttr] = float(latestValues[bAttr])
        elif bAttr in boolUsingAttrs:
            if bAttr not in kfValues:
                calculatedValues[bAttr] = str2bool(str(bVal))
        elif bAttr in intUsingAttrs:
            if bAttr not in kfValues:
                calculatedValues[bAttr] = int(bVal)
        elif bAttr in strUsingAttrs:
            calculatedValues[bAttr] = bVal
                #else:
                #calculatedValues[bAttr] = str2bool(str(latestValues[bAttr]))
                
    if kfValues:
        for attr, val in kfValues.items():
            #if attr != "duration":
            if attr in baseValues:
                if attr in additiveAttrs:
                    #Add func
                    calculatedValues[attr] += float(val)
                elif attr in multiplictiveAttrs:
                    #Mul func
                    calculatedValues[attr] *= float(val)
                elif attr in boolUsingAttrs:
                    #if str2bool(str(val)) != latestValues[attr]:
                    calculatedValues[attr] = str2bool(str(val))
                elif attr in intUsingAttrs:
                    calculatedValues[attr] = int(val)
                elif attr in strUsingAttrs:
                    calculatedValues[attr] = val
                #if calculatedValues.get(attr):
                latestValues[attr] = calculatedValues[attr]
        #Now handle duration to convert from frames to seconds
        currentKfIndex = float(kfValues["index"])
        duration = currentKfIndex - latestValues["index"]
        latestValues["index"] = currentKfIndex
        calculatedValues["time"] = duration * baseValues["frameTime"]
    else:
        calculatedValues["time"] = 0
    #print(calculatedValues)
    return calculatedValues


# Main entryway
pyUtils.VerifyProjectFolderStructure()
startFolder = pyUtils.PART_ANIMATIONS_PATH
animationXMLs = {}
motionXMLs = startFolder.glob('**/*.xml')
for motionXML in motionXMLs:
    if motionXML.stem not in animationXMLs:
        animationXMLs[motionXML.stem] = []
    animationXMLs[motionXML.stem].append(motionXML)

#print(animationXMLs)
for k, vList in animationXMLs.items():
    completeAnimName = k
    output = ""
    animLength = 0
    trackNumber = 0
    trackOutput = ""
    # Z index data gathering
    animCreationInfo = pyUtils.analyzeCreationInfo(completeAnimName)
    for motionXML in vList:
        trackData = {}
        currentTime = 0.0
        #print(motionXML)
        xml = BeautifulSoup(motionXML.read_text(), "xml")
        #print(xml.source.source)
        animationName = motionXML.stem

        animNameParts = pyUtils.GetCharPartSections(motionXML.parent.stem)
        #print(animNameParts)
        variantTag = animNameParts["variant"]
        objectName = animNameParts["name"]
        sideFlag = animNameParts["side"]
        animationName += ' - ' + objectName
        animVariantName = ""
        #What the object will be named in Godot
        objectGdName = objectName
        if len(variantTag) > 0:
            animationName += " ({:s})".format(variantTag)
        if len(sideFlag) > 0:
            objectGdName += " ({:s})".format(sideFlag)
            
        baseValues = { }
        #Used when a attr is not found for a keyframe. The value for the attr does not reset back to the baseValue but remains what it was on the last keyframe.
        latestValues = {'index': 0}
        #frameData = { }
        #Get source values, values after the first defined keyframe are relative to these value (either additively or multiplicatively)
        baseValues["variant"] = latestValues["variant"] = variantTag
        xmlSrc = xml.source.Source
        #print(xmlSrc)
        for attr in xmlSrc.attrs:
            if attr != "rotation":
                if attr not in boolUsingAttrs:
                    latestValues[attr] = baseValues[attr] = xmlSrc[attr]
                else:
                    latestValues[attr] = baseValues[attr] = str2bool(xmlSrc[attr])
            else:
                #Translate rotation into skew instructions
                baseValues["skewY"] = baseValues["skewX"] = xmlSrc[attr]
                latestValues["skewX"] = latestValues["skewY"] = xmlSrc[attr]
        frameRate = float(baseValues["frameRate"])
        baseValues["frameTime"] = 1.0 / frameRate

        if objectGdName in animCreationInfo:
            ciData = animCreationInfo[objectGdName]
            for ciKey, ciVal in ciData.items():
                if (ciKey == "mask_type" or ciKey == "mask_layer") and ciVal == -1:
                    continue
                baseValues[ciKey] = latestValues[ciKey] = ciVal

        allKfData= xml.find_all("Keyframe")
        
        for kf in allKfData:
            # calculate the values here and format the string for the animation data.
            kfData = {}
            # kfNum = int(kf["index"])
            if "blank" in kf.attrs and kf["blank"] == "true":
                continue
            for kfAttr in kf.attrs:
                # if kfAttr == "blank":
                if kfAttr != "rotation":
                    if attr not in boolUsingAttrs:
                        kfData[kfAttr] = kf[kfAttr]
                    else:
                        kfData[kfAttr] = str2bool(kf[kfAttr])
                else:
                    kfData["skewX"] = kfData["skewY"] = kf[kfAttr]

            #if kfNum == 0:
                #kfData = None
            #print(kfData)
            kfData = calculateKeyframeAttr(baseValues, kfData, latestValues)
            #track data is the keyframe data in a format friendlier for how Animation resources are formatted.
            currentTime += kfData["time"]
            processTrackData(trackData, currentTime, kfData)

        xmlFilePath = Path(str(motionXML))
        #print(xmlFilePath)
        
        #print(animationName)
        
        currentMotionLength = float(xml.Motion["duration"]) / frameRate
        if animLength < currentMotionLength:
            animLength = currentMotionLength

        trackStrings = createTrackStrings(trackData, trackNumber, objectGdName)
        for trString in trackStrings:
            trackOutput += trString
        trackNumber += len(trackStrings)
    fileHeaderString = ANIM_HEADER.format(completeAnimName, animLength, baseValues["frameTime"])
    outputString = fileHeaderString + trackOutput
    outFile = Path(pyUtils.BASE_CHAR_ANIMS_PATH / str(completeAnimName + "-animation.tres"))
    #print(outFile)
    outFile.write_text(outputString)
