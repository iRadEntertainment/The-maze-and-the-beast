extends Control


@onready var end_story = %end_story
@onready var title = %title
@onready var lb_time = %lb_time
@onready var lb_mazes = %lb_mazes
@onready var lb_food = %lb_food


var tot_time: int


func _ready():
	Aud.play_end(true)
	stats()
	var text_file = ""
	match Mng.end_state:
		Mng.EndState.EATEN:
			title.text = "You've been devoured!"
			text_file = "res://assets/text/eaten.txt"
		Mng.EndState.DEAD:
			title.text = "You died in the maze!"
			text_file = "res://assets/text/win_maze.txt"
		Mng.EndState.WIN_MAZE:
			title.text = "You completed the maze!"
			text_file = "res://assets/text/win_maze.txt"
		Mng.EndState.WIN_DOOR:
			title.text = "You escaped the maze!"
			text_file = "res://assets/text/win_maze.txt"
	
	end_story.visible_ratio = 0
	var file = FileAccess.open(text_file, FileAccess.READ)
	end_story.text = file.get_as_text()
	var tw = create_tween().bind_node(self)
	tw.tween_property(end_story, "visible_ratio", 1, 3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)


func stats():
	tot_time = Time.get_unix_time_from_system() - Mng.time_start
	lb_time.text = str(Time.get_time_string_from_unix_time(tot_time))
	lb_mazes.text = "%s/%s" % [Mng.level_n, Mng.LEVEL_MAX]
	lb_food.text = str(Mng.food_points)


func _on_btn_back_to_main_pressed():
	Mng.go_to_main_menu()
func _on_btn_credits_pressed():
	Mng.go_to_credits()
