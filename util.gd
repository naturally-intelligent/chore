tool
extends Node

# UTILITY FUNCTIONS AND JUNK LIKE THAT
var desktop := true
var mobile := false
# specific os
var android := false
var apple := false
var windows := false
var linux := false
var osx := false
var web := false
# input
var mouse := false
var keyboard := false
var joystick := false
var touch := false

func _ready():
	platform_detection()
	input_detection()

func platform_detection():
	var name = OS.get_name()
	match name:
		'Android':
			mobile = true
			android = true
		'iOS':
			mobile = true
			apple = true
		'OSX':
			apple = true
		'Windows','WinRT':
			windows = true
		'X11','Haiku':
			linux = true
		'HTML5','Flash':
			web = true
		'BlackBerry 10':
			mobile = true
	# default desktop is true
	if mobile:
		desktop = false

func input_detection():
	if OS.has_touchscreen_ui_hint():
		touch = true
	touch = false

# SORT CLASSES
class FirstElementGreatest:
	static func sort(a, b):
		if a[0] > b[0]:
			return true
		return false

class FirstElementLeast:
	static func sort(a, b):
		if a[0] < b[0]:
			return true
		return false

# HELPER FUNCTIONS
#  these are all static, meaning they arent part of the 'util' object
#  but still called like -> util.fullscreen_flip()

static func fullscreen_flip():
	if OS.is_window_fullscreen():
		OS.set_window_fullscreen(false)
	else:
		OS.set_window_fullscreen(true)

static func random(s, e):
	if typeof(s) == TYPE_INT:
		var div = e-s+1
		if div == 0: return s
		return s + randi()%div
	else:
		return s + randf()*(e-s)+s

static func random_boolean():
	return ((randi()%2) == 0)

static func randomi(s, e):
	var div = e-s+1
	if div == 0: return s
	return s + randi()%div

static func randomf(s, e):
	return s + randf()*(e-s)+s

static func random_array(a):
	if a.size() > 0:
		var i = util.randomi(0,a.size()-1)
		return a[i]
	return null

static func random_array_index(a):
	if a.size() > 0:
		var i = util.randomi(0,a.size()-1)
		return i
	return null

static func random_set(s):
	return random_array(s)
	
static func random_key(dict):
	var keys = dict.keys()
	if keys.size() > 0:
		var i = randi() % keys.size()
		var key = keys[i]
		return key
	else:
		return null

static func random_value(dict):
	var key = random_key(dict)
	if key: return dict[key]
	return false

static func random_integer_key(dict):
	var keysT = dict.keys()
	var keys = Array()
	for key in keysT:
		if typeof(key) == TYPE_INT:
			keys.append(key)
	if keys.size() > 0:
		var i = randi() % keys.size()
		var key = keys[i]
		return key
	else:
		return null

static func random_vector():
	var angle = util.randomf(0,PI)
	return Vector2(cos(angle), sin(angle))

static func random_left_right_up_vector(left_right_scale=1.0, up_scale=1.0):
	var angle = util.randomf(Vector2.LEFT.angle(),Vector2.RIGHT.angle())
	var v = Vector2(cos(angle), sin(angle))
	v.x *= left_right_scale
	v.y *= up_scale
	return v.normalized()

# dict is {} you want key from, exclude is array [] with keys you dont want again
static func random_key_excluding(dict, exclude):
	var keysT = dict.keys()
	var keys = Array()
	for key in keysT:
		if not exclude.has(key):
			keys.append(key)
	if keys.size() > 0:
		var i = randi() % keys.size()
		var key = keys[i]
		return key
	else:
		return null

static func random_value_excluding(dict, exclude=[]):
	var keysT = dict.keys()
	var keys = Array()
	for key in keysT:
		if not exclude.has(dict[key]):
			keys.append(key)
	if keys.size() > 0:
		var i = randi() % keys.size()
		var key = keys[i]
		return dict[key]
	else:
		return null

static func random_array_excluding(array, exclude):
	var pool = Array()
	for a in array:
		if not a in exclude:
			pool.append(a)
	if pool.size() > 0:
		var i = randi() % pool.size()
		var v = pool[i]
		return v
	else:
		return null

static func random_sign():
	if random_boolean():
		return 1
	else:
		return -1

static func random_position(minx,maxx, miny,maxy):
	return Vector2(util.randomi(minx,maxx),util.randomi(miny,maxy))

static func random_color(modifier):
	return Color(util.randomf(0,1)*modifier, 
				 util.randomf(0,1)*modifier, 
				 util.randomf(0,1)*modifier, 1)

static func randomize_color(color, modifier):
	color.r += util.randomf(-modifier/2.0, modifier/2.0) 
	color.r = clamp(color.r, 0, 1)
	color.g += util.randomf(-modifier/2.0, modifier/2.0) 
	color.g = clamp(color.g, 0, 1)
	color.b += util.randomf(-modifier/2.0, modifier/2.0) 
	color.b = clamp(color.b, 0, 1)
	return color

static func random_colors(one,two):
	return Color(util.randomf(one.r,two.r), util.randomf(one.g,two.g), util.randomf(one.b,two.b), 1)

static func rgb100_to_color(r,g,b):
	return Color(r/100.0, g/100.0, b/100.0, 1)

static func rgb256_to_color(r,g,b):
	return Color(r/256.0, g/256.0, b/256.0, 1)

static func thousands_sep(number, prefix=''):
	number = int(number)
	var neg = false
	if number < 0:
		number = -number
		neg = true
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	if neg: res = '-'+prefix+res
	else: res = prefix+res
	return res

static func file_exists(file):
	return File.new().file_exists(file)

static func int_to_currency(i, pennies=false):
	var cash_text = util.thousands_sep(str(i), '$')
	if pennies:	cash_text += '.00'
	return cash_text

static func trim_decimals(f, places):
	return stepify(f, pow(0.1,places))

static func string_upper_first(id):
	return id.substr(0,1).to_upper() + id.substr(1, id.length())

static func first_letter(id):
	return id.substr(0,1)

static func upper_first_letter(id):
	return id.substr(0,1).to_upper()

static func a_an(word):
	var first = word.substr(0,1).to_upper()
	var vowels = ['a','e','i','o','u']
	if first in vowels:
		return 'an'
	else:
		return 'a'

static func name_full(object):
	var full = ''
	if 'prefix' in object:
		full = object['prefix'] + ' '
	full+= object['first'] + ' '
	if 'middle' in object:
		full+= object['middle'] + ' '
	if 'last' in object:
		full+= object['last']
	object['full'] = full

static func name_fills(object):
	name_full(object)
	object['first_upper'] = object['first'].to_upper()
	if 'last' in object:
		object['last_upper'] = object['last'].to_upper()

static func first_upper(string):
	return string.capitalize()

static func calculate_total(data):
	data['total'] = 0
	for col in data:
		if col != 'total':
			var amount = data[col]
			data['total'] += amount

static func clean_string(s):
	return s.replace("\n", '').replace(" ",'')

static func replace_fake_formatting(s):
	return s.replace("\\n", "\n")
	
static func random_phone_number():
	var ph = '555-'
	ph+= str(util.random(0,9))
	ph+= str(util.random(0,9))
	ph+= str(util.random(0,9))
	ph+= str(util.random(0,9))
	return ph

# loads a texxt file, sectioned like:
# [Section]
# keys = values
# keys = array # if split_commas and comma detected
# values converted to ints/floats if convert_numbers, otherwise strings
static func load_config(filename, split_commas=true, convert_numbers=true):
	var path = filename
	var file = File.new()
	var records = {}
	var record = {}
	var title = ''
	var new_record = false
	var added_record = false
	var line_count = 0
	file.open(path, file.READ)
	if file.is_open():
		while !file.eof_reached():
			# read a line
			var line = file.get_line()
			# comments (strip edges on left?)
			if line.find('#')==0:
				pass
			# config section/record check
			elif line.find('[') + line.find(']') > 1:
				# store previous record
				if new_record and not added_record:
					records[title] = record
				# start new record
				var start = line.find('[')+1
				var end = line.find(']') - start
				title = line.substr(start, end)
				record = {}
				new_record = true
				added_record = false
				line_count = 0
			# add key=value line pairs to record
			elif line.find('=') >= 0:
				var data = line.split('=')
				if len(data) == 2:
					var key = data[0].strip_edges(true, true)
					var value = data[1].strip_edges(true, true)
					if split_commas:
						if value.find(',') >= 0:
							var a = value.split(',')
							var d = {}
							for i in range(0,a.size()): 
								var sub_value = a[i].strip_edges(true, true)
								if convert_numbers: sub_value = util.convert_string_to_number(sub_value)
								d[i] = sub_value
							record[key] = d
						else:
							if convert_numbers: value = util.convert_string_to_number(value)
							record[key] = value
					else:
						record[key] = value
			# add non-empty, non-whitespace lines as integer indexes (starting at 1)
			elif line.strip_edges(true, true).length()>0:
				line_count = line_count + 1
				while(line_count in record): line_count = line_count + 1
				record[line_count] = line
		# store lingering record
		if new_record and not added_record:
			records[title] = record
	else:
		debug.print('ERROR: File missing: ', filename)
	return records

# tries to convert a string to a number, if possible
static func convert_string_to_number(value):
	if value.is_valid_integer():
		return value.to_int()
	if value.is_valid_float():
		return value.to_float()
	return value

static func set_texture(sprite, file):
	if util.file_exists(file):
		var tex = load(file)
		sprite.texture = tex
	else:
		debug.print('MISSING TEXTURE: ' + file)

static func number2words(n):
	var num2words = {1: 'One', 2: 'Two', 3: 'Three', 4: 'Four', 5: 'Five', \
				 6: 'Six', 7: 'Seven', 8: 'Eight', 9: 'Nine', 10: 'Ten', \
				11: 'Eleven', 12: 'Twelve', 13: 'Thirteen', 14: 'Fourteen', \
				15: 'Fifteen', 16: 'Sixteen', 17: 'Seventeen', 18: 'Eighteen', \
				19: 'Nineteen', 20: 'Twenty', 30: 'Thirty', 40: 'Forty', \
				50: 'Fifty', 60: 'Sixty', 70: 'Seventy', 80: 'Eighty', \
				90: 'Ninety', 0: 'Zero'}
	if n in num2words:
		return num2words[n]
	else:
		return num2words[n-n%10] + num2words[n%10].to_lower()

static func number2past(n):
	var num2words = {1: 'Once', 2: 'Twice', 3: 'Thrice'}
	if n in num2words:
		return num2words[n]
	else:
		return number2words(n) + ' times'

static func number2present(i):
	var n = str(i)
	var num2present = {0: 'Zeroeth', 1: 'First', 2: 'Second', 3: 'Third', \
		4: 'Fourth', 5: 'Fifth', 6: 'Sixth', 7: 'Seventh', 8: 'Eighth', \
		9: 'Ninth', 10: 'Tenth', 11: 'Eleventh', 12: 'Twelvth', \
		13: 'Thirteenth', 14: 'Fourteenth', 15: 'Fifteenth'}
	if i in num2present:
		return num2present[i]
	else:
		var last = n.substr(n.length()-1, 1)
		if last == '1':
			return number2words(i) + 'st'
		elif last == '2':
			return number2words(i) + 'nd'
		elif last == '3':
			return number2words(i) + 'rd'
		return number2words(i) + 'th'

static func next_in_list(current, list : Array):
	var index = list.find(current, 0)
	if index >= 0:
		index = index + 1
		if index >= list.size():
			index = 0
		return list[index]
	return current

static func prev_in_list(current, list : Array):
	var index = list.find(current, 0)
	if index >= 0:
		index = index - 1
		if index < 0:
			index = list.size()-1
		return list[index]
	return current

# must call yield on t after return
# because gdscript wont wait for a yield in an outside function call
static func wait(time, parent=null):
	var t = Timer.new()
	t.set_wait_time(time)
	t.set_one_shot(true)
	if parent: parent.add_child(t)
	t.start()
	#yield(t, "timeout") # must call this outside of function!
	return t

# https://github.com/godotengine/godot/issues/14562	
static func create_import_files_for_export(texture_dir):
	var file_list = list_files_in_directory(texture_dir)
	for file in file_list:
		if file.ends_with(".import"):
			var file_name = file.replace(".import", "")
			load(texture_dir + file_name)

static func screenshot(scene, scale=false):
	debug.print('Screenshot...')
	scene.get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	# Let two frames pass to make sure the screen was captured
	yield(scene.get_tree(), "idle_frame")
	yield(scene.get_tree(), "idle_frame")

	# Retrieve the captured image
	var img = scene.get_viewport().get_texture().get_data()
	#print(img.get_class())
	# scale after (note, doesn't upscale pixel-art nicely)
	if scale:
		img.resize(scale.x, scale.y, Image.INTERPOLATE_NEAREST)
  
	# Flip it on the y-axis (because it's flipped)
	img.flip_y()

	# Linux: ~/.local/share/godot/app_userdata/Lemkin
	var screens_subdir = "screenshots"
	var dir = "user://" + screens_subdir
	var directory = Directory.new()
	if not directory.file_exists(dir):
		directory.open("user://")
		directory.make_dir(screens_subdir)

	var project_name = ProjectSettings.get_setting('application/config/name').replace(' ','')
	var count = 1
	var file = project_name + "-%03d.png" % count
	var file_dir = dir + '/' + file
	var fileTool = File.new()
	while(fileTool.file_exists(file_dir)):
		count = count + 1
		file = project_name + "-%03d.png" % count
		file_dir = dir + '/' + file
	debug.print('Saving: '+file+'...')
	img.save_png(file_dir)
	
	print('Save Location: ', OS.get_user_data_dir())
	
	return file

# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
static func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files

static func strip_bbcode(text):
	var regex = RegEx.new()
	regex.compile('|[[\\/\\!]*?[^\\[\\]]*?]|')
	return regex.sub(text, '', true)
	
static func open_browser(www_url):
	return OS.shell_open(www_url)
	
static func delete_children(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()	

static func opposite_direction(direction: String) -> String:
	if direction == 'up':
		return 'down'
	if direction == 'down':
		return 'up'
	if direction == 'left':
		return 'right'
	if direction == 'right':
		return 'left'
	return 'none'

# STRING CONVENIENCE

static func s(i: int) -> String:
	if i == 1:
		return ''
	return 's'

static func unlimited(i: int) -> String:
	if i == -1:
		return 'Unlimited'
	return str(i)

static func a_or_number(i: int) -> String:
	if i == 1:
		return 'a'
	return str(i)

static func signed_number(i: int) -> String:
	if i < 0:
		return str(i)
	elif i > 0:
		return '+'+str(i)
	return str(i)
