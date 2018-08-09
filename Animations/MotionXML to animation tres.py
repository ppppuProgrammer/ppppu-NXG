#!python3
from bs4 import BeautifulSoup
from pathlib import Path

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
tracks/{0:d}/path = NodePath(\".:{1:s}\")
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

def createTrackStrings(times, positions, scales, skews):
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
    trackStrList.append(formatAnimationTrackString(0, "exnPos", timesStr, tranStr, posStr))
    trackStrList.append(formatAnimationTrackString(1, "exnScale", timesStr, tranStr, scaleStr))
    trackStrList.append(formatAnimationTrackString(2, "exnSkew", timesStr, tranStr, skewStr))
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
def calculateKeyframeAttr(baseValues, kfValues):
    calculatedValues = {}
    for bAttr, bVal in baseValues.items():
        if bAttr in floatUsingAttrs:
            calculatedValues[bAttr] = float(bVal)
    if kfValues:
        for attr, val in kfValues.items():
            if attr != "duration":
                if attr in baseValues:
                    if attr in additiveAttrs:
                        #Add func
                        calculatedValues[attr] += float(val)
                    elif attr in multiplictiveAttrs:
                        #Mul func
                        calculatedValues[attr] *= float(val)
        #Now handle duration to convert from frames to seconds
        duration = 1
        if "duration" in kfValues:
            duration = baseValues["duration"]
        calculatedValues["time"] = duration * baseValues["frameTime"]
    else:
        calculatedValues["time"] = 0

                
    
    #print(calculatedValues)
    return calculatedValues


##Main entryway
startFolder = Path('.')

motionXMLs = startFolder.glob('**/*.xml')
for motionXML in motionXMLs:
    #print(motionXML)
    xml = BeautifulSoup(motionXML.read_text(), "xml")
    #print(xml.source.source)
    baseValues = { }
    #Used when a attr is not found for a keyframe. The value for the attr does not reset back to the baseValue but remains what it was on the last keyframe.
    latestValues = {}
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
        kfNum = int(kf["index"])
        for kfAttr in kf.attrs:
            if kfAttr != "index":
                if kfAttr != "rotation":
                    kfData[kfAttr] = kf[kfAttr]
                else:
                    kfData["skewX"] = kfData["skewY"] = kf[kfAttr]
                    
        if kfNum == 0:
            kfData = None
        #print(kfData)
        kfData = calculateKeyframeAttr(baseValues, kfData)
        #track data is the keyframe data in a format friendlier for how Animation resources are formatted. 
        trackData = formatTrackData(kfData)
        timeList.append(trackData[0])
        posList.append(trackData[1])
        scaleList.append(trackData[2])
        skewList.append(trackData[3])

    xmlFilePath = Path(startFolder.resolve() / str(motionXML))
    animationName = str(xmlFilePath.parent)
    animationName = animationName[animationName.rfind('/')+1:]
    #print(animationName)
    objectName = xmlFilePath.stem
    #print(objectName)
    fileHeaderString = ANIM_HEADER.format(objectName + ' - ' + animationName, float(xml.Motion["duration"]) / frameRate, baseValues["frameTime"])
    trackStrings = createTrackStrings(timeList, posList, scaleList, skewList)

    output = fileHeaderString
    for track in trackStrings:
        output += track

    tresFile = Path(xmlFilePath.parent).joinpath(str(objectName) + ".tres")
    #print(str(tresFile))
    tresFile.write_text(output)
    #print(output)
        #print(trackData)
        #Now get a way to feed that keyframe data into the track string template
        #print(fullKfData)
