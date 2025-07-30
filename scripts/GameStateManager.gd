extends Node

var saved_game_state: Dictionary = {}
var is_game_saved: bool = false

func save_game_state(main_scene: Control):
	if not main_scene.player or not main_scene.ai:
		push_error("Cannot save game state: player or AI is null")
		return false
	
	var available_cards_snapshot = []
	if UnlockManagers:
		available_cards_snapshot = UnlockManagers.get_available_cards().duplicate()
	
	saved_game_state = {
		"player_hp": main_scene.player.current_hp,
		"player_max_hp": main_scene.player.max_hp,
		"player_mana": main_scene.player.current_mana,
		"player_max_mana": main_scene.player.max_mana,
		"player_shield": main_scene.player.current_shield,
		"player_hand": _serialize_cards(main_scene.player.hand),
		"player_deck": _serialize_cards(main_scene.player.deck),
		"player_discard": _serialize_cards(main_scene.player.discard_pile),
		"player_cards_played": main_scene.player.cards_played_this_turn,
		"player_turn_number": main_scene.player.turn_number,
		"player_was_low_hp": main_scene.player.was_at_low_hp_this_game,
		
		"ai_hp": main_scene.ai.current_hp,
		"ai_max_hp": main_scene.ai.max_hp,
		"ai_mana": main_scene.ai.current_mana,
		"ai_max_mana": main_scene.ai.max_mana,
		"ai_shield": main_scene.ai.current_shield,
		"ai_hand": _serialize_cards(main_scene.ai.hand),
		"ai_deck": _serialize_cards(main_scene.ai.deck),
		"ai_discard": _serialize_cards(main_scene.ai.discard_pile),
		"ai_cards_played": main_scene.ai.cards_played_this_turn,
		"ai_turn_number": main_scene.ai.turn_number,
		
		"is_player_turn": main_scene.is_player_turn,
		"difficulty": main_scene.difficulty,
		"game_count": main_scene.game_count,
		"selected_card_index": main_scene.ui_manager.selected_card_index,
		"gamepad_mode": main_scene.input_manager.gamepad_mode,
		"last_input_was_gamepad": main_scene.input_manager.last_input_was_gamepad,
		
		"available_cards_snapshot": available_cards_snapshot,
		"save_timestamp": Time.get_ticks_msec()
	}
	
	is_game_saved = true
	print("Game state saved successfully with ", available_cards_snapshot.size(), " cards in snapshot")
	return true

func _serialize_cards(cards: Array) -> Array:
	var serialized = []
	for card in cards:
		if card is CardData:
			serialized.append({
				"card_name": card.card_name,
				"card_type": card.card_type,
				"cost": card.cost,
				"damage": card.damage,
				"heal": card.heal,
				"shield": card.shield,
				"description": card.description
			})
	return serialized

func restore_game_state(main_scene: Control) -> bool:
	if not is_game_saved or saved_game_state.is_empty():
		push_error("No saved game state to restore")
		return false
	
	if main_scene.player:
		main_scene.player.current_hp = saved_game_state.get("player_hp", 50)
		main_scene.player.max_hp = saved_game_state.get("player_max_hp", 50)
		main_scene.player.current_mana = saved_game_state.get("player_mana", 5)
		main_scene.player.max_mana = saved_game_state.get("player_max_mana", 5)
		main_scene.player.current_shield = saved_game_state.get("player_shield", 0)
		main_scene.player.cards_played_this_turn = saved_game_state.get("player_cards_played", 0)
		main_scene.player.turn_number = saved_game_state.get("player_turn_number", 1)
		main_scene.player.was_at_low_hp_this_game = saved_game_state.get("player_was_low_hp", false)
		
		main_scene.player.hand = _deserialize_cards(saved_game_state.get("player_hand", []))
		main_scene.player.deck = _deserialize_cards(saved_game_state.get("player_deck", []))
		main_scene.player.discard_pile = _deserialize_cards(saved_game_state.get("player_discard", []))
	
	if main_scene.ai:
		main_scene.ai.current_hp = saved_game_state.get("ai_hp", 50)
		main_scene.ai.max_hp = saved_game_state.get("ai_max_hp", 50)
		main_scene.ai.current_mana = saved_game_state.get("ai_mana", 5)
		main_scene.ai.max_mana = saved_game_state.get("ai_max_mana", 5)
		main_scene.ai.current_shield = saved_game_state.get("ai_shield", 0)
		main_scene.ai.cards_played_this_turn = saved_game_state.get("ai_cards_played", 0)
		main_scene.ai.turn_number = saved_game_state.get("ai_turn_number", 1)
		
		main_scene.ai.hand = _deserialize_cards(saved_game_state.get("ai_hand", []))
		main_scene.ai.deck = _deserialize_cards(saved_game_state.get("ai_deck", []))
		main_scene.ai.discard_pile = _deserialize_cards(saved_game_state.get("ai_discard", []))
	
	main_scene.is_player_turn = saved_game_state.get("is_player_turn", true)
	main_scene.difficulty = saved_game_state.get("difficulty", "normal")
	main_scene.game_count = saved_game_state.get("game_count", 1)
	
	if main_scene.ui_manager:
		main_scene.ui_manager.selected_card_index = saved_game_state.get("selected_card_index", 0)
	
	if main_scene.input_manager:
		main_scene.input_manager.gamepad_mode = saved_game_state.get("gamepad_mode", false)
		main_scene.input_manager.last_input_was_gamepad = saved_game_state.get("last_input_was_gamepad", false)
	
	print("Game state restored successfully")
	return true

func _deserialize_cards(serialized_cards: Array) -> Array:
	var cards = []
	for card_data in serialized_cards:
		var card = CardData.new()
		card.card_name = card_data.get("card_name", "")
		card.card_type = card_data.get("card_type", "")
		card.cost = card_data.get("cost", 1)
		card.damage = card_data.get("damage", 0)
		card.heal = card_data.get("heal", 0)
		card.shield = card_data.get("shield", 0)
		card.description = card_data.get("description", "")
		cards.append(card)
	return cards

func clear_saved_state():
	saved_game_state.clear()
	is_game_saved = false
	print("Saved game state cleared")

func has_saved_state() -> bool:
	return is_game_saved and not saved_game_state.is_empty()

func get_save_age_seconds() -> float:
	if not has_saved_state():
		return -1.0
	
	var current_time = Time.get_ticks_msec()
	var save_time = saved_game_state.get("save_timestamp", current_time)
	return (current_time - save_time) / 1000.0
