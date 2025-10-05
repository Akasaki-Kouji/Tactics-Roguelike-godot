extends Control

const GRID_SIZE = 8
const TILE_SIZE = 64
const MOVE_RANGE = 3  # 移動範囲
const ATTACK_RANGE = 1  # 攻撃範囲

var grid = []
var selected_unit = null
var selected_tile = null
var game_manager

var unit_positions = {}  # unit_index -> Vector2i
var move_range_tiles = []  # 移動可能なタイル
var attack_range_tiles = []  # 攻撃可能なタイル

enum ActionMode { NONE, MOVE, ATTACK }
var current_action_mode = ActionMode.NONE

func _ready():
	game_manager = get_node("/root/GameManager")
	if game_manager == null:
		print("Error: GameManager not found")
		return

	print("Battle scene ready")
	print("Units count: ", game_manager.units.size())

	# ステージ番号を更新
	$VBoxContainer/TopBar/StageLabel.text = "ステージ %d" % game_manager.current_stage

	setup_grid()
	place_units()

	# call_deferred を使って描画を次のフレームで実行
	call_deferred("update_display")

func setup_grid():
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			row.append(null)  # null = 空タイル
		grid.append(row)

func place_units():
	# プレイヤーユニットを左側に配置
	var player_units = []
	var enemy_units = []

	for i in range(game_manager.units.size()):
		var unit = game_manager.units[i]
		if unit.is_player:
			player_units.append(i)
		else:
			enemy_units.append(i)

	# プレイヤーユニット配置
	for i in range(player_units.size()):
		var pos = Vector2i(1, 3 + i)
		unit_positions[player_units[i]] = pos
		grid[pos.y][pos.x] = player_units[i]

	# 敵ユニット配置
	for i in range(enemy_units.size()):
		var pos = Vector2i(6, 3 + i)
		unit_positions[enemy_units[i]] = pos
		grid[pos.y][pos.x] = enemy_units[i]

func update_display():
	# グリッド描画
	draw_grid()
	# ユニット情報表示
	update_unit_info()

func draw_grid():
	# 既存の描画をクリア
	var grid_container = $VBoxContainer/GridContainer
	for child in grid_container.get_children():
		child.queue_free()

	# queue_free()は次のフレームで削除されるので、即座にクリア
	await get_tree().process_frame

	grid_container.columns = GRID_SIZE

	print("Drawing grid: ", GRID_SIZE, "x", GRID_SIZE)

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile = create_tile(x, y)
			grid_container.add_child(tile)

	print("Grid drawn, total tiles: ", grid_container.get_child_count())

func create_tile(x: int, y: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)

	var pos = Vector2i(x, y)
	var unit_index = grid[y][x]

	var is_move_range = pos in move_range_tiles
	var is_attack_range = pos in attack_range_tiles
	var is_selected = (pos == selected_tile)

	# StyleBoxFlat を使って背景色を設定
	var style = StyleBoxFlat.new()

	# デフォルトの色
	var bg_color = Color(0.3, 0.3, 0.35)  # 暗い灰色

	# 移動範囲（緑）
	if is_move_range:
		bg_color = Color(0.2, 0.8, 0.3)  # 鮮やかな緑

	# 攻撃範囲（赤）
	if is_attack_range:
		bg_color = Color(0.9, 0.2, 0.2)  # 鮮やかな赤

	style.bg_color = bg_color

	# 選択されたタイルには明るい青色の太い枠線を追加
	if is_selected:
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.3, 0.7, 1.0)  # 明るい青

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)

	# ユニットがいる場合
	if unit_index != null:
		var unit = game_manager.units[unit_index]
		button.text = unit.name[0] if unit.name.length() > 0 else "U"

		# 行動済みの味方ユニットは暗く表示
		if unit.is_player and unit.has_acted:
			# 背景を暗く
			var acted_style = StyleBoxFlat.new()
			acted_style.bg_color = bg_color * 0.4  # 元の色の40%の明るさ

			# 選択枠線も残す
			if is_selected:
				acted_style.border_width_left = 4
				acted_style.border_width_right = 4
				acted_style.border_width_top = 4
				acted_style.border_width_bottom = 4
				acted_style.border_color = Color(0.3, 0.7, 1.0)

			button.add_theme_stylebox_override("normal", acted_style)
			button.add_theme_stylebox_override("hover", acted_style)
			button.add_theme_stylebox_override("pressed", acted_style)
			button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))  # グレー文字
		# テキスト色を設定
		elif is_attack_range and not unit.is_player:
			# 攻撃可能な敵: 黄色い背景に黒文字で超強調
			var attack_style = StyleBoxFlat.new()
			attack_style.bg_color = Color(1.0, 0.9, 0.0)  # 黄色
			button.add_theme_stylebox_override("normal", attack_style)
			button.add_theme_stylebox_override("hover", attack_style)
			button.add_theme_color_override("font_color", Color(0, 0, 0))  # 黒文字
		elif unit.is_player:
			button.add_theme_color_override("font_color", Color(1, 1, 1))  # 白文字
		else:
			button.add_theme_color_override("font_color", Color(1, 1, 1))  # 白文字
	else:
		button.text = ""

	button.pressed.connect(_on_tile_pressed.bind(Vector2i(x, y)))
	button.mouse_entered.connect(_on_tile_hover.bind(Vector2i(x, y)))
	button.mouse_exited.connect(_on_tile_hover_exit)
	return button

func _on_tile_pressed(pos: Vector2i):
	var unit_index = grid[pos.y][pos.x]

	# アクションモードがNONEの場合は、ユニット選択または選択切り替え
	if current_action_mode == ActionMode.NONE:
		if unit_index != null:
			var unit = game_manager.units[unit_index]

			# 敵ユニットの場合は情報表示のみ
			if not unit.is_player:
				var unit_type = "敵"
				$VBoxContainer/UnitInfo.text = "[%s] %s HP:%d/%d ATK:%d DEF:%d RES:%d SPD:%d DEX:%d LCK:%d" % [
					unit_type, unit.name, unit.hp, unit.max_hp, unit.atk, unit.def, unit.res, unit.spd, unit.dex, unit.lck
				]
				return

			# 味方ユニットの場合は選択
			if not unit.has_acted:
				# 別のユニットを選択（選択切り替え）
				selected_unit = unit_index
				selected_tile = pos
				clear_ranges()
				update_action_buttons()
				update_display()
	elif current_action_mode == ActionMode.MOVE:
		# 移動モード
		if unit_index == null and pos in move_range_tiles:
			move_unit(selected_unit, pos)
			selected_tile = pos  # 移動後の位置を更新
			# 移動済みフラグを設定
			game_manager.units[selected_unit].has_moved = true
			clear_ranges()
			current_action_mode = ActionMode.NONE
			# 移動後も選択を維持（攻撃できるように）
			update_action_buttons()
			update_display()
			print("移動完了。攻撃または待機を選択してください")
	elif current_action_mode == ActionMode.ATTACK:
		# 攻撃モード
		if unit_index != null and unit_index != selected_unit and pos in attack_range_tiles:
			var target_unit = game_manager.units[unit_index]
			if target_unit.is_player != game_manager.units[selected_unit].is_player:
				show_combat_preview(selected_unit, unit_index)
				await get_tree().create_timer(0.5).timeout
				attack_unit(selected_unit, unit_index)
				# 攻撃後は自動的に待機（行動終了）
				game_manager.units[selected_unit].has_acted = true
			clear_ranges()
			hide_combat_preview()
			current_action_mode = ActionMode.NONE
			selected_unit = null
			selected_tile = null
			update_action_buttons()
			update_display()

func _on_tile_hover(pos: Vector2i):
	# マウスオーバー時の処理（戦闘予測のみ）
	var unit_index = grid[pos.y][pos.x]

	# 選択中のユニットがいて、攻撃範囲内の敵の場合は戦闘予測を表示
	if unit_index != null and selected_unit != null and pos in attack_range_tiles:
		var unit = game_manager.units[unit_index]
		if not unit.is_player:
			show_combat_preview(selected_unit, unit_index)

func _on_tile_hover_exit():
	# マウスが離れたときの処理（戦闘予測のクリアのみ）
	hide_combat_preview()

func calculate_move_range(from_pos: Vector2i):
	move_range_tiles.clear()

	# 移動範囲を計算（マンハッタン距離）
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var pos = Vector2i(x, y)
			var distance = abs(pos.x - from_pos.x) + abs(pos.y - from_pos.y)

			# 移動範囲
			if distance <= MOVE_RANGE and distance > 0:
				if grid[y][x] == null:  # 空きマスのみ
					move_range_tiles.append(pos)

func calculate_attack_range(from_pos: Vector2i):
	attack_range_tiles.clear()

	if selected_unit == null:
		print("エラー: selected_unit が null です")
		return

	print("攻撃範囲計算: from_pos=", from_pos, " selected_unit=", selected_unit)

	# 現在位置からの攻撃範囲（すべてのマスを表示）
	for dy in range(-ATTACK_RANGE, ATTACK_RANGE + 1):
		for dx in range(-ATTACK_RANGE, ATTACK_RANGE + 1):
			if abs(dx) + abs(dy) <= ATTACK_RANGE and abs(dx) + abs(dy) > 0:
				var attack_pos = Vector2i(from_pos.x + dx, from_pos.y + dy)
				if attack_pos.x >= 0 and attack_pos.x < GRID_SIZE and attack_pos.y >= 0 and attack_pos.y < GRID_SIZE:
					# 攻撃範囲に追加（敵の有無に関わらず表示）
					attack_range_tiles.append(attack_pos)

					# デバッグ：敵がいる場合はログ出力
					var target_index = grid[attack_pos.y][attack_pos.x]
					if target_index != null:
						var target_unit = game_manager.units[target_index]
						var attacker_unit = game_manager.units[selected_unit]
						if target_unit.is_player != attacker_unit.is_player:
							print("  → 攻撃可能な敵: pos=", attack_pos)

func clear_ranges():
	move_range_tiles.clear()
	attack_range_tiles.clear()

func update_action_buttons():
	var move_btn = $VBoxContainer/ActionButtons/MoveButton
	var attack_btn = $VBoxContainer/ActionButtons/AttackButton
	var wait_btn = $VBoxContainer/ActionButtons/WaitButton

	if selected_unit == null:
		# ユニット未選択時は全て無効
		move_btn.disabled = true
		attack_btn.disabled = true
		wait_btn.disabled = true
	else:
		var unit = game_manager.units[selected_unit]
		# 移動済みの場合は移動ボタンを無効化
		move_btn.disabled = unit.has_moved
		attack_btn.disabled = false
		wait_btn.disabled = false

func _on_move_button_pressed():
	if selected_unit != null and selected_tile != null:
		current_action_mode = ActionMode.MOVE
		calculate_move_range(selected_tile)
		print("移動モード: ", move_range_tiles.size(), " タイル")
		update_display()

func _on_attack_button_pressed():
	if selected_unit != null and selected_tile != null:
		current_action_mode = ActionMode.ATTACK
		calculate_attack_range(selected_tile)
		print("攻撃モード: ", attack_range_tiles.size(), " タイル")
		update_display()

func _on_wait_button_pressed():
	if selected_unit != null:
		game_manager.units[selected_unit].has_acted = true
		print("%s が待機しました" % game_manager.units[selected_unit].name)
		selected_unit = null
		selected_tile = null
		current_action_mode = ActionMode.NONE
		clear_ranges()
		update_action_buttons()
		update_display()

func move_unit(unit_index: int, new_pos: Vector2i):
	var old_pos = unit_positions[unit_index]

	# グリッド更新
	grid[old_pos.y][old_pos.x] = null
	grid[new_pos.y][new_pos.x] = unit_index
	unit_positions[unit_index] = new_pos

	print("ユニット移動: ", old_pos, " -> ", new_pos)

func attack_unit(attacker_index: int, target_index: int):
	var attacker = game_manager.units[attacker_index]
	var target = game_manager.units[target_index]

	# 簡易戦闘計算
	var damage = max(1, attacker.atk - target.def)
	target.hp -= damage

	# ダメージ表示
	show_damage_popup(target_index, damage, false)
	print("%s が %s に %d ダメージ" % [attacker.name, target.name, damage])

	await get_tree().create_timer(0.3).timeout

	# 反撃
	if target.hp > 0:
		var counter_damage = max(1, target.atk - attacker.def)
		attacker.hp -= counter_damage
		show_damage_popup(attacker_index, counter_damage, false)
		print("%s が反撃で %d ダメージ" % [target.name, counter_damage])

		await get_tree().create_timer(0.3).timeout

	# 死亡チェック
	if target.hp <= 0:
		print("%s 撃破！" % target.name)
		var pos = unit_positions[target_index]
		grid[pos.y][pos.x] = null
		unit_positions.erase(target_index)

	if attacker.hp <= 0:
		print("%s 戦闘不能！" % attacker.name)
		var pos = unit_positions[attacker_index]
		grid[pos.y][pos.x] = null
		unit_positions.erase(attacker_index)

	attacker.has_acted = true
	check_battle_end()

func show_damage_popup(unit_index: int, damage: int, is_critical: bool):
	# ダメージポップアップを表示（簡易版：ラベルに表示）
	var msg = "-%d" % damage
	if is_critical:
		msg = "クリティカル! " + msg

	# 一時的にユニット情報欄に表示
	var original_text = $VBoxContainer/UnitInfo.text
	$VBoxContainer/UnitInfo.text = msg
	$VBoxContainer/UnitInfo.modulate = Color(1.0, 0.3, 0.3) if not is_critical else Color(1.0, 0.0, 0.0)

	await get_tree().create_timer(0.3).timeout

	$VBoxContainer/UnitInfo.text = original_text
	$VBoxContainer/UnitInfo.modulate = Color(1.0, 1.0, 1.0)

func show_combat_preview(attacker_index: int, target_index: int):
	var attacker = game_manager.units[attacker_index]
	var target = game_manager.units[target_index]

	# ダメージ計算
	var damage = max(1, attacker.atk - target.def)
	var counter_damage = max(1, target.atk - attacker.def)

	# 命中率（簡易）
	var hit_rate = 90 + (attacker.dex - target.spd) * 2
	hit_rate = clamp(hit_rate, 50, 100)

	# クリティカル率
	var crit_rate = attacker.lck - target.lck
	crit_rate = clamp(crit_rate, 0, 50)

	var preview_text = "【戦闘予測】\n"
	preview_text += "%s → %s: %dダメージ (命中%d%% クリ%d%%)\n" % [
		attacker.name, target.name, damage, hit_rate, crit_rate
	]

	if target.hp > damage:
		preview_text += "%s 反撃: %dダメージ" % [target.name, counter_damage]
	else:
		preview_text += "%s 撃破！" % target.name

	$VBoxContainer/CombatPreview.text = preview_text

func hide_combat_preview():
	$VBoxContainer/CombatPreview.text = ""

func update_unit_info():
	if selected_unit != null:
		var unit = game_manager.units[selected_unit]
		var unit_type = "味方" if unit.is_player else "敵"
		$VBoxContainer/UnitInfo.text = "[%s] %s HP:%d/%d ATK:%d DEF:%d RES:%d SPD:%d DEX:%d LCK:%d" % [
			unit_type, unit.name, unit.hp, unit.max_hp, unit.atk, unit.def, unit.res, unit.spd, unit.dex, unit.lck
		]
	else:
		$VBoxContainer/UnitInfo.text = "ユニットを選択してください"

func check_battle_end():
	var player_alive = false
	var enemy_alive = false

	for unit in game_manager.units:
		if unit.hp > 0:
			if unit.is_player:
				player_alive = true
			else:
				enemy_alive = true

	if not enemy_alive:
		print("勝利！")
		get_tree().change_scene_to_file("res://scenes/card_upgrade.tscn")
	elif not player_alive:
		print("敗北...")
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _on_end_turn_pressed():
	# プレイヤーターン終了
	enemy_turn()

func enemy_turn():
	print("敵ターン開始")

	# 改善されたAI: 移動してから攻撃
	for i in range(game_manager.units.size()):
		var unit = game_manager.units[i]
		if not unit.is_player and unit.hp > 0:
			var enemy_pos = unit_positions.get(i)
			if enemy_pos == null:
				continue

			# 最適なターゲットを見つける（HPが低い順）
			var best_target = null
			var best_target_pos = null
			var best_priority = -999

			for j in range(game_manager.units.size()):
				var player = game_manager.units[j]
				if player.is_player and player.hp > 0:
					var player_pos = unit_positions.get(j)
					if player_pos == null:
						continue

					var dist = abs(enemy_pos.x - player_pos.x) + abs(enemy_pos.y - player_pos.y)
					# 優先度: HPが低い敵を優先、距離が近い敵を優先
					var priority = (100 - player.hp) - dist * 5

					if priority > best_priority:
						best_priority = priority
						best_target = j
						best_target_pos = player_pos

			if best_target == null:
				continue

			var current_dist = abs(enemy_pos.x - best_target_pos.x) + abs(enemy_pos.y - best_target_pos.y)

			# 攻撃範囲内にいる場合は攻撃
			if current_dist <= ATTACK_RANGE:
				print("敵%s が攻撃" % unit.name)
				attack_unit(i, best_target)
				await get_tree().create_timer(0.5).timeout
			else:
				# 攻撃範囲外の場合は移動
				var move_target = find_best_move_position(enemy_pos, best_target_pos)
				if move_target != null and move_target != enemy_pos:
					print("敵%s が移動: %s -> %s" % [unit.name, enemy_pos, move_target])
					move_unit(i, move_target)
					enemy_pos = move_target
					await get_tree().create_timer(0.3).timeout
					update_display()

					# 移動後、攻撃範囲内なら攻撃
					var new_dist = abs(enemy_pos.x - best_target_pos.x) + abs(enemy_pos.y - best_target_pos.y)
					if new_dist <= ATTACK_RANGE:
						print("敵%s が移動後攻撃" % unit.name)
						attack_unit(i, best_target)
						await get_tree().create_timer(0.5).timeout

	# プレイヤーターン再開
	for unit in game_manager.units:
		unit.has_acted = false
		unit.has_moved = false

	update_display()
	print("プレイヤーターン")

func find_best_move_position(from_pos: Vector2i, target_pos: Vector2i) -> Vector2i:
	# ターゲットに近づく最適な移動先を見つける
	var best_pos = from_pos
	var best_distance = abs(from_pos.x - target_pos.x) + abs(from_pos.y - target_pos.y)

	# 移動範囲内の全タイルをチェック
	for dy in range(-MOVE_RANGE, MOVE_RANGE + 1):
		for dx in range(-MOVE_RANGE, MOVE_RANGE + 1):
			var move_dist = abs(dx) + abs(dy)
			if move_dist > MOVE_RANGE or move_dist == 0:
				continue

			var new_pos = Vector2i(from_pos.x + dx, from_pos.y + dy)

			# グリッド範囲内かチェック
			if new_pos.x < 0 or new_pos.x >= GRID_SIZE or new_pos.y < 0 or new_pos.y >= GRID_SIZE:
				continue

			# 空きマスかチェック
			if grid[new_pos.y][new_pos.x] != null:
				continue

			# ターゲットまでの距離を計算
			var distance = abs(new_pos.x - target_pos.x) + abs(new_pos.y - target_pos.y)

			# より近い位置を選択
			if distance < best_distance:
				best_distance = distance
				best_pos = new_pos

	return best_pos
