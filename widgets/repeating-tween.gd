extends Tween
class_name RepeatingTween

func _ready():
	connect("tween_completed", self, "on_tween_completed")

func on_tween_completed():
	start()
