extends Resource
class_name GamePhase
#Game phase represents the various major states that
# the game can be in. A few examples are: splash screen, intro,
# main menu and gameplay.

#The scene that is used for the phase.
export var phase_scene:PackedScene = null
var _scene:Node

var func_add_gui_scene:FuncRef
var func_remove_gui_scene:FuncRef
var func_remove_all_gui_scenes:FuncRef

#Called when the phase is to be no longer in use (as the current phase).
#Should remove connections that were done and anything else that might
#linger around.
func cleanup():
	if _scene:
		_scene.cleanup()

func get_scene()->Node:
	if not _scene:
		_scene = phase_scene.instance()
	return _scene
	
func preconfigure_phase(phase_change_data:Dictionary={}):
	if _scene:
		_scene.preconfigure(phase_change_data)
		
func configure_phase(phase_change_data:Dictionary={}):
	if _scene:
		_scene.configure(phase_change_data)

func setup_scene_funcrefs(add_gui:FuncRef, rem_all_gui:FuncRef, rem_gui:FuncRef):
	_scene.func_add_gui_scene = add_gui
	_scene.func_remove_gui_scene = rem_all_gui
	_scene.func_remove_all_gui_scenes = rem_gui

func reset_phase(phase_data:Dictionary={}):
	_scene.queue_free()
	_scene = phase_scene.instance()
	configure_phase(phase_data)