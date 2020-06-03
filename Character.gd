extends KinematicBody2D

var nav
var path = []
var Goal

var Motion = Vector2(0.0, 0.0)

var MaxJumpStrength = 300.0

func SetGoal(goal):
	Goal = goal
	UpdatePath()

func UpdatePath():
	if Goal:
		path = nav.get_simple_path(get_position(), Goal, false)

func _process(delta):
	var acceleration = 600.0 * delta
	Motion.y += acceleration * 0.8
	
	if path.size() > 0:
		var pos = get_position()
		var next = path[0]
		if next.distance_to(pos) < 10.0:
			path.remove(0)
		else:
			if next.x < pos.x:
				Motion.x -= acceleration
			elif next.x > pos.x:
				Motion.x += acceleration
			
			if next.y < pos.y - 10.0:
				if is_on_floor():
					var strength = (pos.y - next.y) * 10.0
					if strength > MaxJumpStrength:
						UpdatePath()
					else:
						Motion.y -= strength
	else:
		Motion.x = lerp(Motion.x, 0.0, 0.1)
	
	Motion.x = clamp(Motion.x, -100.0, 100.0)
	Motion = move_and_slide(Motion, Vector2(0.0, -1.0))
	
	update()

func _draw():
	var previousPos = get_position()
	for pos in path:
		draw_line(to_local(previousPos), to_local(pos), Color.black, 4.0, false)
		previousPos = pos
