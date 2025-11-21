class_name RunGameManager
extends Node

var main_scene: Control
var player: Player
var ai: Player
var game_ended: bool = false
var run_state: RunState

func setup(main: Control, state: RunState):
	main_scene = main
	run_state = state

func setup_new_battle(enemy: EnemyData):
	_cleanup_existing_players()
	
	game_ended = false
	
	player = Player.new()
	ai = Player.new()
	ai.is_ai = true
	
	if not player or not ai:
		push_error("Failed to create Player or AI instances")
		return
	
	player.difficulty = "normal"
	ai.difficulty = enemy.difficulty
	
	main_scene.add_child(player)
	main_scene.add_child(ai)
	
	player.turn_number = 0
	ai.turn_number = 0
	
	connect_all_signals()

func mark_game_ended() -> bool:
	if game_ended:
		return false
	
	game_ended = true
	return true

func connect_all_signals():
	connect_player_signals()
	connect_ai_signals()

func connect_player_signals():
	if not player or not main_scene:
		push_error("Cannot connect player signals: player or main_scene is null")
		return
	
	disconnect_player_signals()
	
	player.hp_changed.connect(main_scene.ui_manager.update_player_hp)
	player.mana_changed.connect(main_scene.ui_manager.update_player_mana)
	player.shield_changed.connect(main_scene.ui_manager.update_player_shield)
	
	player.player_died.connect(main_scene._on_player_died)
	player.hand_changed.connect(main_scene._on_player_hand_changed)
	player.cards_played_changed.connect(main_scene._on_player_cards_played_changed)
	player.turn_changed.connect(main_scene._on_turn_changed)
	player.card_drawn.connect(main_scene._on_player_card_drawn)
	player.damage_taken.connect(main_scene._on_player_damage_taken)
	player.hp_changed.connect(main_scene._on_player_hp_changed)
	player.shield_changed.connect(main_scene._on_player_shield_changed)

func connect_ai_signals():
	if not ai or not main_scene:
		push_error("Cannot connect AI signals: ai or main_scene is null")
		return
	
	disconnect_ai_signals()
	
	ai.hp_changed.connect(main_scene.ui_manager.update_ai_hp)
	ai.mana_changed.connect(main_scene.ui_manager.update_ai_mana)
	ai.shield_changed.connect(main_scene.ui_manager.update_ai_shield)
	
	ai.player_died.connect(main_scene._on_ai_died)
	ai.ai_card_played.connect(main_scene._on_ai_card_played)

func disconnect_all_signals():
	disconnect_player_signals()
	disconnect_ai_signals()

func disconnect_player_signals():
	if not player or not main_scene:
		return
	
	var signals_to_disconnect = [
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
	
	_disconnect_signals_from_list(player, signals_to_disconnect)

func disconnect_ai_signals():
	if not ai or not main_scene:
		return
	
	var signals_to_disconnect = [
		["hp_changed", main_scene.ui_manager.update_ai_hp],
		["mana_changed", main_scene.ui_manager.update_ai_mana],
		["shield_changed", main_scene.ui_manager.update_ai_shield],
		["player_died", main_scene._on_ai_died],
		["ai_card_played", main_scene._on_ai_card_played]
	]
	
	_disconnect_signals_from_list(ai, signals_to_disconnect)

func _disconnect_signals_from_list(source_object: Object, signals_list: Array):
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

func is_game_ended() -> bool:
	return game_ended

func should_restart_for_no_cards() -> bool:
	if not player or not ai:
		return false
		
	return DeckManager.should_restart_game(
		player.deck.size(), 
		ai.deck.size(), 
		player.hand.size(), 
		ai.hand.size()
	)
