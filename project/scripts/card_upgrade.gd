extends Control

var cards = []
var selected_card = null
var selected_unit_index = -1
var game_manager

func _ready():
	game_manager = get_node("/root/GameManager")
	generate_cards()
	display_cards()

func generate_cards():
	cards.clear()

	# ランダムに3枚のカードを生成
	var card_types = [
		{"name": "HP+5", "type": "hp", "value": 5, "rarity": "standard"},
		{"name": "攻撃+2", "type": "atk", "value": 2, "rarity": "standard"},
		{"name": "防御+2", "type": "def", "value": 2, "rarity": "standard"},
		{"name": "魔防+2", "type": "res", "value": 2, "rarity": "standard"},
		{"name": "速さ+3", "type": "spd", "value": 3, "rarity": "standard"},
		{"name": "技+3", "type": "dex", "value": 3, "rarity": "standard"},
		{"name": "運+3", "type": "lck", "value": 3, "rarity": "standard"},
	]

	for i in range(3):
		cards.append(card_types[randi() % card_types.size()])

func display_cards():
	$CardContainer/Card1.text = cards[0].name
	$CardContainer/Card2.text = cards[1].name
	$CardContainer/Card3.text = cards[2].name

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
			button.text = "%s (HP:%d ATK:%d)" % [unit.name, unit.hp, unit.atk]
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
