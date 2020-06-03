extends Node2D

func _ready():
	$Character.nav = $Navigation2D

func _input(event):
	if event.is_action_pressed("left_mouse_button"):
		$Character.SetGoal(.get_global_mouse_position())
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()
