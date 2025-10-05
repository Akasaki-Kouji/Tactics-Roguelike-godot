extends Control

# Medieval Tactics Battle Screen - Improved UI/UX
# Focus: Usability, Accessibility, Medieval European Theme

const GRID_SIZE = 8
const TILE_SIZE = 64
const MOVE_RANGE = 3
const ATTACK_RANGE = 1

# Design tokens - Medieval Theme
const COLOR_PARCHMENT = Color(0.95, 0.92, 0.85)
const COLOR_PANEL = Color(0.93, 0.90, 0.82)
const COLOR_IRON = Color(0.15, 0.15, 0.18)
const COLOR_BRASS = Color(0.72, 0.58, 0.30)
const COLOR_TEXT = Color(0.12, 0.10, 0.08)
const COLOR_MOVE = Color(0.25, 0.45, 0.75, 0.5)  # Blue with transparency
const COLOR_ATTACK = Color(0.85, 0.25, 0.25, 0.5)  # Red with transparency
const COLOR_DANGER = Color(0.90, 0.55, 0.20, 0.5)  # Orange with transparency

var grid = []
var selected_unit = null
var selected_tile = null
var game_manager
var unit_positions = {}
var move_range_tiles = []
var attack_range_tiles = []

enum ActionMode { NONE, MOVE, ATTACK }
var current_action_mode = ActionMode.NONE
var current_turn = 1

func _ready():
	game_manager = get_node("/root/GameManager")
	if game_manager == null:
		print("Error: GameManager not found")
		return

	print("Battle scene (improved) ready")
	print("Units count: ", game_manager.units.size())

	# Setup input handling
	setup_input_actions()

	# Update info bar
	update_info_bar()

	setup_grid()
	place_units()

	call_deferred("update_display")

func _input(event):
	# Keyboard shortcuts for accessibility
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_button_pressed()
	elif event.is_action_pressed("end_turn"):  # Space
		if not $MainLayout/InfoBar/InfoBarMargin/InfoBarContent/EndTurnButton.disabled:
			_on_end_turn_pressed()
	elif event.is_action_pressed("action_move"):  # M
		if not $MainLayout/BattleArea/LeftPanel/ActionPanel/ActionMargin/ActionGrid/MoveButton.disabled:
			_on_move_button_pressed()
	elif event.is_action_pressed("action_attack"):  # A
		if not $MainLayout/BattleArea/LeftPanel/ActionPanel/ActionMargin/ActionGrid/AttackButton.disabled:
			_on_attack_button_pressed()
	elif event.is_action_pressed("action_wait"):  # W
		if not $MainLayout/BattleArea/LeftPanel/ActionPanel/ActionMargin/ActionGrid/WaitButton.disabled:
			_on_wait_button_pressed()

func setup_input_actions():
	# Define input actions programmatically if not in InputMap
	if not InputMap.has_action("end_turn"):
		InputMap.add_action("end_turn")
		var key = InputEventKey.new()
		key.keycode = KEY_SPACE
		InputMap.action_add_event("end_turn", key)

	if not InputMap.has_action("action_move"):
		InputMap.add_action("action_move")
		var key = InputEventKey.new()
		key.keycode = KEY_M
		InputMap.action_add_event("action_move", key)

	if not InputMap.has_action("action_attack"):
		InputMap.add_action("action_attack")
		var key = InputEventKey.new()
		key.keycode = KEY_A
		InputMap.action_add_event("action_attack", key)

	if not InputMap.has_action("action_wait"):
		InputMap.add_action("action_wait")
		var key = InputEventKey.new()
		key.keycode = KEY_W
		InputMap.action_add_event("action_wait", key)

func update_info_bar():
	$MainLayout/InfoBar/InfoBarMargin/InfoBarContent/TurnLabel.text = "ターン %d" % current_turn
	$MainLayout/InfoBar/InfoBarMargin/InfoBarContent/StageLabel.text = "ステージ %d" % game_manager.current_stage

	# Count enemies
	var enemy_count = 0
	for unit in game_manager.units:
		if not unit.is_player and unit.hp > 0:
			enemy_count += 1
	$MainLayout/InfoBar/InfoBarMargin/InfoBarContent/EnemyCountLabel.text = "敵: %d" % enemy_count

func setup_grid():
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			row.append(null)
		grid.append(row)

func place_units():
	var player_units = []
	var enemy_units = []

	for i in range(game_manager.units.size()):
		var unit = game_manager.units[i]
		if unit.is_player:
			player_units.append(i)
		else:
			enemy_units.append(i)

	for i in range(player_units.size()):
		var pos = Vector2i(1, 3 + i)
		unit_positions[player_units[i]] = pos
		grid[pos.y][pos.x] = player_units[i]

	for i in range(enemy_units.size()):
		var pos = Vector2i(6, 3 + i)
		unit_positions[enemy_units[i]] = pos
		grid[pos.y][pos.x] = enemy_units[i]

func update_display():
	draw_grid()
	update_unit_info_panel()
	update_action_buttons()
	update_info_bar()

func draw_grid():
	var grid_container = $MainLayout/BattleArea/GridPanel/GridMargin/GridContainer
	for child in grid_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	grid_container.columns = GRID_SIZE

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile = create_tile(x, y)
			grid_container.add_child(tile)

func create_tile(x: int, y: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)

	var pos = Vector2i(x, y)
	var unit_index = grid[y][x]

	var is_move_range = pos in move_range_tiles
	var is_attack_range = pos in attack_range_tiles
	var is_selected = (pos == selected_tile)

	# Medieval stone tile style with improved range visualization
	var style = StyleBoxFlat.new()

	# Base color: stone tile pattern
	var bg_color = Color(0.65, 0.63, 0.60) if (x + y) % 2 == 0 else Color(0.70, 0.68, 0.65)

	# Improved range visualization with color + pattern
	if is_move_range:
		# Blue glow for movement range
		bg_color = COLOR_MOVE
		style.draw_center = true
	elif is_attack_range:
		# Red glow for attack range
		bg_color = COLOR_ATTACK
		style.draw_center = true

	style.bg_color = bg_color

	# Selected tile: gold border
	if is_selected:
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = COLOR_BRASS
	else:
		# Normal tiles: subtle iron border
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = COLOR_IRON

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)

	# Unit display
	if unit_index != null:
		var unit = game_manager.units[unit_index]
		button.text = unit.name[0] if unit.name.length() > 0 else "U"

		# Acted units are darkened
		if unit.is_player and unit.has_acted:
			var acted_style = StyleBoxFlat.new()
			acted_style.bg_color = bg_color * 0.4
			acted_style.border_width_left = style.border_width_left
			acted_style.border_width_right = style.border_width_right
			acted_style.border_width_top = style.border_width_top
			acted_style.border_width_bottom = style.border_width_bottom
			acted_style.border_color = style.border_color
			button.add_theme_stylebox_override("normal", acted_style)
			button.add_theme_stylebox_override("hover", acted_style)
			button.add_theme_stylebox_override("pressed", acted_style)
			button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		elif is_attack_range and not unit.is_player:
			# Attackable enemy: yellow highlight
			var attack_style = StyleBoxFlat.new()
			attack_style.bg_color = Color(1.0, 0.9, 0.0)
			attack_style.border_width_left = 3
			attack_style.border_width_right = 3
			attack_style.border_width_top = 3
			attack_style.border_width_bottom = 3
			attack_style.border_color = COLOR_BRASS
			button.add_theme_stylebox_override("normal", attack_style)
			button.add_theme_stylebox_override("hover", attack_style)
			button.add_theme_color_override("font_color", COLOR_IRON)
		else:
			button.add_theme_color_override("font_color", COLOR_TEXT)
	else:
		button.text = ""

	button.pressed.connect(_on_tile_pressed.bind(pos))
	button.mouse_entered.connect(_on_tile_hover.bind(pos))
	button.mouse_exited.connect(_on_tile_hover_exit)

	return button

func _on_tile_pressed(pos: Vector2i):
	var unit_index = grid[pos.y][pos.x]

	if current_action_mode == ActionMode.NONE:
		if unit_index != null:
			var unit = game_manager.units[unit_index]

			if not unit.is_player:
				# Show enemy info
				update_unit_info_panel_for_unit(unit_index)
				return

			if not unit.has_acted:
				selected_unit = unit_index
				selected_tile = pos
				clear_ranges()
				update_action_buttons()
				update_display()
	elif current_action_mode == ActionMode.MOVE:
		if unit_index == null and pos in move_range_tiles:
			move_unit(selected_unit, pos)
			selected_tile = pos
			game_manager.units[selected_unit].has_moved = true
			clear_ranges()
			current_action_mode = ActionMode.NONE
			update_action_buttons()
			update_display()
	elif current_action_mode == ActionMode.ATTACK:
		if unit_index != null and unit_index != selected_unit and pos in attack_range_tiles:
			var target_unit = game_manager.units[unit_index]
			if target_unit.is_player != game_manager.units[selected_unit].is_player:
				show_combat_preview(selected_unit, unit_index, pos)
				await get_tree().create_timer(0.5).timeout
				attack_unit(selected_unit, unit_index)
				game_manager.units[selected_unit].has_acted = true
			clear_ranges()
			hide_combat_preview()
			current_action_mode = ActionMode.NONE
			selected_unit = null
			selected_tile = null
			update_action_buttons()
			update_display()

func _on_tile_hover(pos: Vector2i):
	var unit_index = grid[pos.y][pos.x]

	if unit_index != null and selected_unit != null and pos in attack_range_tiles:
		var unit = game_manager.units[unit_index]
		if not unit.is_player:
			show_combat_preview(selected_unit, unit_index, pos)

func _on_tile_hover_exit():
	hide_combat_preview()

func update_unit_info_panel():
	if selected_unit != null:
		update_unit_info_panel_for_unit(selected_unit)
	else:
		$MainLayout/BattleArea/LeftPanel/UnitInfoPanel/UnitInfoMargin/UnitInfoContent/UnitNameLabel.text = "ユニット情報"
		$MainLayout/BattleArea/LeftPanel/UnitInfoPanel/UnitInfoMargin/UnitInfoContent/UnitStatsLabel.text = "ユニットを選択してください"

func update_unit_info_panel_for_unit(unit_index: int):
	var unit = game_manager.units[unit_index]
	var unit_type = "味方" if unit.is_player else "敵"

	$MainLayout/BattleArea/LeftPanel/UnitInfoPanel/UnitInfoMargin/UnitInfoContent/UnitNameLabel.text = "[%s] %s" % [unit_type, unit.name]
	$MainLayout/BattleArea/LeftPanel/UnitInfoPanel/UnitInfoMargin/UnitInfoContent/UnitStatsLabel.text = "HP: %d/%d
ATK: %d  DEF: %d
RES: %d  SPD: %d
DEX: %d  LCK: %d" % [
		unit.hp, unit.max_hp,
		unit.atk, unit.def,
		unit.res, unit.spd,
		unit.dex, unit.lck
	]

func update_action_buttons():
	var move_btn = $MainLayout/BattleArea/LeftPanel/ActionPanel/ActionMargin/ActionGrid/MoveButton
	var attack_btn = $MainLayout/BattleArea/LeftPanel/ActionPanel/ActionMargin/ActionGrid/AttackButton
	var wait_btn = $MainLayout/BattleArea/LeftPanel/ActionPanel/ActionMargin/ActionGrid/WaitButton
	var cancel_btn = $MainLayout/BattleArea/LeftPanel/ActionPanel/ActionMargin/ActionGrid/CancelButton

	if selected_unit == null:
		move_btn.disabled = true
		attack_btn.disabled = true
		wait_btn.disabled = true
		cancel_btn.disabled = true
	else:
		var unit = game_manager.units[selected_unit]
		move_btn.disabled = unit.has_moved
		attack_btn.disabled = false
		wait_btn.disabled = false
		cancel_btn.disabled = (current_action_mode == ActionMode.NONE)

func _on_move_button_pressed():
	if selected_unit != null and selected_tile != null:
		current_action_mode = ActionMode.MOVE
		calculate_move_range(selected_tile)
		update_display()

func _on_attack_button_pressed():
	if selected_unit != null and selected_tile != null:
		current_action_mode = ActionMode.ATTACK
		calculate_attack_range(selected_tile)
		update_display()

func _on_wait_button_pressed():
	if selected_unit != null:
		game_manager.units[selected_unit].has_acted = true
		selected_unit = null
		selected_tile = null
		current_action_mode = ActionMode.NONE
		clear_ranges()
		update_action_buttons()
		update_display()

func _on_cancel_button_pressed():
	if current_action_mode != ActionMode.NONE:
		current_action_mode = ActionMode.NONE
		clear_ranges()
		update_action_buttons()
		update_display()

func calculate_move_range(from_pos: Vector2i):
	move_range_tiles.clear()

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var pos = Vector2i(x, y)
			var distance = abs(pos.x - from_pos.x) + abs(pos.y - from_pos.y)

			if distance <= MOVE_RANGE and distance > 0:
				if grid[y][x] == null:
					move_range_tiles.append(pos)

func calculate_attack_range(from_pos: Vector2i):
	attack_range_tiles.clear()

	for dy in range(-ATTACK_RANGE, ATTACK_RANGE + 1):
		for dx in range(-ATTACK_RANGE, ATTACK_RANGE + 1):
			if abs(dx) + abs(dy) <= ATTACK_RANGE and abs(dx) + abs(dy) > 0:
				var attack_pos = Vector2i(from_pos.x + dx, from_pos.y + dy)
				if attack_pos.x >= 0 and attack_pos.x < GRID_SIZE and attack_pos.y >= 0 and attack_pos.y < GRID_SIZE:
					attack_range_tiles.append(attack_pos)

func clear_ranges():
	move_range_tiles.clear()
	attack_range_tiles.clear()

func move_unit(unit_index: int, new_pos: Vector2i):
	var old_pos = unit_positions[unit_index]
	grid[old_pos.y][old_pos.x] = null
	grid[new_pos.y][new_pos.x] = unit_index
	unit_positions[unit_index] = new_pos

func attack_unit(attacker_index: int, target_index: int):
	var attacker = game_manager.units[attacker_index]
	var target = game_manager.units[target_index]

	var damage = max(1, attacker.atk - target.def)
	target.hp -= damage

	await get_tree().create_timer(0.3).timeout

	if target.hp > 0:
		var counter_damage = max(1, target.atk - attacker.def)
		attacker.hp -= counter_damage
		await get_tree().create_timer(0.3).timeout

	if target.hp <= 0:
		var pos = unit_positions[target_index]
		grid[pos.y][pos.x] = null
		unit_positions.erase(target_index)

	if attacker.hp <= 0:
		var pos = unit_positions[attacker_index]
		grid[pos.y][pos.x] = null
		unit_positions.erase(attacker_index)

	attacker.has_acted = true
	check_battle_end()

func show_combat_preview(attacker_index: int, target_index: int, target_pos: Vector2i):
	var attacker = game_manager.units[attacker_index]
	var target = game_manager.units[target_index]

	var damage = max(1, attacker.atk - target.def)
	var counter_damage = max(1, target.atk - attacker.def)

	var preview_text = "【戦闘予測】\n%s → %s: %dダメージ\n" % [attacker.name, target.name, damage]

	if target.hp > damage:
		preview_text += "%s 反撃: %dダメージ" % [target.name, counter_damage]
	else:
		preview_text += "%s 撃破！" % target.name

	$CombatPreviewPopup/PreviewMargin/PreviewLabel.text = preview_text
	$CombatPreviewPopup.visible = true

	# Position near cursor/tile
	var grid_panel = $MainLayout/BattleArea/GridPanel/GridMargin/GridContainer
	var tile_pos = Vector2(target_pos.x * TILE_SIZE, target_pos.y * TILE_SIZE) + grid_panel.global_position
	$CombatPreviewPopup.position = tile_pos + Vector2(TILE_SIZE + 10, 0)

func hide_combat_preview():
	$CombatPreviewPopup.visible = false

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
	enemy_turn()

func enemy_turn():
	print("敵ターン開始")
	current_turn += 1
	update_info_bar()

	# Simplified AI for testing
	for i in range(game_manager.units.size()):
		var unit = game_manager.units[i]
		if not unit.is_player and unit.hp > 0:
			var enemy_pos = unit_positions.get(i)
			if enemy_pos == null:
				continue

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
					var priority = (100 - player.hp) - dist * 5

					if priority > best_priority:
						best_priority = priority
						best_target = j
						best_target_pos = player_pos

			if best_target == null:
				continue

			var current_dist = abs(enemy_pos.x - best_target_pos.x) + abs(enemy_pos.y - best_target_pos.y)

			if current_dist <= ATTACK_RANGE:
				attack_unit(i, best_target)
				await get_tree().create_timer(0.5).timeout
			else:
				var move_target = find_best_move_position(enemy_pos, best_target_pos)
				if move_target != null and move_target != enemy_pos:
					move_unit(i, move_target)
					enemy_pos = move_target
					await get_tree().create_timer(0.3).timeout
					update_display()

					var new_dist = abs(enemy_pos.x - best_target_pos.x) + abs(enemy_pos.y - best_target_pos.y)
					if new_dist <= ATTACK_RANGE:
						attack_unit(i, best_target)
						await get_tree().create_timer(0.5).timeout

	for unit in game_manager.units:
		unit.has_acted = false
		unit.has_moved = false

	update_display()
	print("プレイヤーターン")

func find_best_move_position(from_pos: Vector2i, target_pos: Vector2i) -> Vector2i:
	var best_pos = from_pos
	var best_distance = abs(from_pos.x - target_pos.x) + abs(from_pos.y - target_pos.y)

	for dy in range(-MOVE_RANGE, MOVE_RANGE + 1):
		for dx in range(-MOVE_RANGE, MOVE_RANGE + 1):
			var move_dist = abs(dx) + abs(dy)
			if move_dist > MOVE_RANGE or move_dist == 0:
				continue

			var new_pos = Vector2i(from_pos.x + dx, from_pos.y + dy)

			if new_pos.x < 0 or new_pos.x >= GRID_SIZE or new_pos.y < 0 or new_pos.y >= GRID_SIZE:
				continue

			if grid[new_pos.y][new_pos.x] != null:
				continue

			var distance = abs(new_pos.x - target_pos.x) + abs(new_pos.y - target_pos.y)

			if distance < best_distance:
				best_distance = distance
				best_pos = new_pos

	return best_pos
