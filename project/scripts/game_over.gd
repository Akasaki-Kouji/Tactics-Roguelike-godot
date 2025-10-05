extends Control

var game_manager

func _ready():
	game_manager = get_node("/root/GameManager")

	# 到達ステージを表示
	var stage_text = "到達ステージ: %d" % game_manager.current_stage
	$VBoxContainer/StageLabel.text = stage_text

	# 難易度を表示
	var difficulty_text = ""
	match game_manager.current_difficulty:
		game_manager.Difficulty.EASY:
			difficulty_text = "難易度: イージー"
		game_manager.Difficulty.NORMAL:
			difficulty_text = "難易度: ノーマル"
		game_manager.Difficulty.HARD:
			difficulty_text = "難易度: ハード"

	$VBoxContainer/DifficultyLabel.text = difficulty_text

func _on_retry_button_pressed():
	# 同じ難易度で最初から
	game_manager.start_new_game(game_manager.current_difficulty)

func _on_home_button_pressed():
	# ホーム画面に戻る
	get_tree().change_scene_to_file("res://scenes/home.tscn")
