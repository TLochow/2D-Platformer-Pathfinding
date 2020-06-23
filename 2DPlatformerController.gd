extends Node2D

export(Vector2) var Extends

export(NodePath) var ParentKinematicBody2DNodePath
onready var ParentBody = get_node(ParentKinematicBody2DNodePath)

onready var GapCast = $GapCast
onready var LeftJumpCast = $JumpCasts/Left
onready var RightJumpCast = $JumpCasts/Right
onready var NextPointCast = $NextPointCast

var nav
var path = []
var Goal

var Motion = Vector2(0.0, 0.0)

var MaxJumpStrength
var JumpStrength = 0.0
var MoveSpeed = 0.0
var GravityForce = 0.0
var JumpLength
var SlowerJumpLength
var MaxJumpHeight = 0.0

var FramesSinceWaypointRemoved = 0

var RoutesSinceLastProgressImprovement = 0
var CurrentProgress = 0
var LastProgress = 0
var LastGoal = Vector2(0.0, 0.0)
var Slower = false

var BodyRange
var HalfExtends
var RoutStartPushStrength

var OSixTwoFiveX
var OSixTwoFiveY
var OneSixTwoFive
var OneTwoFive

func _ready():
	var leftJumpCastPos = Vector2(-(Extends.x * 0.5 - 1.0), -(Extends.y * 0.5))
	var rightJumpCastPos = Vector2((Extends.x * 0.5 - 1.0), -(Extends.y * 0.5))
	LeftJumpCast.set_position(leftJumpCastPos)
	LeftJumpCast.cast_to = Vector2(0.0, -Extends.y)
	RightJumpCast.set_position(rightJumpCastPos)
	RightJumpCast.cast_to = Vector2(0.0, -Extends.y)
	
	GapCast.cast_to = Vector2(0.0, Extends.y)
	
	BodyRange = min(Extends.x, Extends.y) * 0.5
	HalfExtends = Extends * 0.5
	RoutStartPushStrength = max(Extends.x, Extends.y) * 6.25
	
	OSixTwoFiveX = Extends.x * 0.625
	OSixTwoFiveY = Extends.y * 0.625
	OneSixTwoFive = Extends.x * 1.625
	OneTwoFive = Extends.x * 1.25

func SetMovementValues(jumpStrength, moveSpeed, gravityForce):
	JumpStrength = jumpStrength
	MaxJumpStrength = jumpStrength
	MoveSpeed = moveSpeed
	GravityForce = gravityForce
	JumpLength = CalculateJumpLength(JumpStrength, MoveSpeed, GravityForce)
	SlowerJumpLength = CalculateJumpLength(JumpStrength, MoveSpeed * 0.5, GravityForce)

func CalculateJumpLength(jumpStrength, moveSpeed, gravityForce):
	var pos = Vector2(0.0, 0.0)
	moveSpeed /= 60.0
	var yMovement = -jumpStrength
	while pos.y <= 0.0:
		pos.y += yMovement / 60.0
		yMovement += gravityForce
		pos.x += moveSpeed
		MaxJumpHeight = max(MaxJumpHeight, abs(pos.y))
	return pos.x

func SetGoal(goal, navigationMesh):
	Goal = goal
	nav = navigationMesh
	UpdatePath()

func UpdatePath():
	if Goal:
		var pos = ParentBody.get_position()
		path = nav.get_simple_path(pos, Goal, false)
		FramesSinceWaypointRemoved = 0
		var pathLength = path.size()
		if Goal == LastGoal:
			if CurrentProgress >= LastProgress:
				RoutesSinceLastProgressImprovement += 1
				if RoutesSinceLastProgressImprovement >= 2:
					Slower = true
					if RoutesSinceLastProgressImprovement >= 4:
						var succesfulSteps = pathLength - LastProgress
						Goal = path[succesfulSteps - 1]
						UpdatePath()
		else:
			LastGoal = Goal
			RoutesSinceLastProgressImprovement = 0
			LastProgress = pathLength
			Slower = false
		CurrentProgress = pathLength
		if path.size() > 1:
			Motion = (path[1] - pos).normalized() * RoutStartPushStrength

func _process(delta):
	Motion.y += GravityForce
	
	var pathSize = path.size()
	if pathSize > 0:
		var pos = ParentBody.get_position()
		var next = path[0]
		var overNext = next
		if pathSize > 1:
			overNext = path[1]
		SetPointCastCoords(to_local(next))
		
		var isOnFloor = ParentBody.is_on_floor()
		
		FramesSinceWaypointRemoved += 1
		if pos.distance_to(next) <= BodyRange or (abs(next.x - pos.x) <= OneTwoFive and next.y > pos.y - OSixTwoFiveY and next.y < pos.y + OneSixTwoFive and PathClear()):
			path.remove(0)
			FramesSinceWaypointRemoved = 0
			CurrentProgress = path.size()
			if CurrentProgress < LastProgress:
				Slower = false
				LastProgress = CurrentProgress
		elif FramesSinceWaypointRemoved > 100 and isOnFloor:
			UpdatePath()
		else:
			if next.x < pos.x - OSixTwoFiveX:
				if isOnFloor:
					Motion.x = -MoveSpeed
				else:
					Motion.x = lerp(Motion.x, -MoveSpeed, 0.2)
				NextPointCast.set_position(Vector2(HalfExtends.x, 0.0))
				GapCast.set_position(Vector2(-Extends.x, 0.0))
			elif next.x > pos.x + OSixTwoFiveX:
				if isOnFloor:
					Motion.x = MoveSpeed
				else:
					Motion.x = lerp(Motion.x, MoveSpeed, 0.2)
				NextPointCast.set_position(Vector2(-HalfExtends.x, 0.0))
				GapCast.set_position(Vector2(Extends.x, 0.0))
			
			var jumpUp = next.y < pos.y - OSixTwoFiveY
			var jumpOverGap = not GapCast.is_colliding() and abs(pos.y - next.y) < OSixTwoFiveY and abs(overNext.y - next.y) < 2.0
			if jumpUp or jumpOverGap:
				if isOnFloor:
					var jumpHeight = abs(pos.y - next.y)
					if jumpUp and not jumpOverGap:
						var removePoints = true
						while removePoints:
							var point = path[0]
							jumpHeight = abs(pos.y - point.y)
							SetPointCastCoords(to_local(point))
							NextPointCast.force_raycast_update()
							if point.y < pos.y and abs(pos.x - point.x) < OneTwoFive and PathClear():
								path.remove(0)
								if path.size() == 0:
									removePoints = false
							else:
								removePoints = false
					var strength = mapLog(jumpHeight, MaxJumpHeight, MaxJumpStrength)
					if jumpOverGap and not jumpUp:
						var jumpDistance = min(GetJumpDistance(Motion.x < 0.0), JumpLength)
						if Slower:
							strength = MaxJumpStrength * (jumpDistance / SlowerJumpLength)
						else:
							strength = MaxJumpStrength * (jumpDistance / JumpLength)
						var removePoints = true
						while removePoints:
							var point = path[0]
							if abs(point.y - pos.y) < OSixTwoFiveY and abs(point.x - pos.x) < jumpDistance:
								path.remove(0)
								if path.size() == 0:
									strength = 0.0
									removePoints = false
							else:
								removePoints = false
					if strength > MaxJumpStrength * 1.5:
						UpdatePath()
					elif IsJumpFree():
						Motion.y -= strength
						if jumpUp:
							Motion.x = 0.0
	else:
		Motion.x = lerp(Motion.x, 0.0, 0.2)
	
	if Slower:
		Motion.x *= 0.8
	Motion.x = clamp(Motion.x, -MoveSpeed, MoveSpeed)
	Motion = ParentBody.move_and_slide(Motion, Vector2(0.0, -1.0))
	update()

func _draw():
	var previousPos = ParentBody.get_position()
	for pos in path:
		draw_line(to_local(previousPos), to_local(pos), Color.black, 4.0, false)
		previousPos = pos

func GetJumpDistance(goingLeft):
	var distance = OneTwoFive
	var changeValue = 1.0
	if goingLeft:
		distance *= -1.0
		changeValue *= -1.0
	while not GapCast.is_colliding() and abs(distance) < JumpLength:
		distance += changeValue
		GapCast.set_position(Vector2(distance, 0.0))
		GapCast.force_raycast_update()
	return abs(distance) + 5.0

func IsJumpFree():
	return not (LeftJumpCast.is_colliding() or RightJumpCast.is_colliding())

func SetPointCastCoords(castTo):
	NextPointCast.cast_to = castTo

func PathClear():
	return not NextPointCast.is_colliding()

func mapLog(position, maxp, maxv):
	return (log(position) / log(maxp)) * maxv;
