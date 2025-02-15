# pick_up
@tool
extends Node2D
class_name  PickUp

@onready var sprite = $sprite
@onready var anim = $anim

enum Types{
	RAT, HAND, LEG, TORSO, HEAD, HUNGER, HUNGER_SMALL,
	SWORD, AXE,
	SPEED, LIGHT, SPEED_SMALL, LIGHT_SMALL,
	CRATE, BARREL, CHEST
	}
@export var type : Types : set = _set_type

var maze: GeneratedMaze

var food_hunger_value : float = 0.0
var potion_duration : float = 0.0
var weapon_damage : float = 0.0

var is_food := false
var is_potion := false
var is_weapon := false
var is_prop := false
var in_range := false : set = _set_in_range

const TEX_REGIONS = {
	"rat" : Rect2i(68, 170, 16, 16),
	"hand" : Rect2i(68, 187, 16, 16),
	"leg" : Rect2i(85, 187, 16, 16),
	"torso" : Rect2i(102, 187, 16, 16),
	"head" : Rect2i(136, 187, 16, 16),
	"sword" : Rect2i(136, 136, 16, 16),
	"axe" : Rect2i(136, 136, 16, 16),
	"speed_potion" : Rect2i(102, 153, 16, 16),
	"light_potion" : Rect2i(136, 153, 16, 16),
	"speed_potion_small" : Rect2i(102, 170, 16, 16),
	"light_potion_small" : Rect2i(136, 170, 16, 16),
	"barrel" : Rect2i(170, 102, 16, 16),
	"chest" : Rect2i(85, 119, 16, 16),
	"crate" : Rect2i(51, 85, 16, 16),
}

func _ready():
	sprite.material = sprite.material.duplicate()
	toggle_outline(false)

func set_as_food():
	type = [Types.RAT, Types.HAND, Types.LEG, Types.TORSO, Types.HEAD].pick_random()
	anim.play("levitating")
func set_as_potion():
	type = [Types.SPEED, Types.LIGHT, Types.SPEED_SMALL, Types.LIGHT_SMALL].pick_random()
	anim.play("levitating")
func set_as_weapon():
	type = [Types.SWORD, Types.AXE].pick_random()
	anim.play("levitating")
func set_as_prop():
	type = [Types.BARREL, Types.CHEST, Types.CRATE].pick_random()


func _set_type(val):
	type = val
	if !is_node_ready() and Engine.is_editor_hint(): return
	name = Types.keys()[type]
	is_food = type in [Types.RAT, Types.HAND, Types.LEG, Types.TORSO, Types.HEAD]
	is_potion = type in [Types.SPEED, Types.SPEED_SMALL, Types.LIGHT, Types.LIGHT_SMALL]
	is_weapon = type in [Types.SWORD, Types.AXE]
	is_prop = type in [Types.BARREL, Types.CRATE, Types.CHEST]
	match type:
		Types.RAT:
			sprite.region_rect = TEX_REGIONS.rat
			food_hunger_value = 10.0
		Types.HAND:
			sprite.region_rect = TEX_REGIONS.hand
			food_hunger_value = 13.0
		Types.LEG:
			sprite.region_rect = TEX_REGIONS.leg
			food_hunger_value = 20.0
		Types.TORSO:
			sprite.region_rect = TEX_REGIONS.torso
			food_hunger_value = 25.0
		Types.HEAD:
			sprite.region_rect = TEX_REGIONS.head
			food_hunger_value = 18.0
		Types.SWORD:
			sprite.region_rect = TEX_REGIONS.sword
			weapon_damage = 15.0
		Types.AXE:
			sprite.region_rect = TEX_REGIONS.axe
			weapon_damage = 25.0
		Types.SPEED:
			sprite.region_rect = TEX_REGIONS.speed_potion
			potion_duration = 20.0
		Types.LIGHT:
			sprite.region_rect = TEX_REGIONS.light_potion
			potion_duration = 20.0
		Types.SPEED_SMALL:
			sprite.region_rect = TEX_REGIONS.speed_potion_small
			potion_duration = 10.0
		Types.LIGHT_SMALL:
			sprite.region_rect = TEX_REGIONS.light_potion_small
			potion_duration = 10.0
		Types.BARREL: sprite.region_rect = TEX_REGIONS.barrel
		Types.CHEST: sprite.region_rect = TEX_REGIONS.chest
		Types.CRATE: sprite.region_rect = TEX_REGIONS.crate

func pick(player) -> void:
	if is_prop:
		player.is_holding = true
		player.holded_obj = self
		player.hold_sprite.region_rect = sprite.region_rect
		label_feedback()
		get_parent().remove_child(self)
	if is_food:
		player.is_holding = true
		player.holded_obj = self
		player.hold_sprite.region_rect = sprite.region_rect
		label_feedback()
		get_parent().remove_child(self)
	
	if is_potion:
		match type:
			Types.SPEED:
				player.apply_speed_modifier(2.5, potion_duration)
				player.display_new_fx(sprite.region_rect, potion_duration)
			Types.SPEED_SMALL:
				player.apply_speed_modifier(2.5, potion_duration)
				player.display_new_fx(sprite.region_rect, potion_duration)
			Types.LIGHT:
				maze.apply_light_fx(potion_duration)
				player.display_new_fx(sprite.region_rect, potion_duration)
			Types.LIGHT_SMALL:
				maze.apply_light_fx(potion_duration)
				player.display_new_fx(sprite.region_rect, potion_duration)
		add_consumed_particles()
		label_feedback()
		queue_free()


func label_feedback():
	var feedback_label = preload("res://assets/feedbak_label.tscn").instantiate()
	if is_food:
		feedback_label.text = "Food! +%s hunger"%(food_hunger_value)
	elif is_potion:
		feedback_label.text = "Potion! +%s sec"%(potion_duration)
	elif is_weapon:
		feedback_label.text = "Weapon! Damage: %s"%(weapon_damage)
	elif is_prop:
		feedback_label.text = "Useless stuff!"
	feedback_label.position = position
	add_sibling(feedback_label)

func add_consumed_particles():
	var part = preload("res://instances/consumed_part.tscn").instantiate()
	part.position = position
	add_sibling(part)

func toggle_outline(val: bool) -> void:
	sprite.material.set("shader_parameter/width", 1 if val else 0)

func _set_in_range(val):
	in_range = val
	toggle_outline(in_range)
