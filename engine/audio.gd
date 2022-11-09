extends Node

var sounds := {}
var sound_dirs = settings.sound_dirs
var history := {}
var ambience_timers := {}
var file_locations := {}
var current_song = false
var missing_files := []

signal music_volume_changed()

onready var music_tween = $MusicTween

func _ready():
	set_sound_volume(settings.sound_volume)
	set_music_volume(settings.music_volume)

func play_music(song_name, volume=1.0):
	if dev.silence: return
	if dev.no_music: return
	var name = song_name
	if song_name in settings.tracklist:
		var song_data = settings.tracklist[song_name]
		if typeof(song_data) == TYPE_STRING:
			name = song_data
			volume = 1.0
		else: # array
			name = song_data[0]
			volume = song_data[1]
	if music_playing(name): return
	debug.print('playing song: ' + name)
	if $MusicFadeOut.is_active():
		$MusicFadeOut.stop_all()
	stop_and_reset_music()
	var songfile = find_music_file(name)
	if songfile:
		var stream = load(songfile)
		if stream:
			if volume:
				set_music_volume(settings.music_volume*volume)
			$MusicPlayer.set_stream(stream)
			$MusicPlayer.stream_paused = false
			$MusicPlayer.play()
			current_song = name
		else:
			if not songfile in missing_files:
				debug.print("MUSIC FILE FAILED TO LOAD:",name,songfile)
				missing_files.append(songfile)
	else:
		if not name in missing_files:
			debug.print("MUSIC FILE MISSING:",name)
			missing_files.append(name)

func find_music_file(name):
	var file_check = File.new()
	for dir in settings.music_dirs:
		var file_name = 'res://' + dir + '/' + name + settings.music_ext
		if file_check.file_exists(file_name) or file_check.file_exists(file_name+".import"):
			return file_name
	return false

func music_playing(song):
	if $MusicPlayer.is_playing() and current_song == song:
		return true
	return false

func stop_music():
	$MusicPlayer.stop()
	current_song = false

func stop_and_reset_music():
	stop_music()
	set_music_volume(settings.music_volume)

func play_sound(name, volume=1.0, origin=false, listener=false, allow_multiple=true):
	if dev.silence: return
	var file_name = sound_file(name)
	if file_name:
		# stop already playing sounds of this
		stop_sound(file_name)
		# play the sound
		if origin and listener:
			var distance = listener.distance_to(origin)
			# todo: cleanup w/settings
			var distance_multi = distance/80
			if distance_multi < 1: distance_multi = 1
			volume /= distance_multi
			if distance > 300:
				return
		return queue_sound(file_name, volume, allow_multiple)
	else:
		if not name in missing_files:
			debug.print("SOUND FILE MISSING:",name)
			missing_files.append(name)

func play_once(name, volume=1.0):
	return play_sound(name, volume, false, false, true)

func play_random_sound(name, total, volume=1.0, origin=false, listener=false):
	if dev.silence: return
	var c = math.random_int(1,total)
	return play_sound(name + str(c), volume, origin, listener)

func play_sound_pitched(name, pitch_start=0.8, pitch_end=1.2):
	var player = play_sound(name)
	if player:
		player.pitch_scale = math.random_float(pitch_start, pitch_end)

func play_ambience_sound(name, total=1, origin=false, listener=false, time=0.33, random=true):
	if dev.silence: return
	if not name in ambience_timers:
		var timer = Timer.new()
		timer.one_shot = true
		timer.autostart = false
		$Timers.add_child(timer)
		ambience_timers[name] = timer
	var timer = ambience_timers[name]
	if timer.is_stopped():
		if total == 1:
			play_sound(name, 1.0, origin, listener)
		else:
			play_random_sound(name, total, 1.0, origin, listener)
		if random:
			time = math.random_float(time/2,time+time/2)
		timer.start(time)

func queue_sound(file_name, volume=1.0, allow_multiple=true):
	if dev.silence: return
	var player = false
	if not allow_multiple:
		for check in $SoundPlayers.get_children():
			if check.playing and check.name == file_name:
				return
	for test in $SoundPlayers.get_children():
		if not test.playing:
			player = test
			break
	if not player:
		player = $SoundPlayers/SoundPlayer1
	var stream = load(file_name)
	if stream:
		player.volume_db = convert_percent_to_db(volume*settings.sound_volume)
		player.set_stream(stream)
		player.stream_paused = false
		player.play()
		player.pitch_scale = 1.0
		history[player.name] = file_name
		return player

func stop_sound(name):
	var file_name = sound_file(name)
	for player in $SoundPlayers.get_children():
		if player.playing:
			if player.name in history:
				if history[player.name] == file_name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					#player.set_stream(null)
					history.erase(player.name)
				elif history[player.name] == name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					#player.set_stream(null)
					history.erase(player.name)
				elif player.name == name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					#player.set_stream(null)
					history.erase(player.name)
	for player in $SoundLoopers.get_children():
		if player.playing:
			if player.name in history:
				if history[player.name] == file_name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					player.set_stream(null)
					history.erase(player.name)
				elif history[player.name] == name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					player.set_stream(null)
					history.erase(player.name)
				elif player.name == name:
					player.stream_paused = true
					player.stop()
					player.playing = false
					player.set_stream(null)
					history.erase(player.name)

func sound_file(name):
	if util.file_exists(name):
		return name
	if name in file_locations:
		return file_locations[name]
	var file_name = find_sound_file(name)
	if file_name:
		file_locations[name] = file_name
		return file_name
	if name in settings.sound_alias:
		var alias_name = settings.sound_alias[name]
		if alias_name:
			var file_name2 = find_sound_file(alias_name)
			if file_name2:
				file_locations[name] = file_name2
			return file_name2
	return false

func find_sound_file(name):
	var file_check = File.new()
	for dir in settings.sound_dirs:
		var file_name = 'res://' + dir + '/' + name + settings.sound_ext
		if file_check.file_exists(file_name) or file_check.file_exists(file_name+".import"):
			return file_name
	return false

func loop_sound(name, volume=1.0):
	if dev.silence: return
	var file_name = sound_file(name)
	if file_name:
		# stop already playing sounds of this
		stop_sound(file_name)
		var player = false
		for test in $SoundLoopers.get_children():
			if not test.playing:
				player = test
				break
		if not player:
			player = $SoundLoopers/SoundLooper1
		var stream = load(file_name)
		if stream:
			player.volume_db = convert_percent_to_db(volume*settings.sound_volume)
			player.set_stream(stream)
			player.stream_paused = false
			player.play()
			player.connect("finished", self, "on_loop_sound", [player])
			history[player.name] = file_name

func convert_percent_to_db(amount):
	return 12.5 * log(amount)

func set_sound_volume(amount):
	var db = convert_percent_to_db(amount)
	#var db = linear2db(amount)
	for player in $SoundPlayers.get_children():
		player.volume_db = db
		#player.volume_db = (1.0-amount) * -80.0
	for player in $SoundLoopers.get_children():
		player.volume_db = db
		#player.volume_db = (1.0-amount) * -80.0

func set_music_volume(amount):
	var db = convert_percent_to_db(amount)
	$MusicPlayer.volume_db = db
	emit_signal("music_volume_changed", db)
	#$MusicPlayer.volume_db = (1.0-amount) * -80.0

func fade_in_music(name, time, ease_method=Tween.EASE_IN):
	set_music_volume(0)
	play_music(name, false)
	if $MusicFadeIn.is_active():
		$MusicFadeIn.stop_all()
	var db = convert_percent_to_db(settings.music_volume)
	$MusicFadeIn.interpolate_property($MusicPlayer, "volume_db", -80, db, time, Tween.TRANS_SINE, ease_method, 0)
	$MusicFadeIn.start()

func fade_out_music(time=1.0, ease_method=Tween.EASE_IN):
	if $MusicPlayer.playing:
		if not $MusicFadeOut.is_active():
			$MusicFadeOut.interpolate_property($MusicPlayer, "volume_db", 0, -80, time, Tween.TRANS_SINE, ease_method, 0)
			#broken: $MusicFadeOut.interpolate_property($MusicPlayer, "volume_db", $MusicPlayer.volume_db, convert_percent_to_db(0), time, Tween.TRANS_SINE, ease_method, 0)
			$MusicFadeOut.connect("tween_all_completed", self, "stop_and_reset_music")
			$MusicFadeOut.start()

func button_sounds(button, hover_sound, press_sound):
	button.connect("mouse_entered", self, "play_sound", [hover_sound])
	button.connect("pressed", self, "play_sound", [press_sound])

func button_hover_sounds(button, focus_sound, unfocus_sound=false):
	button.connect("mouse_entered", self, "play_sound", [focus_sound])
	#button.connect("focus_entered", self, "play_sound", [focus_sound])
	if unfocus_sound:
		button.connect("mouse_exited", self, "play_sound", [unfocus_sound])
		#button.connect("focus_exited", self, "play_sound", [unfocus_sound])

func calm_button_hover_sounds(button, focus_sound, unfocus_sound=false):
	button.connect("on_hover_state", self, "play_sound", [focus_sound])
	if unfocus_sound:
		button.connect("on_normal_state", self, "play_sound", [unfocus_sound])

func delayed_sound(name, time, volume=1.0):
	if dev.silence: return
	# todo: more timers
	if $Timers/DelayedTimer1.is_connected("timeout", self, "play_sound"):
		$Timers/DelayedTimer1.disconnect("timeout", self, "play_sound")
	$Timers/DelayedTimer1.connect("timeout", self, "play_sound", [name, volume])
	$Timers/DelayedTimer1.wait_time = time
	$Timers/DelayedTimer1.start()

func on_loop_sound(player):
	player.stream_paused = false
	player.play()

func stop_all_sounds():
	for sound in $SoundPlayers.get_children():
		sound.stop()
		sound.playing = false
	for looper in $SoundLoopers.get_children():
		if not dev.silence:
			looper.disconnect("finished", self, "on_loop_sound")
		looper.stop()
		looper.playing = false
	history = {}

# plays a sound if not already playing
# todo: add within last time played
func play_sound_if_not(name, volume=1.0):
	play_sound(name, volume, false, false, false)
