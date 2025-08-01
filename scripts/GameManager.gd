class_name GameManager
extends RefCounted

var main_scene: Control
var player: Player
var ai: Player
var game_ended: bool = false
var pending_game_end: bool = false

func setup(main: Control):
	main_scene = main

func setup_new_game(difficulty: String):
	game_ended = false
	pending_game_end = false

	_cleanup_existing_players()
	
	player = Player.new()
	ai = Player.new()
	ai.is_ai = true
	
	if not player or not ai:
		push_error("Failed to create Player or AI instances")
		return
	
	player.difficulty = difficulty
	ai.difficulty = difficulty
	
	main_scene.add_child(player)
	main_scene.add_child(ai)
	
	player.turn_number = 0
	ai.turn_number = 0
	
	main_scene.game_over_label.visible = false
	
	print("Game setup complete - Turn numbers reset to 0")

func _cleanup_existing_players():
	if player:
		_disconnect_player_signals(player)
		player.queue_free()
		player = null
	
	if ai:
		_disconnect_ai_signals(ai)
		ai.queue_free()
		ai = null
	
	if main_scene:
		await main_scene.get_tree().process_frame
		await main_scene.get_tree().process_frame

func _disconnect_player_signals(p: Player):
	if not p:
		return
		
	var connections_to_disconnect = [
		["hp_changed", main_scene.ui_manager.update_player_hp],
		["mana_changed", main_scene.ui_manager.update_player_mana],
		["shield_changed", main_scene.ui_manager.update_player_shield],
		["player_died", main_scene._on_player_died],
		["hand_changed", main_scene._on_player_hand_changed],
		["cards_played_changed", main_scene._on_player_cards_played_changed],
		["turn_changed", main_scene._on_turn_changed],
		["card_drawn", main_scene._on_player_card_drawn],
		["damage_taken", main_scene._on_player_damage_taken],
		["hp_changed", main_scene._on_player_hp_changed],
		["shield_changed", main_scene._on_player_shield_changed]
	]
	
	for connection in connections_to_disconnect:
		var signal_name = connection[0]
		var callable_target = connection[1]
		
		if p.has_signal(signal_name) and p.is_connected(signal_name, callable_target):
			p.disconnect(signal_name, callable_target)

func _disconnect_ai_signals(a: Player):
	if not a:
		return
		
	var connections_to_disconnect = [
		["hp_changed", main_scene.ui_manager.update_ai_hp],
		["mana_changed", main_scene.ui_manager.update_ai_mana],
		["shield_changed", main_scene.ui_manager.update_ai_shield],
		["player_died", main_scene._on_ai_died],
		["ai_card_played", main_scene._on_ai_card_played]
	]
	
	for connection in connections_to_disconnect:
		var signal_name = connection[0]
		var callable_target = connection[1]
		
		if a.has_signal(signal_name) and a.is_connected(signal_name, callable_target):
			a.disconnect(signal_name, callable_target)

func restart_game(game_count: int, difficulty: String):
	game_ended = false
	pending_game_end = false
	
	main_scene.turn_label.text = "New game!"
	main_scene.ui_manager.selected_card_index = 0
	
	var difficulty_desc = GameBalance.get_difficulty_description(difficulty)
	main_scene.game_info_label.text = "Game #" + str(game_count) + " | " + difficulty.to_upper()

func should_restart_for_no_cards() -> bool:
	if game_ended or not player or not ai:
		return false
		
	return DeckManager.should_restart_game(
		player.get_deck_size(), 
		ai.get_deck_size(), 
		player.get_hand_size(), 
		ai.get_hand_size()
	)
	
func restart_for_no_cards():
	if game_ended:
		return
		
	game_ended = true
	
	main_scene.turn_label.text = "Both out of cards!"
	main_scene.game_info_label.text = "Restarting game..."
	
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("game_restart")).timeout
	
	main_scene.restart_game()

func mark_game_ended():
	pending_game_end = true
	print("Game end marked - waiting for actions to complete")

func can_end_game() -> bool:
	if not pending_game_end:
		return false
	
	if ai and ai.has_method("is_ai_turn_active") and ai.is_ai_turn_active():
		print("Waiting for AI turn to complete...")
		return false
	
	if _has_pending_card_animations():
		print("Waiting for card animations to complete...")
		return false
	
	return true

func _has_pending_card_animations() -> bool:
	if main_scene and main_scene.ui_manager and main_scene.ui_manager.card_instances:
		for card in main_scene.ui_manager.card_instances:
			if is_instance_valid(card) and card.has_method("_cleanup_tweens"):
				if card.play_tween or card.selection_tween or card.hover_tween:
					return true
	return false

func finalize_game_end():
	if game_ended:
		return
		
	game_ended = true
	pending_game_end = false
	print("Game end finalized - all actions completed")

func is_game_ended() -> bool:
	return game_ended

func is_game_ending() -> bool:
	return pending_game_end or game_ended

func end_turn_limit_reached():
	if game_ended:
		return
		
	main_scene.turn_label.text = "Limit reached!"
	main_scene.game_info_label.text = "Ending turn automatically..."
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout

func end_turn_no_cards():
	if game_ended:
		return
		
	main_scene.turn_label.text = "No cards!"
	main_scene.game_info_label.text = "Ending turn automatically..."
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout

func handle_game_over(message: String, end_turn_button: Button):
	if game_ended:
		return
		
	game_ended = true
	
	if main_scene.has_method("cleanup_notifications"):
		main_scene.cleanup_notifications()
	
	main_scene.game_over_label.text = message
	main_scene.game_over_label.visible = true
	
	if end_turn_button:
		end_turn_button.disabled = true
	
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("death_restart")).timeout
