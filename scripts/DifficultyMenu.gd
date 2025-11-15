extends Control

@onready var normal_card = $MenuContainer/DifficultyContainer/NormalCard
@onready var hard_card = $MenuContainer/DifficultyContainer/HardCard
@onready var expert_card = $MenuContainer/DifficultyContainer/ExpertCard

@onready var normal_bg = $MenuContainer/DifficultyContainer/NormalCard/CardBG
@onready var hard_bg = $MenuContainer/DifficultyContainer/HardCard/CardBG
@onready var expert_bg = $MenuContainer/DifficultyContainer/ExpertCard/CardBG

@onready var normal_border = $MenuContainer/DifficultyContainer/NormalCard/CardBorder/BorderColor
@onready var hard_border = $MenuContainer/DifficultyContainer/HardCard/CardBorder/BorderColor
@onready var expert_border = $MenuContainer/DifficultyContainer/ExpertCard/CardBorder/BorderColor

@onready var back_button = $MenuContainer/ButtonsContainer/BackButton
@onready var start_button = $MenuContainer/ButtonsContainer/StartButton

@onready var ui_player = $AudioManager/UIPlayer
@onready var hover_player = $AudioManager/HoverPlayer
@onready var global_music_manager = get_node("/root/GlobalMusicManager")

var selected_difficulty: String = "normal"
var is_transitioning: bool = false

const COLORS = {
	"normal": {
		"bg_normal": Color(0.15, 0.2, 0.3, 0.95),
		"bg_selected": Color(0.2, 0.3, 0.45, 1.0),
		"bg_hover": Color(0.18, 0.25, 0.38, 0.98),
		"border_normal": Color(0.2, 0.47, 0.63, 0.4),
		"border_selected": Color(0.52, 0.81, 1.0, 0.8),
		"border_hover": Color(0.4, 0.7, 0.9, 0.6)
	},
	"hard": {
		"bg_normal": Color(0.25, 0.15, 0.1, 0.95),
		"bg_selected": Color(0.35, 0.22, 0.15, 1.0),
		"bg_hover": Color(0.3, 0.18, 0.12, 0.98),
		"border_normal": Color(0.9, 0.49, 0.13, 0.4),
		"border_selected": Color(1.0, 0.65, 0.25, 0.8),
		"border_hover": Color(0.95, 0.6, 0.2, 0.6)
	},
	"expert": {
		"bg_normal": Color(0.3, 0.1, 0.1, 0.95),
		"bg_selected": Color(0.4, 0.15, 0.15, 1.0),
		"bg_hover": Color(0.35, 0.12, 0.12, 0.98),
		"border_normal": Color(0.91, 0.3, 0.3, 0.4),
		"border_selected": Color(1.0, 0.4, 0.4, 0.8),
		"border_hover": Color(0.95, 0.35, 0.35, 0.6)
	}
}

func _ready():
	load_difficulty_data()
	setup_cards()
	setup_buttons()
	select_difficulty("normal", false)
	

	var difficulty_music = preload("res://audio/music/difficulty_menu.ogg")
	if global_music_manager:
		global_music_manager.set_difficulty_music_stream(difficulty_music)
		global_music_manager.start_difficulty_music(1.5)
	
	await handle_scene_entrance()
	normal_card.grab_focus()

func load_difficulty_data():
	for difficulty in ["normal", "hard", "expert"]:
		update_difficulty_stats(difficulty)

func update_difficulty_stats(difficulty: String):
	var player_config = GameBalance.get_player_config(difficulty)
	var ai_config = GameBalance.get_ai_config(difficulty)
	var balance_stats = GameBalance.get_balance_stats(difficulty)
	
	var card = get_card_node(difficulty)
	if not card:
		return

	var title_label = card.get_node_or_null("Content/TitleLabel")
	if title_label:
		title_label.text = difficulty.to_upper() + " - " + balance_stats.description
	
	var player_stats = card.get_node_or_null("Content/StatsContainer/PlayerStats")
	if player_stats:
		player_stats.text = "\n%d HP | %d Mana\n%d card%s/turn | %d max hand" % [
			player_config.hp,
			player_config.mana,
			player_config.cards_per_turn,
			"s" if player_config.cards_per_turn > 1 else "",
			player_config.hand_size
		]
	
	var ai_stats = card.get_node_or_null("Content/StatsContainer/AIStats")
	if ai_stats:
		var behavior = get_ai_behavior_text(ai_config)
		ai_stats.text = "\n%d HP | %d Mana\n%d card%s/turn | %s" % [
			ai_config.hp,
			ai_config.mana,
			ai_config.cards_per_turn,
			"s" if ai_config.cards_per_turn > 1 else "",
			behavior
		]
	
	var card_dist_label = card.get_node_or_null("Content/CardDistribution")
	if card_dist_label:
		card_dist_label.text = "Cards: %d%% ATK | %d%% HEAL | %d%% SHIELD | %d%% HYBRID" % [
			balance_stats.attack_percentage,
			balance_stats.heal_percentage,
			balance_stats.shield_percentage,
			int((1.0 - (balance_stats.attack_percentage + balance_stats.heal_percentage + balance_stats.shield_percentage) / 100.0) * 100)
		]
	
	var balance_label = card.get_node_or_null("Content/BalanceInfo")
	if balance_label:
		var ratio_text = "Balance: %.2f" % balance_stats.balance_ratio
		if balance_stats.balanced:
			ratio_text += " ✓"
		balance_label.text = ratio_text
		balance_label.modulate = Color.LIME_GREEN if balance_stats.balanced else Color.YELLOW
	
	var details_label = card.get_node_or_null("Content/DetailsLabel")
	if details_label:
		var details = []
		
		details.append("Deck: %d cards" % player_config.deck_size)
		
		var aggr_percent = int(ai_config.aggression * 100)
		details.append("AI Aggression: %d%%" % aggr_percent)
		
		var heal_percent = int(ai_config.heal_threshold * 100)
		details.append("AI Heals at: <%d%% HP" % heal_percent)
		
		details_label.text = "\n".join(details)

func get_ai_behavior_text(ai_config: Dictionary) -> String:
	var aggression = ai_config.get("aggression", 0.5)
	
	if aggression >= 0.8:
		return "Brutal"
	elif aggression >= 0.6:
		return "Aggressive"
	elif aggression >= 0.4:
		return "Balanced"
	else:
		return "Defensive"

func setup_cards():
	var cards = [
		{"node": normal_card, "diff": "normal"},
		{"node": hard_card, "diff": "hard"},
		{"node": expert_card, "diff": "expert"}
	]
	
	for i in cards.size():
		var card = cards[i]
		var card_node = card.node
		
		card_node.focus_mode = Control.FOCUS_ALL
		card_node.focus_neighbor_bottom = start_button.get_path()
		
		if i > 0:
			card_node.focus_neighbor_left = cards[i - 1].node.get_path()
		if i < cards.size() - 1:
			card_node.focus_neighbor_right = cards[i + 1].node.get_path()
		
		card_node.gui_input.connect(_on_card_clicked.bind(card.diff))
		card_node.mouse_entered.connect(_on_card_mouse_entered.bind(card.diff))
		card_node.mouse_exited.connect(_on_card_mouse_exited.bind(card.diff))
		card_node.focus_entered.connect(_on_card_focused.bind(card.diff))

func setup_buttons():
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	back_button.focus_neighbor_right = start_button.get_path()
	back_button.focus_neighbor_top = normal_card.get_path()
	start_button.focus_neighbor_left = back_button.get_path()
	start_button.focus_neighbor_top = hard_card.get_path()
	
	for button in [back_button, start_button]:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))

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
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	animate_cards_entrance()

func animate_cards_entrance():
	var cards = [normal_card, hard_card, expert_card]
	var delay = 0.0
	
	for card in cards:
		card.modulate.a = 0.0
		card.position.y -= 30
		
		await get_tree().create_timer(delay).timeout
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.4)
		tween.tween_property(card, "position:y", card.position.y + 30, 0.4)
		
		delay = 0.1

func _on_card_clicked(event: InputEvent, difficulty: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_difficulty(difficulty)

func _on_card_mouse_entered(difficulty: String):
	if selected_difficulty == difficulty:
		return
	
	play_hover_sound()
	animate_card_hover(difficulty, true)

func _on_card_mouse_exited(difficulty: String):
	if selected_difficulty == difficulty:
		return
	
	animate_card_hover(difficulty, false)

func _on_card_focused(difficulty: String):
	play_hover_sound()
	select_difficulty(difficulty)

func animate_card_hover(difficulty: String, is_hovering: bool):
	var card = get_card_node(difficulty)
	var bg = get_card_bg(difficulty)
	var border = get_card_border(difficulty)
	var colors = COLORS[difficulty]
	
	if not card or not bg or not border:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if is_hovering:
		tween.tween_property(bg, "color", colors.bg_hover, 0.2)
		tween.tween_property(border, "color", colors.border_hover, 0.2)
		tween.tween_property(card, "scale", Vector2(1.03, 1.03), 0.2)
	else:
		tween.tween_property(bg, "color", colors.bg_normal, 0.2)
		tween.tween_property(border, "color", colors.border_normal, 0.2)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.2)

func select_difficulty(difficulty: String, play_sound: bool = true):
	if is_transitioning:
		return
	
	var was_different = selected_difficulty != difficulty
	selected_difficulty = difficulty
	
	if was_different and play_sound:
		play_ui_sound("select")
	
	update_all_cards()
	
	if was_different:
		animate_card_selection(difficulty)
	
	update_start_button()

func update_all_cards():
	for diff in ["normal", "hard", "expert"]:
		var card = get_card_node(diff)
		var bg = get_card_bg(diff)
		var border = get_card_border(diff)
		var colors = COLORS[diff]
		
		if not card or not bg or not border:
			continue
		
		var is_selected = (diff == selected_difficulty)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		
		var target_bg = colors.bg_selected if is_selected else colors.bg_normal
		var target_border = colors.border_selected if is_selected else colors.border_normal
		
		tween.tween_property(bg, "color", target_bg, 0.3)
		tween.tween_property(border, "color", target_border, 0.3)

func animate_card_selection(difficulty: String):
	var card = get_card_node(difficulty)
	if not card:
		return
	
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.06, 1.06), 0.1)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15)

func update_start_button():
	start_button.text = "PLAY %s" % selected_difficulty.to_upper()
	
	var tween = create_tween()
	tween.tween_property(start_button, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.1)
	tween.tween_property(start_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _on_back_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	if global_music_manager:
		global_music_manager.stop_difficulty_music_for_menu(0.8)
		await get_tree().create_timer(0.5).timeout
		global_music_manager.start_menu_music(1.0)
	
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
	
	await tween.finished
	
	if global_music_manager:
		global_music_manager.stop_all_music(0.5)
	
	TransitionManager.fade_to_scene("res://scenes/Main.tscn", 1.0)

func _on_button_hover(button: Button):
	play_hover_sound()
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)

func play_ui_sound(sound_type: String):
	if sound_type in ["button_click", "select"]:
		ui_player.stream = preload("res://audio/ui/button_click.wav")
		ui_player.play()

func play_hover_sound():
	pass

func _input(event):
	if is_transitioning:
		return
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_back"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("game_select"):
		if normal_card.has_focus() or hard_card.has_focus() or expert_card.has_focus():
			_on_start_pressed()
		elif start_button.has_focus():
			_on_start_pressed()
		elif back_button.has_focus():
			_on_back_pressed()
		get_viewport().set_input_as_handled()

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

func get_card_border(difficulty: String) -> ColorRect:
	match difficulty:
		"normal":
			return normal_border
		"hard":
			return hard_border
		"expert":
			return expert_border
		_:
			return null
