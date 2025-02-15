extends Control

@onready var btns = %btns
@onready var ln_seed = %ln_seed
@onready var ck_debug = %ck_debug
@onready var pnl_settings = %pnl_settings
@onready var sp_level = %sp_level



func _ready():
	Aud.play_intro(true)
	pnl_settings.visible = false
	sp_level.visible = Mng.is_debug_mode
	ck_debug.button_pressed = Mng.is_debug_mode
	ck_debug.visible = Mng.is_debug_mode
	ln_seed.text = "Pandainstacoder"

func select_random_seed():
	ln_seed.text = Mng.seed_donors.pick_random()


func _on_btn_play_pressed():
	Mng.main_seed = ln_seed.text
	Mng.play_maze(int(sp_level.value))
	Aud.play_intro(false)
func _on_btn_credits_pressed():
	Mng.go_to_credits()
func _on_btn_quit_pressed():
	Mng.quit()


func _on_btn_settings_pressed():
	pnl_settings.visible = !pnl_settings.visible
func _on_btn_shuffle_pressed():
	select_random_seed()
func _on_ck_debug_toggled(toggled_on):
	if Mng.is_debug_mode == toggled_on: return
	Mng.is_debug_mode = toggled_on




func _on_btn_fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
