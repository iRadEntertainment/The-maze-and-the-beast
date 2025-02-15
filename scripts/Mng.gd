# MNG
extends Node
class_name Utl

const TILE_TO_CELL_RATIO = 3
const CELL_SIZE = 16 #px
const CELL_VEC = Vector2i(CELL_SIZE, CELL_SIZE) #px

# references
var maze: GeneratedMaze
var player: Player
var minotaur: Minotaur
var cam: Camera2D
var overlay: Overlay

# maze info
var maze_dim_base = Vector2i(21,15)
var maze_expansion = Vector2i(2, 2)
var main_seed: String
var maze_data : MazeGenData
var maze_map_data : MazeMapData

# seeds
const RNG_SEEDS_PATH = "res://assets/text/rng_seeds.txt"
var seed_donors = []

# game info
enum EndState{EATEN, DEAD, WIN_MAZE, WIN_DOOR}
var end_state: EndState

var time_start: int
var level_n : int = 0
const LEVEL_MAX = 10
var MAX_HUNGER : float = 100.0
var hunger_left : float = MAX_HUNGER
var hunger_rate = 1.0
var follow_threshold = 0.4

var food_collected : int = 0 : set = _set_food_collected
signal food_collected_changed
const BASE_FOOD = 10
var food_in_maze : int = 10
var food_points = 0
var potions_in_maze : int = 2
var doors_in_maze : int = 0
var traps_in_maze : int = 0
var weapons_in_maze : int = 0
var props_in_maze : int = 0

signal player_position_updated(map_position)
signal minotaur_position_updated(map_position)

var is_debug_mode := true
var is_cutscene := false : set = _set_is_cutscene
signal is_cutscene_changed


func _ready():
	load_seed_donors()

func play_maze(_level: int = 1):
	level_n = _level
	seed(hash(main_seed) + level_n)
	if level_n == 1:
		food_points = 0
		time_start = Time.get_unix_time_from_system()
	var maze_dimensions = calculate_maze_dim_from_level()
	generate_maze_data(maze_dimensions)
	var pack = load("res://instances/generated_maze.tscn")
	get_tree().change_scene_to_packed(pack)

func load_seed_donors():
	seed_donors.clear()
	var file = FileAccess.open(RNG_SEEDS_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if line.is_empty(): continue
		seed_donors.append(line)

func calculate_maze_dim_from_level() -> Vector2i:
	return maze_dim_base + maze_expansion * level_n

func play_intro():
	pass

func push_dialog(text: String, is_cutscene := false):
	overlay.push_dialog(text, is_cutscene)

func generate_maze_data(_maze_dimensions: Vector2i):
	maze_data = MazeGen.generate_maze(_maze_dimensions, main_seed)
	maze_map_data = Utl.convert_data_to_map_data(maze_data)

func set_camera_limits():
	cam.limit_bottom = (maze_data.maze_dimensions * Mng.TILE_TO_CELL_RATIO * Mng.CELL_SIZE).y
	cam.limit_right = (maze_data.maze_dimensions * Mng.TILE_TO_CELL_RATIO * Mng.CELL_SIZE).x

func pause_game_toggle():
	get_tree().paused = !get_tree().paused

func game_over(_state := EndState.EATEN):
	end_state = _state
	get_tree().change_scene_to_file("res://instances/game_over.tscn")

func go_to_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://instances/main_menu.tscn")

func go_to_credits():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://instances/credits.tscn")

func go_to_next_maze():
	if level_n == LEVEL_MAX:
		end_state = EndState.WIN_MAZE
		get_tree().change_scene_to_file("res://instances/game_over.tscn")
	else :
		play_maze(level_n+1)

func quit():
	get_tree().quit()

func _set_is_cutscene(val: bool) -> void:
	is_cutscene = val
	is_cutscene_changed.emit()
func _set_food_collected(val):
	food_collected = val
	food_collected_changed.emit()

static func clamp_point_to_rect(point: Vector2i, rect: Rect2i) -> Vector2i:
	if !rect.has_point(point):
		point.x = max(rect.position.x, point.x)
		point.x = min(rect.end.x, point.x)
		point.y = max(rect.position.y, point.y)
		point.y = min(rect.end.y, point.y)
	return point

static func global_to_data(_pos : Vector2) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i((_pos / Mng.TILE_TO_CELL_RATIO) / Mng.CELL_SIZE)
static func data_to_global(grid_pos : Vector2i) -> Vector2:
	return Vector2(grid_pos * Mng.TILE_TO_CELL_RATIO * Mng.CELL_SIZE) + Vector2.ONE * (Mng.CELL_SIZE*3)/2.0
static func data_to_map(_pos: Vector2i) -> Vector2i:
	return Vector2i(_pos*3) + Vector2i.ONE
static func map_to_data(_pos: Vector2i) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(_pos/3)
static func global_to_map(_pos: Vector2) -> Vector2i:
	return Vector2i(_pos/float(CELL_SIZE))
static func map_to_global(_pos: Vector2i) -> Vector2:
	return Vector2(_pos * float(CELL_SIZE)) + Vector2(CELL_VEC)/2.0
static func convert_data_to_map_data(data: MazeGenData) -> MazeMapData:
	var map_data := MazeMapData.new()
	
	map_data.map_size = data.maze_dimensions * Mng.TILE_TO_CELL_RATIO
	map_data.map_rect = Rect2i(Vector2i(), map_data.map_size)
	
	map_data.btm_walls_all.create(map_data.map_size)
	map_data.btm_walls_top.create(map_data.map_size)
	map_data.btm_walls_vert.create(map_data.map_size)
	
	map_data.btm_occupied_tiles.create(map_data.map_size)
	map_data.btm_pick_ups_food.create(map_data.map_size)
	map_data.btm_pick_ups_potions.create(map_data.map_size)
	map_data.btm_pick_ups_weapons.create(map_data.map_size)
	
	map_data.btm_maze_floor = data.btm_maze.duplicate()
	map_data.btm_maze_floor.resize(data.btm_maze.get_size() * Mng.TILE_TO_CELL_RATIO)
	
	for x in map_data.map_size.x:
		for y in map_data.map_size.y:
			var p = Vector2i(x,y)
			if map_data.btm_maze_floor.get_bit(x, y):
				map_data.list_maze_floor.append(p)
				continue
			if y < map_data.map_size.y-1 and !map_data.btm_maze_floor.get_bit(x, y+1):
				map_data.list_walls_top.append(p)
				map_data.btm_walls_top.set_bitv(p, true)
			else:
				map_data.list_walls_vert.append(p)
				map_data.btm_walls_vert.set_bitv(p, true)
			
			map_data.list_walls_all.append(p)
			map_data.btm_walls_all.set_bitv(p, true)
	
	# astar
	map_data.astar = AStarGrid2D.new()
	map_data.astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	map_data.astar.region = Rect2i(0, 0, map_data.map_size.x, map_data.map_size.y)
	map_data.astar.cell_size = Vector2(Mng.CELL_SIZE, Mng.CELL_SIZE)
	map_data.astar.update()

	for p in map_data.list_walls_all:
		map_data.astar.set_point_solid(p)
	return map_data


static func sort_data_points_for_distance_to_point(a: Vector2i, b: Vector2i, c: Vector2i) -> bool:
	var dist_a = (a - c).length_squared()
	var dist_b = (b - c).length_squared()
	return dist_a > dist_b
