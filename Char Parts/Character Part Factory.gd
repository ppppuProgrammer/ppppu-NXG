extends Object
class_name CharacterPartFactory

var _parts_registry:Dictionary = {}
var _registeredPackedScenes:PoolIntArray

var _run_lock:Mutex
var _factory_mutex:Mutex
var creation_semaphore:Semaphore
var _factory_active:bool = true
var _factory_thread:Thread
var creation_queue:Array = []
func _init() -> void:
	_factory_mutex = Mutex.new()
	_run_lock = Mutex.new()
	creation_semaphore = Semaphore.new()
	_factory_thread = Thread.new()
	_factory_thread.start(self, "_factory_loop")

func _factory_loop() -> void:
	while true:
		creation_semaphore.wait()
		
		_run_lock.lock()
		if !_factory_active:
			break
		_run_lock.unlock()
		
		_factory_mutex.lock()
		while creation_queue.size() > 0:
			var task:Dictionary = creation_queue.pop_front()
			var part_types_list:Array = task["Types"]
			var part_names_list:Array = task["Names"]
			var character:Character = task["Target"]
			_create_parts(part_types_list, part_names_list, character)
		_factory_mutex.unlock()
#				if !part_scene_name in _registry:
#					#For now discard the task
#					print_debug(task_discard_str % [part_scene_name, task["name"]])
#				else:
#					pass
func shutdown() -> void:
	_run_lock.lock()
	_factory_active = false
	_run_lock.unlock()
	creation_semaphore.post()
	_factory_thread.wait_for_finish()
		
func _cleanup() ->void:
	pass
	
func register_multiple_parts(list:Array):
	_factory_mutex.lock()
	for part in list:
		if part is CharacterPart:
			_register_part(part)
	_factory_mutex.unlock()
	
func register_single_part(part_scene:PackedScene)->bool:
	_factory_mutex.lock()
	var ret = _register_part(part_scene)
	_factory_mutex.unlock()
	return ret
	
func _register_part(part_scene:PackedScene)->bool:
	var reg_success:bool = false
	var part = part_scene.instance()
	if part is CharacterPart and not part_scene.get_rid().get_id() in _registeredPackedScenes:
		_registeredPackedScenes.append(part_scene.get_rid().get_id())
		_parts_registry[part.name] = {"PartScene": part_scene, "MainTexs": [], "DecalTexs": []}
		reg_success = true
	return reg_success

func _create_parts(parts_list:Array, parts_names:Array, recipient:Character)->void:
	var created_parts:Array = []
	for i in range(0, parts_list.size()):
		var char_part:CharacterPart = _create_part(parts_list[i])
		if char_part:
			char_part.name = parts_names[i]
			created_parts.append(char_part)
	recipient.add_character_parts(created_parts)
	

func _create_part(part_type:String)->CharacterPart:
	if part_type in _parts_registry:
		var part:CharacterPart = _parts_registry[part_type]["PartScene"].instance()
		var mainLayer:int = CharacterPart.layers.MAIN
		var decalLayer:int = CharacterPart.layers.DECAL
		for mainTex in _parts_registry[part_type]["MainTexs"]:
			part.add_texture(mainLayer, mainTex.instance())
		for decalTex in _parts_registry[part_type]["DecalTexs"]:
			part.add_texture(decalLayer, decalTex.instance())
		return part
	else:
		return null

func add_sprite_to_part(sprite_scene:PackedScene, part_type:String)->bool:
	_factory_mutex.lock()
	var success:bool = false
	if part_type in _parts_registry:
		var ss_state:SceneState = sprite_scene.get_state()
		#Don't assume that target_layer property will use the same value for all the sprite packed scenes.
		for idx in ss_state.get_node_property_count(0):
			var node_prop_name:String = ss_state.get_node_property_name(0, idx)
			if node_prop_name == "target_layer":
				var layer_value:int = ss_state.get_node_property_value(0, idx)
				var layer:String = "MainTexs" if layer_value == CharacterPart.layers.MAIN else "DecalTexs" if layer_value == CharacterPart.layers.DECAL else null
				if not sprite_scene in _parts_registry[part_type][layer]:
					_parts_registry[part_type][layer].append(sprite_scene)
					success = true
					break
	_factory_mutex.unlock()
	return success
	
func add_create_parts_task(part_types:Array, part_names:Array, recipient:Character):
	if part_types.size() == part_names.size():
		var task:Dictionary = {"Types": part_types, "Names": part_names, "Target": recipient}
		_factory_mutex.lock()
		creation_queue.append(task)
		_factory_mutex.unlock()
		creation_semaphore.post()
