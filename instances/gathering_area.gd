extends Node2D
class_name GatheringArea


var food_gathered : Array[PickUp]

func _ready():
	pass # Replace with function body.



func _on_area_body_entered(body):
	if body is PickUp:
		if body.is_food:
			food_gathered.append(body)
func _on_area_body_exited(body):
	if body is PickUp:
		if body.is_food:
			food_gathered.erase(body)
