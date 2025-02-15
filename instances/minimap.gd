extends PanelContainer
class_name MiniMap

@onready var maze = %maze
@onready var player = %player
@onready var minotaur = %minotaur

const COLOR_BG_WALL = Color("#93604b")
const COLOR_BG_MAZE = Color("#ffffd2")
const COLOR_PLAYER = Color("#ff412f")
const COLOR_MINOTAUR = Color("#ff412f")
const COLOR_PICK_UP = Color("#ff412f")

var player_map_pos := Vector2i()
var minotaur_map_pos := Vector2i()

func _ready():
	from_map_data(Mng.maze_map_data)
	Mng.player_position_updated.connect(update_player)
	Mng.minotaur_position_updated.connect(update_minotaur)

func from_map_data(map_data: MazeMapData):
	var base_img := Image.create(map_data.map_size.x, map_data.map_size.y, true, Image.FORMAT_RGBA8)
	player.texture = ImageTexture.create_from_image(base_img)
	minotaur.texture = ImageTexture.create_from_image(base_img)
	for x in map_data.map_size.x:
		for y in map_data.map_size.y:
			var p = Vector2i(x, y)
			base_img.set_pixelv(p, COLOR_BG_MAZE if map_data.btm_maze_floor.get_bitv(p) else COLOR_BG_WALL)
	maze.texture = ImageTexture.create_from_image(base_img)
	maze.custom_minimum_size = maze.texture.get_size() * 1


func update_player(new_map_pos: Vector2i):
	var img : Image = player.texture.get_image() as Image
	img.set_pixelv(player_map_pos, Color.TRANSPARENT)
	player_map_pos = new_map_pos
	img.set_pixelv(player_map_pos, COLOR_PLAYER)
	player.texture = ImageTexture.create_from_image(img)
func update_minotaur(new_map_pos: Vector2i):
	var img : Image = minotaur.texture.get_image() as Image
	img.set_pixelv(minotaur_map_pos, Color.TRANSPARENT)
	minotaur_map_pos = new_map_pos
	img.set_pixelv(minotaur_map_pos, COLOR_MINOTAUR)
	minotaur.texture = ImageTexture.create_from_image(img)
