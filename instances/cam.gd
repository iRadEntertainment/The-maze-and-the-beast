extends Camera2D


func _ready():
	Mng.cam = self

func _input(event):
	if !Mng.is_debug_mode: return
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom *= 0.95
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom /= 0.95
