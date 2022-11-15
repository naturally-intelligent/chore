class_name GameViewport extends ViewportContainer

func _ready():
	set_process_unhandled_input(true)

func _input(event):
	if event is InputEventMouse:
		root.update_mouse_position()

func viewport():
	return $Viewport
