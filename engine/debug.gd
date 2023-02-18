extends Node

### DEBUG MODULE

# Try calling debug.print() instead of print() in your game
# - debug.print(...) can save to a log file and send back to an in-game widget

# echo to console (print)
var echo: bool = true
# log file
var log_file_name = false
# hook to print to your own widget
var callback_object: WeakRef = null
var print_callback = false
# debug.cat
var categories := {}
var echo_all_categories := false

func _ready():
	if OS.is_debug_build():
		echo = true
	else:
		echo = false

# call this from another object such as your game object
# - this way you can control if logs are created or not since debug is first autoload
func open_log():
	var logs_subdir = "logs"
	var dir = "user://" + logs_subdir
	var directory = Directory.new()
	if not directory.file_exists(dir):
		directory.open("user://")
		directory.make_dir(logs_subdir)

	var project_name = ProjectSettings.get_setting('application/config/name')
	var count = 1
	var file = project_name + "-Gameplay-%04d.txt" % count
	var file_dir = dir + '/' + file
	var fileTool = File.new()
	while(fileTool.file_exists(file_dir)):
		count = count + 1
		file = project_name + "-Gameplay-%04d.txt" % count
		file_dir = dir + '/' + file
	# final log file name
	log_file_name = file_dir
	print('Log Location: ', OS.get_user_data_dir())
	print('Debug log: ', log_file_name)
	var log_file = File.new()
	if log_file.open(log_file_name, File.WRITE) == 0:
		log_file.store_line("Log started: "+log_file_name)
		log_file.close()
	else:
		print('ERROR: Cannot open log for writing!')
		log_file_name = false

func print(s1, s2='',s3='',s4='',s5='',s6='',s7='',s8='',s9='',s10='',s11='',s12='',s13='',s14=''):
	if echo or log_file_name:
		var s = convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
		if echo:
			print(s)
		if log_file_name:
			append_log(s)
		if print_callback and callback_object.get_ref():
			callback_object.get_ref().call(print_callback, s)

# Give an object and method, for example ->
#   MyGameConsole.print_to_console(line: String)
#    calls ->
#   debug.print(MyGameConsole, "print_to_console")
func set_callback(object: Object, method: String):
	callback_object = weakref(object)
	print_callback = method

# print a dictionary
func dict(d, title=false):
	if title:
		print('Dict: '+title)
	for key in d:
		var value = d[key]
		print(str(key)+' = '+str(value))

# print an array
func array(a, title=false):
	if title:
		print('Array: '+title)
	if a is Array:
		var count = 0
		for value in a:
			print(str(count)+' = '+str(value))
	elif a is Dictionary:
		dict(a)

# ignore; used by debug,print()
static func convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14):
	var s = str(s1)
	var c = ' '
	if s2 != null: s+=c+str(s2); else: return s
	if s3 != null: s+=c+str(s3); else: return s
	if s4 != null: s+=c+str(s4); else: return s
	if s5 != null: s+=c+str(s5); else: return s
	if s6 != null: s+=c+str(s6); else: return s
	if s7 != null: s+=c+str(s7); else: return s
	if s8 != null: s+=c+str(s8); else: return s
	if s9 != null: s+=c+str(s9); else: return s
	if s10 != null: s+=c+str(s10); else: return s
	if s11 != null: s+=c+str(s11); else: return s
	if s12 != null: s+=c+str(s12); else: return s
	if s13 != null: s+=c+str(s13); else: return s
	if s14 != null: s+=c+str(s14); else: return s
	return s

# same as print(), but forced to print
func error(s1, s2='',s3='',s4='',s5='',s6='',s7='',s8='',s9='',s10='',s11='',s12='',s13='',s14=''):
	var s = convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
	print(s)
	append_log(s)

# debug printing by "category"
# any categories enabled will be printed to console
#  but all will still be recorded to log
func cat(cat, s1, s2='',s3='',s4='',s5='',s6='',s7='',s8='',s9='',s10='',s11='',s12='',s13='',s14=''):
	if echo:
		if echo_all_categories or cat in categories:
			var s = cat+': '+convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
			print(s)
	if log_file_name:
		var s = cat+': '+convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
		append_log(s)

# add mode to keep log file open isntead of opening/closing each line?
func append_log(s):
	if log_file_name:
		var log_file = File.new()
		if log_file.open(log_file_name, File.READ_WRITE) == 0:
			log_file.seek_end()
			log_file.store_line(s)
			log_file.close()
		else:
			print('ERROR: Cannot write to log file! Aborting log.')
			log_file_name = false

# built-in console (not very good)
func console(s1, s2='',s3='',s4='',s5='',s6='',s7='',s8='',s9='',s10='',s11='',s12='',s13='',s14=''):
	var s = convert_string(s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14)
	print(s)
	root.add_debug_line(s)

func print_instance(id):
	var object = instance_from_id(id)
	if object:
		print_object(object)

func print_object(object):
	var property_list = object.get_property_list()
	for prop in property_list:
		debug.print (prop.name, object.get(prop.name))

func var_dump(variable):
	debug.print(to_json(variable))
