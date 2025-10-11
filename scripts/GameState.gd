extends Node

var selected_difficulty: String = "normal"

var gamepad_mode: bool = false:
	set(value):
		if gamepad_mode != value:
			gamepad_mode = value
			gamepad_mode_changed.emit(value)
			if has_node("/root/CursorManager"):
				CursorManager.set_gamepad_mode(value)

var input_enabled: bool = true:
	set(value):
		if input_enabled != value:
			input_enabled = value
			input_enabled_changed.emit(value)

var is_processing_input: bool = false

signal gamepad_mode_changed(enabled: bool)
signal input_enabled_changed(enabled: bool)

func _ready():
	print("GameState initialized")

	if StatisticsManagers:
		StatisticsManagers.milestone_reached.connect(_on_milestone_reached)

func can_process_input() -> bool:
	return input_enabled and not is_processing_input

func get_selected_difficulty() -> String:
	return selected_difficulty

func set_selected_difficulty(difficulty: String):
	selected_difficulty = difficulty

func add_game_result(player_won: bool):
	if StatisticsManagers:
		pass

func get_win_rate() -> float:
	if StatisticsManagers:
		return StatisticsManagers.get_win_rate()
	return 0.0

func reset_stats():
	if StatisticsManagers:
		StatisticsManagers.reset_statistics()

func get_stats_text() -> String:
	if not StatisticsManagers:
		return "Statistics not available"
	
	var stats = StatisticsManagers.get_comprehensive_stats()
	var basic = stats.basic
	
	if basic.games_played == 0:
		return "No statistics yet"
	
	return "Games: %d | Wins: %d | Losses: %d | Rate: %.1f%%" % [
		basic.games_played, 
		StatisticsManagers.games_won, 
		StatisticsManagers.games_lost, 
		basic.win_rate * 100.0
	]

func _on_milestone_reached(milestone_type: String, value: int):
	match milestone_type:
		"games_played":
			print("Milestone reached: %d games played!" % value)
		"games_won":
			print("Milestone reached: %d games won!" % value)
		"win_streak":
			print("Milestone reached: %d win streak!" % value)
