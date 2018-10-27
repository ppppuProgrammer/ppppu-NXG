extends TextureRect

const POINT_WIDTH = 6
const CLIP_AVOID_LENGTH:float = 0.002
const GRAB_FACTOR:float = 1.0

var grabbedPoint:int = -1
var dragging:bool = false

signal show_color_picker
var _inputs_enabled = true setget set_inputs_enabled

func _gui_input(event:InputEvent):
	if not _inputs_enabled:
		accept_event()
		return
		
	var texGradient:Gradient = texture.gradient
	#Mouse button press events
	var mouseBtn:InputEventMouseButton = event as InputEventMouseButton
	
	if mouseBtn and mouseBtn.button_index == 1 and mouseBtn.doubleclick and mouseBtn.pressed:
		print("Double")
		grabbedPoint = _get_point_by_pos(mouseBtn.position.x)
		emit_signal("show_color_picker")
		accept_event()
	
	#Remove point
	if mouseBtn and mouseBtn.button_index == 2 and mouseBtn.pressed:
		print("remove")
		grabbedPoint = _get_point_by_pos(mouseBtn.position.x)
		if grabbedPoint > -1:
			texGradient.remove_point(grabbedPoint)
			grabbedPoint = -1
			update()
			accept_event()
		
	#Select	
	if mouseBtn and mouseBtn.button_index == 1 and mouseBtn.pressed:
		update()
		var mouseX:float = mouseBtn.position.x
		dragging = true
		print("select")
		grabbedPoint = _get_point_by_pos(mouseX)
		print("grabbed %d" % grabbedPoint)
		if grabbedPoint != -1:
			return
		var newOffset = clamp(mouseX / rect_size.x, 0, 1)
		texGradient.add_point(newOffset, 
				texGradient.interpolate(newOffset))
		
	if mouseBtn and mouseBtn.button_index == 1 and !mouseBtn.pressed:
		if dragging:
			dragging = false
		update()
	
	#Mouse movement events
	var mouseMove:InputEventMouseMotion = event as InputEventMouseMotion
		
	if mouseMove and dragging and grabbedPoint != -1:
		print("Starting mouse movement")
		
		var newofs:float = clamp(mouseMove.position.x / rect_size.x,
				0, 1)
		var offsets = texGradient.offsets
		var valid:bool = true
		for i in range(0, texGradient.get_point_count()):
			if offsets[i] == newofs and i != grabbedPoint:
				valid = false
		if not valid:
			return
			
		#offsets
		#print(grabbedPoint)
		#print(newofs)
		print("about to set offset")
		var mouseRelativeMove:Vector2 = mouseMove.relative
		#Mouse moving to left
		var oldofs:float = offsets[grabbedPoint]
		if mouseRelativeMove.x < 0:
			#Swap colors with any points that are in the way
			# of the new offset for the grabbed point 
			for x in range(grabbedPoint - 1, -1, -1):
				if newofs < offsets[x]:
					_swap_point_colors(x + 1, x)
					grabbedPoint = x
		elif mouseRelativeMove.x > 0:
			for x in range(grabbedPoint + 1, offsets.size()):
				if newofs > offsets[x]:
					_swap_point_colors(x - 1, x)
					grabbedPoint = x
		texGradient.set_offset(grabbedPoint, newofs)
		update()

func _swap_point_colors(idx1:int, idx2:int):
	var colors:PoolColorArray = texture.gradient.colors
	var tmpColor:Color = colors[idx1]
	texture.gradient.set_color(idx1, colors[idx2])
	texture.gradient.set_color(idx2, tmpColor)

func _get_point_by_pos(mouseX:int):
	var result:int = -1
	var offsets = texture.gradient.offsets
	var min_distance:float = 1e20
	for i in range(0, texture.gradient.get_point_count()):
		var distance:float = abs(mouseX - offsets[i] * rect_size.x)
		var minimum:float = POINT_WIDTH / 2 * GRAB_FACTOR
		if (distance <= minimum and distance < min_distance):
			min_distance = distance
			result = i
	return result

func _draw():
	var gradientTex:GradientTexture = self.texture as GradientTexture
	if gradientTex:
		var colors:PoolColorArray = gradientTex.gradient.colors
		var offsets = gradientTex.gradient.offsets
		for i in range(0, gradientTex.gradient.get_point_count()):
			var edgeColor:Color = colors[i].contrasted()
			edgeColor.a = 0.8
			var pointX:float = offsets[i] * rect_size.x
			var h:float = rect_size.y
			#Make sure that clip contents don't clip the indicator line 
			#if pointX == 0.0:
			#	pointX = CLIP_AVOID_LENGTH
			var drawRect:Rect2 = Rect2(pointX - (POINT_WIDTH / 2), (h / 2) - CLIP_AVOID_LENGTH, POINT_WIDTH, h / 2)
			draw_line(Vector2(pointX, 0), Vector2(pointX, h/2), edgeColor)
			draw_rect(drawRect, colors[i])
			draw_rect(drawRect, edgeColor, false)
			if grabbedPoint == i:
				drawRect = drawRect.grow(-1)
				if has_focus():
					draw_rect(drawRect, Color(1.0, 0, 0, 0.9), false)
				else:
					draw_rect(drawRect, Color(0.6, 0, 0, 0.9), false)
				drawRect = drawRect.grow(-1)
				draw_rect(drawRect, edgeColor, false)

func _on_ColorPicker_color_changed(color:Color):
	if grabbedPoint > -1:
		texture.gradient.set_color(grabbedPoint, color)

func set_inputs_enabled(enabled:bool):
	_inputs_enabled = enabled

func _on_PopupPanel_popup_hide():
	dragging = false
