extends KinematicBody2D

onready var Controller = get_node("2DPlatformerController")

export(NodePath) var Nav2D
onready var nav = get_node(Nav2D)

func SetGoal(goal):
	Controller.SetGoal(goal, nav)

func SetMovementValues(jumpStrength, moveSpeed, gravityForce):
	Controller.SetMovementValues(jumpStrength, moveSpeed, gravityForce)
