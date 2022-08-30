extends Camera2D
class_name FeatureCamera2D

var target: Node2D

var max_offset = Vector2(10, 5)  # Maximum hor/ver shake in pixels.
var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var quake_decay = 0.8  # How quickly the shaking stops [0, 1].
var quake = 0.0  # Current shake strength.
var quake_power = 2  # quake exponent. Use [2, 3].
onready var noise = OpenSimplexNoise.new()
var noise_y = 0

var shoot_shake = 0.0
var shoot_shake_decay = 2.0
var shoot_shake_power = 2

export var target_ahead = true
export var target_ahead_pixels = 90
export var target_behind_pixels = 0
export var target_buffer_behind = -20
export var target_ahead_factor = 1
export var target_behind_factor = 1
var target_offset = Vector2(target_ahead_pixels,0)
var target_point = Vector2.ZERO

export var look_ahead = false
export var look_ahead_factor = 0.2
const look_ahead_trans = Tween.TRANS_SINE
const look_ahead_ease = Tween.EASE_OUT
const look_ahead_time = 1.5

onready var last_camera_position = get_camera_position()
var last_camera_direction_x = 0

func _ready():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2
	$PunchTimer.connect("timeout", self, "after_punch")
	#$TargetAheadTimer.connect("timeout", self, "target_ahead_buffer")

func _physics_process(delta):
	if target:
		if target_ahead:
			target_ahead_camera()
		else:
			global_position = target.global_position
	elif look_ahead:
		look_ahead_camera()
	if quake:
		if quake > 0:
			quake = max(quake - quake_decay * delta, 0)
			do_shake(quake, quake_power)
	if shoot_shake:
		if shoot_shake > 0:
			shoot_shake = max(shoot_shake - shoot_shake_decay * delta, 0)
			do_shake(shoot_shake, shoot_shake_power)
	last_camera_position = get_camera_position()
		
func do_shake(_shake, _shake_power):
	var amount = pow(_shake, _shake_power)
	noise_y += 1
	# Using noise
	rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed*2, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed*3, noise_y)
	if offset.y > 0:
		offset.y = 0
	# Pure randomness
#	rotation = max_roll * amount * rand_range(-1, 1)
#	offset.x = max_offset.x * amount * rand_range(-1, 1)
#	offset.y = max_offset.y * amount * rand_range(-1, 1)
	
func shake(amount):
	quake = min(quake + amount, 1.0)
	
func shoot_shake(direction):
	shoot_shake = 1
	 
func zoom_punch(wait=0.25, zoom_factor=0.5):
	zoom_to(zoom_factor)
	$PunchTimer.wait_time = wait
	$PunchTimer.start()
	
func after_punch():
	#zoom_normal()
	var tween = $PunchTween
	tween.interpolate_property(self, "zoom", 
	  null, Vector2(1.0,1.0), 0.22, 
	  Tween.TRANS_SINE, Tween.EASE_IN)
	tween.start()
	target = game.chip
	#tween.connect("tween_completed", self, "expire")

func zoom_normal():
	zoom.x = 1.0
	zoom.y = 1.0

func zoom_to(target):
	zoom.x = target
	zoom.y = target

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
		limit_top = -640*(zoom.y-1.0)
	else:
		limit_top = 0
	if target:
		global_position = target.global_position
		
func look_ahead_camera():
	var new_direction_x = sign(get_camera_position().x - last_camera_position.x)
	if new_direction_x != 0 and new_direction_x != last_camera_direction_x:
		last_camera_direction_x = new_direction_x
		var look_offset_x = get_viewport_rect().size.x * look_ahead_factor * new_direction_x
		var tween = $LookTween
		tween.interpolate_property(self,
			"position:x", offset.x, look_offset_x, 
			look_ahead_time, look_ahead_trans, look_ahead_ease)
		tween.start()

func target_ahead_camera_old():
	var target_pos = target.global_position
	var new_direction_x = sign(target.direction.x)
	if new_direction_x == 0:
		new_direction_x = last_camera_direction_x
	target_pos.x += new_direction_x * target_ahead_pixels
	var tween = $LookTween
	if new_direction_x != 0 and new_direction_x != last_camera_direction_x:
		tween.interpolate_property(self,
			"global_position:x", null, target_pos.x, 
			look_ahead_time, look_ahead_trans, look_ahead_ease)
		tween.start()
	else:
		if abs(game.chip.velocity.x) > 0.1:
			global_position = target_pos
		else:
			tween.interpolate_property(self,
				"global_position", null, target_pos, 
				look_ahead_time*0.5, look_ahead_trans, look_ahead_ease)
			tween.start()
	last_camera_direction_x = new_direction_x
		
func target_ahead_camera():
	var new_direction_x = sign(target.direction.x)
	if new_direction_x == 0:
		new_direction_x = last_camera_direction_x
	
	if new_direction_x != last_camera_direction_x:
		$TargetAheadTimer.start()

	var end_reached = false
		
	if $TargetAheadTimer.is_stopped():

		if abs(target.velocity.x) > 0:
			if new_direction_x > 0:
				target_point.x += target_ahead_factor
				if target_point.x > target_ahead_pixels:
					target_point.x = target_ahead_pixels
					end_reached = true
			elif new_direction_x < 0:
				target_point.x -= target_behind_factor
				if target_point.x < -target_behind_pixels:
					target_point.x = -target_behind_pixels
					end_reached = true
	
	var tween = $LookTween
	tween.interpolate_property(self,
		"global_position", null, target.global_position + target_point, 
		0.2, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()

	#global_position = target.global_position + target_point
	
	last_camera_direction_x = new_direction_x
	
func npc_punch(_target=null, wait=0.25, zoom_factor=0.5):
	# todo: multitarget cam
	if _target:
		target = _target
		zoom_to(zoom_factor)
		$PunchTimer.wait_time = wait
		$PunchTimer.start()
