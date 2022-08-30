extends Node

# COMMAND LINE ARGUMENTS (populated at launch)
var args = []

# AUDIO
var sound_volume = 1.0
var music_volume = 1.0

# MENUS
var main_menu_name = 'main'
var menu_dirs = []
var custom_menu_dirs_only = false
var allow_res_menus = false # allows: res://mydir/mymenu.tscn
var always_hide_underlying_menus = false
var single_menu_mode = false # force only one active menu at a time

# SCENES
var scene_dirs = []
var custom_scene_dirs_only = false
var allow_res_scenes = false # allows: res://mydir/myscene.tscn
var always_hide_scenes_for_menus = false
var destroy_all_scenes_for_menus = false
var single_scene_mode = false # force only one active scene at a time
var pause_tree_during_switch = false

# MOUSE
var custom_mouse_cursor = "res://art/hud/cursor-1.png"
var allow_mouse_cursor = true
var hide_system_cursor = true
var scale_mouse_cursor = true
var scale_mouse_cursor_w = 640
var scale_mouse_cursor_h = 360

# TRANSITIONS
var transition_out = 'fade' # fade / alpha / none
var transition_middle = 'black'
var transition_in = 'fade'
var transition_out_time = 0.1
var transition_middle_time = 0.2
var transition_in_time = 0.1
var transition_quit = 'fade'
var transition_quit_time = 0.5
var transition_scene_to_menu = 'slide_new' # default / fade / slide_new / slide_old / slide_both
var transition_menu_to_menu = 'slide_both'
var transition_scene_to_scene = 'default'
var transition_menu_to_scene = 'slide_old'
var transition_slide_in_direction = 'right' # left / right / up / down
var transition_slide_out_direction = 'left'
var transition_reverse_threshold = 2 # menus that exist before reversing direction, 0/false to ignore
var transition_slide_in_direction_scene_to_menu = 'down' # false or a direction for showing menu after scene
var transition_slide_out_direction_scene_to_menu = 'down' # false or a direction for hiding menu after scene

# ROOT / HUD / Mouse + Menu Layer Priority
var root_overlay_canvas_layer = 111

# MUSIC
var music_ext = '.ogg'
var music_dirs = ['music']
var tracklist = {
	'main-menu': ['song-file-todo', 0.8],
}
# SOUND
var sound_ext = '.wav'
var sound_dirs = ['sound']
var sound_alias = {
	# MENU
	'menu-hover': 'bump',
	'menu-press': 'pick',
}
# COLORS
var color_rgbs = {
	'red': Color(1,0,0),
	'blue': Color(0,0,1),
	'green': Color(0,1,0),
	'purple': Color(64/256,0,64/256),
	'yellow': Color(1,2/3,0),
	'orange': Color(1,1/3,0),
	'white': Color(1,1,1),
	'black': Color(0,0,0),
}
var colors = color_rgbs.keys()
