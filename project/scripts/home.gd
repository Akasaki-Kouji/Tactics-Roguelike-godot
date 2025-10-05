extends Control

func _ready():
	var start_button = get_node_or_null("MainLayout/ButtonContainer/StartButton")
	if start_button == null:
		start_button = get_node_or_null("VBoxContainer/StartButton")
	if start_button != null:
		start_button.grab_focus()

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/difficulty_improved.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
