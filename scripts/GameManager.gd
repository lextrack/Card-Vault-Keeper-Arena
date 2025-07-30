class_name GameManager
extends RefCounted

var main_scene: Control
var player: Player
var ai: Player

func setup(main: Control):
	main_scene = main

func setup_new_game(difficulty: String):
	if player:
		player.queue_free()
	if ai:
		ai.queue_free()
	
	player = Player.new()
	ai = Player.new()
	ai.is_ai = true
	
	player.difficulty = difficulty
	ai.difficulty = difficulty
	
	main_scene.add_child(player)
	main_scene.add_child(ai)
	
	player.turn_number = 0
	ai.turn_number = 0
	
	main_scene.game_over_label.visible = false
	
	print("Game setup complete - Turn numbers reset to 0")

func restart_game(game_count: int, difficulty: String):
	main_scene.turn_label.text = "New game!"
	main_scene.ui_manager.selected_card_index = 0
	
	var difficulty_desc = GameBalance.get_difficulty_description(difficulty)
	main_scene.game_info_label.text = "Game #" + str(game_count) + " | " + difficulty.to_upper()

func should_restart_for_no_cards() -> bool:
	return DeckManager.should_restart_game(
		player.get_deck_size(), 
		ai.get_deck_size(), 
		player.get_hand_size(), 
		ai.get_hand_size()
	)
	
func restart_for_no_cards():
	main_scene.turn_label.text = "Both out of cards!"
	main_scene.game_info_label.text = "Restarting game..."
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("game_restart")).timeout
	main_scene.restart_game()

func end_turn_limit_reached():
	main_scene.turn_label.text = "Limit reached!"
	main_scene.game_info_label.text = "Ending turn automatically..."
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout

func end_turn_no_cards():
	main_scene.turn_label.text = "No cards!"
	main_scene.game_info_label.text = "Ending turn automatically..."
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("turn_end")).timeout

func handle_game_over(message: String, end_turn_button: Button):
	main_scene.game_over_label.text = message
	main_scene.game_over_label.visible = true
	if end_turn_button:
		end_turn_button.disabled = true
	await main_scene.get_tree().create_timer(GameBalance.get_timer_delay("death_restart")).timeout
