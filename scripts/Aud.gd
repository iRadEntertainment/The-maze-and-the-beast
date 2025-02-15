# AUD
extends Node

@onready var mus_menu = $mus_menu
@onready var mus_end = $mus_end
@onready var btn_press = $btn_press
@onready var btn_hover = $btn_hover


func play_btn_press(): btn_press.play()
func play_btn_hover(): btn_hover.play()

func play_intro(val):
	if val:
		mus_menu.play()
		play_end(false)
	else:
		var init_vol = mus_menu.volume_db
		var tw = create_tween()
		tw.tween_property(mus_menu, "volume_db", -78, 4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tw.finished
		mus_menu.stop()
		mus_menu.volume_db = init_vol
func play_end(val: bool):
	if val:
		mus_end.play()
		play_intro(false)
	else:
		var init_vol = mus_end.volume_db
		var tw = create_tween()
		tw.tween_property(mus_end, "volume_db", -78, 4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tw.finished
		mus_end.stop()
		mus_end.volume_db = init_vol
