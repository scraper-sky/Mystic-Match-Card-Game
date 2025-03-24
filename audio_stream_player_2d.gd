extends AudioStreamPlayer2D

func _ready():
	play()
	finished.connect(_on_music_finished)

func _on_music_finished():
	play()  
	
