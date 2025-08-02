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
		
func initialize_game():
	_setup_components()
	_setup_notifications()
	_setup_controls_panel()
	_setup_unlock_system()
	_setup_options_menu()
	_load_difficulty()
	
	if StatisticsManagers:
		StatisticsManagers.start_game(difficulty)
	
	await handle_scene_entrance()
	setup_game()
	
func _setup_options_menu():
	options_menu = options_menu_scene.instantiate()
	options_menu.setup(audio_manager, true)
	options_menu.options_closed.connect(_on_options_menu_closed)
	ui_layer.add_child(options_menu)
	options_menu.visible = false
	
func _on_options_menu_closed():
	if is_player_turn:
		input_manager.start_player_turn()
		controls_panel.update_player_turn(true)
		controls_panel.update_cards_available(player.hand.size() > 0)
		
func show_options_menu():
	if not options_menu:
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
	await bundle_celebration_system.wait_for_celebrations_to_complete()

func _wait_for_actions_to_complete():
	var max_wait_time = 10.0
	var wait_time = 0.0
	var check_interval = 0.1
	
	while wait_time < max_wait_time:
		if game_manager.can_end_game():
			return

		await get_tree().create_timer(check_interval).timeout
		wait_time += check_interval
	
	print("Timeout reached, proceeding with game end anyway")

func _on_card_unlocked(card_name: String):
	pass

func _on_unlock_progress_updated(bundle_id: String, current: int, required: int):
	pass

func _setup_components():
	ui_manager = UIManager.new()
	ui_manager.setup(self)
	
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
	
	bundle_celebration_system.clear_all_celebrations()
	
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
	
	game_manager.setup_new_game(difficulty)
	player = game_manager.player
	ai = game_manager.ai
	
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
	input_manager.start_player_turn()
	
	player.turn_number += 1
	player.current_mana = player.max_mana
	player.cards_played_this_turn = 0
	
	var cards_to_draw = min(player.get_max_cards_per_turn(), player.max_hand_size - player.hand.size())
	var cards_actually_drawn = 0
	
	for i in range(cards_to_draw):
		if player.draw_card():
			cards_actually_drawn += 1
		else:
			break
	
	if cards_actually_drawn == 0:
		player.draw_card()
	
	player.mana_changed.emit(player.current_mana)
	player.cards_played_changed.emit(player.cards_played_this_turn, player.get_max_cards_per_turn())
	
	var current_bonus = player.get_damage_bonus()
	player.turn_changed.emit(player.turn_number, current_bonus)
	
	audio_helper.play_turn_change_sound(true)
	ui_manager.start_player_turn(player, difficulty)

	if end_turn_button:
		ui_manager.reset_turn_button(end_turn_button, input_manager.gamepad_mode)
		ui_manager.update_turn_button_text(player, end_turn_button, input_manager.gamepad_mode)
	
	controls_panel.update_player_turn(true)
	controls_panel.update_cards_available(player.hand.size() > 0)
	
	if cards_actually_drawn > 0:
		player.card_drawn.emit(cards_actually_drawn, true)

func start_ai_turn():
	if not is_player_turn or game_manager.is_game_ended():
		return
		
	is_player_turn = false
	input_manager.start_ai_turn()
	
	ai.turn_number += 1
	ai.current_mana = ai.max_mana
	ai.cards_played_this_turn = 0
	
	var cards_to_draw = min(ai.get_max_cards_per_turn(), ai.max_hand_size - ai.hand.size())
	var cards_actually_drawn = 0
	
	for i in range(cards_to_draw):
		if ai.draw_card():
			cards_actually_drawn += 1
		else:
			break
	
	if cards_actually_drawn == 0:
		ai.draw_card()
	
	ai.mana_changed.emit(ai.current_mana)
	ai.cards_played_changed.emit(ai.cards_played_this_turn, ai.get_max_cards_per_turn())
	
	var current_bonus = ai.get_damage_bonus()
	ai.turn_changed.emit(ai.turn_number, current_bonus)
	
	if StatisticsManagers:
		StatisticsManagers.turn_completed()
	
	controls_panel.force_hide()
	audio_helper.play_turn_change_sound(false)
	ui_manager.start_ai_turn(ai)
	
	await ai.ai_turn(player)
	
	if not game_manager.is_game_ended():
		if game_manager.should_restart_for_no_cards():
			await game_manager.restart_for_no_cards()
			return
		
		await get_tree().create_timer(0.8).timeout
		
		if not game_manager.is_game_ended():
			start_player_turn()

func restart_game():
	if game_manager.is_restart_in_progress():
		return
	
	cleanup_notifications()
	
	game_count += 1
	game_manager.restart_game(game_count, difficulty)
	
	await get_tree().create_timer(GameBalance.get_timer_delay("new_game") + 0.5).timeout
	
	setup_game_with_new_music()

func setup_game_with_new_music():
	verify_and_startup_deck()
	
	start_game_music(true)
	
	game_manager.setup_new_game(difficulty)
	player = game_manager.player
	ai = game_manager.ai

	if damage_bonus_label:
		damage_bonus_label.visible = false
	
	if end_turn_button:
		ui_manager.reset_turn_button(end_turn_button, input_manager.gamepad_mode)
	
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

func _on_player_hand_changed():
	if not player:
		return
		
	ui_manager.update_hand_display_no_animation(player, card_scene, hand_container)
	ui_manager.update_turn_button_text(player, end_turn_button, input_manager.gamepad_mode)
	
	if is_player_turn and player.get_hand_size() == 0 and not game_manager.is_game_ended():
		await game_manager.end_turn_no_cards()
		start_ai_turn()

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

func _on_player_card_drawn(cards_count: int, from_deck: bool):
	await get_tree().create_timer(0.2).timeout
	audio_helper.play_card_draw_sound()
	
	if cards_count > 0 and ui_manager.has_method("update_hand_display_with_new_cards_animation"):
		ui_manager.update_hand_display_with_new_cards_animation(player, card_scene, hand_container, cards_count)
	else:
		ui_manager.update_hand_display(player, card_scene, hand_container)

func _on_turn_changed(turn_num: int, damage_bonus: int):
	ui_manager.update_all_labels(player, ai)
	ui_manager.update_damage_bonus_indicator(player, damage_bonus_label)
	
	if damage_bonus > 0 and GameBalance.is_damage_bonus_turn(turn_num):
		audio_helper.play_bonus_sound()
		game_notification.show_damage_bonus_notification(turn_num, damage_bonus)
	elif damage_bonus > 0:
		ui_manager.show_damage_bonus_info(turn_num, damage_bonus)
	else:
		if damage_bonus_label:
			damage_bonus_label.visible = false

func _on_player_died():
	if not game_manager.mark_game_ended():
		return
	
	_track_game_end(false)
	
	await _wait_for_actions_to_complete()

	game_manager.finalize_game_end()
	
	await _wait_for_celebrations_to_complete()
	
	cleanup_notifications()
	
	if audio_manager and audio_manager.lose_player:
		audio_manager.lose_player.play()
	
	if StatisticsManagers:
		StatisticsManagers.end_game(false, difficulty, player.turn_number)
		
	GameState.add_game_result(false)
	game_notification.show_game_end_notification("Defeat", "hp_zero")
	
	await get_tree().create_timer(1.5).timeout
	
	await game_manager.handle_game_over("YOU LOST! Restarting...", end_turn_button)
	restart_game()

func _on_ai_card_played(card: CardData):
	ai_notification.show_card_notification(card, "AI")

func _on_ai_died():
	if not game_manager.mark_game_ended():
		return
	
	_track_game_end(true)
	await _wait_for_actions_to_complete()
	game_manager.finalize_game_end()
	await _wait_for_celebrations_to_complete()
	
	cleanup_notifications()

	if audio_manager and audio_manager.win_player:
		audio_manager.win_player.play()
	
	if StatisticsManagers:
		StatisticsManagers.end_game(true, difficulty, player.turn_number)
		
	GameState.add_game_result(true)
	game_notification.show_game_end_notification("Victory!", "hp_zero")
	
	await get_tree().create_timer(1.5).timeout
	
	await game_manager.handle_game_over("YOU WON! Restarting...", end_turn_button)
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
		"was_at_low_hp": player.was_at_low_hp_this_game if player else false
	}
	
	if player_won:
		UnlockManagers.track_progress("game_won", 1, extra_data)
		
		if damage_taken == 0:
			UnlockManagers.track_progress("perfect_victory", 1, extra_data)
		
		if difficulty == "hard" and game_time <= 120:
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

func _on_card_clicked(card: Card):
	if not is_player_turn or not player.can_play_card(card.card_data):
		return

	var card_data = card.card_data
	var card_type = card_data.card_type
	var card_name = card_data.card_name
	var card_cost = card_data.cost
	
	if UnlockManagers:
		var extra_data = {
			"card_type": card_type,
			"card_name": card_name,
			"card_cost": card_cost,
			"turn": player.turn_number,
			"difficulty": difficulty
		}
		UnlockManagers.track_progress("card_played", 1, extra_data)
		
		if card_type == "hybrid":
			UnlockManagers.track_progress("hybrid_cards_played", 1, extra_data)
	
	audio_helper.play_card_play_sound(card_type)
	
	if StatisticsManagers:
		StatisticsManagers.card_played(card_name, card_type, card_cost)
	
	card.play_card_animation()

	await get_tree().create_timer(0.2).timeout
	
	match card_type:
		"attack":
			player.play_card_without_hand_removal(card_data, ai, audio_helper)
		"heal", "shield":
			player.play_card_without_hand_removal(card_data, null, audio_helper)
		"hybrid":
			player.play_card_without_hand_removal(card_data, ai, audio_helper)
	
	player.remove_card_from_hand(card_data)

func _on_end_turn_pressed():
	if not is_player_turn or game_manager.is_game_ended():
		return
	
	if game_manager.should_restart_for_no_cards():
		await game_manager.restart_for_no_cards()
		return
	
	start_ai_turn()

func _input(event):
	if confirmation_dialog.is_showing:
		confirmation_dialog.handle_input(event)
		return
		
	if event is InputEventJoypadButton and event.pressed:
		CursorManager.set_gamepad_mode(true)
	elif event is InputEventMouse:
		CursorManager.set_gamepad_mode(false)
		
	if event.is_action_pressed("show_options") and is_player_turn and not options_menu.visible:
		show_options_menu()
		return
		
	if event.is_action_pressed("ui_accept") and is_player_turn and not end_turn_button.disabled and not input_manager.gamepad_mode:
		_on_end_turn_pressed()
		return
		
	if event.is_action_pressed("ChallengeHub_access") and is_player_turn:
		open_challengehub()
		return
		
	if OS.is_debug_build() and event.is_action_pressed("ui_home"):
		debug_show_deck_info()
		
	input_manager.handle_input(event)
	
func debug_show_deck_info():
	if not player or not ai:
		print("=== DEBUG: Player or AI not available ===")
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
	if not is_player_turn or confirmation_dialog.is_showing:
		return
	
	if not GameStateManager.save_game_state(self):
		push_error("Failed to save game state")
		return
	
	cleanup_notifications()
	stop_game_music(0.8)
	
	await get_tree().create_timer(0.5).timeout
	TransitionManager.fade_to_scene("res://scenes/ChallengeHub.tscn", 1.0)

func show_exit_confirmation():
	confirmation_dialog.show()

func return_to_menu():
	cleanup_notifications()
	stop_game_music(0.8)
	await get_tree().create_timer(0.5).timeout
	TransitionManager.fade_to_scene("res://scenes/MainMenu.tscn", 1.0)
