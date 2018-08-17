#!python3
from bs4 import BeautifulSoup
from pathlib import Path
import pyUtils
#Like motionXML to animation tres but exports all the track to one file instead of one for each char part
#Animation String
ANIM_HEADER='''[gd_resource type=\"Animation\" format=2]

[resource]

resource_name = \"{:s}\"
length = {:f}
loop = true
step = {:f}
'''#.format(Animation Name) (Don't actually uncomment this)

ANIM_TRACK_STR='''
tracks/{0:d}/type = \"value\"
tracks/{0:d}/path = NodePath(\"{1:s}\")
tracks/{0:d}/interp = 1
tracks/{0:d}/loop_wrap = true
tracks/{0:d}/imported = false
tracks/{0:d}/enabled = true
tracks/{0:d}/keys = {{
\"times\": PoolRealArray( {2:s} ),
\"transitions\": PoolRealArray( {3:s} ),
\"update\": 0,
\"values\": [ {4:s} ]
}}
'''
Vec2fStr = "Vector2( {:.4f}, {:.4f} )"

def createTrackStrings(times, positions, scales, skews, baseTrackNum=0, nodeName="."):
    timesStr = ""
    currentTime = 0.0
    for time in times:
        if len(timesStr) > 0:
            timesStr += ", "
        currentTime += time
        timesStr += "{:.3f}".format(currentTime)
        
    posStr = ""
    for posV2 in positions:
        if len(posStr) > 0:
            posStr += ", "
        posStr += Vec2fStr.format(*posV2)

    scaleStr = ""
    for scaleV2 in scales:
        if len(scaleStr) > 0:
            scaleStr += ", "
        scaleStr += Vec2fStr.format(*scaleV2)

    skewStr = ""
    for skewV2 in skews:
        if len(skewStr) > 0:
            skewStr += ", "
        skewStr += Vec2fStr.format(*skewV2)

    tranStr = ""
    for x in range(0, len(times)):
        if len(tranStr) > 0:
            tranStr += ", "
        tranStr += "1"

    #Can now work on the individual tracks.
    trackStrList = []
    trackStrList.append(formatAnimationTrackString((baseTrackNum*3)+0, nodeName + ":exnPos", timesStr, tranStr, posStr))
    trackStrList.append(formatAnimationTrackString((baseTrackNum*3)+1, nodeName + ":exnScale", timesStr, tranStr, scaleStr))
    trackStrList.append(formatAnimationTrackString((baseTrackNum*3)+2, nodeName + ":exnSkew", timesStr, tranStr, skewStr))
    return trackStrList

def formatAnimationTrackString(trackNum, funcName, times, transitions, values):
    return ANIM_TRACK_STR.format(trackNum, funcName, times, transitions, values)

def formatTrackData(keyframeData):
    #print(keyframeData)
    pos = (keyframeData['x'], keyframeData['y'])
    scale = (keyframeData['scaleX'], keyframeData['scaleY'])
    skew = (keyframeData['skewX'], keyframeData['skewY'])
    return [keyframeData['time'], pos, scale, skew]

additiveAttrs = ["x", "y", "skewX", "skewY", "rotation"]
multiplictiveAttrs = ["scaleX", "scaleY"]
floatUsingAttrs = ["x", "y", "skewX", "skewY", "rotation", "scaleX", "scaleY"]

#Only need to care about attributes found in the kfValue dictionary
def calculateKeyframeAttr(baseValues, kfValues, latestValues):
    calculatedValues = {}
    for bAttr, bVal in baseValues.items():
        if bAttr in floatUsingAttrs:
            if bAttr in kfValues:
                calculatedValues[bAttr] = float(bVal)
            elif bAttr not in kfValues:
                calculatedValues[bAttr] = float(latestValues[bAttr])
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


##Main entryway
startFolder = Path('./Animations')
animationXMLs = {}
motionXMLs = startFolder.glob('**/*.xml')
for motionXML in motionXMLs:
    if not motionXML.stem in animationXMLs:
        animationXMLs[motionXML.stem] = []
    animationXMLs[motionXML.stem].append(motionXML)

#print(animationXMLs)
for k, vList in animationXMLs.items():
    completeAnimName = k
    output = ""
    animLength = 0
    trackSet = 0
    trackOutput = ""
    for motionXML in vList:
        xml = BeautifulSoup(motionXML.read_text(), "xml")
        #print(xml.source.source)
        baseValues = { }
        #Used when a attr is not found for a keyframe. The value for the attr does not reset back to the baseValue but remains what it was on the last keyframe.
        latestValues = {'index': 0}
        #frameData = { }
        #Get source values, values after the first defined keyframe are relative to these value (either additively or multiplicatively)
        xmlSrc = xml.source.Source
        #print(xmlSrc)
        for attr in xmlSrc.attrs:
            if attr != "rotation":
                latestValues[attr] = baseValues[attr] = xmlSrc[attr]
            else:
                #Translate rotation into skew instructions
                baseValues["skewY"] = baseValues["skewX"] = xmlSrc[attr]
                latestValues["skewX"] = latestValues["skewY"] = xmlSrc[attr]
        frameRate = float(baseValues["frameRate"])
        baseValues["frameTime"] = 1.0 / frameRate

        allKfData= xml.find_all("Keyframe")
        trackData = {}
        timeList,posList,scaleList,skewList = [],[],[],[]

        for kf in allKfData:
            #calculate the values here and format the string for the animation data.
            kfData = {}
            #kfNum = int(kf["index"])
            for kfAttr in kf.attrs:
                #if kfAttr != "index":
                if kfAttr != "rotation":
                    kfData[kfAttr] = kf[kfAttr]
                else:
                    kfData["skewX"] = kfData["skewY"] = kf[kfAttr]

            #if kfNum == 0:
                #kfData = None
            #print(kfData)
            kfData = calculateKeyframeAttr(baseValues, kfData, latestValues)
            #track data is the keyframe data in a format friendlier for how Animation resources are formatted. 
            trackData = formatTrackData(kfData)
            timeList.append(trackData[0])
            posList.append(trackData[1])
            scaleList.append(trackData[2])
            skewList.append(trackData[3])

        xmlFilePath = Path(str(motionXML))
        #print(xmlFilePath)
        animationName = motionXML.stem
        #print(animationName)
        animNameParts = pyUtils.GetCharPartSections(motionXML.parent.stem)
        #print(animNameParts)
        variantTag = animNameParts["variant"]
        objectName = animNameParts["name"]
        sideFlag = animNameParts["side"]
        animationName += ' - ' + objectName
        animVariantName = ""
        objectGdName = objectName
        if len(variantTag) > 0:
            animationName += " ({:s})".format(variantTag)
        if len(sideFlag) > 0:
            objectGdName += " ({:s})".format(sideFlag)
        currentMotionLength = float(xml.Motion["duration"]) / frameRate
        if animLength < currentMotionLength:
            animLength = currentMotionLength
         
        #print(objectName)
        #print(animationName)
        #print(objectGdName)
        trackStrings = createTrackStrings(timeList, posList, scaleList, skewList, trackSet, objectGdName)
        for trString in trackStrings:
            trackOutput += trString
        trackSet += 1
    fileHeaderString = ANIM_HEADER.format(completeAnimName, animLength, baseValues["frameTime"])
    outputString = fileHeaderString + trackOutput
    outFile = Path(pyUtils.BASE_CHAR_ANIMS_PATH / str(completeAnimName + "-animation.tres"))
    #print(outFile)
    outFile.write_text(outputString)
