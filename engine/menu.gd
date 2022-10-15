extends Control
class_name RootBaseMenuScene

# contains the optional methods called by Chore management
# - meant primarily for reference, inheritance of class is optional
# - these functions are arranged in order of being called by root
# - normally you may only need one or two of these depending on your scene

# data passed to menus/scenes.show(), called before displaying
func pass_data(data):
	pass

# called before transition
func on_show():
	pass

# called after transition
func on_focus():
	pass

# called if hidden by root manager (not deleted)
func on_hide():
	pass

# called before transition out
func notify_closing():
	pass

func on_pause():
	pass

func on_resume():
	pass

# BACK - to where?
#  this overrides the default behavior of menus.back() / scenes.back()

func back():
	pass

# MENUS - special case for menus

func on_menu_open():
	pass

# SCENES - special case for scenes

func on_scene_open():
	pass

# HUD - special case for HUD widgets -> if added to root.add_hud()

func update_hud():
	pass

func set_text(text):
	pass
