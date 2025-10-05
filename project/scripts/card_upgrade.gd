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
	display_cards()

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
	# カード1
	var card1_text = "[%s]\n\n%s" % [cards[0].name, cards[0].desc]
	$CardContainer/Card1.text = card1_text

	# カード2
	var card2_text = "[%s]\n\n%s" % [cards[1].name, cards[1].desc]
	$CardContainer/Card2.text = card2_text

	# カード3
	var card3_text = "[%s]\n\n%s" % [cards[2].name, cards[2].desc]
	$CardContainer/Card3.text = card3_text

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
