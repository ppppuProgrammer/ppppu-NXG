extends Node
class_name CharacterPartFactory

var _parts_master_copy:Dictionary = {}
var _registeredPackedScenes:PoolIntArray
func registerPartsList(list:Array):
	for part in list:
		if part is CharacterPart:
			registerPart(part)

func registerPart(part_scene:PackedScene)->bool:
	var part = part_scene.instance()
	if part is CharacterPart and not part_scene.get_rid().get_id() in _registeredPackedScenes:
		_registeredPackedScenes.append(part_scene.get_rid().get_id())
		_parts_master_copy[part.name] = {"PartScene": part_scene, "MainTexs": [], "DecalTexs": []}
		return true
	return false

func createParts(parts_list:Array, parts_names:Array)->Array:
	return []

func createPart(part_name:String)->CharacterPart:
	if part_name in _parts_master_copy:
		return _parts_master_copy[part_name].clone()
	else:
		return null

func addSpriteToPart(sprite:CharacterSpriteContainer, part_name:String)->bool:
	if part_name in _parts_master_copy:
		var layer:String = "MainTexs" if sprite.target_layer == CharacterPart.layers.MAIN else "DecalTexs" if sprite.target_layer == CharacterPart.layers.Decal else null
		_parts_master_copy[part_name][layer] = sprite
		return true
	return false
	
