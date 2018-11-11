#!python3

from PIL import Image, ImageColor
colorClamps = ["#1a1a1a",
               "#333333", "#4d4d4d", "#666666", "#808080",
               "#999999", "#b3b3b3", "#cccccc"]
colorSections = []
img = Image.open("Ear_SkinColor.png")
imgSize = img.size
modifiedPixels = []
pixels = [(x, y) for x in range(imgSize[0]) for y in range(imgSize[1])]


def isRGBcolorsclose(color1, color2):
    if abs(color1[0] - color2[0]) < 10 and abs(
            color1[1] - color2[1]) < 10 and abs(
                color1[2] - color2[2]) < 10:
        return True
    else:
        return False


for clamp in colorClamps:
    clamp = ImageColor.getrgb(clamp)
    sectionClamp = (int(clamp[0]), int(clamp[1]), int(clamp[2]))
    colorSections.append(sectionClamp)

imgData = img.getdata()
for pixel in imgData:
    for sectionColor in colorSections:
        if isRGBcolorsclose(pixel, sectionColor):
            pixel = (sectionColor[0], sectionColor[1],
                     sectionColor[2], pixel[3])
            break
    modifiedPixels.append(pixel)
modifiedImg = img.copy()
modifiedImg.putdata(modifiedPixels)
modifiedImg.save("Modified Ear.png")
print(img.format)
