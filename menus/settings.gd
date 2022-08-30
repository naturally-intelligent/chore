extends "res://menus/menu.gd"

# Copyright (C) 2018 Naturally Intelligent

var text_entry = true
var no_back_button = true

func _ready():
	customize_to_platform()
	var fullscreen = get_widget('fullscreen')
	fullscreen.set_pressed(OS.is_window_fullscreen())
	fullscreen.connect('toggled', self, 'fullscreen_toggle')
	$BackButton.connect('pressed', self, 'back_button_pressed')
	var sound = get_widget('sound')
	sound.value = settings.sound_volume
	sound.connect('value_changed', self, 'sound_changed')
	var music = get_widget('music')
	music.value = settings.music_volume
	music.connect('value_changed', self, 'music_changed')
	set_default_menu_button($BackButton)

func get_widget(name):
	if name == 'fullscreen':
		return $GridNames/FullscreenCheckBox
	elif name == 'fullscreen_label':
		return $GridNames/FullscreenLabel
	elif name == 'sound':
		return $GridAudio/HSliderSound
	elif name == 'music':
		return $GridAudio/HSliderMusic
	elif name == 'reset':
		return $GridNames/ResetButton

func customize_to_platform():
	if util.mobile:
		get_widget('fullscreen').visible = false
		get_widget('fullscreen_label').visible = false

func fullscreen_toggle(state):
	if state == true:
		OS.set_window_fullscreen(true)
	else:
		OS.set_window_fullscreen(false)
	var fullscreen = get_widget('fullscreen')
	fullscreen.set_pressed(OS.is_window_fullscreen())
	
func back_button_pressed():
	menus.back()

func sound_changed(value):
	settings.sound_volume = value
	audio.set_sound_volume(settings.sound_volume)

func music_changed(value):
	settings.music_volume = value
	audio.set_music_volume(settings.music_volume)

func notify_fullscreen():	
	var fullscreen = get_widget('fullscreen')
	fullscreen.set_pressed(OS.is_window_fullscreen())
