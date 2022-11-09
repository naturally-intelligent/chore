extends Control

# CHORE ENGINE v0.6
# Copyright (C) 2018-2022 Naturally Intelligent
# Designed and developed by David Glen Kerr

# root scene manager
#  loads and swaps scenes with transitions
#  avoid using directly, use 'menus' global object

onready var viewport: Viewport = get_viewport()

# scene info
var last_scene_name := ''
var switching_scene := false
var root_scene := false
var first_scene := true

# screen
var pixel_perfect := false
var scale_window := false

# current scene pointer (focus_scene)
var current_scene: Node = null
var current_scene_name := ''
var current_scene_type := 'none'

# temporary next scene pointer
var _next_scene: Node = null
var _next_scene_name := ''
var _next_scene_type := ''
# storage about current scenes/menus
var scenes_info := {}
var menus_info := {}

# ui
var mouse := false
var debug_lines := []
var debug_max := 5
var hud_allowed := true
var has_quit := false

# scenes don't stack, they are a pool of persistent nodes
#  only 1 is ever running
#  usually only 1 is visible (sometimes 2 for example during slide transitions)
var scene_container_style := 'pool'
onready var scenes_root: Control = $Scenes
# menus do stack, first-in-last-out
#  more than one menu may be visible, and may be overlaid on top of the scenes
var menu_container_style := 'stack'
onready var menus_root: Control = $Overlay/Menus

signal scene_switch_complete()
signal transition_finished()
signal switch_transition_finished()
signal scene_deleted(current_scene_name)

func _ready():
	current_scene = null
	seed(game.title.hash())
	randomize()
	$Overlay.layer = settings.root_overlay_canvas_layer
	if settings.hide_system_cursor:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if pixel_perfect:
		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_IGNORE, Vector2(game.pixel_width,game.pixel_height))
		get_tree().connect("screen_resized", self, "pixel_perfect_resize")
		pixel_perfect_resize()
	else:
		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_KEEP, Vector2(game.pixel_width,game.pixel_height))
		if scale_window:
			scale_root()
	hide_transitions()
	scale_transitions()
	if settings.custom_mouse_cursor:
		set_cursor(settings.custom_mouse_cursor)
	if settings.scale_mouse_cursor:
		scale_cursor()
	# dev timers
	if not game.release:
		$Timers/Screenshot.connect("timeout", self, "auto_screenshot")
		if dev.autoscreenshot_timer:
			$Timers/Screenshot.start() # use A key to start/stop
		$Timers/Advance.connect("timeout", self, "stop_frame")
	# POST LAUNCH
	if dev.dev_mode_enabled:
		dev.post_launch_hacks()

# called by menus.show()
func switch_to_menu(menu, menu_name, menu_data=false, info={}, transitions={}):
	if 'switch_target' in info:
		info['switch_target'] = info['switch_target']
	else:
		info['switch_target'] = 'menu'
	if 'switch_origin' in info:
		info['switch_origin'] = info['switch_origin']
	else:
		info['switch_origin'] = current_scene_type
	reset_time_scale()
	_switch_prepare(menu, menu_name, menu_data, info, transitions)

# called by scenes.show()
func switch_to_scene(scene, scene_name, scene_data=false, info={}, transitions={}):
	if 'switch_target' in info:
		info['switch_target'] = info['switch_target']
	else:
		info['switch_target'] = 'scene'
	if 'switch_origin' in info:
		info['switch_origin'] = info['switch_origin']
	else:
		info['switch_origin'] = current_scene_type
	_switch_prepare(scene, scene_name, scene_data, info, transitions)

func _switch_prepare(scene, scene_name, scene_data=false, info={}, transitions={}):
	var switch_target = info['switch_target']
	var switch_origin = info['switch_origin']
	# TRANSITION OUT
	if not 'out' in transitions:
		transitions['out'] = settings.transition_out
		if settings.transition_menu_to_menu != 'default' and switch_origin == 'menu' and switch_target == 'menu':
			transitions['out'] = 'none'
		if settings.transition_menu_to_scene != 'default' and switch_origin == 'menu' and switch_target == 'scene':
			transitions['out'] = 'none'
		if settings.transition_scene_to_menu != 'default' and switch_origin == 'scene' and switch_target == 'menu':
			transitions['out'] = 'none'
		if settings.transition_scene_to_scene != 'default' and switch_origin == 'scene' and switch_target == 'scene':
			transitions['out'] = 'none'
	# TRANSITION MIDDLE
	if not 'middle' in transitions:
		transitions['middle'] = settings.transition_middle
		if settings.transition_menu_to_menu != 'default' and switch_origin == 'menu' and switch_target == 'menu':
			transitions['middle'] = settings.transition_menu_to_menu
		elif settings.transition_scene_to_menu != 'default' and switch_origin == 'scene' and switch_target == 'menu':
			transitions['middle'] = settings.transition_scene_to_menu
		elif settings.transition_menu_to_scene != 'default' and switch_origin == 'menu' and switch_target == 'scene':
			transitions['middle'] = settings.transition_menu_to_scene
		elif settings.transition_scene_to_scene != 'default' and switch_origin == 'scene' and switch_target == 'scene':
			transitions['middle'] = settings.transition_scene_to_scene
	# TRANSITION IN
	if not 'in' in transitions:
		transitions['in'] = settings.transition_in
		if settings.transition_menu_to_menu != 'default' and switch_origin == 'menu' and switch_target == 'menu':
			transitions['in'] = 'none'
		if settings.transition_menu_to_scene != 'default' and switch_origin == 'menu' and switch_target == 'scene':
			transitions['in'] = 'none'
		if settings.transition_scene_to_menu != 'default' and switch_origin == 'scene' and switch_target == 'menu':
			transitions['in'] = 'none'
		if settings.transition_scene_to_scene != 'default' and switch_origin == 'scene' and switch_target == 'scene':
			transitions['in'] = 'none'
	# DIRECTIONS
	if not 'out_direction' in transitions:
		transitions['out_direction'] = settings.transition_slide_out_direction
	if not 'in_direction' in transitions:
		transitions['in_direction'] = settings.transition_slide_in_direction
	# DISABLE VIA DEV?
	if dev.skip_transitions:
		transitions['out'] = 'none'
		transitions['middle'] = 'none'
		transitions['in'] = 'none'
	# REVERSE THRESHOLD
	if settings.transition_reverse_threshold and settings.transition_reverse_threshold >= 1:
		if switch_target == 'menu':
			if menus_root.get_child_count() >= settings.transition_reverse_threshold:
				transitions['out_direction'] = util.opposite_direction(transitions['out_direction'])
				transitions['in_direction'] = util.opposite_direction(transitions['in_direction'])
	# SPECIAL SCENE TO MENU DIRECTION
	if settings.transition_slide_in_direction_scene_to_menu:
		if switch_origin == 'scene' and switch_target == 'menu':
			transitions['in_direction'] = settings.transition_slide_in_direction_scene_to_menu
	# SPECIAL MENU TO SCENE DIRECTION
	if settings.transition_slide_out_direction_scene_to_menu:
		if switch_origin == 'menu' and switch_target == 'scene':
			transitions['out_direction'] = settings.transition_slide_out_direction_scene_to_menu
	# SWITCH
	_soft_switch(scene, scene_name, scene_data, info, transitions)

# called by scenes.show()
func _soft_switch(scene, scene_name, scene_data, info, transitions):
	#debug.print('--------------------------------')
	#debug.print('switching_scene',scene_name)
	#debug_scene_roots()
	var transition_out = transitions['out']
	var transition_middle = transitions['middle']
	var transition_in = transitions['in']
	# already switching?
	if switching_scene:
		debug.print('WARNING: repeating scene switching:', scene_name)
		return false
	# semaphore
	switching_scene = true
	# notify current scene
	if current_scene:
		if current_scene.has_method("notify_closing"):
			current_scene.notify_closing()
		last_scene_name = current_scene_name
	# PAUSE SCENE
	_pause_current_scene()
	# TRANSITION OUT
	if transition_out and transition_out != 'none':
		_transition_out(transitions)
		yield(self, "switch_transition_finished")
	# PRE-DELETE SCENES
	_pre_delete_scenes(info)
	# ADD/RESTORE NEW SCENE
	_add_next_scene(scene, scene_name, info)
	# TRANSITION MIDDLE
	if transition_middle and transition_middle != 'none':
		_transition_middle(info, transitions)
		yield(self, "switch_transition_finished")
	# REMOVE/HIDE OLD SCENE
	if current_scene:
		_remove_current_scene(info)
	# HARD SWITCH
	_hard_switch_scene()
	# PASS DATA
	if current_scene.has_method('pass_data'):
		current_scene.pass_data(scene_data)
	# ON_SHOW
	if current_scene.has_method('on_show'):
		current_scene.on_show()
	# ENABLE
	reset_overlay()
	if dev.shader_test:
		enable_shader(dev.shader_test)
	if current_scene_type == 'scene':
		enable_scenes()
	if current_scene_type == 'menu':
		enable_menus()
	# RESUME
	_resume_current_scene()
	# TRANSITION IN
	if transition_in and transition_in != 'none':
		_transition_in(transitions)
		yield(self, "switch_transition_finished")
	# UPDATE UI
	update_ui()
	# ON_FOCUS
	if current_scene.has_method('on_focus'):
		current_scene.on_focus()
	# FINISH
	switching_scene = false
	first_scene = false
	emit_signal("scene_switch_complete")
	#debug.print('finished!')
	#debug_scene_roots()
	#debug.print('--------------------------------')

func _add_next_scene(scene, scene_name, info):
	# notify engine we have a proper root scene
	root_scene = true
	# gather info
	var switch_target = info['switch_target']
	var target_root = get_scene_container(switch_target)
	var target_style = get_container_style(switch_target)
	#debug.print('_add_next_scene:','switch_origin=',switch_origin,',switch_target=',switch_target,',origin_style=',origin_style,',target_style=',target_style)
	if switch_target == 'scene':
		hide_menus()
	# new current scene
	_next_scene = scene
	_next_scene.name = scene_name
	_next_scene_name = scene_name
	_next_scene_type = switch_target
	# add to container
	if target_style == 'pool':
		var found = false
		for child in target_root.get_children():
			child.visible = false
			if child.name == scene_name:
				child.visible = true
				found = true
		if not found:
			target_root.add_child(_next_scene)
	elif target_style == 'stack':
		var inside = false
		for child in target_root.get_children():
			if child == _next_scene:
				inside = true
		if not inside:
			target_root.add_child(_next_scene)

func _pre_delete_scenes(info):
	var switch_target = info['switch_target']
	var target_root = get_scene_container(switch_target)
	var removal_method = 'hide'
	if 'remove' in info:
		removal_method = 'delete'
	if 'clear' in info:
		removal_method = 'delete_all'
	# removal
	if removal_method == 'delete':
		if current_scene:
			current_scene.queue_free()
			target_root.remove_child(current_scene)
			current_scene = null
			if switch_target == 'scene':
				emit_signal("scene_deleted", current_scene_name)
	# removal?
	elif removal_method == 'delete_all':
		var removal = []
		for child in target_root.get_children():
			child.queue_free()
			removal.append(child)
		for child in removal:
			target_root.remove_child(child)
		if switch_target == 'scene':
			emit_signal("scene_deleted", current_scene_name)

# removing may not mean deleting, could be hiding
func _remove_current_scene(info):
	# gather info
	var switch_target = info['switch_target']
	var switch_origin = info['switch_origin']
	var origin_root = get_scene_container(switch_origin)
	var target_root = get_scene_container(switch_target)
	var origin_style = get_container_style(switch_origin)
	#debug.print('_remove_current_scene:','current_scene_name=',current_scene_name,',switch_origin=',switch_origin,',switch_target=',switch_target,',origin_style=',origin_style,',target_style=',target_style)
	# remove/hide old scene
	if origin_style == 'pool':
		# hide other scenes (unless switching to overlay menu)
		if switch_target == 'scene':
			for child in origin_root.get_children():
				if child == current_scene:
					child.visible = false
	elif origin_style == 'stack':
		# remove anything above next_scene
		var found = false
		var to_remove = []
		for child in origin_root.get_children():
			if found:
				to_remove.append(child)
			if child == _next_scene:
				found = true
		for child in to_remove:
			#debug.print('removing from stack:',child.name)
			origin_root.remove_child(child)
			child.queue_free()
	# special modes
	var removal_method = 'hide'
	if settings.single_scene_mode and switch_target == 'scene' and switch_origin == 'scene':
		removal_method = 'delete'
	if settings.single_menu_mode and switch_target == 'menu' and switch_origin == 'menu':
		removal_method = 'delete'
	# removal
	if removal_method == 'delete':
		if current_scene:
			current_scene.queue_free()
			target_root.remove_child(current_scene)
			current_scene = null
			if switch_target == 'scene':
				emit_signal("scene_deleted", current_scene_name)
	if removal_method == 'hide':
		if current_scene.has_method('on_hide'):
			current_scene.on_hide()
	# clear pointer
	current_scene_name = ''
	current_scene_type = ''
	current_scene = null
	# hide override?
	if switch_origin == 'menu' and switch_target == 'scene':
		hide_menus()
	if switch_target == 'menu' and settings.always_hide_scenes_for_menus:
		hide_scenes()
	if switch_target == 'menu' and settings.destroy_all_scenes_for_menus:
		clear_scenes()
	if switch_target == 'menu' and settings.always_hide_underlying_menus:
		hide_menus()
		enable_menus()
	if switch_target == 'scene':
		hide_menus()
	hide_shaders()

# do not call directly
func _hard_switch_scene():
	if _next_scene:
		current_scene = _next_scene
		current_scene_name = _next_scene_name
		current_scene_type = _next_scene_type
		current_scene.visible = true
		current_scene.raise()
	_next_scene = null
	_next_scene_name = ''
	_next_scene_type = ''

func _pause_current_scene():
	if current_scene:
		current_scene.set_process(false)
		current_scene.set_physics_process(false)
		current_scene.set_process_input(false)
		if current_scene.has_method('on_pause'):
			current_scene.on_pause()
		if settings.pause_tree_during_switch:
			if current_scene_type == 'scene':
				pause()

func _resume_current_scene():
	if current_scene:
		current_scene.set_process(true)
		current_scene.set_physics_process(true)
		current_scene.set_process_input(true)
		if current_scene.has_method('on_resume'):
			current_scene.on_resume()
		if settings.pause_tree_during_switch:
			if current_scene_type == 'scene':
				resume()

func get_scene_container(scene_type: String) -> Control:
	if scene_type == 'scene':
		return scenes_root
	if scene_type == 'menu':
		return menus_root
	#debug.print("WARNING: unknown scene container type!", scene_type)
	return scenes_root

func get_container_style(scene_type: String) -> String:
	if scene_type == 'scene':
		return scene_container_style # pool
	if scene_type == 'menu':
		return menu_container_style # stack
	#debug.print("WARNING: unknown scene container type!", scene_type)
	return 'pool'

# CLEAR / DELETE / HIDE / SHOW SCENES

func clear_scenes():
	var remove = []
	for child in root.scenes_root.get_children():
		if current_scene == child:
			current_scene = null
			current_scene_name = ''
			current_scene_type = 'none'
		child.queue_free()
		remove.append(child)
	for child in remove:
		root.scenes_root.remove_child(child)

func clear_menus():
	var remove = []
	for child in root.menus_root.get_children():
		if current_scene == child:
			current_scene = null
			current_scene_name = ''
			current_scene_type = 'none'
		child.queue_free()
		remove.append(child)
	for child in remove:
		root.menus_root.remove_child(child)

func clear_menus_above(menu):
	var remove = []
	var found = false
	for child in root.menus_root.get_children():
		if found:
			if current_scene == child:
				current_scene = null
				current_scene_name = ''
				current_scene_type = 'none'
			child.queue_free()
			remove.append(child)
		if child == menu:
			found = true
	for child in remove:
		root.menus_root.remove_child(child)

# for running from F6 within godot editor
func check_is_root_scene(scene, scene_name):
	if not root_scene:
		debug.print('F6 root scene override')
		root_scene = true
		scene.queue_free()
		menus.show(scene_name)
		return false
	return true

func _notification(note):
	# clear pointers
	if note == NOTIFICATION_PREDELETE:
		current_scene = null
		_next_scene = null

func enable_menus():
	menus_root.visible = true

func hide_menus():
	menus_root.visible = false
	for menu in menus_root.get_children():
		menu.visible = false

func enable_scenes():
	scenes_root.visible = true

func hide_scenes():
	scenes_root.visible = false
	for scene in scenes_root.get_children():
		scene.visible = false

# WINDOW / SCALING

func scale_root():
	var orig_w = game.pixel_width
	var orig_h = game.pixel_height
	var proj_w = ProjectSettings.get_setting("display/window/size/width")
	var proj_h = ProjectSettings.get_setting("display/window/size/height")
	var scale_w = int(proj_w / orig_w)
	var scale_h = int(proj_h / orig_h)
	set_scale(Vector2(scale_w, scale_h))

func scale_transitions():
	if game.pixel_width > 640:
		$Overlay/Transitions.rect_scale.x = game.pixel_width / 640
		$Overlay/Transitions.rect_scale.y = game.pixel_height / 320

func scale_cursor():
	# if you use this, reimport mouse cursor texture with no filter
	if game.pixel_width > settings.scale_mouse_cursor_w:
		$Overlay/Mouse/Cursor.rect_scale.x = game.pixel_width / settings.scale_mouse_cursor_w
		$Overlay/Mouse/Cursor.rect_scale.y = game.pixel_height / settings.scale_mouse_cursor_h

# https://godotengine.org/qa/25504/pixel-perfect-scaling
func pixel_perfect_resize():
	var window_size = OS.get_window_size()

	# see how big the window is compared to the viewport size
	# floor it so we only get round numbers (0, 1, 2, 3 ...)
	var scale_x = floor(window_size.x / viewport.size.x)
	var scale_y = floor(window_size.y / viewport.size.y)

	# use the smaller scale with 1x minimum scale
	var scale = max(1, min(scale_x, scale_y))

	# find the coordinate we will use to center the viewport inside the window
	var diff = window_size - (viewport.size * scale)
	var diffhalf = (diff * 0.5).floor()

	# attach the viewport to the rect we calculated
	viewport.set_attach_to_screen_rect(Rect2(diffhalf, viewport.size * scale))

# INPUT

func _input(event):
	# mouse cursor / back button
	if event is InputEventMouseMotion:
		mouse = true
		update_mouse_position()
		update_mouse()
	# common keys
	else:
		if settings.root_capture_ui_cancel and Input.is_action_just_pressed("ui_cancel"):
			menus.back()
		if Input.is_action_just_pressed("ui_fullscreen"):
			util.fullscreen_flip()
		if Input.is_action_just_pressed("ui_screenshot"):
			util.screenshot(self, dev.screenshot_size)
			#util.screenshot(self, Vector2(640,360))
		if dev.dev_mode_enabled:
			if Input.is_action_just_pressed("ui_hud"):
				hud_allowed = not hud_allowed
				update_hud()
			if !has_text_entry():
				if Input.is_key_pressed(KEY_Q):
					quit()
				if Input.is_action_just_pressed("ui_autoscreenshot"):
					flip_autoscreenshot()
			if Input.is_action_just_pressed("ui_quit"):
				quit()
			if Input.is_action_just_pressed("dev_pause"):
				debug.console('pause - press Backspace to resume')
				pause()
				Engine.time_scale = 0.0
			elif Input.is_action_just_pressed("dev_advance"):
				debug.console('advance - \\ for next frame or Backspace to resume')
				Engine.time_scale = 1.0
				resume()
				reset()
				$Timers/Advance.start()
			elif Input.is_action_just_pressed("dev_resume"):
				hide_console()
				resume()
				reset()
			elif Input.is_action_pressed("dev_slow"):
				resume()
				Engine.time_scale *= 0.75
				if Engine.time_scale < 0.1:
					Engine.time_scale = 0.1
				debug.console('slow ',util.trim_decimals(Engine.time_scale, 1),'  - press Backspace for normal')
			elif Input.is_action_pressed("dev_fast"):
				resume()
				Engine.time_scale *= 1.5
				if Engine.time_scale > 10:
					Engine.time_scale = 10
				debug.console('fast ',util.trim_decimals(Engine.time_scale, 1),' - press Backspace for normal')
			elif Input.is_action_just_pressed("dev_console"):
				flip_console()
				if is_console_visible():
					show_console_readme()

# UPDATES

func update_ui():
	if settings.hide_system_cursor:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if mouse:
		update_mouse()
	update_debug()
	update_hud()

func reset_overlay():
	for node in $Overlay.get_children():
		node.visible = false

# MOUSE / CURSOR

func update_mouse():
	var show_mouse = false
	if util.desktop and settings.allow_mouse_cursor:
		show_mouse = true
	if current_scene:
		if current_scene.get('no_mouse'):
			show_mouse = false
	if show_mouse:
		update_mouse_position()
		show_cursor()
	else:
		hide_cursor()

func update_mouse_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var root_scale = get_scale()
	mouse_pos.x /= root_scale.x
	mouse_pos.y /= root_scale.y
	$Overlay/Mouse/Cursor.rect_position = mouse_pos

func set_cursor(file):
	if util.file_exists(file):
		var tex = load(file)
		$Overlay/Mouse/Cursor.texture = tex

func show_cursor():
	if settings.custom_mouse_cursor:
		$Overlay/Mouse.visible = true

func hide_cursor():
	$Overlay/Mouse.visible = false
	if dev.emulate_touch and dev.emulate_touch_mouse:
		show_cursor()
		mouse = true

func show_mouse_cursor():
	Input.set_mouse_mode( Input.MOUSE_MODE_VISIBLE )

func hide_mouse_cursor():
	if dev.hide_system_cursor:
		Input.set_mouse_mode( Input.MOUSE_MODE_HIDDEN )

func capture_mouse_cursor():
	Input.set_mouse_mode( Input.MOUSE_MODE_CAPTURED )

# SHADERS

func enable_shader(name):
	hide_shaders()
	$Overlay/Shaders.visible = true
	if name == 'whirl':
		$Overlay/Shaders/WhirlShader.visible = true
	elif name == 'mirage':
		$Overlay/Shaders/MirageShader.visible = true
	elif name == 'blur':
		$Overlay/Shaders/BlurShader.visible = true
	elif name == 'grey':
		$Overlay/Shaders/GreyShader.visible = true
	elif name == 'brightness':
		$Overlay/Shaders/BrightnessShader.visible = true
	#elif name == 'sepia':
	#	$Overlay/Shaders/SepiaShader.visible = true
	#elif name == 'film':
	#	$Overlay/Shaders/FilmShader.visible = true

func hide_shaders():
	$Overlay/Shaders.visible = false
	for shader in $Overlay/Shaders.get_children():
		shader.visible = false

# TRANSITIONS

func enable_transitions():
	hide_transitions()
	$Overlay/Transitions.visible = true

func hide_transitions():
	#$Overlay/Transitions.visible = false
	for node in $Overlay/Transitions.get_children():
		node.visible = false

func _transition_out(transitions):
	var transition_out = transitions['out']
	if transition_out and transition_out != 'none':
		enable_transitions()
		if transition_out == 'fade':
			transition_fade_out(settings.transition_out_time)
			yield(self, "transition_finished")
		elif transition_out == 'fade_stagger':
			transition_fade_out_stagger(settings.transition_out_time)
			yield(self, "transition_finished")
	emit_signal("switch_transition_finished")

func _transition_middle(info, transitions):
	var transition_middle = transitions['middle']
	var switch_origin = info['switch_origin']
	var switch_target = info['switch_target']
	var slide_out_direction = transitions['out_direction']
	var slide_in_direction = transitions['in_direction']
	if transition_middle and transition_middle != 'none':
		enable_transitions()
		if transition_middle == 'black' or transition_middle == 'fade':
			transition_wait(settings.transition_middle_time)
			yield(self, "transition_finished")
		elif transition_middle == 'slide_both':
			if switch_origin == 'menu' or switch_target == 'menu':
				enable_menus()
			transition_slide_both(current_scene, _next_scene, slide_out_direction)
			yield(self, "transition_finished")
		elif transition_middle == 'slide_new':
			if switch_origin == 'menu' or switch_target == 'menu':
				enable_menus()
			transition_slide(_next_scene, 'in', slide_in_direction)
			yield(self, "transition_finished")
		elif transition_middle == 'slide_old':
			if switch_origin == 'menu' or switch_target == 'menu':
				enable_menus()
			transition_slide(current_scene, 'out', slide_out_direction)
			yield(self, "transition_finished")
	emit_signal("switch_transition_finished")

func _transition_in(transitions):
	var transition_in = transitions['in']
	if transition_in and transition_in != 'none':
		if transition_in == 'fade':
			transition_fade_in(game.time(settings.transition_in_time))
			yield(self, "transition_finished")
		elif transition_in == 'fade_stagger':
			transition_fade_in_stagger(game.time(settings.transition_in_time))
			yield(self, "transition_finished")
		hide_transitions()
	emit_signal("switch_transition_finished")

func fade_out_and_quit():
	resume()
	# transition?
	if settings.transition_quit != 'none':
		enable_transitions()
		if settings.transition_quit == 'fade':
			transition_fade_out(game.time(settings.transition_quit_time))
			yield(self, "transition_finished")
		elif settings.transition_quit == 'fade_stagger':
			transition_fade_out_stagger(game.time(settings.transition_quit_time))
			yield(self, "transition_finished")
	# quit
	quit()

func transition_wait(middle_time=0.3):
	if dev.skip_transitions:
		emit_signal("transition_finished")
		return
	enable_transitions()
	var transition = $Overlay/Transitions/Fader
	transition.visible = true
	# stay for a little while
	var middle_timer = util.wait(game.time(middle_time), self)
	yield(middle_timer, "timeout")
	emit_signal("transition_finished")

func transition_fade_out(fade_time=0.3):
	if dev.skip_transitions:
		emit_signal("transition_finished")
		return
	enable_transitions()
	var transition = $Overlay/Transitions/Fader
	transition.visible = true
	var tween = $Overlay/Transitions/Fader/Tween
	tween.interpolate_property(transition, "modulate",
	  Color(1, 1, 1, 0), Color(1, 1, 1, 1), game.time(fade_time),
	  Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	emit_signal("transition_finished")

func transition_fade_in(fade_time=0.3):
	if dev.skip_transitions:
		emit_signal("transition_finished")
		return
	# fade in from black
	enable_transitions()
	var transition = $Overlay/Transitions/Fader
	transition.visible = true
	var tween = $Overlay/Transitions/Fader/Tween
	tween.interpolate_property(transition, "modulate",
	  Color(1, 1, 1, 1), Color(1, 1, 1, 0), game.time(fade_time),
	  Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	emit_signal("transition_finished")

func transition_fade_out_stagger(fade_out_time=0.2):
	if dev.skip_transitions:
		emit_signal("transition_finished")
		return
	# fade out to black
	enable_transitions()
	hide_cursor()
	var fade_out_steps = 3
	var fade_out_step_time = fade_out_time/float(fade_out_steps)
	var transition = $Overlay/Transitions/Fader
	transition.visible = true
	for i in range(fade_out_steps+1):
		var a = i/float(fade_out_steps)
		transition.modulate = Color(1, 1, 1, a)
		var timer = util.wait(game.time(fade_out_step_time), self)
		yield(timer, "timeout")
	emit_signal('transition_finished')

func transition_fade_in_stagger(fade_in_time=0.3):
	if dev.skip_transitions:
		emit_signal("transition_finished")
		return
	enable_transitions()
	var fade_in_steps = 5
	var fade_in_step_time = fade_in_time/float(fade_in_steps)
	# fade out to black
	var transition = $Overlay/Transitions/Fader
	transition.visible = true
	# fade back in from black to new scene
	for i in range(fade_in_steps+1):
		var a = 1-i/float(fade_in_steps)
		transition.modulate = Color(1, 1, 1, a)
		var timer = util.wait(game.time(fade_in_step_time), self)
		yield(timer, "timeout")
	emit_signal('transition_finished')

func transition_slide(scene, in_out, direction, time=0.5):
	scene.visible = true
	var off_screen
	var on_screen
	if in_out == 'out':
		direction = util.opposite_direction(direction)
	# off_screen
	if direction == 'left':
		off_screen = Vector2(game.pixel_width, 0)
	elif direction == 'right':
		off_screen = Vector2(-game.pixel_width, 0)
	elif direction == 'up':
		off_screen = Vector2(0, game.pixel_height)
	elif direction == 'down':
		off_screen = Vector2(0, -game.pixel_height)
	# on_screen
	on_screen = Vector2(0,0)
	var destination
	var param = 'position'
	if 'rect_position' in scene:
		param = 'rect_position'
	if in_out == 'in':
		destination = on_screen
		if param == 'rect_position':
			scene.rect_position = off_screen
		else:
			scene.position = off_screen
	elif in_out == 'out':
		destination = off_screen
		if param == 'rect_position':
			scene.rect_position = on_screen
		else:
			scene.position = on_screen
	var tween = Tween.new()
	tween.interpolate_property(scene,
		param, null, destination, game.time(time),
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Timers.add_child(tween)
	tween.start()
	yield(tween, 'tween_completed')
	tween.queue_free()
	$Timers.remove_child(tween)
	emit_signal('transition_finished')

func transition_slide_both(old, new, direction, time=0.5):
	#new.rect_position = Vector2(game.pixel_width*dir, 0)
	new.visible = true
	old.visible = true
	var on_screen = Vector2(0,0)
	var off_screen_new
	var off_screen_old
	# off_screen
	if direction == 'left':
		off_screen_new = Vector2(-game.pixel_width, 0)
		off_screen_old = Vector2(game.pixel_width, 0)
	elif direction == 'right':
		off_screen_new = Vector2(game.pixel_width, 0)
		off_screen_old = Vector2(-game.pixel_width, 0)
	elif direction == 'up':
		off_screen_new = Vector2(0, game.pixel_height)
		off_screen_old = Vector2(0, -game.pixel_height)
	elif direction == 'down':
		off_screen_new = Vector2(0, -game.pixel_height)
		off_screen_old = Vector2(0, game.pixel_height)
	# parameter
	var new_param = 'position'
	if 'rect_position' in new:
		new_param = 'rect_position'
	var old_param = 'position'
	if 'rect_position' in old:
		old_param = 'rect_position'
	# setup
	if new_param == 'rect_position':
		new.rect_position = off_screen_new
	else:
		new.position = off_screen_new
	# tween
	var new_tween = Tween.new()
	new_tween.interpolate_property(new,
		new_param, null, on_screen, game.time(time),
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Timers.add_child(new_tween)
	new_tween.start()
	var old_tween = Tween.new()
	old_tween.interpolate_property(old,
		old_param, null, off_screen_old, time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Timers.add_child(old_tween)
	old_tween.start()
	yield(new_tween, 'tween_completed')
	new_tween.queue_free()
	$Timers.remove_child(new_tween)
	old_tween.queue_free()
	$Timers.remove_child(old_tween)
	emit_signal('transition_finished')

func black_box_slide():
	enable_transitions()
	$Overlay/Transitions.visible = true
	hide_cursor()
	var time = 1.5
	var transition = $Overlay/Transitions/Box
	var tween = $Overlay/Transitions/Box/Tween
	var material = transition.get_material()
	transition.visible = true
	$Overlay/Transitions/Box/Top.visible = false
	$Overlay/Transitions/Box/Bottom.visible = false
	$Overlay/Transitions/Box/Right.visible = false
	$Overlay/Transitions/Box/Left.visible = false
	#tween.interpolate_property(material, "slide",
	#  1.0, 0.0, fade_time,
	#  Tween.TRANS_LINEAR, Tween.EASE_IN)
	var start_slide = 1.0
	var end_slide = 0.0
	material.set_shader_param("slide", start_slide)
	tween.interpolate_method(self, "set_box_slide",
	  start_slide, end_slide, game.time(time),
	  Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	hide_transitions()
	show_cursor()
	update_ui()

func set_box_slide(value):
	var transition = $Overlay/Transitions/Box
	var material = transition.get_material()
	material.set_shader_param("slide", value)

# SCREENSHOTS

func auto_screenshot():
	debug.print('autoscreenshot')
	if current_scene:
		util.screenshot(self, dev.autoscreenshot_resolution)

func flip_autoscreenshot():
	if not game.release:
		if $Timers/Screenshot.is_stopped():
			debug.print('autoscreenshot started')
			if dev.autoscreenshot_hidecursor:
				dev.allow_mouse_cursor = false
				hide_cursor()
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$Timers/Screenshot.start()
		else:
			debug.print('autoscreenshot stopped')
			if dev.autoscreenshot_hidecursor:
				dev.allow_mouse_cursor = true
				update_ui()
			$Timers/Screenshot.stop()

# DEBUG / CONSOLE

func update_debug():
	$Overlay/Debug.visible = false
	if dev.debug_overlay:
		$Overlay/Debug.visible = true

func set_debug_info(text):
	$Overlay/Debug.visible = true
	$Overlay/Debug/Info.set_text(text)

func add_debug_line(text):
	# check for duplicate with last line
	if debug_lines.size() > 0 and debug_lines[debug_lines.size()-1] == text:
		return
	debug_lines.append(text)
	if debug_lines.size() > 5:
		debug_lines.pop_front()
	$Overlay/Debug.visible = true
	var full = ''
	for line in debug_lines:
		full += line + "\n"
	$Overlay/Debug/Info.set_text(full)

func show_console():
	$Overlay/Debug.visible = true

func hide_console():
	$Overlay/Debug.visible = false

func flip_console():
	$Overlay/Debug.visible = not $Overlay/Debug.visible

func is_console_visible():
	return $Overlay/Debug.visible

func show_console_readme():
	debug_lines = []
	add_debug_line('~ show/hide')
	add_debug_line('[ slow')
	add_debug_line('] fast')
	add_debug_line('\\ step')
	add_debug_line('backspace resumes')

func debug_reset():
	debug_lines = []

func debug_scene_roots():
	debug.print('SCENE ROOT')
	var count = 0
	for child in scenes_root.get_children():
		debug.print('-' + str(count) + ': ' + child.name)
		count += 1
	debug.print('MENU ROOT')
	count = 0
	for child in menus_root.get_children():
		debug.print('-' + str(count) + ': ' + child.name)
		count += 1
	debug.print('current_scene_name = ' + current_scene_name)
	debug.print('current_scene_type = ' + current_scene_type)

# HUD
# - an empty node that you can add scenes to with some convenience methods

func update_hud():
	if not hud_allowed or dev.no_hud_ever:
		hide_hud()
		return
	var allow_hud = true
	if current_scene:
		if 'show_hud' in current_scene:
			if current_scene.show_hud:
				allow_hud = true
		if 'no_hud' in current_scene:
			if current_scene.no_hud:
				allow_hud = false
	if allow_hud:
		show_hud()
		for child in $Overlay/HUD.get_children():
			if child.has_method('update_hud'):
				child.update_hud()
	else:
		hide_hud()

func show_hud():
	$Overlay/HUD.visible = true
	for child in $Overlay/HUD.get_children():
		child.visible = true

func hide_hud():
	$Overlay/HUD.visible = false

func is_hud_visible():
	return $Overlay/HUD.visible

func set_hud_text(text):
	for child in $Overlay/HUD.get_children():
		if child.has_method('set_text'):
			child.set_text(text)

func has_hud():
	return $Overlay/HUD.get_child_count() > 0

func get_hud():
	if $Overlay/HUD.get_child_count() > 0:
		return $Overlay/HUD.get_children()[0]
	else:
		return null

func add_hud(hud):
	for child in $Overlay/HUD.get_children():
		if child == hud:
			return false
	$Overlay/HUD.add_child(hud)
	return true

func remove_hud():
	for child in $Overlay/HUD.get_children():
		child.queue_free()

# MISC

func has_text_entry():
	if current_scene:
		if current_scene.get('text_entry'):
			return true
	return false

# SPEED / PAUSE / RESUME

func pause():
	get_tree().paused = true

func resume():
	get_tree().paused = false

func stop_frame():
	pause()
	Engine.time_scale = 0

func reset():
	Engine.time_scale = 1

func reset_time_scale():
	if Engine.time_scale != 1:
		Engine.time_scale = 1

# COMMAND-LINE START - called by launch.gd
# common dev command line arguments:
#  -menu=name
#  -fullscreen
#  -screen=1200x800
func command_line_start():
	# store command line arguments
	var commands = OS.get_cmdline_args()
	for i in range(commands.size()):
		var arg = commands[i]
		#debug.print(i,'-',arg)
		var split = arg.split('=')
		if split.size() > 1:
			settings.args[split[0]] = split[1]
		elif split.size() == 1:
			settings.args[split[0]] = true
	#for arg in settings.arg:
		#var value = settings.arg[arg]
		#debug.print(arg,'=',value)

	# launch dev settings, careful here
	if not game.release and not util.mobile:
		if dev.dev_mode_enabled:
			dev.launch_hacks()
			if dev.forced_window:
				print('forcing window size')
				OS.set_window_fullscreen(false)
				OS.set_window_size(dev.forced_window)

	# CHECK ARGUMENTS
	if 'monitor' in settings.args:
		var mon = int(settings.args['monitor'])-1
		if OS.get_screen_count() >= mon:
			OS.set_current_screen(mon)
		if 'position' in settings.args:
			debug.print("WARNING: monitor may be ignored if position also set.")
	# fullscreen
	if 'fullscreen' in settings.args:
		OS.set_window_fullscreen(true)
	# screen size (windowed)
	elif 'screen' in settings.args:
		var xstr = settings.args['screen']
		var split = xstr.split('x')
		if split.size()==2:
			var w = int(split[0])
			var h = int(split[1])
			if w>0 && h>0:
				var v2 = Vector2(w,h)
				OS.set_window_fullscreen(false)
				OS.set_window_size(v2)
	# windowed
	elif 'window' in settings.args:
		OS.set_window_fullscreen(false)
	# debug info\
	if 'debug' in settings.args:
		debug.print("Display size: ", OS.get_screen_size())
		debug.print("Decorated size: ", OS.get_real_window_size())
		debug.print("Window size: ", OS.get_window_size())
		ProjectSettings.set_setting("display/window/size/width", 320)
		ProjectSettings.set_setting("display/window/size/height", 180)
		root.set_scale(Vector2(1,1))
		debug.print("Project display w: ", ProjectSettings.get_setting("display/window/size/width"))
		debug.print("Project display h: ", ProjectSettings.get_setting("display/window/size/height"))
	# fast mode
	if 'position' in settings.args:
		var xstr = settings.args['position']
		var split = xstr.split('x')
		if split.size()==2:
			var w = int(split[0])
			var h = int(split[1])
			if w>0 && h>0:
				var v2 = Vector2(w,h)
				OS.set_window_position(v2)
	# FIRST MENU TO SHOW
	if !game.release:
		if '-menu' in settings.args:
			game.launch_menu = settings.args['-menu']

# QUIT

func quit():
	if not has_quit:
		has_quit = true
		debug.print('quit')
		#print_stray_nodes()
		#debug.print(print_tree_pretty())
		get_tree().quit()
