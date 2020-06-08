extends Node2D

func _input(event):
	if event.is_action_pressed("left_mouse_button"):
		$Character.SetMovementValues(300.0, 100.0, 8.0)
		$Character.SetGoal(.get_global_mouse_position())
	elif event.is_action_pressed("right_mouse_button"):
		$Character.SetMovementValues(300.0, 200.0, 8.0)
		$Character.SetGoal(.get_global_mouse_position())
	elif event.is_action_pressed("middle_mouse_button"):
		$Character.SetMovementValues(300.0, 50.0, 8.0)
		$Character.SetGoal(.get_global_mouse_position())
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()
