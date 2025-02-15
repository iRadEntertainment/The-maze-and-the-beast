extends Label


func _ready():
	position -= pivot_offset
	modulate.a = 0
	var tw = create_tween().bind_node(self)
	var final_pos =position + Vector2.UP * 40
	tw.tween_property(self, "position", final_pos, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.parallel().tween_property(self, "modulate:a", 1, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_interval(1.0)
	await tw.finished
	queue_free()


