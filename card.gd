extends Node2D

var suit: String
var number: String

signal card_selected(card)

func _ready():
	$Sprite2D/Label.text = number + " of " + suit
	if has_node("Area2D"):
		var area = $Area2D
		if not area.is_connected("input_event", Callable(self, "_on_area_2d_input_event")):
			area.connect("input_event", Callable(self, "_on_area_2d_input_event"))
			print("Connected input_event for ", number, " of ", suit)
	else:
		print("Error: No Area2D in card!")

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Card clicked: ", number, " of ", suit)
		emit_signal("card_selected", self)
