extends CharacterBody2D
class_name Minotaur

@export var light_color_range : Gradient

@onready var sprite = $sprite
@onready var anim = $anim
@onready var torch = $torch
@onready var torch_anim = %torch_anim
@onready var food_sprite = %food_sprite

const IMPATIENT_DIALOGS = [
	"What are you doing? I'm coming for you.",
	"Where did you go? I'll find you.",
	"I'm starving here! Are you done yet?",
	"Pandacoder submitted the game already. Are you dona with finding the food?",
	"Dev_Row_ can make 5 games in the time you bring me one piece of food! Where are you?",
]

const TIMES_UP_DIALOGS = [
	"Time is up! I'm starving, prepaare to die!",
	"Here I come!",
	"I am craving for fresh flash!",
	"Hahahah, tanks for playing with me!",
]

var maze: GeneratedMaze
var gathering_area: GatheringArea

var speed = 60.0
var speed_modifier : float = 1.0
const CHASE_SPEED_MULT = 3.5

enum State{WAIT, EAT, FOLLOW, CHASE, KILL, NONE}
var state := State.WAIT

var path_points : Array[Vector2] = []
var last_footstep_pos: Vector2
var map_pos: Vector2i : set = _set_map_pos

var player_in_range := false
var player: Player


func _ready():
	food_sprite.visible = false
	last_footstep_pos = position

func _input(event):
	if !Mng.is_debug_mode: return
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			go_to_global_pos(get_global_mouse_position())

func _physics_process(d):
	if Mng.is_debug_mode: queue_redraw()
	if path_points.is_empty():
		if state in [State.FOLLOW, State.WAIT]:
			anim.play("idle")
		return
	
	var next = path_points[-1]
	if position.distance_to(next) < 4:
		next = path_points.pop_back()
	
	velocity = velocity.slerp(position.direction_to(next) * speed * speed_modifier, 0.3)
	if velocity.length_squared() > 8:
		if state in [State.FOLLOW, State.WAIT]:
			anim.play("walk")
	move_and_slide()
	
	for col_idx in get_slide_collision_count():
		var col := get_slide_collision(col_idx)
		var collider = col.get_collider()
		if collider is RigidBody2D:
			collider.apply_impulse(-col.get_normal() * 100 * d, col.get_position() - collider.global_position)
		if collider is Player:
			collider.velocity = position.direction_to(next) * speed * 0.9
			collider.move_and_slide()

var tick : float = 0.0
func _process(d):
	sprite.flip_h = velocity.x < 0
	footsteps()
	process_map_pos()
	if !Mng.is_cutscene: process_states(d)

func process_map_pos():
	if Mng.global_to_map(position) != map_pos:
		map_pos = Mng.global_to_map(position)

func process_states(d):
	torch.color = light_color_range.sample(1.0 - Mng.hunger_left/Mng.MAX_HUNGER)
	tick += d
	if state in [State.WAIT, State.FOLLOW]:
		Mng.hunger_left -= d * Mng.hunger_rate
		if Mng.hunger_left <= 0.0:
			Mng.hunger_left = 0.0
			state = State.KILL
			Mng.push_dialog(TIMES_UP_DIALOGS.pick_random())
			go_to_global_pos(maze.player.position)
			var tw = create_tween().bind_node(self)
			tw.tween_property(self, "speed_modifier", CHASE_SPEED_MULT, 2)
			
		elif Mng.hunger_left/Mng.MAX_HUNGER < Mng.follow_threshold:
			if state == State.WAIT:
				state = State.FOLLOW
				Mng.push_dialog(IMPATIENT_DIALOGS.pick_random())
	
	
	match state:
		State.WAIT:
			if tick < 2.5: return
			if path_points.is_empty():
				go_to_global_pos(get_random_point_around(gathering_area.position))
		State.FOLLOW:
			if tick < 5: return
			go_to_global_pos(get_random_point_around(maze.player.position, 3))
		State.EAT:
			if !anim.is_playing() or anim.current_animation != "eating":
				anim.play("eating")
				await anim.animation_finished
				if Mng.food_collected == Mng.food_in_maze:
					Mng.go_to_next_maze()
					state = State.NONE
				else:
					state = State.WAIT
		State.KILL:
			if !torch_anim.is_playing():
				torch_anim.play("kill")
			
			if player_in_range and (anim.current_animation != "killing" or !anim.is_playing()):
				anim.play("killing")
				#state = State.NONE
				path_points.clear()
				Mng.push_dialog("NOM NOM NOM", true)
				player.visible = false
				await anim.animation_finished
				Mng.game_over(Mng.EndState.EATEN)
			
			if tick < 0.25: return
			go_to_global_pos(maze.player.position)
	
	tick = 0


func get_random_point_around(_pos: Vector2, r := 5) -> Vector2:
	var grid_pos = Utl.global_to_map(_pos)
	var new_grid_pos = grid_pos + Vector2i(randi_range(-r,r), randi_range(-r,r))
	new_grid_pos = Utl.clamp_point_to_rect(new_grid_pos, Mng.maze_map_data.map_rect)
	
	while !Mng.maze_map_data.btm_maze_floor.get_bitv(new_grid_pos):
		new_grid_pos = grid_pos + Vector2i(randi_range(-r,r), randi_range(-r,r))
		new_grid_pos = Utl.clamp_point_to_rect(new_grid_pos, Mng.maze_map_data.map_rect)
	var final_destination := Utl.map_to_global(new_grid_pos)
	return final_destination

func footsteps():
	if position.distance_to(last_footstep_pos) > Mng.CELL_SIZE*1.5:
		var footstep = preload("res://instances/footstep.tscn").instantiate()
		footstep.type = footstep.Type.BEAST
		footstep.position = position
		footstep.rotation = last_footstep_pos.angle_to_point(position)
		add_sibling(footstep)
		last_footstep_pos = position


func go_to_global_pos(target: Vector2) -> void:
	if player:
		if player.is_being_eaten: return
	path_points.clear()
	var start = Utl.global_to_map(position)
	var end = Utl.global_to_map(target)
	var result = Mng.maze_map_data.astar.get_point_path(start, end)
	for i in range(result.size()-1, 0,-1):
		var p = result[i]
		p += Vector2(Mng.CELL_VEC)/2
		path_points.append(p)

func _draw():
	if path_points.is_empty(): return
	
	for p in path_points:
		draw_circle(p - position, 2, Color.RED)


func _on_pick_area_body_entered(body):
	if body is PickUp and !state in [State.KILL, State.EAT]:
		if body.is_food:
			state = State.EAT
			path_points.clear()
			body.queue_free()
			food_sprite.region_rect = body.sprite.region_rect
			Mng.food_collected += 1
			Mng.food_points += body.food_hunger_value
			var tw = create_tween().bind_node(self)
			var hunger_final = min(Mng.hunger_left + body.food_hunger_value, Mng.MAX_HUNGER)
			tw.tween_property(Mng, "hunger_left", hunger_final, 2)
	if body is Player:
		player_in_range = true
		player = body
func _on_pick_area_body_exited(body):
	if body is Player:
		player_in_range = false

func call_fade_to_black():
	Mng.overlay.fade_to_black(5.0)


func _set_map_pos(val):
	map_pos = val
	Mng.minotaur_position_updated.emit(val)
