extends Camera2D
class_name FeatureCamera2D

# target
export (NodePath) var target_node
var target_ref: WeakRef
var target: Node2D setget set_target

# targeting behavior
export var target_ahead := true
export var target_ahead_pixels := 90
export var target_behind_pixels := 0
export var target_ahead_factor := 1
export var target_behind_factor := 1
export var target_ahead_vector := Vector2.ZERO
var target_point := Vector2.ZERO
var last_camera_direction_x := 0
#var last_camera_direction := Vector2.ZERO

# earthquake
onready var noise := OpenSimplexNoise.new()
var quake_decay := 0.8  # How quickly the shaking stops [0, 1].
var quake := 0.0  # Current shake strength.
var quake_power := 2  # quake exponent. Use [2, 3].
var quake_noise := 0
var max_shake_offset := Vector2(10, 5)  # Maximum hor/ver shake in pixels.
var max_shake_roll := 0.1  # Maximum rotation in radians (use sparingly).

# shake due to shooting
var shoot_shake := 0.0
var shoot_shake_decay := 2.0
var shoot_shake_power := 2

# camera trigger areas - parent container of CameraTrigger objects
export (NodePath) var camera_trigger_areas = null
var trigger_areas: Control = null
var last_trigger_area := ''

# maintenance
onready var last_camera_position: Vector2 = get_camera_position()
var initial_camera_left_limit := 0
var initial_camera_right_limit := 0

func _ready():
	# random noise
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2
	# timers
	$DramaticTimer.connect("timeout", self, "after_drama")
	# limits
	init_limits()
	if camera_trigger_areas:
		trigger_areas = get_node(camera_trigger_areas)
		trigger_areas.visible = false
	# target
	if target_node:
		target = get_node(target_node)

# PROCESS
func _process(delta):
	# target valid?
	if not target_ref or not target_ref.get_ref():
		target_ref = null
		target = null
	# trigger areas
	if trigger_areas and target:
		for trigger_area in trigger_areas.get_children():
			if trigger_area.check_trigger(target.global_position):
				if trigger_area.name != last_trigger_area:
					#debug.print('Inside', trigger_area.name)
					# tween
					var tween = $LimitsTween
					var time = 0.5
					var trans_type = Tween.TRANS_CUBIC
					var ease_type = Tween.EASE_IN_OUT
					tween.stop_all()
					tween.remove_all()
					# y limits
					if trigger_area.new_y_limits:
						tween.interpolate_property(self, "limit_top",
							null, trigger_area.limit_y_top, time,
							trans_type, ease_type)
						tween.interpolate_property(self, "limit_bottom",
							null, trigger_area.limit_y_bottom, time,
							trans_type, ease_type)
					# x limits
					if trigger_area.new_x_limits:
						limit_left = trigger_area.limit_x_left
						limit_right = trigger_area.limit_x_right
						initial_camera_left_limit = limit_left
						initial_camera_right_limit = limit_right
					# target distance pixels
					if trigger_area.new_target_ahead:
						target_ahead_pixels = trigger_area.target_ahead_pixels
						target_behind_pixels = trigger_area.target_behind_pixels
					tween.start()
					last_trigger_area = trigger_area.name
					call_deferred("check_empty_triggers")

# MOVEMENT
func _physics_process(delta):
	if target:
		if target_ahead:
			target_ahead_camera(delta)
		else:
			global_position = target.global_position
	if quake:
		if quake > 0:
			quake = max(quake - quake_decay * delta, 0)
			do_shake(quake, quake_power)
	if shoot_shake:
		if shoot_shake > 0:
			shoot_shake = max(shoot_shake - shoot_shake_decay * delta, 0)
			do_shake(shoot_shake, shoot_shake_power)
	last_camera_position = get_camera_position()

# TARGET
func set_target(_target):
	target_ref = weakref(_target)
	target = _target

func target_ahead_camera(delta):
	var new_direction_x = sign(target.direction.x)
	if new_direction_x == 0:
		new_direction_x = last_camera_direction_x

	if new_direction_x != last_camera_direction_x:
		$TargetAheadTimer.start()

	if $TargetAheadTimer.is_stopped():
		if abs(target.velocity.x) > 0:
			if new_direction_x > 0:
				target_point.x += target_ahead_factor
				if target_point.x > target_ahead_pixels:
					target_point.x = target_ahead_pixels
			elif new_direction_x < 0:
				target_point.x -= target_behind_factor
				if target_point.x < -target_behind_pixels:
					target_point.x = -target_behind_pixels

	var tween = $TargetTween
	tween.interpolate_property(self,
		"global_position", null, target.global_position + target_point,
		0.2, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()

	last_camera_direction_x = new_direction_x

# SHAKE / QUAKE
func do_shake(_shake, _shake_power):
	var amount = pow(_shake, _shake_power)
	quake_noise += 1
	rotation = max_shake_roll * amount * noise.get_noise_2d(noise.seed, quake_noise)
	offset.x = max_shake_offset.x * amount * noise.get_noise_2d(noise.seed*2, quake_noise)
	offset.y = max_shake_offset.y * amount * noise.get_noise_2d(noise.seed*3, quake_noise)
	if offset.y > 0:
		offset.y = 0

func shake(amount):
	quake = min(quake + amount, 1.0)

func shooty_shake(_direction):
	shoot_shake = 1

# DRAMA
func zoom_drama(wait=0.25, zoom_factor=0.5):
	zoom_to(zoom_factor)
	$DramaticTimer.wait_time = wait
	$DramaticTimer.start()

func after_drama():
	#zoom_normal()
	var tween = $DramaticTween
	tween.interpolate_property(self, "zoom",
	  null, Vector2(1.0,1.0), 0.22,
	  Tween.TRANS_SINE, Tween.EASE_IN)
	tween.start()

# ZOOM
func zoom_normal():
	zoom.x = 1.0
	zoom.y = 1.0

func zoom_to(_target):
	zoom.x = _target
	zoom.y = _target

func zoom_in(amount):
	var min_zoom = 0.5
	zoom.x -= amount
	zoom.y -= amount
	if zoom.x < min_zoom:
		zoom.x = min_zoom
	if zoom.y < min_zoom:
		zoom.y = min_zoom
	if target:
		global_position = target.global_position

func zoom_out(amount):
	var max_zoom = 1.5
	zoom.x += amount
	zoom.y += amount
	if zoom.x > max_zoom:
		zoom.x = max_zoom
	if zoom.y > max_zoom:
		zoom.y = max_zoom
	if zoom.y > 1.0:
		limit_top = int(-640.0*(zoom.y-1.0))
	else:
		limit_top = 0
	if target:
		global_position = target.global_position

# LIMITS
func init_limits():
	# limits?
	if has_node('LeftLimit'):
		var node = get_node('LeftLimit')
		limit_left = node.global_position.x
	if has_node('RightLimit'):
		var node = get_node('RightLimit')
		limit_right = node.global_position.x
	initial_camera_left_limit = limit_left
	initial_camera_right_limit = limit_right

func change_camera_limits(left_x, right_x, top_y=false, bottom_y=false):
	limit_left = left_x
	limit_right = right_x
	if top_y: limit_top = top_y
	if bottom_y: limit_bottom = bottom_y

func reset_camera_limits():
	if smoothing_speed > 1:
		set_smoothing_speed_temporarily()
	limit_left = initial_camera_left_limit
	limit_right = initial_camera_right_limit

func check_empty_triggers():
	if trigger_areas and trigger_areas.get_child_count() == 0:
		trigger_areas = null

# SMOOTHING
func set_smoothing_speed_temporarily(speed=1, time=2.5):
	var old_speed = smoothing_speed
	smoothing_speed = speed
	var tween = Tween.new()
	tween.interpolate_property(self,
		'smoothing_speed', speed, old_speed, time,
		Tween.TRANS_CUBIC, Tween.EASE_IN)
	add_child(tween)
	tween.start()
	yield(tween, "tween_all_completed")
	tween.queue_free()
