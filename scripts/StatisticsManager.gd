class_name StatisticsManager
extends Node

signal stats_updated
signal milestone_reached(milestone_type: String, value: int)

var games_played: int = 0
var games_won: int = 0
var games_lost: int = 0
var total_play_time: float = 0.0
var jokers_played: int = 0

var difficulty_stats: Dictionary = {
	"normal": {"played": 0, "won": 0, "lost": 0, "total_time": 0.0},
	"hard": {"played": 0, "won": 0, "lost": 0, "total_time": 0.0},
	"expert": {"played": 0, "won": 0, "lost": 0, "total_time": 0.0}
}

var game_start_time: float = 0.0
var current_game_turns: int = 0
var total_turns_played: int = 0
var shortest_game_time: float = 999999.0
var longest_game_time: float = 0.0
var shortest_game_turns: int = 999999
var longest_game_turns: int = 0

var cards_played_total: int = 0
var cards_played_by_type: Dictionary = {
	"attack": 0,
	"heal": 0,
	"shield": 0,
	"hybrid": 0
}
var cards_used_count: Dictionary = {}
var most_effective_cards: Dictionary = {}

var total_damage_dealt: int = 0
var total_damage_taken: int = 0
var total_healing_done: int = 0
var total_shield_gained: int = 0
var total_mana_spent: int = 0

var current_win_streak: int = 0
var current_loss_streak: int = 0
var best_win_streak: int = 0
var worst_loss_streak: int = 0

var session_start_time: float = 0.0
var session_games_played: int = 0
var session_games_won: int = 0

var save_file_path: String = "user://statistics.save"

func _ready():
	session_start_time = Time.get_ticks_msec() / 1000.0
	load_statistics()
	
	if GameState:
		print("StatisticsManager initialized and connected to GameState")


func start_game(difficulty: String):
	game_start_time = Time.get_ticks_msec() / 1000.0
	current_game_turns = 0
	
	games_played += 1
	session_games_played += 1
	difficulty_stats[difficulty]["played"] += 1
	
	print("Game started - Total games: ", games_played)

func end_game(player_won: bool, difficulty: String, final_turns: int):
	var game_time = (Time.get_ticks_msec() / 1000.0) - game_start_time
	current_game_turns = final_turns
	
	if player_won:
		games_won += 1
		session_games_won += 1
		difficulty_stats[difficulty]["won"] += 1
		current_win_streak += 1
		current_loss_streak = 0
		best_win_streak = max(best_win_streak, current_win_streak)
	else:
		games_lost += 1
		difficulty_stats[difficulty]["lost"] += 1
		current_loss_streak += 1
		current_win_streak = 0
		worst_loss_streak = max(worst_loss_streak, current_loss_streak)
	
	total_play_time += game_time
	difficulty_stats[difficulty]["total_time"] += game_time
	shortest_game_time = min(shortest_game_time, game_time)
	longest_game_time = max(longest_game_time, game_time)
	
	total_turns_played += final_turns
	shortest_game_turns = min(shortest_game_turns, final_turns)
	longest_game_turns = max(longest_game_turns, final_turns)
	
	_check_milestones()
	
	save_statistics()
	stats_updated.emit()
	
	print("Game ended - Win: ", player_won, " | Time: ", "%.1f" % game_time, "s | Turns: ", final_turns)


func card_played(card_name: String, card_type: String, card_cost: int, is_joker: bool = false, player_won_game: bool = false):
	cards_played_total += 1
	
	if cards_played_by_type.has(card_type):
		cards_played_by_type[card_type] += 1
	
	if not cards_used_count.has(card_name):
		cards_used_count[card_name] = 0
	cards_used_count[card_name] += 1
	
	if not most_effective_cards.has(card_name):
		most_effective_cards[card_name] = {"wins": 0, "total": 0}
	most_effective_cards[card_name]["total"] += 1
	
	total_mana_spent += card_cost
	
	# Nuevo: Contar Jokers jugados
	if is_joker:
		jokers_played += 1

func mark_cards_for_win():
	for card_name in cards_used_count.keys():
		if not most_effective_cards.has(card_name):
			most_effective_cards[card_name] = {"wins": 0, "total": 0}
		most_effective_cards[card_name]["wins"] += 1

func combat_action(action_type: String, amount: int):
	match action_type:
		"damage_dealt":
			total_damage_dealt += amount
		"damage_taken":
			total_damage_taken += amount
		"healing_done":
			total_healing_done += amount
		"shield_gained":
			total_shield_gained += amount

func turn_completed():
	current_game_turns += 1

func get_win_rate() -> float:
	if games_played == 0:
		return 0.0
	return float(games_won) / float(games_played)

func get_win_rate_by_difficulty(difficulty: String) -> float:
	var stats = difficulty_stats.get(difficulty, {"played": 0, "won": 0})
	if stats.played == 0:
		return 0.0
	return float(stats.won) / float(stats.played)

func get_average_game_time() -> float:
	if games_played == 0:
		return 0.0
	return total_play_time / games_played

func get_average_game_turns() -> float:
	if games_played == 0:
		return 0.0
	return float(total_turns_played) / float(games_played)

func get_most_used_cards(limit: int = 10) -> Array:
	var sorted_cards = []
	
	for card_name in cards_used_count.keys():
		sorted_cards.append({
			"name": card_name,
			"count": cards_used_count[card_name],
			"percentage": float(cards_used_count[card_name]) / float(cards_played_total) * 100.0
		})
	
	sorted_cards.sort_custom(func(a, b): return a.count > b.count)
	
	return sorted_cards.slice(0, limit)

func get_most_effective_cards(limit: int = 10) -> Array:
	var effective_cards = []
	
	for card_name in most_effective_cards.keys():
		var card_stats = most_effective_cards[card_name]
		if card_stats.total >= 5:
			var win_rate = float(card_stats.wins) / float(card_stats.total)
			effective_cards.append({
				"name": card_name,
				"win_rate": win_rate,
				"total_uses": card_stats.total,
				"wins": card_stats.wins
			})
	
	effective_cards.sort_custom(func(a, b): return a.win_rate > b.win_rate)
	
	return effective_cards.slice(0, limit)

func get_favorite_card_type() -> String:
	var max_count = 0
	var favorite_type = "attack"
	
	for type in cards_played_by_type.keys():
		if cards_played_by_type[type] > max_count:
			max_count = cards_played_by_type[type]
			favorite_type = type
	
	return favorite_type

func get_session_stats() -> Dictionary:
	var session_time = (Time.get_ticks_msec() / 1000.0) - session_start_time
	return {
		"session_time": session_time,
		"games_played": session_games_played,
		"games_won": session_games_won,
		"win_rate": float(session_games_won) / max(1, session_games_played)
	}

func get_combat_efficiency() -> Dictionary:
	return {
		"damage_per_game": float(total_damage_dealt) / max(1, games_played),
		"healing_per_game": float(total_healing_done) / max(1, games_played),
		"shield_per_game": float(total_shield_gained) / max(1, games_played),
		"damage_taken_per_game": float(total_damage_taken) / max(1, games_played),
		"mana_efficiency": float(total_damage_dealt + total_healing_done + total_shield_gained) / max(1, total_mana_spent)
	}

func _check_milestones():
	var milestones = [10, 25, 50, 100, 250, 500, 1000]
	for milestone in milestones:
		if games_played == milestone:
			milestone_reached.emit("games_played", milestone)
	
	for milestone in milestones:
		if games_won == milestone:
			milestone_reached.emit("games_won", milestone)
	
	var streak_milestones = [5, 10, 15, 20, 25]
	for milestone in streak_milestones:
		if current_win_streak == milestone:
			milestone_reached.emit("win_streak", milestone)

func save_statistics():
	var save_data = {
		"version": "1.0",
		"games_played": games_played,
		"games_won": games_won,
		"games_lost": games_lost,
		"total_play_time": total_play_time,
		"difficulty_stats": difficulty_stats,
		"total_turns_played": total_turns_played,
		"shortest_game_time": shortest_game_time,
		"longest_game_time": longest_game_time,
		"shortest_game_turns": shortest_game_turns,
		"longest_game_turns": longest_game_turns,
		"cards_played_total": cards_played_total,
		"cards_played_by_type": cards_played_by_type,
		"cards_used_count": cards_used_count,
		"most_effective_cards": most_effective_cards,
		"total_damage_dealt": total_damage_dealt,
		"total_damage_taken": total_damage_taken,
		"total_healing_done": total_healing_done,
		"total_shield_gained": total_shield_gained,
		"total_mana_spent": total_mana_spent,
		"current_win_streak": current_win_streak,
		"current_loss_streak": current_loss_streak,
		"best_win_streak": best_win_streak,
		"worst_loss_streak": worst_loss_streak,
		"jokers_played": jokers_played
	}
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Statistics saved")
	else:
		push_error("Failed to save statistics")

func load_statistics():
	if not FileAccess.file_exists(save_file_path):
		print("No statistics file found, starting fresh")
		return
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		push_error("Failed to load statistics")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse statistics JSON")
		return
	
	var data = json.get_data()
	
	games_played = data.get("games_played", 0)
	games_won = data.get("games_won", 0)
	games_lost = data.get("games_lost", 0)
	total_play_time = data.get("total_play_time", 0.0)
	difficulty_stats = data.get("difficulty_stats", difficulty_stats)
	total_turns_played = data.get("total_turns_played", 0)
	shortest_game_time = data.get("shortest_game_time", 999999.0)
	longest_game_time = data.get("longest_game_time", 0.0)
	shortest_game_turns = data.get("shortest_game_turns", 999999)
	longest_game_turns = data.get("longest_game_turns", 0)
	cards_played_total = data.get("cards_played_total", 0)
	cards_played_by_type = data.get("cards_played_by_type", cards_played_by_type)
	cards_used_count = data.get("cards_used_count", {})
	most_effective_cards = data.get("most_effective_cards", {})
	total_damage_dealt = data.get("total_damage_dealt", 0)
	total_damage_taken = data.get("total_damage_taken", 0)
	total_healing_done = data.get("total_healing_done", 0)
	total_shield_gained = data.get("total_shield_gained", 0)
	total_mana_spent = data.get("total_mana_spent", 0)
	current_win_streak = data.get("current_win_streak", 0)
	current_loss_streak = data.get("current_loss_streak", 0)
	best_win_streak = data.get("best_win_streak", 0)
	worst_loss_streak = data.get("worst_loss_streak", 0)
	jokers_played = data.get("jokers_played", 0)
	
	print("Statistics loaded - Games played: ", games_played)

func reset_statistics():
	games_played = 0
	games_won = 0
	games_lost = 0
	total_play_time = 0.0
	difficulty_stats = {
		"normal": {"played": 0, "won": 0, "lost": 0, "total_time": 0.0},
		"hard": {"played": 0, "won": 0, "lost": 0, "total_time": 0.0},
		"expert": {"played": 0, "won": 0, "lost": 0, "total_time": 0.0}
	}
	current_game_turns = 0
	total_turns_played = 0
	shortest_game_time = 999999.0
	longest_game_time = 0.0
	shortest_game_turns = 999999
	longest_game_turns = 0
	cards_played_total = 0
	cards_played_by_type = {"attack": 0, "heal": 0, "shield": 0, "hybrid": 0}
	cards_used_count.clear()
	most_effective_cards.clear()
	total_damage_dealt = 0
	total_damage_taken = 0
	total_healing_done = 0
	total_shield_gained = 0
	total_mana_spent = 0
	current_win_streak = 0
	current_loss_streak = 0
	best_win_streak = 0
	worst_loss_streak = 0
	jokers_played = 0
	
	save_statistics()
	stats_updated.emit()
	print("Statistics reset")

func format_time(seconds: float) -> String:
	var hours = int(seconds) / 3600
	var minutes = (int(seconds) % 3600) / 60
	var secs = int(seconds) % 60
	
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	else:
		return "%d:%02d" % [minutes, secs]

func get_comprehensive_stats() -> Dictionary:
	return {
		"basic": {
			"games_played": games_played,
			"games_won": games_won,
			"games_lost": games_lost,
			"win_rate": get_win_rate(),
			"total_play_time": total_play_time,
			"average_game_time": get_average_game_time()
		},
		"difficulty": difficulty_stats,
		"turns": {
			"total_turns": total_turns_played,
			"average_turns": get_average_game_turns(),
			"shortest_game": shortest_game_turns,
			"longest_game": longest_game_turns
		},
		"cards": {
			"total_played": cards_played_total,
			"by_type": cards_played_by_type,
			"most_used": get_most_used_cards(5),
			"most_effective": get_most_effective_cards(5),
			"favorite_type": get_favorite_card_type(),
			"jokers_played": jokers_played,
		},
		"combat": get_combat_efficiency(),
		"streaks": {
			"current_win": current_win_streak,
			"current_loss": current_loss_streak,
			"best_win": best_win_streak,
			"worst_loss": worst_loss_streak
		},
		"session": get_session_stats()
	}
