extends KinematicBody2D

export(NodePath) var Nav2D
onready var nav = get_node(Nav2D)
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
	
	var pathSize = path.size()
	if pathSize > 0:
		var pos = get_position()
		var next = path[0]
		var overNext = next
		if pathSize > 1:
			overNext = path[1]
		if pathSize > 1:
			SetPointCastCoords(to_local(path[1]))
		print(abs(next.x - pos.x))
		if abs(next.x - pos.x) <= 10.0 and next.y > pos.y - 10.0 and next.y < pos.y + 26.0 and PathClear():
			path.remove(0)
		else:
			if next.x < pos.x - 10.0:
				Motion.x = -100.0
				$NextPointCast.set_position(Vector2(8.0, 0.0))
				$JumpCast.set_position(Vector2(-8.0, 0.0))
				$JumpCast.cast_to = Vector2(-12.0, 12.0)
			elif next.x > pos.x + 10.0:
				Motion.x = 100.0
				$NextPointCast.set_position(Vector2(-8.0, 0.0))
				$JumpCast.set_position(Vector2(8.0, 0.0))
				$JumpCast.cast_to = Vector2(12.0, 12.0)
			
			var jumpOverGap = not $JumpCast.is_colliding() and overNext.y <= pos.y
			var jumpUp = next.y < pos.y - 10.0
			if jumpUp or jumpOverGap:
				if is_on_floor():
					var strength = (pos.y - next.y) * 10.0
					if jumpOverGap and not jumpUp:
						strength = MaxJumpStrength * 0.5
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

func SetPointCastCoords(castTo):
	$NextPointCast.cast_to = castTo

func PathClear():
	return not $NextPointCast.is_colliding()
