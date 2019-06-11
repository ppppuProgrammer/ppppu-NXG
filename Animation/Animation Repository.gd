extends Object
class_name AnimationRepository

var _repository:Dictionary = {}

#Contains the many animations that will be used for the Characters.
#The repository is a Dictionary containing a String key for the name of the animation slot and a dictionary for the value.
#The sub dictionary uses a String key for the CHaracter ANimation ELEment's (Chanele) name and a reference to the Chanele 
#resource as the value. 
# An Animation slot tells the intended use for a given set of Chaneles, which are combined to compose the final animation.

func AddAnimationSlot(slot_name:String):
	if slot_name and not slot_name in _repository:
		_repository[slot_name] = {}

func HasAnimationSlot(slot_name:String)->bool:
	return _repository.has(slot_name)

func AddChanele(animation:CharacterAnimationElement)->bool:
	var anim_slot_name:String = animation.animation_slot_name
	var anim_name:String = animation.animation_name
	if _repository.has(anim_slot_name) and _repository[anim_slot_name].get(anim_name) == null:
		_repository[anim_slot_name][anim_name] = animation
		return true
	else:
		return false
	
func HasChanele(slot_name:String, anim_name:String)->bool:
	if HasAnimationSlot(slot_name):
		return _repository[slot_name].has(anim_name)
	else:
		return false
		
func GetChaneleCountForSlot(slot_name:String)->int:
	if HasAnimationSlot(slot_name):
		return _repository[slot_name].size()
	else:
		return 0