extends Resource
class_name MazeGenData


@export var rng_seed : String
@export var maze_dimensions : Vector2i
@export var btm_boundaries : BitMap
@export var btm_corners : BitMap
@export var btm_corners_removed : BitMap
@export var btm_walls : BitMap
@export var btm_maze : BitMap
@export var list_boundaries : Array[Vector2i]
@export var list_corners : Array[Vector2i]
@export var list_corners_removed : Array[Vector2i]
@export var list_walls : Array[Vector2i]
@export var list_maze : Array[Vector2i]

@export var end_points : Array[Vector2i]
@export var corner_points : Array[Vector2i]
@export var straight_points : Array[Vector2i]
@export var one_wall_points : Array[Vector2i]
@export var open_points : Array[Vector2i]
