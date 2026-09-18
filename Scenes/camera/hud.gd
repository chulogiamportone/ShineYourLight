extends CanvasLayer


@export var player1: Node2D
@export var player2: Node2D
@onready var label: Label = $Control/Label
@onready var label_2: Label = $Control/Label2


func _process(delta):
	label.text=str(int(player1.puntaje))
	label_2.text=str(int(player2.puntaje))
