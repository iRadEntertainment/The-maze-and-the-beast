extends Resource
class_name MazeMapData

var map_size := Vector2i()
var map_rect := Rect2i()
var astar: AStarGrid2D

@export var btm_maze_floor := BitMap.new()
@export var btm_walls_all := BitMap.new()
@export var btm_walls_top := BitMap.new()
@export var btm_walls_vert := BitMap.new()
@export var list_maze_floor : PackedVector2Array = []
@export var list_walls_all : PackedVector2Array = []
@export var list_walls_top : PackedVector2Array = []
@export var list_walls_vert : PackedVector2Array = []

@export var btm_occupied_tiles := BitMap.new()
@export var btm_pick_ups_food := BitMap.new()
@export var btm_pick_ups_potions := BitMap.new()
@export var btm_pick_ups_weapons := BitMap.new()
