extends Node

# ゲーム全体の状態管理
enum Difficulty { EASY, NORMAL, HARD }

var current_difficulty: Difficulty = Difficulty.NORMAL
var inheritance_enabled: bool = true
var tutorial_enabled: bool = true
var current_stage: int = 1

# ユニットデータ
var units: Array = []

func _ready():
	# 初期ユニットを作成
	reset_units()

func reset_units():
	units.clear()
	# プレイヤーユニット2体
	units.append(create_unit("騎士", 25, 8, 6, 5, 7, 8, 5, true))
	units.append(create_unit("剣士", 20, 7, 4, 3, 9, 10, 7, true))
	# 敵ユニット2体
	units.append(create_unit("敵兵士", 18, 6, 5, 4, 6, 7, 4, false))
	units.append(create_unit("敵盗賊", 16, 5, 3, 2, 8, 9, 6, false))

func create_unit(unit_name: String, hp: int, atk: int, def_val: int, res: int, spd: int, dex: int, lck: int, is_player: bool) -> Dictionary:
	return {
		"name": unit_name,
		"hp": hp,
		"max_hp": hp,
		"atk": atk,
		"def": def_val,
		"res": res,
		"spd": spd,
		"dex": dex,
		"lck": lck,
		"is_player": is_player,
		"cards": [],
		"has_acted": false
	}

func start_new_game(difficulty: Difficulty):
	current_difficulty = difficulty
	current_stage = 1
	reset_units()
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func apply_card_to_unit(unit_index: int, card_data: Dictionary):
	if unit_index >= 0 and unit_index < units.size():
		var unit = units[unit_index]
		unit.cards.append(card_data)
		# カード効果を適用
		match card_data.type:
			"hp":
				unit.max_hp += card_data.value
				unit.hp += card_data.value
			"atk":
				unit.atk += card_data.value
			"def":
				unit.def += card_data.value
			"res":
				unit.res += card_data.value
			"spd":
				unit.spd += card_data.value
			"dex":
				unit.dex += card_data.value
			"lck":
				unit.lck += card_data.value

func next_stage():
	current_stage += 1
	# ユニットの行動済みフラグをリセット
	for unit in units:
		unit.has_acted = false
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
