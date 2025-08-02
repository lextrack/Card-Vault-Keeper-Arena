class_name GameManager
extends RefCounted

var main_scene: Control
var player: Player
var ai: Player
var game_ended: bool = false
var pending_game_end: bool = false
var restart_in_progress: bool = false

func setup(main: Control):
	main_scene = main

func setup_new_game(difficulty: String):
	game_ended = false
	pending_game_end = false
	restart_in_progress = false

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
	
	# Conectar las señales centralizadamente
	connect_all_signals()
	
	print("Game setup complete - Turn numbers reset to 0")

func connect_all_signals():
	"""Conecta todas las señales del player y AI de forma centralizada"""
	connect_player_signals()
	connect_ai_signals()

func connect_player_signals():
	"""Conecta todas las señales del player"""
	if not player or not main_scene:
		push_error("Cannot connect player signals: player or main_scene is null")
		return
	
	# Desconectar primero para evitar conexiones duplicadas
	disconnect_player_signals()
	
	# Conectar señales del UI
	player.hp_changed.connect(main_scene.ui_manager.update_player_hp)
	player.mana_changed.connect(main_scene.ui_manager.update_player_mana)
	player.shield_changed.connect(main_scene.ui_manager.update_player_shield)
	
	# Conectar señales de eventos del juego
	player.player_died.connect(main_scene._on_player_died)
	player.hand_changed.connect(main_scene._on_player_hand_changed)
	player.cards_played_changed.connect(main_scene._on_player_cards_played_changed)
	player.turn_changed.connect(main_scene._on_turn_changed)
	player.card_drawn.connect(main_scene._on_player_card_drawn)
	player.damage_taken.connect(main_scene._on_player_damage_taken)
	player.hp_changed.connect(main_scene._on_player_hp_changed)
	player.shield_changed.connect(main_scene._on_player_shield_changed)
	
	print("Player signals connected successfully")

func connect_ai_signals():
	"""Conecta todas las señales del AI"""
	if not ai or not main_scene:
		push_error("Cannot connect AI signals: ai or main_scene is null")
		return
	
	# Desconectar primero para evitar conexiones duplicadas
	disconnect_ai_signals()
	
	# Conectar señales del UI
	ai.hp_changed.connect(main_scene.ui_manager.update_ai_hp)
	ai.mana_changed.connect(main_scene.ui_manager.update_ai_mana)
	ai.shield_changed.connect(main_scene.ui_manager.update_ai_shield)
	
	# Conectar señales de eventos del juego
	ai.player_died.connect(main_scene._on_ai_died)
	ai.ai_card_played.connect(main_scene._on_ai_card_played)
	
	print("AI signals connected successfully")

func disconnect_all_signals():
	"""Desconecta todas las señales del player y AI"""
	disconnect_player_signals()
	disconnect_ai_signals()

func disconnect_player_signals():
	"""Desconecta todas las señales del player"""
	if not player:
		return
	
	var signals_to_disconnect = [
		# Señales del UI
		["hp_changed", main_scene.ui_manager.update_player_hp],
		["mana_changed", main_scene.ui_manager.update_player_mana],
		["shield_changed", main_scene.ui_manager.update_player_shield],
		
		# Señales de eventos del juego
		["player_died", main_scene._on_player_died],
		["hand_changed", main_scene._on_player_hand_changed],
		["cards_played_changed", main_scene._on_player_cards_played_changed],
		["turn_changed", main_scene._on_turn_changed],
		["card_drawn", main_scene._on_player_card_drawn],
		["damage_taken", main_scene._on_player_damage_taken],
		["hp_changed", main_scene._on_player_hp_changed],
		["shield_changed", main_scene._on_player_shield_changed]
	]
	
	_disconnect_signals_from_list(player, signals_to_disconnect)

func disconnect_ai_signals():
	"""Desconecta todas las señales del AI"""
	if not ai:
		return
	
	var signals_to_disconnect = [
		# Señales del UI
		["hp_changed", main_scene.ui_manager.update_ai_hp],
		["mana_changed", main_scene.ui_manager.update_ai_mana],
		["shield_changed", main_scene.ui_manager.update_ai_shield],
		
		# Señales de eventos del juego
		["player_died", main_scene._on_ai_died],
		["ai_card_played", main_scene._on_ai_card_played]
	]
	
	_disconnect_signals_from_list(ai, signals_to_disconnect)

func _disconnect_signals_from_list(source_object: Object, signals_list: Array):
	"""Función helper para desconectar señales de una lista"""
	if not source_object or not main_scene:
		return
		
	for connection in signals_list:
		var signal_name = connection[0]
		var callable_target = connection[1]
		
		if source_object.has_signal(signal_name) and source_object.is_connected(signal_name, callable_target):
			source_object.disconnect(signal_name, callable_target)

func _cleanup_existing_players():
	if player:
		disconnect_player_signals()
		player.queue_free()
		player = null
	
	if ai:
		disconnect_ai_signals()
		ai.queue_free()
		ai = null
	
	if main_scene:
		await main_scene.get_tree().process_frame
		await main_scene.get_tree().process_frame

# Resto de funciones de GameManager permanecen igual...
func restart_game(game_count: int, difficulty: String):
	if restart_in_progress:
		return
	
	restart_in_progress = true
	game_ended = false
	pending_game_end = false
	
	main_scene.turn_label.text = "New game!"
	main_scene.ui_manager.selected_card_index = 0

	if main_scene.end_turn_button:
		main_scene.ui_manager.reset_turn_button(main_scene.end_turn_button, false)
	
	var difficulty_desc = GameBalance.get_difficulty_description(difficulty)
	main_scene.game_info_label.text = "Game #" + str(game_count) + " | " + difficulty.to_upper()

func should_restart_for_no_cards() -> bool:
	if game_ended or pending_game_end or restart_in_progress or not player or not ai:
		return false
		
	return DeckManager.should_restart_game(
		player.get_deck_size(), 
		ai.get_deck_size(), 
		player.get_hand_size(), 
		ai.get_hand_size()
	)
	
func restart_for_no_cards():
	if game_ended or restart_in_progress:
		print("Cannot restart for no cards: game ended or restart in progress")
		return
	
	restart_in_progress = true
	game_ended = true
	
	main_scene.turn_label.text = "Both out of cards!"
	main_scene.game_info_label.text = "Restarting game..."
	
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("game_restart")).timeout
	
	main_scene.restart_game()

func mark_game_ended() -> bool:
	if pending_game_end or game_ended:
		return false
	
	pending_game_end = true
	return true

func can_end_game() -> bool:
	if not pending_game_end:
		return false
	
	if ai and ai.has_method("is_ai_turn_active") and ai.is_ai_turn_active():
		return false
	
	if _has_pending_card_animations():
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
		print("Game end already finalized")
		return
		
	game_ended = true
	pending_game_end = false
	print("Game end finalized - all actions completed")

func is_game_ended() -> bool:
	return game_ended

func is_game_ending() -> bool:
	return pending_game_end or game_ended

func is_restart_in_progress() -> bool:
	return restart_in_progress

func end_turn_limit_reached():
	if game_ended or restart_in_progress:
		return
		
	main_scene.turn_label.text = "Limit reached!"
	main_scene.game_info_label.text = "Ending turn automatically..."
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout

func end_turn_no_cards():
	if game_ended or restart_in_progress:
		return
		
	main_scene.turn_label.text = "No cards!"
	main_scene.game_info_label.text = "Ending turn automatically..."
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout

func handle_game_over(message: String, end_turn_button: Button):
	if game_ended or restart_in_progress:
		return
		
	game_ended = true
	
	if main_scene.has_method("cleanup_notifications"):
		main_scene.cleanup_notifications()
	
	main_scene.game_over_label.text = message
	main_scene.game_over_label.visible = true
	
	if end_turn_button:
		end_turn_button.disabled = true
	
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("death_restart")).timeout
