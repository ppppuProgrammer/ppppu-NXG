extends "res://addons/gut/test.gd"

var _partFactory:CharacterPartFactory
var _headwear:PackedScene = preload("res://Char Parts/Headwear/Headwear.tscn")
func before_each():
	_partFactory = CharacterPartFactory.new()
	
func after_each():
	_partFactory.shutdown()
	_partFactory.free()
	_partFactory = null
	
func test_ridtest():
	var base:PackedScene = load("res://Characters/Character.tscn")
	assert_gt(base.get_instance_id(), 0)
	
func test_partRegistration():
	gut.p("Testing that registration will fail when given an invalid packed scene")
	var bad_part:PackedScene = load("res://Testing/unit/test_CharParts/InvalidCharPart.tscn")
	assert_false(_partFactory.register_single_part(bad_part))
	gut.p("Registrating valid character part")
	assert_true(_partFactory.register_single_part(_headwear))
	gut.p("Testing that an instance of a part can be created")
	assert_not_null(_partFactory._create_part("Headwear"))
	gut.p("Making sure that re-registrating a part is not allowed")
	assert_false(_partFactory.register_single_part(_headwear))
	
func test_partExtending():
	_partFactory.register_single_part(_headwear)
	var headwear_extra = load("res://Testing/unit/test_CharParts/Sprite_Headwear-Test.tscn")
	assert_true(_partFactory.add_sprite_to_part(headwear_extra, "Headwear"))
	gut.p("Make sure duplicate instances are not allowed")
	assert_false(_partFactory.add_sprite_to_part(headwear_extra, "Headwear"))
	var headwear_extra_dup = load("res://Testing/unit/test_CharParts/Sprite_Headwear-Test.tscn")
	assert_false(_partFactory.add_sprite_to_part(headwear_extra_dup, "Headwear"))
	gut.p("Ensure that duplicated instances have the newly added sprite")
	var dup_headwear:CharacterPart = _partFactory._create_part("Headwear")

func test_scan_parts_resources():
	#Does not test for variant collisions currently. Make it test for this. 
	#Boob and sideboob are intentionally set to testing collisions.
	var factory_register_data:Dictionary = {}
	var char_parts_root_folder:String = "res://Char Parts"
	var char_parts_folder_list:PoolStringArray = _get_directory_contents(
			char_parts_root_folder, filesystem_types.DIRECTORIES)
	var part_dir_scanner:Directory = Directory.new()
	for part_folder_name in char_parts_folder_list:
		var current_path:String = "%s/%s" % [char_parts_root_folder, part_folder_name] 
		if part_dir_scanner.open(current_path) == OK:
			if part_dir_scanner.file_exists("%s.tscn" % part_folder_name):
				if part_dir_scanner.dir_exists("Texture"):
					#Scan for all the variants
					if part_dir_scanner.change_dir("Texture") == OK:
#						if not part_dir_scanner.dir_exists("Default"):
#							continue
						factory_register_data[part_folder_name] = {"Scene": load("%s/%s.tscn" % [current_path, 
								part_folder_name]), CharacterPart.layers.MAIN: {}, CharacterPart.layers.DECAL: {}}
						var part_registry:Dictionary = factory_register_data[part_folder_name]
						var variants_folders:PoolStringArray = _get_directory_contents(
								part_dir_scanner.get_current_dir(), filesystem_types.DIRECTORIES)
						for variant_folder_name in variants_folders:
							part_dir_scanner.change_dir(variant_folder_name)
							var sprite_scene_path:PoolStringArray = _get_directory_contents(
									part_dir_scanner.get_current_dir(), filesystem_types.FILES, ".*\\.tscn")
							if sprite_scene_path.size() > 0:
								var load_path:String = "%s/%s" % [part_dir_scanner.get_current_dir(), sprite_scene_path[0]]
								#print_debug(load_path)
								var sprite_scene:PackedScene = load(load_path)
								assert_not_null(sprite_scene, "[%s; %s] PackedScene could not be loaded, check for errors such as missing external resources" % [part_folder_name, variant_folder_name])
								if sprite_scene:
									var sprite_layer:int = 0
									var variant_name:String = ""
									var state:SceneState = sprite_scene.get_state()
									for prop_idx in state.get_node_property_count(0):
										if state.get_node_property_name(0, prop_idx) == "target_layer":
											sprite_layer = state.get_node_property_value(0, prop_idx)
										if state.get_node_property_name(0, prop_idx) == "variantName":
											variant_name = state.get_node_property_value(0, prop_idx)
										if sprite_layer > 0 and not variant_name.empty():
											if sprite_layer == CharacterPart.layers.MAIN and not part_registry[CharacterPart.layers.MAIN].has(variant_name):
												part_registry[CharacterPart.layers.MAIN][variant_name] = sprite_scene
											elif sprite_layer == CharacterPart.layers.DECAL and not part_registry[CharacterPart.layers.DECAL].has(variant_name):
												part_registry[CharacterPart.layers.DECAL][variant_name] = sprite_scene
											assert_eq(part_registry[sprite_layer][variant_name], sprite_scene, 
													"[type: %s] sprite \"%s\" could not added, variant \"%s\" was already in use. Conflicting files [%s , %s]" % 
													[part_folder_name, load_path.get_file(), variant_name, (part_registry[sprite_layer][variant_name] as PackedScene).resource_path, sprite_scene.resource_path])
									assert_gt(sprite_layer, 0, "[%s; %s] sprite layer for \"%s\" was not set " % [part_folder_name, variant_folder_name, load_path.get_file()])
							part_dir_scanner.change_dir("..")
						assert_eq(variants_folders.size(), part_registry[1].size() + part_registry[2].size(), "[type: %s] Found %d variant(s) but only %d were added" % [part_folder_name, variants_folders.size(), part_registry[1].size() + part_registry[2].size()])
	_partFactory.register_parts(factory_register_data)

enum filesystem_types {ALL, DIRECTORIES, FILES}

func _get_directory_contents(search_dir:String, type:int, regex_pattern:String="", skip_hidden_files:bool=true)->PoolStringArray:
	var ret:PoolStringArray
	var regex:RegEx = null
	var dir:Directory = Directory.new()
	if dir.dir_exists(search_dir):
		if dir.change_dir(search_dir) == OK:
			if not regex_pattern.empty():
				regex = RegEx.new()
				regex.compile(regex_pattern)
				if not regex.is_valid():
					print_debug("\"%s\" is not a valid pattern" % regex_pattern)
					return ret
			if dir.list_dir_begin(true, skip_hidden_files) == OK:
				var dir_element:String = dir.get_next()
				while not dir_element.empty():
					if regex:
						if not regex.search(dir_element):
							dir_element = dir.get_next()
							continue
					if type == filesystem_types.ALL:
						ret.push_back(dir_element)
					elif type == filesystem_types.DIRECTORIES and dir.current_is_dir():
						ret.push_back(dir_element)
					elif type == filesystem_types.FILES and not dir.current_is_dir():
						ret.push_back(dir_element)
					dir_element = dir.get_next()
	return ret
