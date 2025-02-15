extends HBoxContainer
class_name FxDisplay


@onready var ico = $ico
@onready var progress = $progress

var region: Rect2i
var duration: float

var _max_duration: float


func _ready():
	ico.texture = ico.texture.duplicate()
	ico.texture.region = region
	progress.value = 1
	_max_duration = duration

func _process(d):
	if Mng.is_cutscene: return
	duration -= d
	progress.value = duration/_max_duration
	if duration < 0:
		queue_free()
