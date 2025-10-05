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
	# プレイヤーユニット2体（攻撃力を大幅に強化）
	units.append(create_unit("騎士", 25, 25, 6, 5, 7, 8, 5, true))
	units.append(create_unit("剣士", 20, 25, 4, 3, 9, 10, 7, true))
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

	# プレイヤーユニットのHPを全回復
	for i in range(units.size()):
		var unit = units[i]
		if unit.is_player and unit.hp > 0:
			unit.hp = unit.max_hp
			unit.has_acted = false

	# 敵ユニットを削除して新しい敵を生成
	var player_units = []
	for i in range(units.size()):
		if units[i].is_player:
			player_units.append(units[i])

	units.clear()
	units = player_units.duplicate()

	# ステージに応じて敵を強化
	var enemy_boost = (current_stage - 1) * 3  # ステージごとに全ステータス+3

	# 敵の数も増やす（最大4体まで）
	var enemy_count = min(2 + (current_stage - 1), 4)

	for i in range(enemy_count):
		if i % 2 == 0:
			units.append(create_unit("敵兵士Lv%d" % current_stage, 18 + enemy_boost, 6 + enemy_boost, 5 + enemy_boost, 4 + enemy_boost, 6 + enemy_boost, 7 + enemy_boost, 4 + enemy_boost, false))
		else:
			units.append(create_unit("敵盗賊Lv%d" % current_stage, 16 + enemy_boost, 5 + enemy_boost, 3 + enemy_boost, 2 + enemy_boost, 8 + enemy_boost, 9 + enemy_boost, 6 + enemy_boost, false))

	get_tree().change_scene_to_file("res://scenes/battle.tscn")
