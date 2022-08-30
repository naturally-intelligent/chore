extends TextureButton

# CALM TEXTURE BUTTON
#
#  Doesn't glitch out when cursor entered/exited quickly
#  Must Set these Textures: Normal, Pressed, Hover
#   Normal texture changed to Hover/Normal on timers
#
#  TODO: Test for joystick/keyboard/touch
#  TODO: Have another small delay after returning to normal before next hover?

export var hover_time = 0.5
signal on_hover_state
signal on_normal_state

onready var normal_tex = get_normal_texture()
onready var hover_tex = get_hover_texture()

func _ready():
	connect("mouse_entered", self, "to_hover_state")
	connect("mouse_exited", self, "to_normal_state")
	connect("focus_entered", self, "to_hover_state")
	connect("focus_exited", self, "to_normal_state")
	$HoverTimer.wait_time = hover_time 
	$HoverTimer.connect("timeout", self, "set_normal_textures")
	set_normal_texture(normal_tex)
	set_hover_texture(normal_tex)	

func to_hover_state():
	$HoverTimer.stop()
	if hover_tex != get_hover_texture():
		set_hover_textures()
		emit_signal('on_hover_state')
	
func to_normal_state():
	$HoverTimer.start()

func set_normal_textures():
	if is_pressed():
		$HoverTimer.start()
	else:
		set_normal_texture(normal_tex)
		set_hover_texture(normal_tex)	
		emit_signal('on_normal_state')
	
func set_hover_textures():
	set_normal_texture(hover_tex)
	set_hover_texture(hover_tex)
