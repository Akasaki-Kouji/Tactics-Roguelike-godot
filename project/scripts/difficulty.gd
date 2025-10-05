extends Control

var selected_difficulty = 1  # 0=Easy, 1=Normal, 2=Hard

func _ready():
	update_difficulty_display()
	$VBoxContainer/StartButton.grab_focus()

func update_difficulty_display():
	var difficulties = ["Easy", "Normal", "Hard"]
	$VBoxContainer/DifficultyLabel.text = "難易度: " + difficulties[selected_difficulty]

func _on_prev_button_pressed():
	selected_difficulty = max(0, selected_difficulty - 1)
	update_difficulty_display()

func _on_next_button_pressed():
	selected_difficulty = min(2, selected_difficulty + 1)
	update_difficulty_display()

func _on_start_button_pressed():
	var game_manager = get_node("/root/GameManager")
	if game_manager == null:
		# GameManagerが存在しない場合は作成
		game_manager = load("res://scripts/game_manager.gd").new()
		game_manager.name = "GameManager"
		get_tree().root.add_child(game_manager)
	game_manager.start_new_game(selected_difficulty)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/home.tscn")
