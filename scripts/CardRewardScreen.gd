extends Control

signal card_selected(card_name: String)

@onready var title_label = $MainContainer/VBoxContainer/HeaderContainer/TitleLabel
@onready var subtitle_label = $MainContainer/VBoxContainer/HeaderContainer/SubtitleLabel
@onready var instruction_label = $MainContainer/VBoxContainer/HeaderContainer/InstructionLabel
@onready var deck_info_label = $MainContainer/VBoxContainer/BottomInfoContainer/DeckInfoLabel

@onready var cards_container = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer

@onready var card1_container = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card1Container
@onready var card2_container = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card2Container
@onready var card3_container = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card3Container

@onready var card_panel1 = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card1Container/CardPanel
@onready var card_panel2 = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card2Container/CardPanel
@onready var card_panel3 = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card3Container/CardPanel

@onready var card_placeholder1 = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card1Container/CardPanel/MarginContainer/CardPlaceholder1
@onready var card_placeholder2 = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card2Container/CardPanel/MarginContainer/CardPlaceholder2
@onready var card_placeholder3 = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card3Container/CardPanel/MarginContainer/CardPlaceholder3

@onready var select_button1 = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card1Container/SelectButton1
@onready var select_button2 = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card2Container/SelectButton2
@onready var select_button3 = $MainContainer/VBoxContainer/CardsScrollContainer/CardsContainer/Card3Container/SelectButton3

var card_scene = preload("res://scenes/Card.tscn")
var reward_cards: Array[CardData] = []
var card_instances: Array = []
var card_panels: Array = []
var hovered_card_index: int = -1
var current_deck_size: int = 0

func _ready():
	select_button1.pressed.connect(_on_card1_selected)
	select_button2.pressed.connect(_on_card2_selected)
	select_button3.pressed.connect(_on_card3_selected)

	select_button1.mouse_entered.connect(_on_button1_hover)
	select_button2.mouse_entered.connect(_on_button2_hover)
	select_button3.mouse_entered.connect(_on_button3_hover)
	
	select_button1.mouse_exited.connect(_on_button_unhover.bind(0))
	select_button2.mouse_exited.connect(_on_button_unhover.bind(1))
	select_button3.mouse_exited.connect(_on_button_unhover.bind(2))
	
	card_panels = [card_panel1, card_panel2, card_panel3]
	
	if is_instance_valid(title_label):
		title_label.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(title_label, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)

func show_rewards(deck_size: int = 0):
	current_deck_size = deck_size
	
	if is_instance_valid(deck_info_label):
		deck_info_label.text = "Current Deck Size: %d cards" % current_deck_size
	
	reward_cards = CardDatabase.get_random_reward_cards(3)
	
	_create_card_display(reward_cards[0], card_placeholder1, 0)
	_create_card_display(reward_cards[1], card_placeholder2, 1)
	_create_card_display(reward_cards[2], card_placeholder3, 2)
	
	_animate_entrance()

func _create_card_display(card_data: CardData, placeholder: Control, index: int):
	var card_instance = card_scene.instantiate()
	card_instance.set_card_data(card_data)
	
	placeholder.add_child(card_instance)
	card_instances.append(card_instance)
	
	if card_instance.has_signal("mouse_entered"):
		card_instance.mouse_entered.connect(_on_card_hover.bind(index))
	if card_instance.has_signal("mouse_exited"):
		card_instance.mouse_exited.connect(_on_card_unhover.bind(index))
	
	card_instance.scale = Vector2.ZERO
	card_instance.modulate = Color.TRANSPARENT
	card_instance.rotation = deg_to_rad(randf_range(-15, 15))

func _animate_entrance():
	await get_tree().create_timer(0.5).timeout
	
	for i in range(card_instances.size()):
		var card = card_instances[i]
		var panel = card_panels[i]
		
		if is_instance_valid(card) and is_instance_valid(panel):
			panel.modulate.a = 0.0
			var panel_tween = create_tween()
			panel_tween.tween_property(panel, "modulate:a", 1.0, 0.3)
			
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(card, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(card, "modulate", Color.WHITE, 0.4).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "rotation", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			
			await get_tree().create_timer(0.2).timeout

func _on_button1_hover():
	_on_button_hover(0)

func _on_button2_hover():
	_on_button_hover(1)

func _on_button3_hover():
	_on_button_hover(2)

func _on_button_hover(index: int):
	_highlight_card(index)

func _on_card_hover(index: int):
	_highlight_card(index)

func _on_card_unhover(index: int):
	if hovered_card_index == index:
		_unhighlight_card(index)

func _on_button_unhover(index: int):
	if hovered_card_index == index:
		_unhighlight_card(index)

func _highlight_card(index: int):
	if hovered_card_index == index:
		return
	
	hovered_card_index = index
	
	var card = card_instances[index] if index < card_instances.size() else null
	var panel = card_panels[index] if index < card_panels.size() else null
	
	if is_instance_valid(card):
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "scale", Vector2(1.03, 1.03), 0.2)
		tween.tween_property(card, "modulate", Color(1.05, 1.05, 1.08, 1.0), 0.2)
		
	if is_instance_valid(panel):
		var panel_tween = create_tween()
		panel_tween.tween_property(panel, "position:y", panel.position.y - 4, 0.2)
	
	for i in range(card_instances.size()):
		if i != index:
			var other_card = card_instances[i]
			if is_instance_valid(other_card):
				var dim_tween = create_tween()
				dim_tween.tween_property(other_card, "modulate", Color(0.88, 0.88, 0.92, 1.0), 0.2)

func _unhighlight_card(index: int):
	hovered_card_index = -1
	
	var card = card_instances[index] if index < card_instances.size() else null
	var panel = card_panels[index] if index < card_panels.size() else null
	
	if is_instance_valid(card):
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "modulate", Color.WHITE, 0.15)
	
	if is_instance_valid(panel):
		var panel_tween = create_tween()
		panel_tween.tween_property(panel, "position:y", 0, 0.15).set_ease(Tween.EASE_OUT)
	
	for i in range(card_instances.size()):
		if i != index:
			var other_card = card_instances[i]
			if is_instance_valid(other_card):
				var restore_tween = create_tween()
				restore_tween.tween_property(other_card, "modulate", Color.WHITE, 0.15)

func _on_card1_selected():
	_select_card(0)

func _on_card2_selected():
	_select_card(1)

func _on_card3_selected():
	_select_card(2)

func _select_card(index: int):
	if index >= 0 and index < reward_cards.size():
		var selected_card = reward_cards[index]
		
		_disable_all_buttons()
		
		if is_instance_valid(subtitle_label):
			subtitle_label.text = "Card Added to Deck!"
		
		if is_instance_valid(instruction_label):
			instruction_label.text = "Preparing next battle..."
		
		if is_instance_valid(deck_info_label):
			deck_info_label.text = "Deck Size: %d cards" % (current_deck_size + 1)
		
		await _animate_selection(index)
		
		await get_tree().create_timer(0.5).timeout
		
		card_selected.emit(selected_card.card_name)
		
		queue_free()

func _disable_all_buttons():
	if is_instance_valid(select_button1):
		select_button1.disabled = true
	if is_instance_valid(select_button2):
		select_button2.disabled = true
	if is_instance_valid(select_button3):
		select_button3.disabled = true

func _animate_selection(selected_index: int):
	for i in range(card_instances.size()):
		var card = card_instances[i]
		var panel = card_panels[i]
		
		if not is_instance_valid(card):
			continue
		
		if i == selected_index:
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(card, "scale", Vector2(1.15, 1.15), 0.25).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.25)
			
			if is_instance_valid(panel):
				var panel_tween = create_tween()
				panel_tween.tween_property(panel, "position:y", -10, 0.25).set_ease(Tween.EASE_OUT)
		else:
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(card, "modulate:a", 0.0, 0.25)
			
			if is_instance_valid(panel):
				var panel_tween = create_tween()
				panel_tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	
	await get_tree().create_timer(0.25).timeout
