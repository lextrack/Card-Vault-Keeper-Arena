class_name RunState
extends Resource

@export var current_round: int = 1
@export var current_phase: String = "minion"
@export var player_deck_card_names: Array[String] = []
@export var player_hp: int = 50
@export var player_max_hp: int = 50
@export var enemies_faced: Array[String] = []
@export var active_negative_effect: String = ""
@export var active_negative_effect_description: String = ""
@export var current_enemy_name: String = ""

func reset():
	current_round = 1
	current_phase = "minion"
	player_deck_card_names.clear()
	player_hp = 50
	player_max_hp = 50
	enemies_faced.clear()
	active_negative_effect = ""
	active_negative_effect_description = ""
	current_enemy_name = ""

func advance_phase() -> String:
	if current_phase == "minion":
		current_phase = "boss"
		return "boss"
	elif current_phase == "boss":
		if current_round < 3:
			current_round += 1
			current_phase = "minion"
			return "minion"
		else:
			return "victory"
	return "continue"

func add_card_to_deck(card_name: String):
	player_deck_card_names.append(card_name)

func get_deck_size() -> int:
	return player_deck_card_names.size()

func is_boss_phase() -> bool:
	return current_phase == "boss"

func is_minion_phase() -> bool:
	return current_phase == "minion"

func get_progress_text() -> String:
	return "Round %d/3 - %s" % [current_round, "Boss" if is_boss_phase() else "Minion"]

func save_to_dict() -> Dictionary:
	return {
		"current_round": current_round,
		"current_phase": current_phase,
		"player_deck_card_names": player_deck_card_names.duplicate(),
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"enemies_faced": enemies_faced.duplicate(),
		"active_negative_effect": active_negative_effect,
		"active_negative_effect_description": active_negative_effect_description,
		"current_enemy_name": current_enemy_name
	}

func load_from_dict(data: Dictionary):
	current_round = data.get("current_round", 1)
	current_phase = data.get("current_phase", "minion")
	player_deck_card_names = data.get("player_deck_card_names", [])
	player_hp = data.get("player_hp", 50)
	player_max_hp = data.get("player_max_hp", 50)
	enemies_faced = data.get("enemies_faced", [])
	active_negative_effect = data.get("active_negative_effect", "")
	active_negative_effect_description = data.get("active_negative_effect_description", "")
	current_enemy_name = data.get("current_enemy_name", "")
