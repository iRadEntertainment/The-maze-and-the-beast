@tool
extends Node2D
class_name GeneratedMaze

@export var do_it = false : set = _set_do_it
@export var map_seed = "Vex667" : set = _set_map_seed
@export var maze_dimensions = Vector2i(21,21) : set = _set_maze_dimensions
@export_range(1, 10, 1) var level : int = 1 : set = _set_level
@export var is_darkness_on := false : set = _set_is_darkness_on

@onready var walls_coll : StaticBody2D = $walls_coll
@onready var occluders = $occluders
@onready var ceiling_lights = $ceiling_lights
@onready var darkness = $darkness
@onready var pick_ups = $pick_ups

@onready var player: Player = $player
@onready var torch = $player/torch
@onready var minotaur: Minotaur = $minotaur
@onready var gathering_area: GatheringArea = $gathering_area



const LIGHT = preload("res://assets/light.png")
var tw_light_fx: Tween

func _ready():
	if !Mng.is_debug_mode:
		is_darkness_on = true
		set_darkness()
	if !Engine.is_editor_hint():
		generate()
		player.maze = self
		minotaur.maze = self
		minotaur.gathering_area = gathering_area
		Mng.maze_map_data.astar.set_point_solid(Utl.global_to_map(gathering_area.position), true)
		Mng.set_camera_limits()
		Mng.is_cutscene_changed.connect(stop_tweens)
		
		if Mng.level_n == 1 and not Mng.is_debug_mode:
			Mng.push_dialog("What did you do to get thrown in here with me?", true)
			Mng.push_dialog("Don't even answer! I don't care!")
			Mng.push_dialog("I'm not gonna eat you straight away, let's play a game instead...")
			Mng.push_dialog("Find for me all the human remains that I've scattered around the place. If I will feel too hungry, then I'll come and eat you instead!")
			Mng.push_dialog("In this maze there are %s pieces of food you can bring me. MOVE NOW, the clock is ticking!"%Mng.food_in_maze)


func generate() -> void:
	seed(hash(map_seed))
	set_references()
	create_wall_collisions_and_occluders(Mng.maze_map_data)
	position_start_area(Mng.maze_data)
	set_item_in_maze()
	add_pick_ups(Mng.maze_data)
	add_ceiling_lights(Mng.maze_data)
	populate_tilemap(Mng.maze_map_data)
	set_darkness()


func set_references() -> void:
	gathering_area.player = player
	gathering_area.minotaur = minotaur


func set_item_in_maze():
	Mng.food_collected = 0
	Mng.food_in_maze = (Mng.BASE_FOOD + Mng.level_n * 2)
	Mng.potions_in_maze = 2 + floor((Mng.level_n) * 1.5)
	Mng.doors_in_maze = 0 if Mng.level_n < 4 else 1
	Mng.traps_in_maze = 5 + floor((Mng.level_n) * 1.5)
	Mng.weapons_in_maze = 0 if Mng.level_n < 4 else 1
	Mng.props_in_maze = 35
	Mng.overlay._on_food_collected_changed()

func set_darkness() -> void:
	occluders.visible = is_darkness_on
	torch.visible = is_darkness_on
	darkness.visible = is_darkness_on
	ceiling_lights.visible = is_darkness_on

func _input(event):
	if !Mng.is_debug_mode: return
	if event.is_action_pressed("toggle_lights"):
		is_darkness_on = !is_darkness_on
		set_darkness()
	if event.is_action_pressed("test"):
		Mng.game_over(Mng.EndState.WIN_MAZE)
		Mng.time_start -= 489


func populate_tilemap(map_data: MazeMapData) -> void:
	%tm_ground.clear()
	%tm_walls.clear()
	%tm_ground.set_cells_terrain_connect(map_data.list_maze_floor, 0, 0)
	%tm_walls.set_cells_terrain_connect(map_data.list_walls_top, 0, 1)
	%tm_walls.set_cells_terrain_connect(map_data.list_walls_vert, 0, 2)


func create_wall_collisions_and_occluders(map_data: MazeMapData) -> void:
	for child in walls_coll.get_children():
		child.queue_free()
	for child in occluders.get_children():
		child.queue_free()
	
	#var size = maze_dimensions*Mng.TILE_TO_CELL_RATIO
	var size = map_data.btm_walls_all.get_size()
	var btm_walls_all_with_gap = map_data.btm_walls_all.duplicate()
	var btm_walls_top_with_gap = map_data.btm_walls_top.duplicate()
	
	for y in range(Mng.TILE_TO_CELL_RATIO):
		var x = Mng.TILE_TO_CELL_RATIO
		btm_walls_all_with_gap.set_bit(x, y, false)
		btm_walls_top_with_gap.set_bit(x, y, false)
	
	var coll_polys = btm_walls_all_with_gap.opaque_to_polygons( Rect2i(0, 0, size.x, size.y), 0)
	var shadow_polys = btm_walls_top_with_gap.opaque_to_polygons( Rect2i(0, 0, size.x, size.y), 0)
	
	# resize polygons considering the tile size
	for poly : PackedVector2Array in (coll_polys + shadow_polys):
		for i in poly.size():
			poly[i] *= Mng.CELL_SIZE
	
	for poly : PackedVector2Array in coll_polys:
		var coll := CollisionPolygon2D.new()
		coll.polygon = poly
		walls_coll.add_child(coll)
		
	for poly : PackedVector2Array in shadow_polys:
		var light_occluder := LightOccluder2D.new()
		var poly_occluder = OccluderPolygon2D.new()
		poly_occluder.polygon = poly
		light_occluder.occluder = poly_occluder
		occluders.add_child(light_occluder)
	
	# plug hole
	var plug_poly_coll = [Vector2(3,0), Vector2(4,0), Vector2(4,3), Vector2(3,3)]
	var plug_poly_occ = [Vector2(3,0), Vector2(4,0), Vector2(4,2), Vector2(3,2)]
	for i in range(plug_poly_coll.size()):
		plug_poly_coll[i] *= Mng.CELL_SIZE
		plug_poly_occ[i] *= Mng.CELL_SIZE
	
	var plug_coll := CollisionPolygon2D.new()
	plug_coll.polygon = plug_poly_coll
	walls_coll.add_child(plug_coll)
	
	var plug_light_occluder := LightOccluder2D.new()
	var plug_poly_occluder = OccluderPolygon2D.new()
	plug_poly_occluder.polygon = plug_poly_occ
	plug_light_occluder.occluder = plug_poly_occluder
	occluders.add_child(plug_light_occluder)


func position_start_area(data: MazeGenData) -> void:
	var init_pos = data.list_corners_removed.pick_random()
	
	gathering_area.position = Utl.data_to_global(init_pos)
	player.position = gathering_area.position + Vector2(Mng.CELL_VEC)
	minotaur.position = gathering_area.position + Vector2.UP * Mng.CELL_SIZE


func add_ceiling_lights(data: MazeGenData) -> void:
	for child in ceiling_lights.get_children():
		child.queue_free()
	
	for p in data.list_corners_removed:
		var ceiling_light = PointLight2D.new()
		ceiling_light.energy = 0.2
		ceiling_light.shadow_enabled = true
		ceiling_light.position = Utl.data_to_global(p)
		ceiling_light.texture = LIGHT
		ceiling_lights.add_child(ceiling_light)


func add_pick_ups(data: MazeGenData) -> void:
	var gath_pos = Utl.global_to_data(gathering_area.position)
	var possible_data_locations : Array[Vector2i] = data.end_points + data.corner_points
	possible_data_locations.sort_custom(Mng.sort_data_points_for_distance_to_point.bind(gath_pos))
	
	for child in pick_ups.get_children():
		child.queue_free()
	
	for i in Mng.weapons_in_maze:
		if possible_data_locations.is_empty(): return
		var index = i if randf() > 0.2 else randi_range(0, possible_data_locations.size()-1)
		var p : Vector2i = possible_data_locations[index]
		possible_data_locations.remove_at(index)
		place_item_at("weapon", p)
	for i in Mng.potions_in_maze:
		var index = i if randf() > 0.2 else randi_range(0, possible_data_locations.size()-1)
		var p : Vector2i = possible_data_locations[index]
		possible_data_locations.remove_at(index)
		place_item_at("potion", p)
	for i in Mng.food_in_maze:
		var index = i if randf() > 0.2 else randi_range(0, possible_data_locations.size()-1)
		var p : Vector2i = possible_data_locations[index]
		possible_data_locations.remove_at(index)
		place_item_at("food", p)
	
	var possible_prop_locations = (data.corner_points + data.end_points + data.one_wall_points).duplicate()
	for i in Mng.props_in_maze:
		var index = randi_range(0, possible_prop_locations.size()-1)
		var p : Vector2i = possible_prop_locations[index]
		possible_prop_locations.remove_at(index)
		place_prop(data, p)
	
	var possible_trap_locations = (data.straight_points + data.open_points).duplicate()
	for i in Mng.traps_in_maze:
		var index = randi_range(0, possible_trap_locations.size()-1)
		var p : Vector2i = possible_trap_locations[index]
		possible_trap_locations.remove_at(index)
		place_trap(data, p)


func place_item_at(item_type: String, data_pos: Vector2i):
	var pick_up := preload("res://instances/pick_up.tscn").instantiate()
	pick_ups.add_child(pick_up)
	pick_up.maze = self
	match item_type:
		"food": pick_up.set_as_food()
		"weapon": pick_up.set_as_weapon()
		"potion": pick_up.set_as_potion()
	pick_up.position = Utl.data_to_global(data_pos) + Vector2(0, 4)

func place_prop(data: MazeGenData, data_pos: Vector2i):
	var prop := preload("res://instances/pick_up.tscn").instantiate()
	pick_ups.add_child(prop)
	prop.maze = self
	prop.set_as_prop()
	var map_pos_center = Utl.data_to_map(data_pos)
	
	var off : Vector2i
	var closest_wall = Vector2i.UP
	var dirs := [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
	dirs.shuffle()
	for dir in dirs:
		if data.btm_walls.get_bitv(data_pos + dir):
			closest_wall = dir
			break
	
	match closest_wall:
		Vector2i.UP: off = Vector2(randi_range(-1,1), -1)
		Vector2i.DOWN: off = Vector2(randi_range(-1,1), 1)
		Vector2i.LEFT: off = Vector2(-1, randi_range(-1,1))
		Vector2i.RIGHT: off = Vector2(1, randi_range(-1,1))
	
	prop.position = Utl.map_to_global(map_pos_center + off) + Vector2(0, 4)


func place_trap(data: MazeGenData, data_pos: Vector2i):
	var trap := preload("res://instances/trap.tscn").instantiate()
	pick_ups.add_child(trap)
	trap.position = Utl.data_to_global(data_pos)


func apply_light_fx(_duration) -> void:
	if tw_light_fx:
		tw_light_fx.kill()
	is_darkness_on = false
	set_darkness()
	tw_light_fx = create_tween().bind_node(self)
	tw_light_fx.tween_interval(_duration)
	await tw_light_fx.finished
	is_darkness_on = true


func _set_do_it(val):
	do_it = val
	if !is_node_ready(): return
	Mng.generate_maze_data(Mng.calculate_maze_dim_from_level())
	generate()
func _set_maze_dimensions(val) -> void:
	maze_dimensions = val
	if !is_node_ready(): return
	if maze_dimensions.x %2 == 0: maze_dimensions.x += 1
	if maze_dimensions.y %2 == 0: maze_dimensions.y += 1
func _set_level(val):
	level = val
	if !is_node_ready(): return
func _set_is_darkness_on(val) -> void:
	is_darkness_on = val
	if !is_node_ready(): return
	set_darkness()
func _set_map_seed(val):
	map_seed = val
	if !is_node_ready(): return
	Mng.main_seed = map_seed
func stop_tweens() -> void:
	if tw_light_fx:
		if Mng.is_cutscene:
			tw_light_fx.pause()
		else:
			tw_light_fx.play()
