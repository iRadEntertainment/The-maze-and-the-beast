extends Sprite2D


const MAX_LIFE = 5.0 #sec
var lifetime = MAX_LIFE
@onready var sfx = $sfx

enum Type {HUMAN, BEAST}
var type := Type.HUMAN

func _ready():
	if type == Type.BEAST:
		region_rect = Rect2i(16,0,16,16)
		sfx.stream = preload("res://assets/sfx/sfx - gravel_impact.ogg")
	sfx.pitch_scale = randf_range(0.75, 1.05)
	sfx.play()

func _process(d):
	lifetime -= d
	modulate.a = lerp(0, 1, lifetime/MAX_LIFE)
	
	if modulate.a <= 0.0:
		queue_free()
