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

# Terrain System - Phase 1
const TERRAIN_TYPES = {
	"plains": {
		"name": "平原",
		"move_cost": 1,
		"height": 0,
		"evasion": 0,
		"defense": 0,
		"walkable": true,
		"projectile_block": false,
		"vision_block": false,
		"color": Color(0.70, 0.68, 0.65),
		"icon": "◇",
		"desc": "平坦な地形"
	},
	"road": {
		"name": "道",
		"move_cost": 1,
		"height": 0,
		"evasion": 0,
		"defense": 0,
		"walkable": true,
		"projectile_block": false,
		"vision_block": false,
		"color": Color(0.60, 0.55, 0.50),
		"icon": "=",
		"desc": "移動しやすい舗装路"
	},
	"forest": {
		"name": "森林",
		"move_cost": 2,
		"height": 0,
		"evasion": 15,
		"defense": 1,
		"walkable": true,
		"projectile_block": false,
		"vision_block": false,
		"color": Color(0.30, 0.55, 0.30),
		"icon": "♠",
		"desc": "回避+15 防御+1"
	},
	"swamp": {
		"name": "沼地",
		"move_cost": 3,
		"height": 0,
		"evasion": -10,
		"defense": 0,
		"walkable": true,
		"projectile_block": false,
		"vision_block": false,
		"wet": true,
		"color": Color(0.45, 0.50, 0.40),
		"icon": "~",
		"desc": "移動困難 回避-10"
	},
	"hill": {
		"name": "丘",
		"move_cost": 2,
		"height": 1,
		"evasion": 10,
		"defense": 2,
		"walkable": true,
		"projectile_block": false,
		"vision_block": false,
		"color": Color(0.65, 0.55, 0.45),
		"icon": "△",
		"desc": "高度+1 回避+10 防御+2"
	},
	"wall": {
		"name": "壁",
		"move_cost": 99,
		"height": 2,
		"evasion": 0,
		"defense": 0,
		"walkable": false,
		"projectile_block": true,
		"vision_block": true,
		"color": Color(0.25, 0.25, 0.28),
		"icon": "█",
		"desc": "通行不可"
	},
	"fire": {
		"name": "炎",
		"move_cost": 2,
		"height": 0,
		"evasion": 0,
		"defense": 0,
		"walkable": true,
		"projectile_block": false,
		"vision_block": false,
		"hazard": "fire",
		"flammable": false,
		"color": Color(0.90, 0.35, 0.15),
		"icon": "🔥",
		"desc": "ターン終了時2ダメージ"
	},
	"poison": {
		"name": "毒沼",
		"move_cost": 3,
		"height": 0,
		"evasion": -10,
		"defense": 0,
		"walkable": true,
		"projectile_block": false,
		"vision_block": false,
		"hazard": "poison",
		"wet": true,
		"color": Color(0.50, 0.30, 0.50),
		"icon": "☠",
		"desc": "ターン終了時1ダメージ"
	}
}

var grid = []
var terrain_map = []  # 2D array of terrain IDs
var selected_unit = null
var selected_tile = null
var game_manager
var unit_positions = {}
var move_range_tiles = []
var attack_range_tiles = []
var hovered_tile = null  # For tooltip
var danger_zone_tiles = []  # Enemy attack ranges
var show_danger_zone = false  # Toggle danger zone visibility

enum ActionMode { NONE, MOVE, ATTACK }
var current_action_mode = ActionMode.NONE
var current_turn = 1
var current_map_id = 0  # Which terrain map to use
var use_procedural = true  # Use procedural generation instead of static maps

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

	# Initialize terrain
	setup_terrain_map()
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
	elif event.is_action_pressed("toggle_danger"):  # D key
		show_danger_zone = not show_danger_zone
		calculate_danger_zones()
		update_display()

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

	if not InputMap.has_action("toggle_danger"):
		InputMap.add_action("toggle_danger")
		var key = InputEventKey.new()
		key.keycode = KEY_D
		InputMap.action_add_event("toggle_danger", key)

func update_info_bar():
	$MainLayout/InfoBar/InfoBarMargin/InfoBarContent/TurnLabel.text = "ターン %d" % current_turn
	$MainLayout/InfoBar/InfoBarMargin/InfoBarContent/StageLabel.text = "ステージ %d" % game_manager.current_stage

	# Count enemies
	var enemy_count = 0
	for unit in game_manager.units:
		if not unit.is_player and unit.hp > 0:
			enemy_count += 1
	$MainLayout/InfoBar/InfoBarMargin/InfoBarContent/EnemyCountLabel.text = "敵: %d" % enemy_count

func setup_terrain_map():
	"""Initialize terrain layout - procedural or static"""
	terrain_map = []

	if use_procedural:
		generate_procedural_map()
		return

	# Map templates (static fallback)
	var maps = [
		# Map 0: Mixed terrain with forest center
		[
			["plains", "road", "road", "plains", "plains", "road", "road", "plains"],
			["plains", "road", "forest", "forest", "forest", "forest", "road", "plains"],
			["plains", "plains", "forest", "forest", "forest", "forest", "plains", "plains"],
			["plains", "plains", "forest", "plains", "plains", "forest", "plains", "plains"],
			["plains", "plains", "forest", "plains", "plains", "forest", "plains", "plains"],
			["plains", "plains", "forest", "forest", "forest", "forest", "plains", "plains"],
			["plains", "road", "forest", "forest", "forest", "forest", "road", "plains"],
			["plains", "road", "road", "plains", "plains", "road", "road", "plains"]
		],
		# Map 1: Hills and swamps with hazards
		[
			["plains", "plains", "swamp", "swamp", "plains", "plains", "plains", "plains"],
			["plains", "hill", "poison", "swamp", "plains", "hill", "plains", "plains"],
			["plains", "hill", "plains", "fire", "plains", "hill", "hill", "plains"],
			["plains", "plains", "plains", "plains", "plains", "plains", "hill", "plains"],
			["plains", "plains", "plains", "plains", "plains", "plains", "plains", "plains"],
			["plains", "hill", "hill", "plains", "fire", "plains", "hill", "plains"],
			["plains", "hill", "plains", "plains", "poison", "swamp", "hill", "plains"],
			["plains", "plains", "plains", "plains", "swamp", "swamp", "plains", "plains"]
		],
		# Map 2: Fortress with walls
		[
			["plains", "plains", "plains", "wall", "wall", "plains", "plains", "plains"],
			["plains", "road", "road", "wall", "wall", "road", "road", "plains"],
			["plains", "road", "plains", "plains", "plains", "plains", "road", "plains"],
			["plains", "road", "plains", "forest", "forest", "plains", "road", "plains"],
			["plains", "road", "plains", "forest", "forest", "plains", "road", "plains"],
			["plains", "road", "plains", "plains", "plains", "plains", "road", "plains"],
			["plains", "road", "road", "wall", "wall", "road", "road", "plains"],
			["plains", "plains", "plains", "wall", "wall", "plains", "plains", "plains"]
		]
	]

	# Select map based on stage or random
	var map_index = (game_manager.current_stage - 1) % maps.size()
	terrain_map = maps[map_index]

	print("Terrain map loaded: Map %d" % map_index)

func setup_grid():
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			row.append(null)
		grid.append(row)

func get_terrain(pos: Vector2i) -> Dictionary:
	"""Get terrain data at position"""
	if pos.x < 0 or pos.x >= GRID_SIZE or pos.y < 0 or pos.y >= GRID_SIZE:
		return TERRAIN_TYPES["wall"]  # Out of bounds = wall

	var terrain_id = terrain_map[pos.y][pos.x]
	return TERRAIN_TYPES[terrain_id]

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
	var terrain = get_terrain(pos)

	var is_move_range = pos in move_range_tiles
	var is_attack_range = pos in attack_range_tiles
	var is_selected = (pos == selected_tile)
	var is_danger_zone = show_danger_zone and (pos in danger_zone_tiles)

	# Medieval stone tile style with terrain colors
	var style = StyleBoxFlat.new()

	# Base color: terrain-specific
	var bg_color = terrain.color
	# Add slight checkerboard variation
	if (x + y) % 2 == 1:
		bg_color = bg_color * 1.1

	# Improved range visualization with color + pattern
	if is_move_range:
		# Blue glow for movement range
		bg_color = COLOR_MOVE
		style.draw_center = true
	elif is_attack_range:
		# Red glow for attack range
		bg_color = COLOR_ATTACK
		style.draw_center = true
	elif is_danger_zone:
		# Orange pattern for enemy danger zones
		bg_color = bg_color.lerp(COLOR_DANGER, 0.4)
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

	# Display terrain icon + unit
	var display_text = ""

	# Terrain icon (small, bottom-right)
	if terrain.icon != "◇":  # Don't show plains icon
		display_text = terrain.icon

	# Unit display (larger, center)
	if unit_index != null:
		var unit = game_manager.units[unit_index]
		var unit_char = unit.name[0] if unit.name.length() > 0 else "U"
		# Show unit on top line, terrain on bottom
		if display_text != "":
			button.text = unit_char + "\n " + display_text
		else:
			button.text = unit_char
		button.add_theme_font_size_override("font_size", 24)

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
		# Empty tile: show terrain icon only
		button.text = display_text
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", COLOR_TEXT * 0.6)

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
	hovered_tile = pos
	var unit_index = grid[pos.y][pos.x]

	# Show combat preview for attackable enemies
	if unit_index != null and selected_unit != null and pos in attack_range_tiles:
		var unit = game_manager.units[unit_index]
		if not unit.is_player:
			show_combat_preview(selected_unit, unit_index, pos)
			return

	# Show terrain tooltip
	show_terrain_tooltip(pos)

func _on_tile_hover_exit():
	hovered_tile = null
	hide_combat_preview()
	hide_terrain_tooltip()

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
	"""Weighted BFS with terrain cost and height"""
	move_range_tiles.clear()

	# Get unit data for jump power (default jump = 1)
	var unit_jump = 1
	if selected_unit != null:
		var unit = game_manager.units[selected_unit]
		# Could add jump stat to units later
		unit_jump = 1

	# BFS with cost tracking
	var queue = []
	var visited = {}  # pos -> remaining_move_points
	var start_terrain = get_terrain(from_pos)

	queue.append({"pos": from_pos, "cost": 0})
	visited[from_pos] = MOVE_RANGE

	while queue.size() > 0:
		var current = queue.pop_front()
		var pos = current.pos
		var accumulated_cost = current.cost

		# Check 4 directions
		var directions = [
			Vector2i(0, -1),  # Up
			Vector2i(0, 1),   # Down
			Vector2i(-1, 0),  # Left
			Vector2i(1, 0)    # Right
		]

		for dir in directions:
			var next_pos = pos + dir

			# Bounds check
			if next_pos.x < 0 or next_pos.x >= GRID_SIZE or next_pos.y < 0 or next_pos.y >= GRID_SIZE:
				continue

			# Skip if occupied
			if grid[next_pos.y][next_pos.x] != null:
				continue

			var next_terrain = get_terrain(next_pos)

			# Check walkable
			if not next_terrain.walkable:
				continue

			# Check height difference (jump check)
			var from_height = get_terrain(pos).height
			var to_height = next_terrain.height
			var height_diff = abs(to_height - from_height)

			if height_diff > unit_jump:
				continue

			# Calculate new cost
			var move_cost = next_terrain.move_cost
			var new_cost = accumulated_cost + move_cost

			# Check if within range
			if new_cost > MOVE_RANGE:
				continue

			# Check if this is a better path
			var remaining = MOVE_RANGE - new_cost
			if next_pos in visited and visited[next_pos] >= remaining:
				continue

			visited[next_pos] = remaining
			queue.append({"pos": next_pos, "cost": new_cost})

	# Convert visited to move_range_tiles (excluding start)
	for pos in visited.keys():
		if pos != from_pos:
			move_range_tiles.append(pos)

func calculate_attack_range(from_pos: Vector2i):
	"""Calculate attack range with line-of-sight check"""
	attack_range_tiles.clear()

	for dy in range(-ATTACK_RANGE, ATTACK_RANGE + 1):
		for dx in range(-ATTACK_RANGE, ATTACK_RANGE + 1):
			if abs(dx) + abs(dy) <= ATTACK_RANGE and abs(dx) + abs(dy) > 0:
				var attack_pos = Vector2i(from_pos.x + dx, from_pos.y + dy)
				if attack_pos.x >= 0 and attack_pos.x < GRID_SIZE and attack_pos.y >= 0 and attack_pos.y < GRID_SIZE:
					# Check line of sight
					if has_line_of_sight(from_pos, attack_pos):
						attack_range_tiles.append(attack_pos)

func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	"""Bresenham line algorithm with projectile_block check"""
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	var sx = 1 if from.x < to.x else -1
	var sy = 1 if from.y < to.y else -1
	var err = dx - dy

	var current = from

	while current != to:
		var e2 = err * 2

		if e2 > -dy:
			err -= dy
			current.x += sx

		if e2 < dx:
			err += dx
			current.y += sy

		# Check if blocked (except the target tile)
		if current != to:
			var terrain = get_terrain(current)
			if terrain.get("projectile_block", false):
				return false

	return true

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

	# Get terrain modifiers
	var attacker_pos = unit_positions[attacker_index]
	var target_pos = unit_positions[target_index]
	var attacker_terrain = get_terrain(attacker_pos)
	var target_terrain = get_terrain(target_pos)

	# Height advantage: +2 damage per height level, max ±4
	var height_diff = attacker_terrain.height - target_terrain.height
	height_diff = clamp(height_diff, -2, 2)
	var height_bonus = height_diff * 2

	# Defense modifier from terrain
	var terrain_def = target_terrain.defense

	# Calculate damage with terrain
	var base_damage = attacker.atk - target.def - terrain_def + height_bonus
	var damage = max(1, base_damage)
	target.hp -= damage

	print("Attack: %s (%d dmg) -> %s | Height: %+d, Terrain Def: %+d" % [
		attacker.name, damage, target.name, height_bonus, terrain_def
	])

	await get_tree().create_timer(0.3).timeout

	if target.hp > 0:
		# Counter attack (reverse height)
		var counter_height_bonus = -height_diff * 2
		var attacker_terrain_def = attacker_terrain.defense
		var counter_base = target.atk - attacker.def - attacker_terrain_def + counter_height_bonus
		var counter_damage = max(1, counter_base)
		attacker.hp -= counter_damage

		print("Counter: %s (%d dmg) -> %s" % [target.name, counter_damage, attacker.name])
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

	# Get terrain modifiers
	var attacker_pos = unit_positions[attacker_index]
	var attacker_terrain = get_terrain(attacker_pos)
	var target_terrain = get_terrain(target_pos)

	# Height advantage
	var height_diff = attacker_terrain.height - target_terrain.height
	height_diff = clamp(height_diff, -2, 2)
	var height_bonus = height_diff * 2

	# Calculate damage with terrain
	var terrain_def = target_terrain.defense
	var base_damage = attacker.atk - target.def - terrain_def + height_bonus
	var damage = max(1, base_damage)

	var counter_height_bonus = -height_diff * 2
	var attacker_terrain_def = attacker_terrain.defense
	var counter_base = target.atk - attacker.def - attacker_terrain_def + counter_height_bonus
	var counter_damage = max(1, counter_base)

	var preview_text = "【戦闘予測】\n%s → %s: %dダメージ" % [attacker.name, target.name, damage]

	# Show terrain effects
	if height_bonus != 0:
		preview_text += " (高度:%+d)" % height_bonus
	if terrain_def != 0:
		preview_text += " (地形防:%+d)" % terrain_def

	preview_text += "\n"

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

func show_terrain_tooltip(pos: Vector2i):
	"""Show terrain information tooltip"""
	var terrain = get_terrain(pos)

	var tooltip_text = "%s %s\n" % [terrain.icon, terrain.name]

	# Add stats
	var stats = []
	if terrain.move_cost != 1:
		stats.append("移動: %d" % terrain.move_cost)
	if terrain.height != 0:
		stats.append("高度: +%d" % terrain.height)
	if terrain.evasion != 0:
		stats.append("回避: %+d" % terrain.evasion)
	if terrain.defense != 0:
		stats.append("防御: +%d" % terrain.defense)
	if not terrain.walkable:
		stats.append("通行不可")

	if stats.size() > 0:
		tooltip_text += " ".join(stats)
	else:
		tooltip_text += terrain.desc

	$CombatPreviewPopup/PreviewMargin/PreviewLabel.text = tooltip_text
	$CombatPreviewPopup.visible = true

	# Position near tile
	var grid_panel = $MainLayout/BattleArea/GridPanel/GridMargin/GridContainer
	var tile_pos = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE) + grid_panel.global_position
	$CombatPreviewPopup.position = tile_pos + Vector2(TILE_SIZE + 10, 0)

func hide_terrain_tooltip():
	# Only hide if not showing combat preview
	if hovered_tile == null:
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
		get_tree().change_scene_to_file("res://scenes/card_upgrade_improved.tscn")
	elif not player_alive:
		print("敗北...")
		get_tree().change_scene_to_file("res://scenes/game_over_improved.tscn")

func _on_end_turn_pressed():
	# Resolve hazards for player units
	resolve_hazards(true)
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

	# Resolve hazards for enemy units
	resolve_hazards(false)

	for unit in game_manager.units:
		unit.has_acted = false
		unit.has_moved = false

	update_display()
	print("プレイヤーターン")

func find_best_move_position(from_pos: Vector2i, target_pos: Vector2i) -> Vector2i:
	var best_pos = from_pos
	var best_distance = abs(from_pos.x - target_pos.x) + abs(from_pos.y - target_pos.y)
	var best_score = -9999.0

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

			# AI evaluation with hazard avoidance
			var score = -distance * 10.0  # Closer is better

			var terrain = get_terrain(new_pos)
			var hazard = terrain.get("hazard", null)

			if hazard != null:
				# Penalize hazardous terrain
				match hazard:
					"fire":
						score -= 30  # Avoid fire heavily
					"poison":
						score -= 20  # Avoid poison moderately
				print("AI評価: %s - ハザード回避 %s (score: %d)" % [new_pos, hazard, int(score)])

			# Prefer high ground
			if terrain.height > 0:
				score += terrain.height * 5

			if score > best_score:
				best_score = score
				best_pos = new_pos
				best_distance = distance

	return best_pos

func resolve_hazards(is_player_phase: bool):
	"""Resolve hazard damage at end of turn"""
	print("ハザード解決フェーズ")

	for i in range(game_manager.units.size()):
		var unit = game_manager.units[i]

		# Only process units of current phase
		if unit.is_player != is_player_phase:
			continue

		if unit.hp <= 0:
			continue

		var pos = unit_positions.get(i)
		if pos == null:
			continue

		var terrain = get_terrain(pos)
		var hazard = terrain.get("hazard", null)

		if hazard != null:
			var damage = 0

			match hazard:
				"fire":
					damage = 2
					print("%s は炎でダメージを受けた！ (2ダメージ)" % unit.name)
				"poison":
					damage = 1
					print("%s は毒でダメージを受けた！ (1ダメージ)" % unit.name)
				"ice":
					# Ice could slow down next turn
					damage = 1
					print("%s は凍結でダメージを受けた！ (1ダメージ)" % unit.name)

			if damage > 0:
				unit.hp -= damage
				await get_tree().create_timer(0.3).timeout

				if unit.hp <= 0:
					print("%s はハザードで倒れた..." % unit.name)
					grid[pos.y][pos.x] = null
					unit_positions.erase(i)

	update_display()
	check_battle_end()

func calculate_danger_zones():
	"""Calculate all enemy attack ranges for danger zone display"""
	danger_zone_tiles.clear()

	if not show_danger_zone:
		return

	for i in range(game_manager.units.size()):
		var unit = game_manager.units[i]
		if not unit.is_player and unit.hp > 0:
			var pos = unit_positions.get(i)
			if pos != null:
				# Calculate enemy attack range
				for dy in range(-ATTACK_RANGE, ATTACK_RANGE + 1):
					for dx in range(-ATTACK_RANGE, ATTACK_RANGE + 1):
						if abs(dx) + abs(dy) <= ATTACK_RANGE and abs(dx) + abs(dy) > 0:
							var attack_pos = Vector2i(pos.x + dx, pos.y + dy)
							if attack_pos.x >= 0 and attack_pos.x < GRID_SIZE and attack_pos.y >= 0 and attack_pos.y < GRID_SIZE:
								if has_line_of_sight(pos, attack_pos):
									if attack_pos not in danger_zone_tiles:
										danger_zone_tiles.append(attack_pos)

# ========================================
# PHASE 3: PROCEDURAL GENERATION
# ========================================

const BIOMES = {
	"plains": {
		"name": "平原",
		"terrain_weights": {
			"plains": 70,
			"road": 10,
			"forest": 15,
			"swamp": 5
		},
		"hazard_chance": 0.02,
		"wall_chance": 0.05
	},
	"forest": {
		"name": "森林",
		"terrain_weights": {
			"plains": 30,
			"forest": 50,
			"swamp": 10,
			"hill": 10
		},
		"hazard_chance": 0.03,
		"wall_chance": 0.05
	},
	"mountain": {
		"name": "山岳",
		"terrain_weights": {
			"plains": 30,
			"hill": 40,
			"wall": 20,
			"road": 10
		},
		"hazard_chance": 0.05,
		"wall_chance": 0.15
	},
	"swampland": {
		"name": "湿地",
		"terrain_weights": {
			"swamp": 50,
			"poison": 20,
			"plains": 20,
			"forest": 10
		},
		"hazard_chance": 0.08,
		"wall_chance": 0.02
	}
}

func generate_procedural_map():
	"""Generate a random map using cellular automata"""
	# Select biome based on stage
	var biome_names = ["plains", "forest", "mountain", "swampland"]
	var biome_id = biome_names[(game_manager.current_stage - 1) % biome_names.size()]
	var biome = BIOMES[biome_id]

	print("生成中: %s バイオーム (ステージ %d)" % [biome.name, game_manager.current_stage])

	# Initialize with base terrain
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			row.append(select_weighted_terrain(biome.terrain_weights))
		terrain_map.append(row)

	# Apply cellular automata for natural clustering
	smooth_terrain_cellular_automata(3)

	# Ensure connectivity
	ensure_map_connectivity()

	# Add hazards based on biome
	add_random_hazards(biome.hazard_chance)

	# Place setpieces
	place_setpieces(biome)

	print("マップ生成完了")

func select_weighted_terrain(weights: Dictionary) -> String:
	"""Select terrain type based on weighted probabilities"""
	var total = 0
	for weight in weights.values():
		total += weight

	var roll = randf() * total
	var accumulated = 0.0

	for terrain_id in weights.keys():
		accumulated += weights[terrain_id]
		if roll <= accumulated:
			return terrain_id

	return "plains"  # Fallback

func smooth_terrain_cellular_automata(iterations: int):
	"""Smooth terrain using cellular automata rules"""
	for iter in range(iterations):
		var new_map = []

		for y in range(GRID_SIZE):
			var row = []
			for x in range(GRID_SIZE):
				# Count neighbor types
				var neighbors = get_neighbor_terrains(x, y)
				var most_common = get_most_common_terrain(neighbors)

				# Keep current or switch to most common
				var current = terrain_map[y][x]
				if neighbors.has(current):
					# Keep if common enough
					var count = neighbors.count(current)
					if count >= 3:
						row.append(current)
					else:
						row.append(most_common)
				else:
					row.append(most_common)

			new_map.append(row)

		terrain_map = new_map

func get_neighbor_terrains(x: int, y: int) -> Array:
	"""Get terrain types of 8 neighbors"""
	var neighbors = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
				neighbors.append(terrain_map[ny][nx])
	return neighbors

func get_most_common_terrain(terrains: Array) -> String:
	"""Find most common terrain in array"""
	var counts = {}
	for terrain in terrains:
		counts[terrain] = counts.get(terrain, 0) + 1

	var max_count = 0
	var most_common = "plains"
	for terrain in counts.keys():
		if counts[terrain] > max_count:
			max_count = counts[terrain]
			most_common = terrain

	return most_common

func ensure_map_connectivity():
	"""Ensure all walkable tiles are connected"""
	# Find start and goal positions (player and enemy spawn areas)
	var start_pos = Vector2i(1, 3)
	var goal_pos = Vector2i(6, 4)

	# BFS to check connectivity
	var visited = {}
	var queue = [start_pos]
	visited[start_pos] = true

	while queue.size() > 0:
		var pos = queue.pop_front()

		for dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var next = pos + dir
			if next.x < 0 or next.x >= GRID_SIZE or next.y < 0 or next.y >= GRID_SIZE:
				continue
			if visited.has(next):
				continue

			var terrain_id = terrain_map[next.y][next.x]
			var terrain_data = TERRAIN_TYPES.get(terrain_id, {})
			if not terrain_data.get("walkable", true):
				continue

			visited[next] = true
			queue.append(next)

	# If goal not reached, create path
	if not visited.has(goal_pos):
		print("接続保証: ゴールへのパスを作成")
		create_path(start_pos, goal_pos)

func create_path(from: Vector2i, to: Vector2i):
	"""Create a walkable path between two points"""
	var current = from
	while current != to:
		# Move towards goal
		if current.x < to.x:
			current.x += 1
		elif current.x > to.x:
			current.x -= 1
		elif current.y < to.y:
			current.y += 1
		elif current.y > to.y:
			current.y -= 1

		# Make walkable
		terrain_map[current.y][current.x] = "road"

func add_random_hazards(chance: float):
	"""Add hazard tiles randomly"""
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if randf() < chance:
				var current = terrain_map[y][x]
				# Don't overwrite important tiles
				if current in ["road", "wall"]:
					continue

				# Choose hazard based on terrain
				if current in ["swamp", "poison"]:
					terrain_map[y][x] = "poison"
				else:
					terrain_map[y][x] = "fire" if randf() < 0.5 else "poison"

func place_setpieces(biome: Dictionary):
	"""Place special structures"""
	# Place 1-2 clusters of walls/obstacles
	var num_obstacles = 1 + (game_manager.current_stage / 3)

	for i in range(num_obstacles):
		var cx = 2 + randi() % (GRID_SIZE - 4)
		var cy = 2 + randi() % (GRID_SIZE - 4)

		# Small 2x2 obstacle
		for dy in range(2):
			for dx in range(2):
				var x = cx + dx
				var y = cy + dy
				if x < GRID_SIZE and y < GRID_SIZE:
					if randf() < biome.wall_chance * 3:
						terrain_map[y][x] = "wall"
