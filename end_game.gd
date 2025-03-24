extends Node2D

func _ready():
	var label = $Label
	match Global.game_result:
		"win_full":
			label.text = "You Win!\nCollected 26 Cards"
		"win_empty":
			label.text = "You Win!\nAI Hand Empty"
		"lose_full":
			label.text = "You Lose!\nAI Collected 26 Cards"
		"lose_empty":
			label.text = "You Lose!\nYour Hand Empty"
	$Button.connect("pressed", Callable(self, "_on_play_again"))

func _on_play_again():
	get_tree().change_scene_to_file("res://GameScene.tscn")
