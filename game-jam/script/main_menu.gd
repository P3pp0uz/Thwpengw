extends Control


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/intro_video.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
