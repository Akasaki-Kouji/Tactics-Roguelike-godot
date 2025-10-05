extends Control

var cards = []
var selected_card = null
var selected_unit_index = -1
var game_manager

func _ready():
	game_manager = get_node("/root/GameManager")

	# タイトルにステージクリア情報を追加
	$VBoxContainer/Title.text = "ステージ %d クリア！\n強化カード選択" % (game_manager.current_stage - 1)

	generate_cards()

	# 次のフレームでカードを表示
	call_deferred("display_cards")

func generate_cards():
	cards.clear()

	# コモンカード（70%確率）
	var common_cards = [
		{"name": "体力強化", "type": "hp", "value": 5, "rarity": "common", "desc": "最大HP+5\n耐久力が上がる"},
		{"name": "攻撃強化", "type": "atk", "value": 2, "rarity": "common", "desc": "攻撃力+2\n与ダメージ増加"},
		{"name": "防御強化", "type": "def", "value": 2, "rarity": "common", "desc": "防御力+2\n物理ダメージ軽減"},
		{"name": "魔防強化", "type": "res", "value": 2, "rarity": "common", "desc": "魔法防御+2\n魔法ダメージ軽減"},
		{"name": "速さ強化", "type": "spd", "value": 3, "rarity": "common", "desc": "速さ+3\n回避率上昇"},
		{"name": "技強化", "type": "dex", "value": 3, "rarity": "common", "desc": "技+3\n命中率上昇"},
		{"name": "運強化", "type": "lck", "value": 3, "rarity": "common", "desc": "運+3\nクリティカル率上昇"},
	]

	# レアカード（25%確率）
	var rare_cards = [
		{"name": "大体力強化", "type": "hp", "value": 10, "rarity": "rare", "desc": "最大HP+10\n大幅な耐久力上昇"},
		{"name": "大攻撃強化", "type": "atk", "value": 5, "rarity": "rare", "desc": "攻撃力+5\n大ダメージ増加"},
		{"name": "大防御強化", "type": "def", "value": 5, "rarity": "rare", "desc": "防御力+5\n強力な物理防御"},
		{"name": "大速さ強化", "type": "spd", "value": 6, "rarity": "rare", "desc": "速さ+6\n大幅な回避率上昇"},
		{"name": "バランス強化", "type": "balanced", "value": 2, "rarity": "rare", "desc": "全ステータス+2\nバランス型成長"},
	]

	# エピックカード（5%確率）
	var epic_cards = [
		{"name": "超体力強化", "type": "hp", "value": 15, "rarity": "epic", "desc": "最大HP+15\n圧倒的耐久力"},
		{"name": "超攻撃強化", "type": "atk", "value": 8, "rarity": "epic", "desc": "攻撃力+8\n圧倒的破壊力"},
		{"name": "完全強化", "type": "all", "value": 3, "rarity": "epic", "desc": "全ステータス+3\n完全な成長"},
		{"name": "英雄の証", "type": "hero", "value": 5, "rarity": "epic", "desc": "HP+10 攻撃+5\n英雄の力"},
	]

	# 3枚のカードを確率で生成
	for i in range(3):
		var roll = randf() * 100
		var selected_card

		if roll < 5:  # 5% エピック
			selected_card = epic_cards[randi() % epic_cards.size()]
		elif roll < 30:  # 25% レア (5% + 25% = 30%)
			selected_card = rare_cards[randi() % rare_cards.size()]
		else:  # 70% コモン
			selected_card = common_cards[randi() % common_cards.size()]

		cards.append(selected_card)

func get_rarity_symbol(rarity: String) -> String:
	match rarity:
		"common":
			return "◆"
		"rare":
			return "★"
		"epic":
			return "◇◇◇"
		_:
			return ""

func display_cards():
	print("Displaying cards...")
	print("Card 0: ", cards[0].name, " [", cards[0].rarity, "] - ", cards[0].desc)
	print("Card 1: ", cards[1].name, " [", cards[1].rarity, "] - ", cards[1].desc)
	print("Card 2: ", cards[2].name, " [", cards[2].rarity, "] - ", cards[2].desc)

	# カード1
	var card1_button = $VBoxContainer/CardContainer/Card1
	card1_button.clip_text = false
	var rarity1 = get_rarity_symbol(cards[0].rarity)
	var card1_text = "%s [%s]\n\n%s" % [rarity1, cards[0].name, cards[0].desc]
	card1_button.text = card1_text
	apply_card_style(card1_button, cards[0])

	# カード2
	var card2_button = $VBoxContainer/CardContainer/Card2
	card2_button.clip_text = false
	var rarity2 = get_rarity_symbol(cards[1].rarity)
	var card2_text = "%s [%s]\n\n%s" % [rarity2, cards[1].name, cards[1].desc]
	card2_button.text = card2_text
	apply_card_style(card2_button, cards[1])

	# カード3
	var card3_button = $VBoxContainer/CardContainer/Card3
	card3_button.clip_text = false
	var rarity3 = get_rarity_symbol(cards[2].rarity)
	var card3_text = "%s [%s]\n\n%s" % [rarity3, cards[2].name, cards[2].desc]
	card3_button.text = card3_text
	apply_card_style(card3_button, cards[2])

	print("Cards displayed!")

func apply_card_style(button: Button, card: Dictionary):
	var style = StyleBoxFlat.new()

	# カードタイプごとに基本色を設定
	var base_color = Color(0.5, 0.5, 0.5)  # デフォルト
	match card.type:
		"hp":
			base_color = Color(0.2, 0.7, 0.3)  # 緑（体力）
		"atk":
			base_color = Color(0.9, 0.3, 0.3)  # 赤（攻撃）
		"def":
			base_color = Color(0.3, 0.5, 0.9)  # 青（防御）
		"res":
			base_color = Color(0.7, 0.3, 0.9)  # 紫（魔防）
		"spd":
			base_color = Color(0.9, 0.8, 0.2)  # 黄色（速さ）
		"dex":
			base_color = Color(0.9, 0.6, 0.2)  # オレンジ（技）
		"lck":
			base_color = Color(0.9, 0.5, 0.7)  # ピンク（運）
		"balanced", "all", "hero":
			base_color = Color(0.6, 0.4, 0.8)  # 特殊カード：紫

	# レアリティに応じて色を調整
	match card.rarity:
		"common":
			style.bg_color = base_color * 0.8  # 少し暗く
		"rare":
			style.bg_color = base_color * 1.2  # 少し明るく
		"epic":
			style.bg_color = base_color * 1.5  # かなり明るく

	# レアリティに応じた枠線
	var border_width = 3
	var border_color = Color(1, 1, 1, 0.5)

	match card.rarity:
		"common":
			border_width = 3
			border_color = Color(0.7, 0.7, 0.7, 0.8)  # グレー
		"rare":
			border_width = 5
			border_color = Color(0.2, 0.6, 1.0, 1.0)  # 青
		"epic":
			border_width = 6
			border_color = Color(1.0, 0.8, 0.0, 1.0)  # 金色

	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)

	# テキストを白色で見やすく
	button.add_theme_color_override("font_color", Color(1, 1, 1))

func _on_card_1_pressed():
	select_card(0)

func _on_card_2_pressed():
	select_card(1)

func _on_card_3_pressed():
	select_card(2)

func select_card(index: int):
	selected_card = cards[index]
	$VBoxContainer/InfoLabel.text = "カード選択: %s\nユニットを選んでください" % selected_card.name
	show_unit_selection()

func show_unit_selection():
	# ユニット選択UIを表示
	for child in $VBoxContainer/UnitContainer.get_children():
		child.queue_free()

	for i in range(game_manager.units.size()):
		var unit = game_manager.units[i]
		if unit.is_player and unit.hp > 0:
			var button = Button.new()
			button.custom_minimum_size = Vector2(0, 60)
			button.text = "%s\nHP:%d/%d ATK:%d DEF:%d SPD:%d" % [unit.name, unit.hp, unit.max_hp, unit.atk, unit.def, unit.spd]
			button.pressed.connect(_on_unit_selected.bind(i))
			$VBoxContainer/UnitContainer.add_child(button)

func _on_unit_selected(unit_index: int):
	selected_unit_index = unit_index
	apply_card()

func apply_card():
	if selected_card == null or selected_unit_index < 0:
		return

	game_manager.apply_card_to_unit(selected_unit_index, selected_card)

	var unit = game_manager.units[selected_unit_index]
	$VBoxContainer/InfoLabel.text = "%s に %s を付与しました！" % [unit.name, selected_card.name]

	# 次のステージへ進む
	await get_tree().create_timer(1.5).timeout
	game_manager.next_stage()

func _on_skip_button_pressed():
	# カードなしで次へ
	game_manager.next_stage()
