extends CharacterBody2D
class_name Player 

@onready var anim = $anim
@onready var sprite = $sprite
@onready var tooltip_can_pick = %tooltip_can_pick
@onready var hold_pos = %hold_pos
@onready var hold_sprite = %hold_sprite
@onready var fx = %fx
@onready var sfx_thud = %sfx_thud
@onready var sfx_bloop = %sfx_bloop
@onready var sfx_scream = %sfx_scream
@onready var sfx_crunch = %sfx_crunch

const TEX_REG = {
	"up": Rect2i(51, 153 ,16, 16),
	"up_lift" : Rect2i(17, 153 ,16, 16),
	"down" : Rect2i(68, 153 ,16, 16),
	"down_lift" : Rect2i(34, 153 ,16, 16),
}

var maze: GeneratedMaze

var dir: Vector2
var dir_last: Vector2
var last_footstep_pos := Vector2()
var map_pos: Vector2i : set = _set_map_pos

var pick_objects_in_range: Array[PickUp] = []
var closest_pickup: PickUp

var is_dead := false
var is_being_eaten := false
var is_holding := false : set = _set_is_holding
var holded_obj: PickUp
var can_action := false : set = _set_can_action

const BASE_SPEED = 180.0
var speed_modifier := 1.0
var loaded_modifier := 0.666
var tw_speed_mod: Tween

func _ready():
	is_dead = false
	is_being_eaten = false
	is_holding = false
	can_action = false
	last_footstep_pos = position
	anim.speed_scale = BASE_SPEED/60.0
	Mng.player = self
	Mng.is_cutscene_changed.connect(stop_tweens)

func _physics_process(d):
	if is_being_eaten or is_dead: return
	if Mng.is_cutscene: return
	dir.x = Input.get_axis("left", "right")
	dir.y = Input.get_axis("up", "down")
	dir = dir.normalized()
	
	velocity = dir * BASE_SPEED * speed_modifier * (loaded_modifier if is_holding else 1.0)
	move_and_slide()
	
	for col_idx in get_slide_collision_count():
		var col := get_slide_collision(col_idx)
		var collider = col.get_collider()
		if collider is RigidBody2D:
			collider.apply_impulse(-col.get_normal() * 100 * d, col.get_position() - collider.global_position)
		if collider is Minotaur:
			collider.velocity = dir * BASE_SPEED * speed_modifier * 0.1
			collider.move_and_slide()

func _process(_d):
	if is_being_eaten or is_dead: return
	if Mng.is_cutscene: return
	if dir != Vector2.ZERO: dir_last = dir
	
	if dir == Vector2.ZERO and anim.current_animation != "idle": anim.play("idle")
	if dir != Vector2.ZERO and anim.current_animation != "walk": anim.play("walk")
	if dir.x != 0: sprite.flip_h = false if dir.x > 0 else true
	
	if dir.y < 0:
		sprite.region_rect = TEX_REG.up if !is_holding else TEX_REG.up_lift
	else:
		sprite.region_rect = TEX_REG.down if !is_holding else TEX_REG.down_lift
	
	footsteps()
	process_map_pos()


func process_map_pos():
	if Mng.global_to_map(position) != map_pos:
		map_pos = Mng.global_to_map(position)


func _input(event):
	if Mng.is_cutscene: return
	
	if event.is_action_pressed("action"):
		if is_holding:
			drop_obj()
		
		if can_action and closest_pickup != null:
			closest_pickup.pick(self)
			sfx_bloop.play()

func drop_obj():
	sfx_thud.play()
	is_holding = false
	holded_obj.position = position + dir_last * Mng.CELL_SIZE
	maze.pick_ups.add_child(holded_obj)
	holded_obj.apply_central_impulse(dir_last * Mng.CELL_SIZE)
	holded_obj = null

func footsteps():
	if position.distance_to(last_footstep_pos) > Mng.CELL_SIZE:
		var footstep = preload("res://instances/footstep.tscn").instantiate()
		footstep.position = position
		footstep.rotation = last_footstep_pos.angle_to_point(position)
		add_sibling(footstep)
		last_footstep_pos = position


func display_new_fx(_ico_region: Rect2i, _duration: float) -> void:
	var new_diplay = preload("res://instances/fx_display.tscn").instantiate()
	new_diplay.region = _ico_region
	new_diplay.duration = _duration
	fx.add_child(new_diplay)

func apply_speed_modifier(_speed: float, _duration: float) -> void:
	if tw_speed_mod:
		tw_speed_mod.kill()
	tw_speed_mod = create_tween().bind_node(self)
	tw_speed_mod.tween_property(self, "speed_modifier", _speed, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw_speed_mod.parallel().tween_interval(_duration)
	tw_speed_mod.tween_property(self, "speed_modifier", 1.0, 1)


func evaluate_closest_pick_up():
	var min_dist = INF
	for obj: PickUp in pick_objects_in_range:
		obj.in_range = false
		var dist = obj.position.distance_squared_to(position)
		if dist < min_dist:
			closest_pickup = obj
			min_dist = dist
	if closest_pickup:
		closest_pickup.in_range = true
	can_action = closest_pickup != null


func die_from_trap(at_pos: Vector2):
	is_dead = true
	sfx_scream.play(0.66)
	sfx_crunch.play(3.80)
	position = at_pos
	await sfx_crunch.finished
	get_tree().reload_current_scene()


func _on_pick_area_body_entered(body):
	if body is PickUp:
		pick_objects_in_range.append(body)
		evaluate_closest_pick_up()
func _on_pick_area_body_exited(body):
	if body is PickUp:
		pick_objects_in_range.erase(body)
		body.in_range = false
	if pick_objects_in_range.is_empty():
		can_action = false

func _set_can_action(val):
	can_action = val
	tooltip_can_pick.visible = can_action
func _set_is_holding(val):
	is_holding = val
	hold_pos.visible = is_holding

func stop_tweens() -> void:
	anim.play("idle")
	if tw_speed_mod:
		if Mng.is_cutscene:
			tw_speed_mod.pause()
		else:
			tw_speed_mod.play()

func _set_map_pos(val):
	map_pos = val
	Mng.player_position_updated.emit(val)
