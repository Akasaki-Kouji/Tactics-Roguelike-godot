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

	# ランダムに3枚のカードを生成
	var card_types = [
		{"name": "体力強化", "type": "hp", "value": 5, "rarity": "standard", "desc": "最大HP+5\n耐久力が上がる"},
		{"name": "攻撃強化", "type": "atk", "value": 2, "rarity": "standard", "desc": "攻撃力+2\n与ダメージ増加"},
		{"name": "防御強化", "type": "def", "value": 2, "rarity": "standard", "desc": "防御力+2\n物理ダメージ軽減"},
		{"name": "魔防強化", "type": "res", "value": 2, "rarity": "standard", "desc": "魔法防御+2\n魔法ダメージ軽減"},
		{"name": "速さ強化", "type": "spd", "value": 3, "rarity": "standard", "desc": "速さ+3\n回避率上昇"},
		{"name": "技強化", "type": "dex", "value": 3, "rarity": "standard", "desc": "技+3\n命中率上昇"},
		{"name": "運強化", "type": "lck", "value": 3, "rarity": "standard", "desc": "運+3\nクリティカル率上昇"},
	]

	for i in range(3):
		cards.append(card_types[randi() % card_types.size()])

func display_cards():
	print("Displaying cards...")
	print("Card 0: ", cards[0].name, " - ", cards[0].desc)
	print("Card 1: ", cards[1].name, " - ", cards[1].desc)
	print("Card 2: ", cards[2].name, " - ", cards[2].desc)

	# カード1
	var card1_button = $CardContainer/Card1
	card1_button.clip_text = false
	var card1_text = "[%s]\n\n%s" % [cards[0].name, cards[0].desc]
	card1_button.text = card1_text
	apply_card_style(card1_button, cards[0].type)

	# カード2
	var card2_button = $CardContainer/Card2
	card2_button.clip_text = false
	var card2_text = "[%s]\n\n%s" % [cards[1].name, cards[1].desc]
	card2_button.text = card2_text
	apply_card_style(card2_button, cards[1].type)

	# カード3
	var card3_button = $CardContainer/Card3
	card3_button.clip_text = false
	var card3_text = "[%s]\n\n%s" % [cards[2].name, cards[2].desc]
	card3_button.text = card3_text
	apply_card_style(card3_button, cards[2].type)

	print("Cards displayed!")

func apply_card_style(button: Button, card_type: String):
	var style = StyleBoxFlat.new()

	# カードタイプごとに色を設定
	match card_type:
		"hp":
			style.bg_color = Color(0.2, 0.7, 0.3)  # 緑（体力）
		"atk":
			style.bg_color = Color(0.9, 0.3, 0.3)  # 赤（攻撃）
		"def":
			style.bg_color = Color(0.3, 0.5, 0.9)  # 青（防御）
		"res":
			style.bg_color = Color(0.7, 0.3, 0.9)  # 紫（魔防）
		"spd":
			style.bg_color = Color(0.9, 0.8, 0.2)  # 黄色（速さ）
		"dex":
			style.bg_color = Color(0.9, 0.6, 0.2)  # オレンジ（技）
		"lck":
			style.bg_color = Color(0.9, 0.5, 0.7)  # ピンク（運）
		_:
			style.bg_color = Color(0.5, 0.5, 0.5)  # グレー（デフォルト）

	# 枠線を追加
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(1, 1, 1, 0.5)  # 白い半透明の枠線

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
	$InfoLabel.text = "カード選択: %s\nユニットを選んでください" % selected_card.name
	show_unit_selection()

func show_unit_selection():
	# ユニット選択UIを表示
	for child in $UnitContainer.get_children():
		child.queue_free()

	for i in range(game_manager.units.size()):
		var unit = game_manager.units[i]
		if unit.is_player and unit.hp > 0:
			var button = Button.new()
			button.custom_minimum_size = Vector2(0, 60)
			button.text = "%s\nHP:%d/%d ATK:%d DEF:%d SPD:%d" % [unit.name, unit.hp, unit.max_hp, unit.atk, unit.def, unit.spd]
			button.pressed.connect(_on_unit_selected.bind(i))
			$UnitContainer.add_child(button)

func _on_unit_selected(unit_index: int):
	selected_unit_index = unit_index
	apply_card()

func apply_card():
	if selected_card == null or selected_unit_index < 0:
		return

	game_manager.apply_card_to_unit(selected_unit_index, selected_card)

	var unit = game_manager.units[selected_unit_index]
	$InfoLabel.text = "%s に %s を付与しました！" % [unit.name, selected_card.name]

	# 次のステージへ進む
	await get_tree().create_timer(1.5).timeout
	game_manager.next_stage()

func _on_skip_button_pressed():
	# カードなしで次へ
	game_manager.next_stage()
