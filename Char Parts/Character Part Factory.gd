extends Node
class_name CharacterPartFactory

var _parts_master_copy:Dictionary = {}
var _registeredPackedScenes:PoolIntArray
func registerPartsList(list:Array):
	for part in list:
		if part is CharacterPart:
			registerPart(part)

func registerPart(part_scene:PackedScene)->bool:
	#validate packed scene instance
	var part = part_scene.instance()
	if part is CharacterPart and not part_scene.get_rid().get_id() in _registeredPackedScenes:
		_registeredPackedScenes.append(part_scene.get_rid().get_id())
		_parts_master_copy[part.name] = part
		return true
	return false

func createPart(part_name:String)->CharacterPart:
	if part_name in _parts_master_copy:
		return _parts_master_copy[part_name].duplicate()
	else:
		return null

func addSpriteToPart(sprite:Sprite, part_name:String):
	pass
	
