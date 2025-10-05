extends Control

@onready var player_hp_label = $UILayer/TopPanel/StatsContainer/PlayerStatsPanel/PlayerStatsContainer/HPStat/HPLabel
@onready var player_mana_label = $UILayer/TopPanel/StatsContainer/PlayerStatsPanel/PlayerStatsContainer/ManaStat/ManaLabel
@onready var player_shield_label = $UILayer/TopPanel/StatsContainer/PlayerStatsPanel/PlayerStatsContainer/ShieldStat/ShieldLabel
@onready var ai_hp_label = $UILayer/TopPanel/StatsContainer/AIStatsPanel/AIStatsContainer/HPStat/HPLabel
@onready var ai_mana_label = $UILayer/TopPanel/StatsContainer/AIStatsPanel/AIStatsContainer/ManaStat/ManaLabel
@onready var ai_shield_label = $UILayer/TopPanel/StatsContainer/AIStatsPanel/AIStatsContainer/ShieldStat/ShieldLabel
@onready var hand_container = $UILayer/CenterArea/HandContainer
@onready var turn_label = $UILayer/TopPanel/StatsContainer/CenterInfo/TurnLabel
@onready var game_info_label = $UILayer/TopPanel/StatsContainer/CenterInfo/GameInfoLabel
@onready var end_turn_button = $UILayer/BottomPanel/TurnButtonsContainer/EndTurnButton
@onready var game_over_label = $UILayer/GameOverLabel
@onready var ui_layer = $UILayer
@onready var top_panel_bg = $UILayer/TopPanel/TopPanelBG
@onready var damage_bonus_label = $UILayer/TopPanel/StatsContainer/CenterInfo/DamageBonusLabel
@onready var audio_manager = $AudioManager
@onready var joker_buff_label: Label = $UILayer/TopPanel/StatsContainer/CenterInfo/JokerBuffLabel
@onready var options_button = $UILayer/BottomPanel/TurnButtonsContainer/OptionsButton
@onready var challengehub_button = $UILayer/BottomPanel/TurnButtonsContainer/ChallengeHubButton
@onready var exit_button = $UILayer/BottomPanel/TurnButtonsContainer/ExitButton

var last_bonus_notification_turn: int = -1
var options_menu: OptionsMenu
var ui_manager: UIManager
var game_manager: GameManager
var input_manager: InputManager
var audio_helper: AudioHelper
var confirmation_dialog: ExitConfirmationDialog
var returning_from_challengehub: bool = false
var bundle_celebration_queue: Array = []
var is_showing_bundle_celebration: bool = false
var player: Player
var ai: Player
var ai_notification: AICardNotification
var game_notification: GameNotification
var controls_panel: ControlsPanel
var is_player_turn: bool = true
var difficulty: String = "normal"
var game_count: int = 1
var is_game_transitioning: bool = false
var joker_card_scene = preload("res://scenes/JokerCard.tscn")
var card_scene = preload("res://scenes/Card.tscn")
var ai_notification_scene = preload("res://scenes/AICardNotification.tscn")
var game_notification_scene = preload("res://scenes/GameNotification.tscn")
var bundle_celebration_system: BundleCelebration

@export var controls_panel_scene: PackedScene = preload("res://scenes/ControlsPanel.tscn")
@export var options_menu_scene: PackedScene = preload("res://scenes/OptionsMenu.tscn")

var game_music_playlist: Array = [
	preload("res://audio/music/game_battle_1.ogg"),
	preload("res://audio/music/game_battle_2.ogg"),
	preload("res://audio/music/game_battle_3.ogg")
]

func _ready():
	if GameStateManager.has_saved_state():
		returning_from_challengehub = true
		await initialize_game_from_saved_state()
	else:
		await initialize_game()
		
	buttons_connections()
		
func buttons_connections():
	if options_button:
		options_button.pressed.connect(_on_options_button_pressed)
	if challengehub_button:
		challengehub_button.pressed.connect(_on_challengehub_button_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_button_pressed)

func _connect_player_buff_signals():
	await get_tree().process_frame
	
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
	
	audio_helper.play_bonus_sound()
	print("Joker buff applied: ", buff_message)

func _on_player_buff_consumed(buff_type: String):
	print("Buff consumed: ", buff_type)
	
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
	print("All buffs cleared")
	
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
		
func initialize_game():
	_setup_components()
	_setup_notifications()
	_setup_controls_panel()
	_setup_unlock_system()
	_setup_options_menu()
	_load_difficulty()
	
	animate_ui()
	
	if StatisticsManagers:
		StatisticsManagers.start_game(difficulty)
	
	await handle_scene_entrance()
	setup_game()
	
func animate_ui():
	$AnimationPlayer.play("show_panels_main")
	await $AnimationPlayer.animation_finished

func _setup_options_menu():
	options_menu = options_menu_scene.instantiate()
	options_menu.setup(audio_manager, true)
	options_menu.options_closed.connect(_on_options_menu_closed)
	ui_layer.add_child(options_menu)
	options_menu.visible = false
	
func set_bottom_buttons_enabled(enabled: bool):
	if options_button:
		options_button.disabled = not enabled
	if challengehub_button:
		challengehub_button.disabled = not enabled
	if exit_button:
		exit_button.disabled = not enabled
	
func _on_options_button_pressed():
	if not is_player_turn or is_game_transitioning:
		return
	audio_helper.play_ui_click_sound()
	show_options_menu()

func _on_challengehub_button_pressed():
	if not is_player_turn or is_game_transitioning:
		return
	audio_helper.play_ui_click_sound()
	open_challengehub()

func _on_exit_button_pressed():
	if is_game_transitioning:
		return
	audio_helper.play_ui_click_sound()
	show_exit_confirmation()
	
func _on_options_menu_closed():
	if is_player_turn:
		input_manager.start_player_turn()
		controls_panel.update_player_turn(true)
		controls_panel.update_cards_available(player.hand.size() > 0)
		
func show_options_menu():
	if not options_menu or is_game_transitioning:
		return
	
	if is_player_turn:
		input_manager.start_ai_turn()
		controls_panel.force_hide()
	
	options_menu.show_options()
		
func initialize_game_from_saved_state():
	_setup_components()
	_setup_notifications()
	_setup_controls_panel()
	_setup_options_menu()
	_setup_unlock_system()
	
	if StatisticsManagers:
		pass
	
	await handle_scene_entrance()
	await restore_game_from_saved_state()
	
func check_and_apply_new_unlocks():
	if not UnlockManagers or not player:
		return
	
	var cards_before_visit = GameStateManager.saved_game_state.get("available_cards_snapshot", [])
	var available_cards_now = UnlockManagers.get_available_cards()
	
	var truly_new_cards = []
	for card_name in available_cards_now:
		if not card_name in cards_before_visit:
			truly_new_cards.append(card_name)
	
	if truly_new_cards.size() > 0:
		show_new_cards_notification(truly_new_cards)

func show_new_cards_notification(new_cards: Array):
	if new_cards.size() == 0:
		return
	
	var title = ""
	var message = ""
	var detail = ""
	
	if new_cards.size() == 1:
		title = "New Card Unlocked!"
		message = new_cards[0] + " is now available for future decks"
		detail = "New card will appear in the future"
	else:
		title = "New Cards Unlocked!"
		message = str(new_cards.size()) + " new cards are now available"
		detail = "New cards will appear in the future"
	
	if game_notification:
		game_notification.show_success(message, detail)
	else:
		push_error("Error trying to show notification")
	
func verify_deck_consistency_after_unlock():
	if not player or not UnlockManagers:
		return
	
	var all_cards = player.get_all_cards()
	var inconsistencies = []
	
	for card in all_cards:
		if card is CardData:
			if card.is_joker:
				continue
			
			if not UnlockManagers.is_card_available(card.card_name):
				inconsistencies.append(card.card_name)
	
	if inconsistencies.size() > 0:
		print("WARNING: Deck contains cards that should not be available: ", inconsistencies)
		for card_name in inconsistencies:
			print("  Keeping locked card in deck: ", card_name, " (player already had it)")

func restore_game_from_saved_state():
	game_manager.setup_new_game(GameStateManager.saved_game_state.get("difficulty", "normal"))
	player = game_manager.player
	ai = game_manager.ai
	
	_connect_player_buff_signals()
	
	if not GameStateManager.restore_game_state(self):
		push_error("Failed to restore game state, starting new game")
		setup_game()
		return
	
	if UnlockManagers:
		if not UnlockManagers.bundle_unlocked.is_connected(_on_bundle_unlocked):
			UnlockManagers.bundle_unlocked.connect(_on_bundle_unlocked)
		if not UnlockManagers.card_unlocked.is_connected(_on_card_unlocked):
			UnlockManagers.card_unlocked.connect(_on_card_unlocked)
		if not UnlockManagers.progress_updated.is_connected(_on_unlock_progress_updated):
			UnlockManagers.progress_updated.connect(_on_unlock_progress_updated)
	
	ui_manager.update_all_labels(player, ai)
	ui_manager.update_hand_display_no_animation(player, card_scene, hand_container)
	
	start_game_music(false)
	
	if is_player_turn:
		ui_manager.start_player_turn(player, difficulty)
		input_manager.start_player_turn()
		controls_panel.update_player_turn(true)
		controls_panel.update_cards_available(player.hand.size() > 0)
	else:
		ui_manager.start_ai_turn(ai)
		input_manager.start_ai_turn()
		controls_panel.force_hide()
		
	check_and_apply_new_unlocks()
	verify_deck_consistency_after_unlock()
	
	if UnlockManagers:
		var current_stats = UnlockManagers.get_unlock_stats()
		if OS.is_debug_build():
			print("Post-ChallengeHub unlock stats: ", current_stats.unlocked_bundles, "/", current_stats.total_bundles)
		
	GameStateManager.clear_saved_state()
	
func _setup_unlock_system():
	if UnlockManagers:
		UnlockManagers.bundle_unlocked.connect(_on_bundle_unlocked)
		UnlockManagers.card_unlocked.connect(_on_card_unlocked)
		UnlockManagers.progress_updated.connect(_on_unlock_progress_updated)

func _on_bundle_unlocked(bundle_id: String, cards: Array):
	var bundle_info = UnlockManagers.get_bundle_info(bundle_id)
	bundle_celebration_system.queue_celebration(bundle_info, cards)
	audio_helper.play_bonus_sound()

func _wait_for_celebrations_to_complete():
	if not bundle_celebration_system:
		print("No bundle celebration system, skipping wait")
		return
	
	var max_wait_time = 2.0
	var wait_time = 0.0
	var check_interval = 0.05
	
	while wait_time < max_wait_time:
		if bundle_celebration_system.is_celebrations_complete():
			print("Celebrations completed after ", wait_time, "s")
			return

		await get_tree().create_timer(check_interval).timeout
		wait_time += check_interval
	
	print("Celebration wait timed out after ", max_wait_time, "s")

func _wait_for_actions_to_complete():
	var max_wait_time = 3.0
	var wait_time = 0.0
	var check_interval = 0.05
	
	while wait_time < max_wait_time:
		if game_manager.can_end_game():
			print("Actions completed after ", wait_time, "s")
			return

		await get_tree().create_timer(check_interval).timeout
		wait_time += check_interval

	print("Actions wait timed out after ", max_wait_time, "s")

func _on_card_unlocked(card_name: String):
	pass

func _on_unlock_progress_updated(bundle_id: String, current: int, required: int):
	pass

func _setup_components():
	ui_manager = UIManager.new()
	ui_manager.setup(self, joker_card_scene)
	
	game_manager = GameManager.new()
	game_manager.setup(self)
	
	input_manager = InputManager.new()
	input_manager.setup(self)
	
	audio_helper = AudioHelper.new()
	audio_helper.setup(audio_manager)
	
	confirmation_dialog = ExitConfirmationDialog.new()
	confirmation_dialog.setup(self)
	
	bundle_celebration_system = BundleCelebration.new()
	bundle_celebration_system.setup(self)

func _setup_notifications():
	ai_notification = ai_notification_scene.instantiate()
	game_notification = game_notification_scene.instantiate()
	add_child(ai_notification)
	add_child(game_notification)

func cleanup_notifications():
	if ai_notification:
		ai_notification.force_close()
	
	if game_notification:
		game_notification.clear_all_notifications()
	
	if controls_panel:
		controls_panel.force_hide()
		
	if options_menu:
		options_menu.hide_options()
	
	if bundle_celebration_system:
		bundle_celebration_system.clear_all_celebrations()
	
	await get_tree().process_frame
	await get_tree().process_frame

func _setup_controls_panel():
	controls_panel = controls_panel_scene.instantiate()
	ui_layer.add_child(controls_panel)

func _load_difficulty():
	difficulty = GameState.get_selected_difficulty()

func handle_scene_entrance():
	await get_tree().process_frame
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		if TransitionManager.current_overlay.has_method("is_ready") and TransitionManager.current_overlay.is_ready():
			await TransitionManager.current_overlay.fade_out(0.8)
		else:
			_play_direct_entrance()
	else:
		_play_direct_entrance()

func _play_direct_entrance():
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween.finished

func stop_game_music(fade_duration: float = 1.0):
	if GlobalMusicManager:
		GlobalMusicManager.stop_all_music(fade_duration)
		
func is_game_being_restored() -> bool:
	return returning_from_challengehub

func setup_game():
	if returning_from_challengehub:
		return
		
	verify_and_startup_deck()
	
	if joker_buff_label:
		joker_buff_label.visible = false
	
	game_manager.setup_new_game(difficulty)
	player = game_manager.player
	ai = game_manager.ai
	
	_connect_player_buff_signals()
	
	if not player:
		push_error("Failed to create player in setup_game")
		return
	if not ai:
		push_error("Failed to create AI in setup_game")
		return
	
	if damage_bonus_label:
		damage_bonus_label.visible = false

	if end_turn_button:
		ui_manager.reset_turn_button(end_turn_button, input_manager.gamepad_mode)
	
	ui_manager.update_all_labels(player, ai)
	ui_manager.update_hand_display_no_animation(player, card_scene, hand_container)
	
	start_game_music(not returning_from_challengehub)
	start_player_turn()
		
func verify_and_startup_deck():
	if not UnlockManagers:
		return
	
	var starter_cards = UnlockManagers.get_starter_cards()
	var available_cards = UnlockManagers.get_available_cards()
	
	var missing_starters = []
	for card_name in starter_cards:
		if not card_name in available_cards:
			missing_starters.append(card_name)
	
	if missing_starters.size() > 0:
		print("Missing starter cards detected: ", missing_starters)
		
		if not UnlockManagers.is_bundle_unlocked("starter_pack"):
			UnlockManagers.unlock_bundle("starter_pack", false)
		
		UnlockManagers.save_progress()

func validate_deck_generation():
	var test_deck = DeckGenerator.create_starter_deck()
	var violations = []
	
	for card in test_deck:
		if card is CardData:
			if not UnlockManagers.is_card_available(card.card_name):
				violations.append(card.card_name)
	
	if violations.size() > 0:
		print("Deck generation violations: ", violations)
		
	var pool = WeightedCardPool.new()
	pool.add_templates(CardDatabase.get_all_card_templates())
	var pool_validation = pool.validate_pool()
	
	if OS.is_debug_build():
		var all_possible = CardDatabase.get_all_card_templates().size()
		var in_pool = pool_validation.total_cards
		var filtered = all_possible - in_pool
		print("Pool status: ", in_pool, "/", all_possible, " cards in pool (", filtered, " filtered out)")
	
	return violations.size() == 0

func start_player_turn():
	if is_player_turn or game_manager.is_game_ended():
		return
		
	is_player_turn = true
	
	if input_manager.last_input_was_gamepad:
		await get_tree().process_frame
		await get_tree().process_frame
		input_manager.start_player_turn()
	else:
		ui_manager.gamepad_selection_active = false
		ui_manager._clear_all_gamepad_selection_styles()
		input_manager.start_player_turn()

	player.start_turn()
	
	audio_helper.play_turn_change_sound(true)
	ui_manager.start_player_turn(player, difficulty)

	if end_turn_button:
		ui_manager.reset_turn_button(end_turn_button, input_manager.gamepad_mode)
		ui_manager.update_turn_button_text(player, end_turn_button, input_manager.gamepad_mode)

	set_bottom_buttons_enabled(true)
	
	controls_panel.update_player_turn(true)
	controls_panel.update_cards_available(player.hand.size() > 0)
	
	if input_manager.last_input_was_gamepad:
		await get_tree().process_frame
		await get_tree().process_frame
		input_manager.start_player_turn()
	else:
		input_manager.start_player_turn()
		
func start_ai_turn():
	if not is_player_turn or game_manager.is_game_ended():
		return
		
	is_player_turn = false
	input_manager.start_ai_turn()
	ai.start_turn()

	var current_bonus = ai.get_damage_bonus()
	var is_bonus_turn = GameBalance.is_damage_bonus_turn(ai.turn_number)

	if is_bonus_turn and current_bonus > 0 and last_bonus_notification_turn != ai.turn_number:
		if game_notification and game_notification.is_showing:
			await game_notification.hide_notification()
			await get_tree().create_timer(0.2).timeout
		
		last_bonus_notification_turn = ai.turn_number
		audio_helper.play_bonus_sound()
		game_notification.show_damage_bonus_notification(ai.turn_number, current_bonus)
		await get_tree().create_timer(0.5).timeout
	
	if StatisticsManagers:
		StatisticsManagers.turn_completed()
	
	set_bottom_buttons_enabled(false)
	
	controls_panel.force_hide()
	audio_helper.play_turn_change_sound(false)
	ui_manager.start_ai_turn(ai)
	
	await ai.ai_turn(player)
	
	if not game_manager.is_game_ended():
		if game_manager.should_restart_for_no_cards():
			await game_manager.restart_for_no_cards()
			return
		
		await get_tree().create_timer(0.4).timeout
		
		if not game_manager.is_game_ended():
			start_player_turn()

func restart_game():
	if is_game_transitioning:
		return
	
	is_game_transitioning = true
	input_manager.disable_input()

	if joker_buff_label:
		joker_buff_label.visible = false
		joker_buff_label.text = ""

	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.size = get_viewport_rect().size
	fade_rect.z_index = 100
	add_child(fade_rect)
	
	var message_label = Label.new()
	message_label.text = "NEW GAME"
	
	var font = load("res://fonts/Philosopher-Bold.ttf")
	if font:
		message_label.add_theme_font_override("font", font)
		message_label.add_theme_font_size_override("font_size", 72)
	
	message_label.modulate.a = 0
	message_label.z_index = 105
	message_label.position = get_viewport_rect().size / 2 - Vector2(200, 36)
	add_child(message_label)

	var restart_sound = load("res://audio/sfx/CardMoving.wav")
	if restart_sound:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = restart_sound
		audio_player.volume_db = 6.0
		add_child(audio_player)
		audio_player.play()
		
		audio_player.finished.connect(func(): audio_player.queue_free())

	var tween = create_tween().set_parallel(true)
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.3).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(message_label, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(message_label, "position:y", message_label.position.y - 30, 1.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	await get_tree().create_timer(0.7).timeout
	
	setup_game_with_new_music()
	
	await get_tree().process_frame

	is_player_turn = true
	if ui_manager and player:
		ui_manager._update_existing_cards_playability(player)
	
	for card in ui_manager.card_instances:
		if is_instance_valid(card):
			card.z_index = 50
	
	tween = create_tween().set_parallel(true)
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 2.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(message_label, "modulate:a", 0, 1.0).set_delay(0.8).set_ease(Tween.EASE_IN)
	tween.tween_property(message_label, "position:y", message_label.position.y - 60, 1.0).set_delay(0.8).set_ease(Tween.EASE_IN)
	
	await tween.finished

	fade_rect.queue_free()
	message_label.queue_free()
	
	is_game_transitioning = false
	input_manager.enable_input()

func setup_game_with_new_music():
	verify_and_startup_deck()
	
	if joker_buff_label:
		joker_buff_label.visible = false
		joker_buff_label.text = ""
	
	start_game_music(true)
	
	game_manager.setup_new_game(difficulty)
	player = game_manager.player
	ai = game_manager.ai
	
	_connect_player_buff_signals()
	
	last_bonus_notification_turn = -1

	if damage_bonus_label:
		damage_bonus_label.visible = false
	
	if end_turn_button:
		ui_manager.reset_turn_button(end_turn_button, input_manager.gamepad_mode)
	
	turn_label.text = "Your turn"
	game_info_label.text = "Game #%d | %s" % [game_count, difficulty.to_upper()]
	
	ui_manager.update_all_labels(player, ai)
	ui_manager.update_hand_display_no_animation(player, card_scene, hand_container)
	
	start_player_turn()
	
func start_game_music(is_new_game: bool = false):
	if GlobalMusicManager:
		if game_music_playlist.size() > 0:
			GlobalMusicManager.set_game_music_playlist(game_music_playlist)
		else:
			print("Warning: No game music playlist configured!")
			return
		
		GlobalMusicManager.start_game_music(1.5, is_new_game)
	
func _on_player_damage_taken(damage_amount: int):
	audio_helper.play_damage_sound(damage_amount)
	ui_manager.play_damage_effects(damage_amount)
	
	if StatisticsManagers:
		StatisticsManagers.combat_action("damage_taken", damage_amount)

func _on_player_cards_played_changed(cards_played: int, max_cards: int):
	ui_manager.update_hand_display(player, card_scene, hand_container)
	ui_manager.update_turn_button_text(player, end_turn_button, input_manager.gamepad_mode)
	ui_manager.update_cards_played_info(cards_played, max_cards, difficulty)
	
	if not game_manager.is_game_ended():
		if cards_played >= max_cards:
			await game_manager.end_turn_limit_reached()
			start_ai_turn()
		elif is_player_turn and player.get_hand_size() == 0:
			await game_manager.end_turn_no_cards()
			start_ai_turn()

func _on_player_hand_changed():
	if not player:
		return
		
	var was_gamepad_selection_active = (
		input_manager.gamepad_mode and
		is_player_turn and
		ui_manager.gamepad_selection_active and
		player.cards_played_this_turn > 0
	)
	
	ui_manager.update_hand_display(player, card_scene, hand_container)
	ui_manager.update_turn_button_text(player, end_turn_button, input_manager.gamepad_mode)
	
	if was_gamepad_selection_active:
		ui_manager.gamepad_selection_active = true
		ui_manager.update_card_selection(true, player)
	
	if is_player_turn and player.get_hand_size() == 0 and not game_manager.is_game_ended():
		await game_manager.end_turn_no_cards()
		start_ai_turn()

func _on_player_card_drawn(cards_count: int, from_deck: bool):
	if cards_count > 0:
		ui_manager.update_hand_display(player, card_scene, hand_container)
	
	await get_tree().create_timer(0.1).timeout
	audio_helper.play_card_draw_sound()

func _on_turn_changed(turn_num: int, damage_bonus: int):
	ui_manager.update_all_labels(player, ai)
	ui_manager.update_damage_bonus_indicator(player, damage_bonus_label)
	
	if is_player_turn and damage_bonus > 0 and GameBalance.is_damage_bonus_turn(turn_num) and last_bonus_notification_turn != turn_num:
		if game_notification and game_notification.is_showing:
			await game_notification.hide_notification()
			await get_tree().create_timer(0.2).timeout
		
		last_bonus_notification_turn = turn_num
		audio_helper.play_bonus_sound()
		game_notification.show_damage_bonus_notification(turn_num, damage_bonus)
	elif is_player_turn and damage_bonus > 0:
		ui_manager.show_damage_bonus_info(turn_num, damage_bonus)
	else:
		if damage_bonus_label:
			if damage_bonus > 0:
				ui_manager.update_damage_bonus_indicator(player, damage_bonus_label)
			else:
				damage_bonus_label.visible = false

func _on_player_died():
	if not game_manager.mark_game_ended():
		return
	
	is_game_transitioning = true
	input_manager.disable_input()
	
	_track_game_end(false)
	
	var start_time = Time.get_ticks_msec() / 1000.0
	await _wait_for_actions_to_complete()
	var actions_wait_time = (Time.get_ticks_msec() / 1000.0) - start_time

	game_manager.finalize_game_end()
	
	start_time = Time.get_ticks_msec() / 1000.0
	await _wait_for_celebrations_to_complete()
	var celebrations_wait_time = (Time.get_ticks_msec() / 1000.0) - start_time
	
	await cleanup_notifications()
	await get_tree().create_timer(0.3).timeout
	
	if audio_manager and audio_manager.lose_player:
		audio_manager.lose_player.play()
	
	if StatisticsManagers:
		StatisticsManagers.end_game(false, difficulty, player.turn_number)
		
	GameState.add_game_result(false)
	
	game_notification.show_game_end_notification("Defeat", "hp_zero")
	
	await get_tree().create_timer(1.5).timeout
	
	game_over_label.text = "YOU LOST! Restarting..."
	game_over_label.visible = true
	
	if end_turn_button:
		end_turn_button.disabled = true
	
	await get_tree().create_timer(2.0).timeout
	is_game_transitioning = false
	
	restart_game()
	
func _on_ai_card_played(card: CardData):
	ai_notification.show_card_notification(card, "AI")

func _on_ai_died():
	if not game_manager.mark_game_ended():
		return
	
	is_game_transitioning = true
	input_manager.disable_input()
	
	_track_game_end(true)
	
	var start_time = Time.get_ticks_msec() / 1000.0
	await _wait_for_actions_to_complete()
	var actions_wait_time = (Time.get_ticks_msec() / 1000.0) - start_time
	
	game_manager.finalize_game_end()
	
	start_time = Time.get_ticks_msec() / 1000.0
	await _wait_for_celebrations_to_complete()
	var celebrations_wait_time = (Time.get_ticks_msec() / 1000.0) - start_time
	
	await cleanup_notifications()
	await get_tree().create_timer(0.3).timeout

	if audio_manager and audio_manager.win_player:
		audio_manager.win_player.play()
	
	if StatisticsManagers:
		StatisticsManagers.mark_cards_for_win()
		StatisticsManagers.end_game(true, difficulty, player.turn_number)
	
	GameState.add_game_result(true)
	
	game_notification.show_game_end_notification("Victory!", "hp_zero")
	
	await get_tree().create_timer(1.5).timeout
	
	game_over_label.text = "YOU WON! Restarting..."
	game_over_label.visible = true
	
	if end_turn_button:
		end_turn_button.disabled = true
	
	await get_tree().create_timer(2.0).timeout

	is_game_transitioning = false
	restart_game()

func _track_game_end(player_won: bool):
	if not UnlockManagers:
		return
	
	var game_time = 0.0
	if StatisticsManagers and StatisticsManagers.game_start_time > 0:
		game_time = (Time.get_ticks_msec() / 1000.0) - StatisticsManagers.game_start_time
	
	var damage_taken = 0
	var final_hp = 0
	if player:
		damage_taken = player.max_hp - player.current_hp
		final_hp = player.current_hp
	
	var extra_data = {
		"difficulty": difficulty,
		"turns": player.turn_number if player else 0,
		"time": game_time,
		"damage_taken": damage_taken,
		"final_hp": final_hp,
		"cards_played": player.cards_played_this_turn if player else 0,
		"was_at_low_hp": player.was_at_low_hp_this_game if player else false,
		"total_damage_this_game": player.total_damage_this_game if player else 0
	}
	
	if player_won:
		UnlockManagers.track_progress("game_won", 1, extra_data)
		
		if damage_taken == 0:
			UnlockManagers.track_progress("perfect_victory", 1, extra_data)
		
		if difficulty == "hard" and game_time <= 480:
			UnlockManagers.track_progress("speed_win_hard", 1, extra_data)
	
	UnlockManagers.track_progress("game_ended", 1, extra_data)
	
	if player and player.turn_number >= 15:
		UnlockManagers.track_progress("survive_turns", player.turn_number, extra_data)

func _on_player_hp_changed(new_hp: int):
	ui_manager.update_player_hp(new_hp)
	
	if StatisticsManagers and new_hp > player.current_hp:
		var healing = new_hp - player.current_hp
		StatisticsManagers.combat_action("healing_done", healing)

func _on_player_shield_changed(new_shield: int):
	ui_manager.update_player_shield(new_shield)
	
	if StatisticsManagers and new_shield > player.current_shield:
		var shield_gained = new_shield - player.current_shield
		StatisticsManagers.combat_action("shield_gained", shield_gained)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		cleanup_notifications()
		stop_game_music(0.3)
		await get_tree().create_timer(0.5).timeout
		get_tree().quit()

func _on_card_clicked(card):
	if not is_player_turn or is_game_transitioning:
		return
	
	var card_data = null
	if card.has_method("get_card_data"):
		card_data = card.get_card_data()
	else:
		card_data = card.card_data
	
	if not card_data or not player.can_play_card(card_data):
		return
	
	if not player.can_play_more_cards():
		card.animate_mana_insufficient()
		return

	var card_type = card_data.card_type
	var card_name = card_data.card_name
	var card_cost = card_data.cost
	
	if UnlockManagers:
		var extra_data = {
			"card_type": card_type,
			"card_name": card_name,
			"card_cost": card_cost,
			"turn": player.turn_number,
			"difficulty": difficulty,
			"shield_value": card_data.shield
		}
		UnlockManagers.track_progress("card_played", 1, extra_data)
		
		if card_type == "hybrid":
			UnlockManagers.track_progress("hybrid_cards_played", 1, extra_data)
	
	audio_helper.play_card_play_sound(card_type)
	
	card.play_card_animation()

	await get_tree().create_timer(0.15).timeout
	
	match card_type:
		"attack":
			player.play_card_without_hand_removal(card_data, ai, audio_helper)
		"heal", "shield":
			player.play_card_without_hand_removal(card_data, null, audio_helper)
		"hybrid":
			player.play_card_without_hand_removal(card_data, ai, audio_helper)
	
	player.remove_card_from_hand(card_data)

func _on_end_turn_pressed():
	if not is_player_turn or game_manager.is_game_ended() or is_game_transitioning:
		return
	
	if game_manager.should_restart_for_no_cards():
		await game_manager.restart_for_no_cards()
		return
	
	if end_turn_button:
		end_turn_button.text = "Ending Turn..."
		end_turn_button.disabled = true
		end_turn_button.modulate = Color(0.7, 0.7, 0.7, 1.0)
	
	set_bottom_buttons_enabled(false)
	
	start_ai_turn()

func _input(event):
	if is_game_transitioning:
		return
		
	if confirmation_dialog.is_showing:
		confirmation_dialog.handle_input(event)
		return
		
	if event is InputEventJoypadButton and event.pressed:
		CursorManager.set_gamepad_mode(true)
	elif event is InputEventMouse:
		CursorManager.set_gamepad_mode(false)
		
	if event.is_action_pressed("show_options") and is_player_turn and not options_menu.visible and not is_game_transitioning:
		show_options_menu()
		return
		
	if event.is_action_pressed("ChallengeHub_access") and is_player_turn and not is_game_transitioning:
		open_challengehub()
		return
		
	if OS.is_debug_build() and event.is_action_pressed("ui_home"):
		debug_show_deck_info()
		
	if not is_game_transitioning:
		input_manager.handle_input(event)
	
func debug_show_deck_info():
	if not player or not ai:
		return
	
	print("\n=== DECK DEBUG INFO ===")
	
	print("\n--- PLAYER DECK ---")
	var player_all_cards = player.get_all_cards()
	var player_card_count = {}
	
	for card in player_all_cards:
		if card is CardData:
			var card_name = card.card_name
			if player_card_count.has(card_name):
				player_card_count[card_name] += 1
			else:
				player_card_count[card_name] = 1
	
	print("Total cards in player deck: ", player_all_cards.size())
	print("Unique cards: ", player_card_count.size())
	
	for card_name in player_card_count.keys():
		print("  ", card_name, " x", player_card_count[card_name])

	print("\n--- AI DECK ---")
	var ai_all_cards = ai.get_all_cards()
	var ai_card_count = {}
	
	for card in ai_all_cards:
		if card is CardData:
			var card_name = card.card_name
			if ai_card_count.has(card_name):
				ai_card_count[card_name] += 1
			else:
				ai_card_count[card_name] = 1
	
	print("Total cards in AI deck: ", ai_all_cards.size())
	print("Unique cards: ", ai_card_count.size())
	
	for card_name in ai_card_count.keys():
		print("  ", card_name, " x", ai_card_count[card_name])
	
	if UnlockManagers:
		print("\n--- AVAILABLE CARDS (UnlockManager) ---")
		var available_cards = UnlockManagers.get_available_cards()
		print("Total available cards: ", available_cards.size())
		for card_name in available_cards:
			print("  ", card_name)
	
func open_challengehub():
	if not is_player_turn or confirmation_dialog.is_showing or is_game_transitioning:
		return
	
	if not GameStateManager.save_game_state(self):
		push_error("Failed to save game state")
		return
	
	cleanup_notifications()
	stop_game_music(0.8)
	
	await get_tree().create_timer(0.5).timeout
	TransitionManager.fade_to_scene("res://scenes/ChallengeHub.tscn", 1.0)

func show_exit_confirmation():
	if is_game_transitioning:
		return
	confirmation_dialog.show()

func return_to_menu():
	if is_game_transitioning:
		return
	cleanup_notifications()
	stop_game_music(0.8)
	await get_tree().create_timer(0.5).timeout
	TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 1.0)
