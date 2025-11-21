extends Control

signal battle_won(remaining_hp: int)
signal battle_lost

@onready var player_hp_label = $UILayer/TopPanel/MainContainer/StatsRow/PlayerStatsPanel/PlayerStatsContainer/HPStat/HPLabel
@onready var player_mana_label = $UILayer/TopPanel/MainContainer/StatsRow/PlayerStatsPanel/PlayerStatsContainer/ManaStat/ManaLabel
@onready var player_shield_label = $UILayer/TopPanel/MainContainer/StatsRow/PlayerStatsPanel/PlayerStatsContainer/ShieldStat/ShieldLabel
@onready var ai_hp_label = $UILayer/TopPanel/MainContainer/StatsRow/AIStatsPanel/AIStatsContainer/HPStat/HPLabel
@onready var ai_mana_label = $UILayer/TopPanel/MainContainer/StatsRow/AIStatsPanel/AIStatsContainer/ManaStat/ManaLabel
@onready var ai_shield_label = $UILayer/TopPanel/MainContainer/StatsRow/AIStatsPanel/AIStatsContainer/ShieldStat/ShieldLabel
@onready var hand_container = $UILayer/CenterArea/HandContainer
@onready var turn_label = $UILayer/TopPanel/MainContainer/StatsRow/CenterInfoPanel/CenterInfo/TopRow/TurnLabel
@onready var game_info_label = $UILayer/TopPanel/MainContainer/StatsRow/CenterInfoPanel/CenterInfo/TopRow/GameInfoLabel
@onready var run_info_label = $UILayer/TopPanel/MainContainer/StatsRow/CenterInfoPanel/CenterInfo/BottomRow/RunInfoLabel
@onready var enemy_label = $UILayer/TopPanel/MainContainer/StatsRow/CenterInfoPanel/CenterInfo/BottomRow/EnemyLabel
@onready var negative_effect_label = $UILayer/TopPanel/MainContainer/StatusRow/NegativeEffectLabel
@onready var end_turn_button = $UILayer/BottomPanel/TurnButtonsContainer/EndTurnButton
@onready var exit_button = $UILayer/BottomPanel/TurnButtonsContainer/ExitButton
@onready var game_over_label = $UILayer/GameOverLabel
@onready var ui_layer = $UILayer
@onready var top_panel_bg = $UILayer/TopPanel/TopPanelBG
@onready var damage_bonus_label = $UILayer/TopPanel/MainContainer/StatusRow/DamageBonusLabel
@onready var audio_manager = $AudioManager
@onready var joker_buff_label = $UILayer/TopPanel/MainContainer/StatusRow/JokerBuffLabel
@onready var time_limit_label = $UILayer/TopPanel/MainContainer/StatsRow/CenterInfoPanel/CenterInfo/TimeLimitLabel

var _tree: SceneTree
var ui_manager: UIManager
var game_manager: RunGameManager
var input_manager: InputManager
var audio_helper: AudioHelper
var confirmation_dialog: ExitConfirmationDialog
var player: Player
var ai: Player
var is_player_turn: bool = true
var is_game_transitioning: bool = false
var controls_panel = null

var run_state: RunState
var current_enemy: EnemyData
var active_negative_effect: String = ""

var time_limit_active: bool = false
var time_limit_duration: float = 0.0
var time_limit_elapsed: float = 0.0

var card_scene = preload("res://scenes/Card.tscn")
var joker_card_scene = preload("res://scenes/JokerCard.tscn")
var ai_notification_scene = preload("res://scenes/AICardNotification.tscn")
var game_notification_scene = preload("res://scenes/GameNotification.tscn")

var ai_notification: Node
var game_notification: Node

var ai_notification_queue: Array[CardData] = []
var is_showing_ai_notification: bool = false

func _ready():
	_tree = get_tree()
	add_to_group("main_scene")

func _process(delta: float):
	if time_limit_active and not is_game_transitioning:
		time_limit_elapsed += delta
		_update_time_limit_display()
		
		if time_limit_elapsed >= time_limit_duration:
			_on_time_limit_exceeded()

func _update_time_limit_display():
	if not time_limit_label:
		return
	
	var remaining = time_limit_duration - time_limit_elapsed
	remaining = max(0.0, remaining)
	
	var minutes = int(remaining) / 60
	var seconds = int(remaining) % 60
	var milliseconds = int((remaining - int(remaining)) * 100)
	
	time_limit_label.text = "%d:%02d.%02d" % [minutes, seconds, milliseconds]
	
	if remaining <= 10.0:
		time_limit_label.modulate = Color(1.5, 0.3, 0.3, 1.0)
	elif remaining <= 30.0:
		time_limit_label.modulate = Color(1.3, 0.8, 0.3, 1.0)
	else:
		time_limit_label.modulate = Color.WHITE

func _on_time_limit_exceeded():
	if is_game_transitioning:
		return
	
	time_limit_active = false
	_on_player_died()

func initialize_run_battle(state: RunState, enemy: EnemyData):
	run_state = state
	current_enemy = enemy
	active_negative_effect = state.active_negative_effect
	
	await _tree.process_frame
	
	_setup_components()
	_setup_notifications()
	setup_battle()

func _setup_components():
	ui_manager = UIManager.new()
	ui_manager.setup(self, joker_card_scene)
	add_child(ui_manager)
	
	game_manager = RunGameManager.new()
	game_manager.setup(self, run_state)
	add_child(game_manager)
	
	input_manager = InputManager.new()
	input_manager.setup(self, null)
	add_child(input_manager)
	
	audio_helper = AudioHelper.new()
	if audio_manager is AudioManager:
		audio_helper.setup(audio_manager)
	
	confirmation_dialog = ExitConfirmationDialog.new()
	confirmation_dialog.setup(self, "", "Exit Run Mode?\nAll progress in this run will be lost")

func _setup_notifications():
	ai_notification = ai_notification_scene.instantiate()
	ui_layer.add_child(ai_notification)
	ai_notification.visible = false
	
	game_notification = game_notification_scene.instantiate()
	ui_layer.add_child(game_notification)
	game_notification.visible = false

func setup_battle():
	game_manager.setup_new_battle(current_enemy)
	
	player = game_manager.player
	ai = game_manager.ai
	
	_setup_player_from_run_state()
	_setup_ai_from_enemy()
	
	ui_manager.update_all_labels(player, ai)
	
	update_run_info_labels()
	
	if active_negative_effect == "time_limit":
		time_limit_active = true
		time_limit_duration = EnemyDatabase.get_time_limit_for_boss(current_enemy.enemy_name)
		time_limit_elapsed = 0.0
		if time_limit_label:
			time_limit_label.visible = true
			_update_time_limit_display()
	else:
		time_limit_active = false
		if time_limit_label:
			time_limit_label.visible = false
	
	if is_instance_valid(negative_effect_label):
		if active_negative_effect != "" and active_negative_effect != "time_limit":
			negative_effect_label.text = run_state.active_negative_effect_description
			negative_effect_label.visible = true
		elif active_negative_effect == "time_limit":
			negative_effect_label.text = run_state.active_negative_effect_description
			negative_effect_label.visible = true
		else:
			negative_effect_label.visible = false
	
	_connect_player_buff_signals()
	
	if not ai.ai_card_played.is_connected(_on_ai_card_played):
		ai.ai_card_played.connect(_on_ai_card_played)
	
	if not end_turn_button.pressed.is_connected(_on_end_turn_pressed):
		end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	if not exit_button.pressed.is_connected(_on_exit_button_pressed):
		exit_button.pressed.connect(_on_exit_button_pressed)
	
	start_player_turn()

func _setup_player_from_run_state():
	GameBalance.setup_player(player, "normal", false)
	
	player.current_hp = run_state.player_hp
	player.max_hp = run_state.player_max_hp
	
	player.deck.clear()
	for card_name in run_state.player_deck_card_names:
		var template = CardDatabase.get_card_by_name(card_name)
		if template:
			var card = CardBuilder.from_template(template)
			if card:
				player.deck.append(card)
	
	player.deck.shuffle()
	player.draw_initial_hand()

func _setup_ai_from_enemy():
	GameBalance.setup_player(ai, current_enemy.difficulty, true)
	
	ai.deck = DeckGenerator.create_difficulty_deck(current_enemy.difficulty, 30)
	ai.deck.shuffle()
	ai.draw_initial_hand()

func update_run_info_labels():
	if is_instance_valid(game_info_label):
		game_info_label.text = run_state.get_progress_text()
	
	if is_instance_valid(run_info_label):
		run_info_label.text = "Deck: %d cards" % run_state.get_deck_size()
	
	if is_instance_valid(enemy_label) and current_enemy:
		enemy_label.text = "Enemy: %s" % current_enemy.enemy_name

func _connect_player_buff_signals():
	if player:
		if not player.buff_applied.is_connected(_on_player_buff_applied):
			player.buff_applied.connect(_on_player_buff_applied)
		if not player.buff_consumed.is_connected(_on_player_buff_consumed):
			player.buff_consumed.connect(_on_player_buff_consumed)
		if not player.buff_cleared.is_connected(_on_player_buff_cleared):
			player.buff_cleared.connect(_on_player_buff_cleared)

func _on_player_buff_applied(buff_type: String, buff_value: Variant):
	var buff_message = _get_buff_display_message(buff_type, buff_value)
	
	if joker_buff_label:
		joker_buff_label.text = buff_message
		joker_buff_label.modulate = _get_buff_color(buff_type)
		joker_buff_label.visible = true
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(joker_buff_label, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(joker_buff_label, "modulate:a", 1.0, 0.2)
		
		tween.finished.connect(func():
			var settle = create_tween()
			settle.tween_property(joker_buff_label, "scale", Vector2(1.0, 1.0), 0.3)
		)
	
	audio_helper.play_joker_sound()

func _on_player_buff_consumed(_buff_type: String):
	if joker_buff_label and joker_buff_label.visible:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(joker_buff_label, "modulate:a", 0.0, 0.3)
		tween.tween_property(joker_buff_label, "scale", Vector2(0.8, 0.8), 0.3)
		
		tween.finished.connect(func():
			joker_buff_label.visible = false
			joker_buff_label.scale = Vector2(1.0, 1.0)
		)

func _on_player_buff_cleared():
	if joker_buff_label and joker_buff_label.visible:
		var tween = create_tween()
		tween.tween_property(joker_buff_label, "modulate:a", 0.0, 0.2)
		tween.finished.connect(func():
			joker_buff_label.visible = false
		)

func _get_buff_display_message(buff_type: String, buff_value: Variant) -> String:
	match buff_type:
		"attack_bonus":
			return "Next Attack +%d" % int(buff_value)
		"heal_bonus":
			return "Next Heal +%d%%" % int(buff_value * 100)
		"cost_reduction":
			return "Next Card -%d Mana" % int(buff_value)
		"hybrid_bonus":
			return "Next Hybrid +%d%%" % int(buff_value * 100)
		_:
			return "Buff Active"

func _get_buff_color(buff_type: String) -> Color:
	match buff_type:
		"attack_bonus":
			return Color(1.0, 0.3, 0.3, 1.0)
		"heal_bonus":
			return Color(0.3, 1.0, 0.5, 1.0)
		"cost_reduction":
			return Color(0.4, 0.7, 1.0, 1.0)
		"hybrid_bonus":
			return Color(1.0, 0.8, 0.2, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)

func start_player_turn():
	is_player_turn = true
	
	player.start_turn()
	
	ui_manager.update_hand_display(player, card_scene, hand_container)
	
	for card_instance in ui_manager.card_instances:
		if is_instance_valid(card_instance):
			if not card_instance.card_clicked.is_connected(_on_card_clicked):
				card_instance.card_clicked.connect(_on_card_clicked)
	
	if active_negative_effect == "boss_lifesteal":
		_apply_boss_lifesteal()
	
	apply_negative_effects()
	
	top_panel_bg.color = Color(0.08, 0.13, 0.18, 0.9)
	
	if end_turn_button:
		end_turn_button.disabled = false
		end_turn_button.text = "End Turn"
		end_turn_button.modulate = Color.WHITE
	
	_check_if_can_play_cards()

func _check_if_can_play_cards():
	var has_playable_cards = false
	
	for card_data in player.hand:
		if player.can_play_card(card_data) and not _is_card_blocked_by_negative_effect(card_data):
			has_playable_cards = true
			break
	
	if not has_playable_cards and player.hand.size() > 0:
		if game_notification:
			game_notification.show_notification(
				"NO PLAYABLE CARDS",
				"Turn will end automatically",
				"",
				Color(1.0, 0.7, 0.3, 0.8),
				Color(0.15, 0.1, 0.05, 0.95),
				1.0
			)
		
		await _tree.create_timer(1.0).timeout
		
		if is_player_turn and not is_game_transitioning:
			_on_end_turn_pressed()

func apply_negative_effects():
	match active_negative_effect:
		"no_shield":
			_apply_no_shield_visual()
		"no_heal":
			_apply_no_heal_visual()
		"increased_cost":
			_apply_increased_cost_visual()

func _apply_no_shield_visual():
	for i in range(ui_manager.card_instances.size()):
		var card_instance = ui_manager.card_instances[i]
		if is_instance_valid(card_instance) and i < player.hand.size():
			var card_data = player.hand[i]
			if card_data.card_type == "shield":
				card_instance.set_blocked_by_effect(true)

func _apply_no_heal_visual():
	for i in range(ui_manager.card_instances.size()):
		var card_instance = ui_manager.card_instances[i]
		if is_instance_valid(card_instance) and i < player.hand.size():
			var card_data = player.hand[i]
			if card_data.card_type == "heal":
				card_instance.set_blocked_by_effect(true)

func _apply_increased_cost_visual():
	for i in range(ui_manager.card_instances.size()):
		var card_instance = ui_manager.card_instances[i]
		if is_instance_valid(card_instance) and i < player.hand.size():
			var modified_cost = player.hand[i].cost + 1
			card_instance.set_modified_cost(modified_cost)

func _apply_boss_lifesteal():
	ai.heal(2)
	
	if game_notification:
		game_notification.show_notification(
			"BOSS LIFESTEAL",
			"Boss healed 2 HP!",
			"",
			Color(0.8, 0.3, 0.3, 0.8),
			Color(0.15, 0.05, 0.05, 0.95),
			1.5
		)

func start_ai_turn():
	is_player_turn = false
	
	top_panel_bg.color = Color(0.15, 0.08, 0.08, 0.9)
	
	if end_turn_button:
		end_turn_button.disabled = true
		end_turn_button.text = "AI Turn..."
		end_turn_button.modulate = Color(0.7, 0.7, 0.7, 1.0)
	
	ai.start_turn()
	
	await _tree.create_timer(GameBalance.get_timer_delay("ai_turn_start")).timeout
	
	if game_manager.is_game_ended():
		return
	
	await ai.ai_turn(player)
	
	if game_manager.is_game_ended():
		return
	
	await _tree.create_timer(GameBalance.get_timer_delay("turn_end")).timeout
	
	start_player_turn()

func _on_card_clicked(card):
	if not is_player_turn or is_game_transitioning:
		return
	
	var card_data = card.get_card_data() if card.has_method("get_card_data") else card.card_data
	
	if not card_data or not player.can_play_card(card_data):
		return
	
	if not player.can_play_more_cards():
		card.animate_mana_insufficient()
		return
	
	if _is_card_blocked_by_negative_effect(card_data):
		card.play_disabled_animation()
		return
	
	var effective_cost = _get_effective_card_cost(card_data)
	
	if player.current_mana < effective_cost:
		card.animate_mana_insufficient()
		return
	
	audio_helper.play_card_play_sound(card_data.card_type)
	
	card.play_card_animation()
	
	await _tree.create_timer(0.2).timeout
	
	var original_cost = card_data.cost
	if active_negative_effect == "increased_cost":
		card_data.cost = effective_cost
	
	var damage_reduction = 0
	if active_negative_effect == "reduced_damage":
		damage_reduction = _get_damage_reduction_amount()
	
	match card_data.card_type:
		"attack":
			_play_attack_card(card_data, damage_reduction)
		"heal", "shield":
			player.play_card_without_hand_removal(card_data, null, audio_helper)
		"hybrid":
			_play_hybrid_card(card_data, damage_reduction)
	
	card_data.cost = original_cost
	
	player.remove_card_from_hand(card_data)
	
	await _tree.create_timer(0.1).timeout
	if is_player_turn and not is_game_transitioning:
		_check_if_can_play_cards()

func _play_attack_card(card_data: CardData, damage_reduction: int):
	var modified_damage = max(0, card_data.damage - damage_reduction)
	
	if damage_reduction > 0:
		var temp_card = CardData.new(
			card_data.card_name,
			card_data.cost,
			modified_damage,
			card_data.heal,
			card_data.shield,
			card_data.card_type,
			card_data.description,
			card_data.is_joker,
			card_data.joker_effect
		)
		temp_card.illustration_index = card_data.illustration_index
		
		player.play_card_without_hand_removal(temp_card, ai, audio_helper)
	else:
		player.play_card_without_hand_removal(card_data, ai, audio_helper)

func _play_hybrid_card(card_data: CardData, damage_reduction: int):
	var modified_damage = max(0, card_data.damage - damage_reduction)
	
	if damage_reduction > 0:
		var temp_card = CardData.new(
			card_data.card_name,
			card_data.cost,
			modified_damage,
			card_data.heal,
			card_data.shield,
			card_data.card_type,
			card_data.description,
			card_data.is_joker,
			card_data.joker_effect
		)
		temp_card.illustration_index = card_data.illustration_index
		
		player.play_card_without_hand_removal(temp_card, ai, audio_helper)
	else:
		player.play_card_without_hand_removal(card_data, ai, audio_helper)

func _get_effective_card_cost(card_data: CardData) -> int:
	var cost = card_data.cost
	
	if active_negative_effect == "increased_cost":
		cost += 1
	
	return cost

func _get_damage_reduction_amount() -> int:
	match current_enemy.difficulty:
		"hard":
			return 2
		"expert":
			return 3
		_:
			return 2

func _is_card_blocked_by_negative_effect(card_data: CardData) -> bool:
	match active_negative_effect:
		"no_shield":
			return card_data.card_type == "shield"
		"no_heal":
			return card_data.card_type == "heal"
	return false

func _on_end_turn_pressed():
	if not is_player_turn or game_manager.is_game_ended() or is_game_transitioning:
		return
	
	if end_turn_button:
		end_turn_button.text = "Ending Turn..."
		end_turn_button.disabled = true
		end_turn_button.modulate = Color(0.7, 0.7, 0.7, 1.0)
	
	player.clear_buffs()
	
	start_ai_turn()

func _on_player_died():
	if not game_manager.mark_game_ended():
		return
	
	is_game_transitioning = true
	time_limit_active = false
	
	print("[RunBattle] Player died - emitting battle_lost signal")
	
	await _tree.create_timer(1.0).timeout
	
	if is_instance_valid(ui_layer):
		ui_layer.visible = false
	
	battle_lost.emit()
	
	print("[RunBattle] battle_lost signal emitted")

func _on_ai_died():
	if not game_manager.mark_game_ended():
		return
	
	is_game_transitioning = true
	time_limit_active = false
	
	print("[RunBattle] AI died - emitting battle_won signal with HP: ", player.current_hp)
	
	await _tree.create_timer(1.0).timeout
	
	if is_instance_valid(ui_layer):
		ui_layer.visible = false
	
	battle_won.emit(player.current_hp)
	
	print("[RunBattle] battle_won signal emitted")

func _on_player_hand_changed():
	ui_manager.update_hand_display(player, card_scene, hand_container)
	
	for card_instance in ui_manager.card_instances:
		if is_instance_valid(card_instance):
			if not card_instance.card_clicked.is_connected(_on_card_clicked):
				card_instance.card_clicked.connect(_on_card_clicked)
	
	apply_negative_effects()

func _on_player_cards_played_changed(cards_played: int, max_cards: int):
	if is_instance_valid(turn_label):
		turn_label.text = "Cards: %d/%d" % [cards_played, max_cards]

func _on_turn_changed(turn_num: int, damage_bonus: int):
	if is_instance_valid(turn_label):
		turn_label.text = "Turn %d" % turn_num
	
	if is_instance_valid(damage_bonus_label):
		if damage_bonus > 0:
			damage_bonus_label.text = "+%d DMG" % damage_bonus
			damage_bonus_label.visible = true
		else:
			damage_bonus_label.visible = false

func _on_player_card_drawn(cards_count: int, from_deck: bool):
	pass

func _on_player_damage_taken(damage_amount: int):
	ui_manager.play_damage_effects(damage_amount)
	audio_helper.play_damage_sound(damage_amount)

func _on_player_hp_changed(new_hp: int):
	pass

func _on_player_shield_changed(new_shield: int):
	pass

func _on_ai_card_played(card: CardData):
	if not is_instance_valid(ai_notification) or is_game_transitioning:
		return
	
	if ai_notification.is_notification_showing():
		ai_notification.force_close()
		await _tree.create_timer(0.1).timeout
	
	if not is_instance_valid(ai_notification) or is_game_transitioning:
		return
	
	ai_notification.show_card_notification(card, current_enemy.enemy_name)

func _on_exit_button_pressed():
	if is_game_transitioning:
		return
	audio_helper.play_ui_click_sound()
	show_exit_confirmation()

func show_exit_confirmation():
	if is_game_transitioning:
		return
	confirmation_dialog.show()

func return_to_menu():
	if is_game_transitioning:
		return
	is_game_transitioning = true
	time_limit_active = false
	
	if is_instance_valid(ui_layer):
		ui_layer.visible = false
	
	_cleanup_scene()
	
	await _tree.create_timer(0.3).timeout
	_tree.change_scene_to_file("res://scenes/MainMenu.tscn")

func _cleanup_scene():
	if confirmation_dialog:
		confirmation_dialog.cleanup()
	
	if ui_manager and ui_manager.card_instances:
		for card in ui_manager.card_instances:
			if is_instance_valid(card):
				card.queue_free()
		ui_manager.card_instances.clear()
	
	if is_instance_valid(ai_notification):
		ai_notification.queue_free()
	
	if is_instance_valid(game_notification):
		game_notification.queue_free()
	
	if game_manager:
		game_manager.disconnect_all_signals()
		if game_manager.player:
			game_manager.player.queue_free()
		if game_manager.ai:
			game_manager.ai.queue_free()

func _input(event):
	if is_game_transitioning:
		return
	
	if confirmation_dialog and confirmation_dialog.is_showing:
		confirmation_dialog.handle_input(event)
		return
	
	if event is InputEventJoypadButton and event.pressed:
		CursorManager.set_gamepad_mode(true)
	elif event is InputEventMouse:
		CursorManager.set_gamepad_mode(false)
	
	if not is_game_transitioning and input_manager:
		input_manager.handle_input(event)
