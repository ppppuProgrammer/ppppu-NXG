extends Node

export var _batches:Dictionary = {} setget batches_set, batches_get
#Hardcoded "batches" that won't count against the Char Part Sprite's limit
var _reserved_names:Array = ["Colorable", "Mask"]

signal material_batch_created(batch_name)
signal material_batch_changed(batch_name)

# Manages a material batch, which is just multiple materials templates
# that are to be chained together.

func batches_get():
	return null
	
func batches_set(dict:Dictionary):
	pass
	
func create_batch(batch_name:String):
	if batch_name in _reserved_names:
		Log.append("@MaterialBatches: Can not create a batch using a reserved batch name. Avoid using the following as names: %s" % _reserved_names)
	elif batch_name in _batches:
		Log.append("@MaterialBatches: Could not create material batch with name of \"%s\", name was already in use." % batch_name)
	else:
		_batches[batch_name] = []
		emit_signal("material_batch_created", batch_name)
		
func get_batch_size(batch_name:String):
	if batch_name in _batches:
		return _batches[batch_name].size()
	else:
		return -1
		
func reorder_batch(batch_name:String, pos:int, new_pos:int):
	if min(pos, new_pos) > -1 and max(pos, new_pos) < get_batch_size(batch_name):
		var batch:Array = _batches[batch_name]
		var mat2:Material = batch[new_pos]
		batch[new_pos] = batch[pos]
		batch[pos] = mat2
		emit_signal("material_batch_changed", batch_name)
		
func add_material_to_batch(batch_name:String, material:Material):
	if batch_name in _batches:
		_batches[batch_name].append(material)
		emit_signal("material_batch_changed", batch_name)
	else:
		Log.append("@MaterialBatches: Batch \"%s\" was not found." % batch_name)
		
func remove_material_from_batch(batch_name:String, pos:int):
	if batch_name in _batches and pos < get_batch_size(batch_name):
		_batches[batch_name].remove(pos)
		emit_signal("material_batch_changed", batch_name)
	else:
		Log.append("@MaterialBatches: Unable to remove material from batch \"%s\" (size: %d) at position %s." % [batch_name, get_batch_size(batch_name), pos])