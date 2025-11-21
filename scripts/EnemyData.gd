class_name EnemyData
extends Resource

@export var enemy_name: String = ""
@export var is_boss: bool = false
@export var difficulty: String = "normal"
@export var negative_effect: String = ""
@export var negative_effect_description: String = ""

func _init(
	name: String = "",
	boss: bool = false,
	diff: String = "normal",
	effect: String = "",
	effect_desc: String = ""
):
	enemy_name = name
	is_boss = boss
	difficulty = diff
	negative_effect = effect
	negative_effect_description = effect_desc

func get_hp() -> int:
	var config = GameBalance.get_ai_config(difficulty)
	return config.hp

func get_mana() -> int:
	var config = GameBalance.get_ai_config(difficulty)
	return config.mana

func get_display_name() -> String:
	if is_boss:
		return "[BOSS] " + enemy_name
	else:
		return enemy_name

func has_negative_effect() -> bool:
	return negative_effect != "" and is_boss
