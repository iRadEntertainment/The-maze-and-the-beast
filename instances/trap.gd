extends Node2D


@onready var sprite = $sprite
@onready var sfx_snap = $sfx_snap


func trigger():
	sfx_snap.play()
	sprite.region_rect = Rect2i(170, 187, 16, 16)
	Mng.player.die_from_trap(position + Vector2(0,1))


func _on_trigger_body_entered(body):
	trigger()
