extends Animation
class_name CharacterAnimationElement

#Extension of an Animation resource that upon being
#loaded will set a cache of what character parts
#are being used by the animation.

#export var animation:Animation
export var animation_slot_name:String
export var animation_name:String
var _part_dependencies:Dictionary = {}

func _init():
	#print(self.get_track_count())
	for i in range(0, self.get_track_count()):
		var partNames = deduceCharPartNames(track_get_path(i))
		_part_dependencies[partNames[1]] = partNames[0]
	#print(_part_dependencies)
	
#Returns an array with 2 values, the first is base character part name, which is what the tscn for the part is named. 
#The second is being the full name of the char part as it will be referred to in the animation page or current character page.
func deduceCharPartNames(animTrackNodePath:String):
	var fullPartName:String = animTrackNodePath.split(":", false, 1)[0]
	#Here for future proofing
	#fullPartName = fullPartName.lstrip("./")
	
	#Check for left parenthesis "(" since that means that the current node path is for a variant.
	var variantStartIdx = fullPartName.rfind(" (")
	
	var basePartName:String = fullPartName.substr(0, variantStartIdx if variantStartIdx > -1 else fullPartName.length())
	return [basePartName, fullPartName]
	
	