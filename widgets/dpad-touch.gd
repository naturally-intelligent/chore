extends TouchScreenButton

var outer_boundary = 128
var inner_boundary = 8
var touch_idx = -1
var direction = Vector2.RIGHT
var active = false
var instant_direction = false
var instant_threshold = 1
var last_position = Vector2.ZERO

var up = false
var down = false
var left = false
var right = false

var last_degrees = -1
var wiggle = 23

func _process(_delta):
	if active:
		press_events()
	
func _input(event):
	
	if event is InputEventScreenTouch \
	and event.get_index() == touch_idx \
	and !event.is_pressed():
		active = false
		touch_idx = -1
		reset_dpad()
		release_events()
		return

	if event is InputEventScreenDrag \
	or (event is InputEventScreenTouch and event.is_pressed()):
		
		var valid_touch = false
		var new_touch = false
		
		if touch_idx == -1:
			touch_idx = event.get_index()
			new_touch = true
			valid_touch = true
		elif touch_idx == event.get_index():
			valid_touch = true

		if valid_touch:
			var new_position = event.position
			var vector = new_position - $Sprite.global_position
			var distance = vector.length()
			var dpad_normal = vector.normalized()
			if new_touch:
				last_position = event.position
			if new_touch and distance > outer_boundary:
				valid_touch = false
				touch_idx = -1
				return
			if not new_touch and instant_direction:
				var instant_vector = new_position - last_position
				var instant_distance = instant_vector.length()
				if instant_distance > instant_threshold:
					direction = instant_vector.normalized()
					active = true
					update_dpad(direction)
			elif distance > inner_boundary and distance <= outer_boundary:
				active = true
				direction = dpad_normal
				update_dpad(direction)						
			else:
				active = false
				release_events()
				reset_dpad()				
			#print(active, ' ',touch_idx)
			last_position = new_position


func reset_dpad():
	$Sprite.frame = 4
	last_degrees = -1
	
func update_dpad(vector):
	var deg360 = math.normal_to_360_degrees(vector)
	var degrees = math.normal_to_45(vector)
	#print(degrees, ' ', deg360)
	if last_degrees == degrees:
		return
	if degrees == 0 or (deg360 <= 0+wiggle and deg360 >= 0-wiggle):
		$Sprite.frame = 3
		right = true
		release_left()
		release_up()
		release_down()
	elif degrees == 180 or (deg360 <= 180+wiggle and deg360 >= 180-wiggle):
		$Sprite.frame = 5
		left = true
		release_down()
		release_right()
		release_up()
	elif degrees == 90 or (deg360 <= 90+wiggle and deg360 >= 90-wiggle):
		$Sprite.frame = 7
		down = true
		release_right()
		release_left()
		release_up()
	elif degrees == 45:
		$Sprite.frame = 8
		right = true
		down = true
		release_left()
		release_up()
	elif degrees == 135:
		$Sprite.frame = 6
		down = true
		left = true
		release_right()
		release_up()
	elif degrees == 225:
		$Sprite.frame = 0
		left = true
		up = true
		release_right()
		release_down()
	elif degrees == 270:
		$Sprite.frame = 1
		up = true
		release_left()
		release_right()
		release_down()
	elif degrees == 315:
		$Sprite.frame = 2
		up = true
		right = true
		release_left()
		release_down()
	last_degrees = degrees

func press_events():
	if up: Input.action_press("ui_up")
	if left: Input.action_press("ui_left")
	if right: Input.action_press("ui_right")
	if down: Input.action_press("ui_down")
		
func release_left():
	if left:
		Input.action_release("ui_left")
		left = false

func release_right():
	if right:
		Input.action_release("ui_right")
		right = false

func release_up():
	if up:
		Input.action_release("ui_up")
		up = false
		
func release_down():
	if down:
		Input.action_release("ui_down")
		down = false
	
func release_events():
	release_left()
	release_right()
	release_up()
	release_down()
