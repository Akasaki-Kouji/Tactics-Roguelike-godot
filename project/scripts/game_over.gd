extends Control

var game_manager

func _ready():
	game_manager = get_node("/root/GameManager")

	# 到達ステージを表示
	var stage_text = "到達ステージ: %d" % game_manager.current_stage
	var stage_label = get_node_or_null("MainLayout/ResultsPanel/ResultsMargin/ResultsContent/StageLabel")
	if stage_label == null:
		stage_label = get_node_or_null("VBoxContainer/StageLabel")
	if stage_label != null:
		stage_label.text = stage_text

	# 難易度を表示
	var difficulty_text = ""
	match game_manager.current_difficulty:
		game_manager.Difficulty.EASY:
			difficulty_text = "難易度: Easy"
		game_manager.Difficulty.NORMAL:
			difficulty_text = "難易度: Normal"
		game_manager.Difficulty.HARD:
			difficulty_text = "難易度: Hard"

	var difficulty_label = get_node_or_null("MainLayout/ResultsPanel/ResultsMargin/ResultsContent/DifficultyLabel")
	if difficulty_label == null:
		difficulty_label = get_node_or_null("VBoxContainer/DifficultyLabel")
	if difficulty_label != null:
		difficulty_label.text = difficulty_text

func _on_retry_button_pressed():
	# 同じ難易度で最初から
	game_manager.start_new_game(game_manager.current_difficulty)

func _on_home_button_pressed():
	# ホーム画面に戻る
	get_tree().change_scene_to_file("res://scenes/home_improved.tscn")
