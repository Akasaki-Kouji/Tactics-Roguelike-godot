extends Control

var selected_difficulty = 1  # 0=Easy, 1=Normal, 2=Hard

func _ready():
	update_difficulty_display()
	$VBoxContainer/StartButton.grab_focus()

func update_difficulty_display():
	var difficulties = ["イージー", "ノーマル", "ハード"]
	var descriptions = [
		"敵が弱い（基本ステータス -30%）",
		"標準的な難易度",
		"敵が強い（基本ステータス +50%）"
	]

	$VBoxContainer/DifficultyLabel.text = "難易度: " + difficulties[selected_difficulty]
	$VBoxContainer/DescriptionLabel.text = descriptions[selected_difficulty]

func _on_prev_button_pressed():
	selected_difficulty = max(0, selected_difficulty - 1)
	update_difficulty_display()

func _on_next_button_pressed():
	selected_difficulty = min(2, selected_difficulty + 1)
	update_difficulty_display()

func _on_start_button_pressed():
	var game_manager = get_node("/root/GameManager")
	if game_manager == null:
		print("Error: GameManager not found")
		return

	# 難易度をenumに変換
	var difficulty_enum = game_manager.Difficulty.EASY
	match selected_difficulty:
		0:
			difficulty_enum = game_manager.Difficulty.EASY
		1:
			difficulty_enum = game_manager.Difficulty.NORMAL
		2:
			difficulty_enum = game_manager.Difficulty.HARD

	game_manager.start_new_game(difficulty_enum)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/home.tscn")
