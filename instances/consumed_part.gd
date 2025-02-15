extends Node2D

@onready var part = $part
@onready var sfx = $sfx


func _ready():
	part.emitting = true
	sfx.play()
	await part.finished
	queue_free()
