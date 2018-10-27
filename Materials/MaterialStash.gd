extends Node

#Manages the collection of materials that are used for the program.
#Materials are stored and retrieved by name.
#In the case of this class, added materials are used as templates
#and a copy of the material will be distributed to requested nodes.
#This avoids the issues caused by resource types being passed by reference.
export var _materials:Dictionary = {} setget materials_set, materials_get

#Do not allow direct outside modification or access to the materials
func materials_get():
	return null
	
func materials_set(dict:Dictionary):
	pass
	
func add(material:Material):
	var ret:int = 0
	var material_name = material.resource_path.get_file().trim_suffix(".tres")
	var logOutput:String = ""
	if material_name in _materials:
		ret = -1
		logOutput += "\tMaterial name \"%s\" was already assigned (%s). Assign a different name to avoid future conflicts.\n" % [material_name, _materials[material_name].resource_path]
	if material in _materials.values():
		ret = -1
		logOutput += "\tMaterial was already loaded\n"
		
	if ret == 0:
		_materials[material_name] = material
	else:
		Log.append("@MaterialStash: Material (%s) could not be added." % material.resource_path) 
		Log.append(logOutput)
			
func get_material(material_name:String):
	if material_name in _materials:
		return _materials[material_name].duplicate()