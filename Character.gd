extends KinematicBody2D

onready var JumpCast = $JumpCast
onready var LeftJumpCast = $JumpCasts/Left
onready var RightJumpCast = $JumpCasts/Right
onready var NextPointCast = $NextPointCast

export(NodePath) var Nav2D
onready var nav = get_node(Nav2D)
var path = []
var Goal

var Motion = Vector2(0.0, 0.0)

var MaxJumpStrength
var JumpStrength = 0.0
var MoveSpeed = 0.0
var GravityForce = 0.0
var JumpLength

func SetMovementValues(jumpStrength, moveSpeed, gravityForce):
	JumpStrength = jumpStrength
	MaxJumpStrength = jumpStrength
	MoveSpeed = moveSpeed
	GravityForce = gravityForce
	JumpLength = CalculateJumpLength(JumpStrength, MoveSpeed, GravityForce)

func CalculateJumpLength(jumpStrength, moveSpeed, gravityForce):
	var pos = Vector2(0.0, 0.0)
	moveSpeed /= 60.0
	var yMovement = -jumpStrength
	while pos.y <= 0.0:
		pos.y += yMovement
		yMovement += gravityForce
		pos.x += moveSpeed
	return pos.x

func SetGoal(goal):
	Goal = goal
	UpdatePath()

func UpdatePath():
	if Goal:
		path = nav.get_simple_path(get_position(), Goal, false)

func _process(delta):
	Motion.y += GravityForce
	
	var pathSize = path.size()
	if pathSize > 0:
		var pos = get_position()
		var next = path[0]
		var overNext = next
		if pathSize > 1:
			overNext = path[1]
		if pathSize > 1:
			SetPointCastCoords(to_local(path[1]))
		
		if abs(next.x - pos.x) <= 16.0 and next.y > pos.y - 16.0 and next.y < pos.y + 26.0 and PathClear():
			path.remove(0)
		else:
			var isOnFloor = is_on_floor()
			if next.x < pos.x - 10.0:
				if isOnFloor:
					Motion.x = -MoveSpeed
				else:
					Motion.x = lerp(Motion.x, -MoveSpeed, 0.2)
				NextPointCast.set_position(Vector2(8.0, 0.0))
				JumpCast.set_position(Vector2(-8.0, 0.0))
				JumpCast.cast_to = Vector2(-12.0, 12.0)
			elif next.x > pos.x + 10.0:
				if isOnFloor:
					Motion.x = MoveSpeed
				else:
					Motion.x = lerp(Motion.x, MoveSpeed, 0.2)
				NextPointCast.set_position(Vector2(-8.0, 0.0))
				JumpCast.set_position(Vector2(8.0, 0.0))
				JumpCast.cast_to = Vector2(12.0, 12.0)
			
			var jumpUp = next.y < pos.y - 10.0
			var jumpOverGap = not JumpCast.is_colliding() and abs(overNext.y - pos.y) < 10.0
			if jumpUp or jumpOverGap:
				if isOnFloor:
					var strength = (pos.y - next.y) * 10.0
					if jumpOverGap and not jumpUp:
						var jumpDistance = GetJumpDistance(Motion.x < 0.0)
						strength = MaxJumpStrength * (jumpDistance / JumpLength)
						var removePoints = true
						while removePoints:
							var point = path[0]
							if abs(overNext.y - pos.y) < 10.0 and abs(point.x - pos.x) < jumpDistance:
								 path.remove(0)
							else:
								removePoints = false
					if strength > MaxJumpStrength:
						UpdatePath()
					elif IsJumpFree():
						Motion.y -= strength
						if jumpUp:
							Motion.x = 0.0
	else:
		Motion.x = lerp(Motion.x, 0.0, 0.2)
	
	Motion.x = clamp(Motion.x, -MoveSpeed, MoveSpeed)
	Motion = move_and_slide(Motion, Vector2(0.0, -1.0))
	update()

func _draw():
	var previousPos = get_position()
	for pos in path:
		draw_line(to_local(previousPos), to_local(pos), Color.black, 4.0, false)
		previousPos = pos

func GetJumpDistance(goingLeft):
	var distance = 20.0
	var changeValue = 1.0
	if goingLeft:
		distance *= -1.0
		changeValue *= -1.0
	while not JumpCast.is_colliding() and abs(distance) < 1000.0:
		distance += changeValue
		JumpCast.set_position(Vector2(distance, 0.0))
		JumpCast.cast_to = Vector2(0.0, 12.0)
		JumpCast.force_raycast_update()
	return abs(distance)

func IsJumpFree():
	return not (LeftJumpCast.is_colliding() or RightJumpCast.is_colliding())

func SetPointCastCoords(castTo):
	NextPointCast.cast_to = castTo

func PathClear():
	return not NextPointCast.is_colliding()
