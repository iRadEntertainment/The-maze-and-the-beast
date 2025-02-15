extends CanvasLayer
class_name Overlay


@onready var top = %top
@onready var lb_dialog = %lb_dialog
@onready var pnl_dialog = %pnl_dialog
@onready var sfx_text = %sfx_text
@onready var sfx_ui = %sfx_ui
@onready var game_menu = $game_menu
@onready var bot = %bot

@onready var cine_band_1 = %cine_band1
@onready var cine_band_2 = %cine_band2
@onready var black_fade = $gui/black_fade

@onready var lb_food = %lb_food
@onready var lb_level = %lb_level
@onready var hunger_bar = %hunger_bar


var tw_cine_bands: Tween
var dialog_queue : Array[String] = []

const LAUGH_STREAM = [
	preload("res://assets/sfx/sfx - laugh_1.ogg"),
	preload("res://assets/sfx/sfx - laugh_2.ogg"),
	preload("res://assets/sfx/sfx - laugh_3.ogg"),
]

var _dialog_displaying := false
var _dialog_on := false : set = _set_dialog_on
var _dialog_display_duration = 1.3


func _ready():
	Mng.overlay = self
	visible = true
	black_fade.color.a = 0
	pnl_dialog.visible = false
	game_menu.visible = get_tree().paused
	cine_band_1.custom_minimum_size.y = 0
	cine_band_2.custom_minimum_size.y = 0
	bot.visible = Mng.is_debug_mode
	
	lb_level.text = "maze %s/%s" % [Mng.level_n, Mng.LEVEL_MAX]
	
	Mng.is_cutscene_changed.connect(_on_cutscene_changed)
	Mng.food_collected_changed.connect(_on_food_collected_changed)


func toggle_pause():
	Mng.pause_game_toggle()
	game_menu.visible = get_tree().paused

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
	if event.is_action_pressed("action"):
		if _dialog_on:
			sfx_ui.play()
			if _dialog_displaying:
				_dialog_displaying = false
				lb_dialog.visible_ratio = 1
			else:
				_dialog_on = false


func push_dialog(_text: String, is_cutscene: bool = false):
	if is_cutscene:
		Mng.is_cutscene = true
	dialog_queue.append(_text)


func _process(d):
	process_dialog(d)
	hunger_bar.value = Mng.hunger_left/Mng.MAX_HUNGER

func process_dialog(d):
	if !_dialog_on and !dialog_queue.is_empty():
		_dialog_on = true
		_dialog_displaying = true
		lb_dialog.text = dialog_queue.pop_front()
		lb_dialog.visible_ratio = 0
		sfx_text.stream = LAUGH_STREAM.pick_random()
		sfx_text.play()
	
	if _dialog_displaying:
		lb_dialog.visible_ratio += d / _dialog_display_duration
		if lb_dialog.visible_ratio >= 1.0:
			_dialog_displaying = false
	
	if !_dialog_on and !_dialog_displaying and dialog_queue.is_empty() and Mng.is_cutscene:
		Mng.is_cutscene = false

func fade_to_black(sec: float):
	var tw = create_tween().bind_node(self)
	tw.tween_property(black_fade, "color:a", 1, sec).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _set_dialog_on(val) -> void:
	_dialog_on = val
	pnl_dialog.visible = _dialog_on
func _on_cutscene_changed():
	top.visible = !Mng.is_cutscene
	if tw_cine_bands:
		tw_cine_bands.kill()
	
	tw_cine_bands = create_tween().bind_node(self)
	var final_height = 48 if Mng.is_cutscene else 0
	tw_cine_bands.tween_property(cine_band_1, "custom_minimum_size:y", final_height, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_cine_bands.parallel().tween_property(cine_band_2, "custom_minimum_size:y", final_height, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_food_collected_changed():
	lb_food.text = "Food eaten: %s/%s" % [Mng.food_collected, Mng.food_in_maze]

func _on_btn_prev_level_pressed():
	var level = clamp(Mng.level_n + 1, 1, 10)
	Mng.play_maze(level)
func _on_btn_next_level_pressed():
	var level = clamp(Mng.level_n + 1, 1, 10)
	Mng.play_maze(level)
