extends Resource
class_name MazeGen

const dir_card : Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT,Vector2i.RIGHT, Vector2i.DOWN]

static func generate_maze(maze_dim : Vector2i,
						rng_seed : String,
						noise_threshold := 0.6,
						noise_resolution := 15) -> MazeGenData:
#region INIT DATA
	if maze_dim.x%2 != 1:
		maze_dim.x += 1
	if maze_dim.y%2 != 1:
		maze_dim.y += 1
	assert(maze_dim.x%2 == 1 and maze_dim.y%2 == 1, "Make sure that the maze's dimensions are odd")
	var noise := FastNoiseLite.new()
	var rng := RandomNumberGenerator.new()
	noise.seed = hash(rng_seed)
	rng.seed = hash(rng_seed)
	
	var data := MazeGenData.new()
	data.rng_seed = rng_seed
	data.maze_dimensions = maze_dim
	data.btm_boundaries = BitMap.new()
	data.btm_corners = BitMap.new()
	data.btm_corners_removed = BitMap.new()
	data.btm_walls = BitMap.new()
	data.btm_boundaries.create(maze_dim)
	data.btm_corners.create(maze_dim)
	data.btm_corners_removed.create(maze_dim)
	data.btm_walls.create(maze_dim)
	data.list_boundaries = []
	data.list_corners = []
	data.list_corners_removed = []
	data.list_walls = []
	data.corner_points = []
	data.straight_points = []
	data.one_wall_points = []
	data.open_points = []
	data.end_points = []
	
	for x in maze_dim.x:
		for y in maze_dim.y:
			var p = Vector2i(x,y)
			if x in [0, maze_dim.x-1] or y in [0, maze_dim.y-1]:
				data.btm_boundaries.set_bitv(p, true)
				data.list_boundaries.append(p)
			elif x%2 == 0 and y%2 == 0:
				data.btm_corners.set_bitv(p, true)
				data.list_corners.append(p)
			elif (x%2 == 0 and y%2 != 0) or (x%2 != 0 and y%2 == 0):
				data.btm_walls.set_bitv(p, true)
				data.list_walls.append(p)
	
	data.btm_maze = BitMap.new()
	data.btm_maze.create(maze_dim)
	data.list_maze = []
	
#endregion
	
#region MAZE GEN
	# --- initial cell
	var list_walls_to_be_checked : Array[Vector2i] = []
	var cell = Vector2i()
	@warning_ignore("integer_division")
	cell.x = rng.randi_range(0, (maze_dim.x/2)-1) * 2 + 1
	@warning_ignore("integer_division")
	cell.y = rng.randi_range(0, (maze_dim.y/2)-1) * 2 + 1
	cell = Vector2i(1,1)
	data.btm_maze.set_bitv(cell, true)
	data.list_maze.append(cell)
	
	# --- initial list of walls to be checked
	for d in dir_card:
		var n_p = cell + d
		if data.btm_boundaries.get_bitv(n_p): continue
		list_walls_to_be_checked.append(n_p)
	
	while list_walls_to_be_checked.size() > 0:
		var wall_id = rng.randi_range(0, list_walls_to_be_checked.size()-1)
		var possible_passage = list_walls_to_be_checked.pop_at(wall_id)
		
		var n_cells = []
		for d in dir_card:
			var n_p = possible_passage + d
			if data.btm_maze.get_bitv(n_p):
				n_cells.append(n_p)
		
		# --- if the possible passage has only one maze cell adjacent then do the thing
		if n_cells.size() == 1:
			var dir = n_cells[0] - possible_passage
			var next_cell = possible_passage - dir
			data.btm_walls.set_bitv(possible_passage, false)
			data.btm_maze.set_bitv(possible_passage, true)
			data.btm_maze.set_bitv(next_cell, true)
			data.list_maze.append(possible_passage)
			data.list_maze.append(next_cell)
			
			# --- adding new walls to be checked
			for d in dir_card:
				var d_pos := next_cell + d as Vector2i
				if data.btm_boundaries.get_bitv(d_pos): continue
				if d_pos == possible_passage: continue
				list_walls_to_be_checked.append(d_pos)
#endregion
#region MAZE MANIPULATION
	#--- reduce amount of walls
	for x in maze_dim.x:
		for y in maze_dim.y:
			var p = Vector2i(x,y)
			if data.btm_walls.get_bitv(p):
				var noise_p = p * noise_resolution
				if (noise.get_noise_2d(noise_p.x, noise_p.y)+1)/2 > noise_threshold:
					data.btm_walls.set_bitv(p, false)
					data.btm_maze.set_bitv(p, true)
					data.list_maze.append(p)
	# --- remove isolated corners
	for x in maze_dim.x:
		for y in maze_dim.y:
			var p = Vector2i(x,y)
			if data.btm_corners.get_bitv(p):
				var has_wall_neigh = false
				for d in dir_card:
					var d_pos := p + d as Vector2i
					if data.btm_walls.get_bitv(d_pos):
						has_wall_neigh = true
						continue
				if !has_wall_neigh:
					data.btm_corners.set_bitv(p, false)
					data.list_corners.erase(p)
					data.btm_corners_removed.set_bitv(p, true)
					data.list_corners_removed.append(p)
					data.btm_maze.set_bitv(p, true)
					data.list_maze.append(p)
	# --- check for path end points, corner points straight point and open points
	for x in maze_dim.x:
		for y in maze_dim.y:
			var p = Vector2i(x,y)
			if x %2 == 1 and y %2 == 1:
				var free_cell_count = 0
				var neighs : Array[Vector2i] = []
				for dir in dir_card:
					var p_to_check = p + dir
					if data.btm_maze.get_bitv(p_to_check):
						neighs.append(p_to_check)
						free_cell_count += 1
				match free_cell_count :
					1: data.end_points.append(p)
					2:
						if neighs[0].x == neighs[1].x or neighs[0].y == neighs[1].y:
							data.straight_points.append(p)
						else:
							data.corner_points.append(p)
					3: data.one_wall_points.append(p)
					4: data.open_points.append(p)
#endregion
	
	return data


static func flood_fill(grid_pos : Vector2i, btm_maze : BitMap, max_steps : int = 6) -> Array[Vector2i]:
	#--- first steps
	var flood : Array[Vector2i] = get_neighbouring_true_cell(grid_pos, btm_maze)
	var steps : Array[int] = []
	for i in flood.size():
		steps.append(1)
	
	var queue := flood.duplicate()
	while !queue.is_empty():
		var next_point = queue.pop_front()
		var next_point_step = steps[flood.find(next_point)]
		if next_point_step == max_steps: continue
		
		var neigh = get_neighbouring_true_cell(next_point, btm_maze)
		for n in neigh:
			if n in flood: continue
			flood.append(n)
			steps.append(next_point_step + 1)
			queue.append(n)
	return flood


static func get_neighbouring_true_cell(_grid_pos : Vector2i, btm : BitMap) -> Array[Vector2i]:
	var n : Array[Vector2i] = []
	var btm_size = btm.get_size()
	for d in dir_card:
		var new_pos : Vector2i = _grid_pos + d
		if new_pos.x < 0 or new_pos.y < 0 or new_pos.x >= btm_size.x or new_pos.y >= btm_size.y: continue
		if btm.get_bitv(new_pos):
			n.append(new_pos)
	return n

static func poly_from_grid_array(grid_array : Array[Vector2i], grid_dim : Vector2i, poly_scale := 60.0) -> PackedVector2Array:
	if grid_array.is_empty(): return []
	var poly : PackedVector2Array = []
	var btm := BitMap.new()
	btm.create(grid_dim)
	for p in grid_array:
		btm.set_bitv(p, true)
	var polys = btm.opaque_to_polygons(Rect2i(Vector2i.ZERO, btm.get_size()), 0.0)
	for p in polys[0]:
		var new_p = p * poly_scale
		poly.append(new_p)
	return poly


static func grid_pos_to_coord(grid_pos : Vector2i) -> String:
	var letter = char(grid_pos.y + KEY_A)
	var num = str(grid_pos.x)
	var coord = "%s%s"%[letter, num]
	return coord
static func coord_to_grid_pos(coord : String) -> Vector2i:
	coord.to_upper()
	var grid_pos = Vector2i()
	var letter : String = coord.left(1)
	#grid_pos.y = letter.unicode_at(0) - KEY_A
	grid_pos.y = letter.to_ascii_buffer()[0] - KEY_A
	grid_pos.x = int(coord.right(coord.length()-1))
	return grid_pos






