extends Control

@onready var normal_card = $MenuContainer/DifficultyContainer/NormalContainer/NormalCard
@onready var hard_card = $MenuContainer/DifficultyContainer/HardContainer/HardCard
@onready var expert_card = $MenuContainer/DifficultyContainer/ExpertContainer/ExpertCard

@onready var normal_bg = $MenuContainer/DifficultyContainer/NormalContainer/NormalCard/NormalCardBG
@onready var hard_bg = $MenuContainer/DifficultyContainer/HardContainer/HardCard/HardCardBG
@onready var expert_bg = $MenuContainer/DifficultyContainer/ExpertContainer/ExpertCard/ExpertCardBG

@onready var back_button = $MenuContainer/ButtonsContainer/BackButton
@onready var start_button = $MenuContainer/ButtonsContainer/StartButton

@onready var ui_player = $AudioManager/UIPlayer
@onready var hover_player = $AudioManager/HoverPlayer

var selected_difficulty: String = "normal"
var is_transitioning: bool = false

var normal_colors = {
	"selected": Color(0.2, 0.35, 0.5, 1.0),
	"normal": Color(0.15, 0.2, 0.3, 0.9),
	"hover": Color(0.18, 0.25, 0.35, 0.95)
}

var hard_colors = {
	"selected": Color(0.4, 0.25, 0.15, 1.0),
	"normal": Color(0.25, 0.15, 0.1, 0.9),
	"hover": Color(0.3, 0.18, 0.12, 0.95)
}

var expert_colors = {
	"selected": Color(0.45, 0.15, 0.15, 1.0),
	"normal": Color(0.3, 0.1, 0.1, 0.9),
	"hover": Color(0.35, 0.12, 0.12, 0.95)
}

func _ready():
	load_difficulty_data()
	setup_cards()
	setup_buttons()
	_setup_default_selection()
	
	await handle_scene_entrance()
	_ensure_normal_selected()

func load_difficulty_data():
	update_difficulty_card("normal")
	update_difficulty_card("hard")
	update_difficulty_card("expert")

func update_difficulty_card(difficulty: String):
	var player_config = GameBalance.get_player_config(difficulty)
	var ai_config = GameBalance.get_ai_config(difficulty)
	
	var card_content = get_difficulty_content_node(difficulty)
	if not card_content:
		return
	
	var header_label = get_node_by_partial_name(card_content, "Header")
	if header_label:
		header_label.text = difficulty.to_upper()
	
	var player_details = get_node_by_partial_name(card_content, "PlayerDetails")
	if player_details:
		var player_text = str(player_config.hp) + " HP | " + str(player_config.mana) + " Mana\n"
		player_text += str(player_config.cards_per_turn) + " cards per turn | " + str(player_config.hand_size) + " in hand"
		player_details.text = player_text
	
	var ai_details = get_node_by_partial_name(card_content, "AIDetails")
	if ai_details:
		var ai_behavior = get_ai_behavior_description(ai_config)
		var ai_text = str(ai_config.hp) + " HP | " + str(ai_config.mana) + " Mana\n"
		ai_text += str(ai_config.cards_per_turn) + " cards per turn | " + ai_behavior
		ai_details.text = ai_text

func get_ai_behavior_description(ai_config: Dictionary) -> String:
	var aggression = ai_config.get("aggression", 0.5)
	var heal_threshold = ai_config.get("heal_threshold", 0.3)
	
	if aggression >= 0.7:
		return "Aggressive"
	elif aggression <= 0.5:
		return "Defensive"
	elif heal_threshold >= 0.4:
		return "Brutal" 
	else:
		return "Balanced"

func get_difficulty_content_node(difficulty: String) -> Node:
	var container_name = difficulty.capitalize() + "Container"
	var card_name = difficulty.capitalize() + "Card"
	var content_name = difficulty.capitalize() + "Content"
	
	var path = "MenuContainer/DifficultyContainer/" + container_name + "/" + card_name + "/" + content_name
	if has_node(path):
		return get_node(path)
	
	var container_node = get_node("MenuContainer/DifficultyContainer/" + container_name)
	if container_node:
		var card_node = container_node.get_node(card_name)
		if card_node:
			for child in card_node.get_children():
				if "content" in child.name.to_lower() or "vbox" in child.name.to_lower():
					return child
	
	return null

func _setup_default_selection():
	selected_difficulty = "normal"
	
	normal_bg.color = normal_colors.selected
	hard_bg.color = hard_colors.normal
	expert_bg.color = expert_colors.normal
	
	update_start_button_text()
	
	normal_card.modulate = Color(1.1, 1.1, 1.05, 1.0)
	hard_card.modulate = Color(1.0, 1.0, 1.0, 1.0)
	expert_card.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _ensure_normal_selected():
	if selected_difficulty == "normal":
		select_difficulty("normal")
		normal_card.grab_focus()

func handle_scene_entrance():
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		if (TransitionManager.current_overlay.has_method("is_ready") and
			TransitionManager.current_overlay.is_ready() and
			TransitionManager.current_overlay.has_method("is_covering") and
			TransitionManager.current_overlay.is_covering()):
			
			await TransitionManager.current_overlay.fade_out(0.1)
		else:
			play_entrance_animation()
	else:
		play_entrance_animation()

func play_entrance_animation():
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)

	await tween.finished
	animate_cards_entrance()

func animate_cards_entrance():
	var original_normal_color = normal_bg.color
	var original_normal_modulate = normal_card.modulate
	
	normal_card.position.y -= 50
	hard_card.position.y -= 50
	expert_card.position.y -= 50
	normal_card.modulate.a = 0.0
	hard_card.modulate.a = 0.0
	expert_card.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(normal_card, "position:y", normal_card.position.y + 50, 0.4)
	tween.tween_property(normal_card, "modulate:a", original_normal_modulate.a, 0.4)

	await get_tree().create_timer(0.15).timeout

	tween.tween_property(hard_card, "position:y", hard_card.position.y + 50, 0.4)
	tween.tween_property(hard_card, "modulate:a", 1.0, 0.4)
	
	await get_tree().create_timer(0.15).timeout
	tween.tween_property(expert_card, "position:y", expert_card.position.y + 50, 0.4)
	tween.tween_property(expert_card, "modulate:a", 1.0, 0.4)
	
	await tween.finished
	
	normal_bg.color = original_normal_color
	normal_card.modulate = original_normal_modulate

func setup_cards():
	normal_card.focus_mode = Control.FOCUS_ALL
	hard_card.focus_mode = Control.FOCUS_ALL
	expert_card.focus_mode = Control.FOCUS_ALL
	
	normal_card.focus_neighbor_right = hard_card.get_path()
	hard_card.focus_neighbor_left = normal_card.get_path()
	hard_card.focus_neighbor_right = expert_card.get_path()
	expert_card.focus_neighbor_left = hard_card.get_path()
	
	normal_card.focus_neighbor_bottom = start_button.get_path()
	hard_card.focus_neighbor_bottom = start_button.get_path()
	expert_card.focus_neighbor_bottom = start_button.get_path()
	
	normal_card.gui_input.connect(_on_card_input.bind("normal"))
	hard_card.gui_input.connect(_on_card_input.bind("hard"))
	expert_card.gui_input.connect(_on_card_input.bind("expert"))
	
	normal_card.mouse_entered.connect(_on_card_hover.bind("normal"))
	normal_card.mouse_exited.connect(_on_card_unhover.bind("normal"))
	hard_card.mouse_entered.connect(_on_card_hover.bind("hard"))
	hard_card.mouse_exited.connect(_on_card_unhover.bind("hard"))
	expert_card.mouse_entered.connect(_on_card_hover.bind("expert"))
	expert_card.mouse_exited.connect(_on_card_unhover.bind("expert"))
	
	normal_card.focus_entered.connect(_on_card_focus.bind("normal"))
	hard_card.focus_entered.connect(_on_card_focus.bind("hard"))
	expert_card.focus_entered.connect(_on_card_focus.bind("expert"))

func setup_buttons():
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	back_button.focus_neighbor_right = start_button.get_path()
	start_button.focus_neighbor_left = back_button.get_path()

	back_button.focus_neighbor_top = normal_card.get_path()
	start_button.focus_neighbor_top = hard_card.get_path()

	var all_buttons = [back_button, start_button]
	
	for button in all_buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.focus_entered.connect(_on_button_focus.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
		button.focus_exited.connect(_on_button_unfocus.bind(button))

func _on_card_input(event: InputEvent, difficulty: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_difficulty_selected(difficulty)

func _on_card_hover(difficulty: String):
	if selected_difficulty == difficulty:
		return
		
	play_hover_sound()
	
	var card = get_card_node(difficulty)
	var card_bg = get_card_bg(difficulty)
	var colors = get_colors(difficulty)
	
	if card_bg and card:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(card_bg, "color", colors.hover, 0.2)
		tween.tween_property(card, "position:y", card.position.y - 5, 0.2)
		tween.tween_property(card, "scale", Vector2(1.02, 1.02), 0.2)
		tween.tween_property(card, "modulate", Color(1.05, 1.05, 1.05, 1.0), 0.2)

func _on_card_unhover(difficulty: String):
	if selected_difficulty == difficulty:
		return
		
	var card = get_card_node(difficulty)
	var card_bg = get_card_bg(difficulty)
	var colors = get_colors(difficulty)
	
	if card_bg and card:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(card_bg, "color", colors.normal, 0.2)
		tween.tween_property(card, "position:y", card.position.y + 5, 0.2)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)
		tween.tween_property(card, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _on_card_focus(difficulty: String):
	play_hover_sound()
	select_difficulty(difficulty)

func get_card_bg(difficulty: String) -> ColorRect:
	match difficulty:
		"normal":
			return normal_bg
		"hard":
			return hard_bg
		"expert":
			return expert_bg
		_:
			return null

func get_colors(difficulty: String) -> Dictionary:
	match difficulty:
		"normal":
			return normal_colors
		"hard":
			return hard_colors
		"expert":
			return expert_colors
		_:
			return normal_colors

func _on_difficulty_selected(difficulty: String):
	if is_transitioning:
		return
	
	select_difficulty(difficulty)

func select_difficulty(difficulty: String):
	var was_same_difficulty = selected_difficulty == difficulty
	selected_difficulty = difficulty
	
	if not was_same_difficulty:
		play_ui_sound("select")
	
	update_card_colors("normal")
	update_card_colors("hard")
	update_card_colors("expert")
	
	animate_selected_card(difficulty)
	update_start_button_text()

func update_card_colors(difficulty: String):
	var card_bg = get_card_bg(difficulty)
	var card_node = get_card_node(difficulty)
	var colors = get_colors(difficulty)
	
	if not card_bg or not card_node:
		return
	
	var target_color = colors.selected if selected_difficulty == difficulty else colors.normal
	var target_modulate = Color(1.1, 1.1, 1.05, 1.0) if selected_difficulty == difficulty else Color(1.0, 1.0, 1.0, 1.0)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_bg, "color", target_color, 0.3)
	tween.tween_property(card_node, "modulate", target_modulate, 0.3)

func animate_selected_card(difficulty: String):
	var card = get_card_node(difficulty)
	
	if card:
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(card, "scale", Vector2(1.08, 1.08), 0.12)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.12)
		
		var original_modulate = card.modulate
		tween.tween_property(card, "modulate", Color(1.2, 1.2, 1.1, 1.0), 0.1)
		tween.tween_property(card, "modulate", original_modulate, 0.1)

func get_card_node(difficulty: String) -> Control:
	match difficulty:
		"normal":
			return normal_card
		"hard":
			return hard_card
		"expert":
			return expert_card
		_:
			return null

func update_start_button_text():
	var difficulty_name = selected_difficulty.to_upper()
	start_button.text = "PLAY " + difficulty_name
	
	var tween = create_tween()
	tween.tween_property(start_button, "modulate", Color(1.15, 1.15, 1.0, 1.0), 0.1)
	tween.tween_property(start_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _on_back_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 1.0)

func _on_start_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	GameState.selected_difficulty = selected_difficulty
	
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.1)
	
	TransitionManager.fade_to_scene("res://scenes/Main.tscn", 1.2)

func _on_button_hover(button: Button):
	play_hover_sound()
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_focus(button: Button):
	play_hover_sound()
	
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)

func _on_button_unfocus(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func play_ui_sound(sound_type: String):
	match sound_type:
		"button_click", "select":
			ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.play()
			pass
		_:
			pass

func play_hover_sound():
	pass

func _input(event):
	if is_transitioning:
		return
	
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
	elif event.is_action_pressed("ui_accept"):
		if normal_card.has_focus() or hard_card.has_focus() or expert_card.has_focus():
			_on_start_pressed()
		elif start_button.has_focus():
			_on_start_pressed()
		elif back_button.has_focus():
			_on_back_pressed()
	
	elif event.is_action_pressed("game_select"):
		if normal_card.has_focus() or hard_card.has_focus() or expert_card.has_focus():
			_on_start_pressed()
		elif start_button.has_focus():
			_on_start_pressed()
		elif back_button.has_focus():
			_on_back_pressed()
	
	elif event.is_action_pressed("game_back"):
		_on_back_pressed()

func get_node_by_partial_name(parent: Node, partial_name: String) -> Node:
	if not parent:
		return null
		
	for child in parent.get_children():
		if partial_name.to_lower() in child.name.to_lower():
			return child
		
		var nested_result = get_node_by_partial_name(child, partial_name)
		if nested_result:
			return nested_result
	
	return null
