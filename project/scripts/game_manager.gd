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

	# 難易度に応じて敵のステータスを調整
	var difficulty_multiplier = 1.0
	match current_difficulty:
		Difficulty.EASY:
			difficulty_multiplier = 0.7  # -30%
		Difficulty.NORMAL:
			difficulty_multiplier = 1.0  # 標準
		Difficulty.HARD:
			difficulty_multiplier = 1.5  # +50%

	# 敵ユニット2体（難易度補正適用）
	var soldier_hp = int(18 * difficulty_multiplier)
	var soldier_atk = int(6 * difficulty_multiplier)
	var soldier_def = int(5 * difficulty_multiplier)
	var soldier_res = int(4 * difficulty_multiplier)
	var soldier_spd = int(6 * difficulty_multiplier)
	var soldier_dex = int(7 * difficulty_multiplier)
	var soldier_lck = int(4 * difficulty_multiplier)

	var thief_hp = int(16 * difficulty_multiplier)
	var thief_atk = int(5 * difficulty_multiplier)
	var thief_def = int(3 * difficulty_multiplier)
	var thief_res = int(2 * difficulty_multiplier)
	var thief_spd = int(8 * difficulty_multiplier)
	var thief_dex = int(9 * difficulty_multiplier)
	var thief_lck = int(6 * difficulty_multiplier)

	units.append(create_unit("敵兵士", soldier_hp, soldier_atk, soldier_def, soldier_res, soldier_spd, soldier_dex, soldier_lck, false))
	units.append(create_unit("敵盗賊", thief_hp, thief_atk, thief_def, thief_res, thief_spd, thief_dex, thief_lck, false))

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
		"has_acted": false,
		"has_moved": false
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
			unit.has_moved = false

	# 敵ユニットを削除して新しい敵を生成
	var player_units = []
	for i in range(units.size()):
		if units[i].is_player:
			player_units.append(units[i])

	units.clear()
	units = player_units.duplicate()

	# 難易度に応じた基礎倍率
	var difficulty_multiplier = 1.0
	match current_difficulty:
		Difficulty.EASY:
			difficulty_multiplier = 0.7  # -30%
		Difficulty.NORMAL:
			difficulty_multiplier = 1.0  # 標準
		Difficulty.HARD:
			difficulty_multiplier = 1.5  # +50%

	# ステージに応じて敵を強化
	var enemy_boost = (current_stage - 1) * 3  # ステージごとに全ステータス+3

	# 敵の数も増やす（最大4体まで）
	var enemy_count = min(2 + (current_stage - 1), 4)

	for i in range(enemy_count):
		if i % 2 == 0:
			var base_hp = int((18 + enemy_boost) * difficulty_multiplier)
			var base_atk = int((6 + enemy_boost) * difficulty_multiplier)
			var base_def = int((5 + enemy_boost) * difficulty_multiplier)
			var base_res = int((4 + enemy_boost) * difficulty_multiplier)
			var base_spd = int((6 + enemy_boost) * difficulty_multiplier)
			var base_dex = int((7 + enemy_boost) * difficulty_multiplier)
			var base_lck = int((4 + enemy_boost) * difficulty_multiplier)
			units.append(create_unit("敵兵士Lv%d" % current_stage, base_hp, base_atk, base_def, base_res, base_spd, base_dex, base_lck, false))
		else:
			var base_hp = int((16 + enemy_boost) * difficulty_multiplier)
			var base_atk = int((5 + enemy_boost) * difficulty_multiplier)
			var base_def = int((3 + enemy_boost) * difficulty_multiplier)
			var base_res = int((2 + enemy_boost) * difficulty_multiplier)
			var base_spd = int((8 + enemy_boost) * difficulty_multiplier)
			var base_dex = int((9 + enemy_boost) * difficulty_multiplier)
			var base_lck = int((6 + enemy_boost) * difficulty_multiplier)
			units.append(create_unit("敵盗賊Lv%d" % current_stage, base_hp, base_atk, base_def, base_res, base_spd, base_dex, base_lck, false))

	get_tree().change_scene_to_file("res://scenes/battle.tscn")
