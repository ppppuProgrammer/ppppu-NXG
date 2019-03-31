extends Control

func add_gui_scene(scene:Node):
	if not scene in self.get_children():
		add_child(scene)

func remove_gui_scene(scene:Node):
	if scene in self.get_children():
		remove_child(scene)
	
func remove_all_gui_scenes():
	for gui_scene in self.get_children():
		self.remove_child(gui_scene)