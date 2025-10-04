class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var damage: int
@export var heal: int
@export var shield: int
@export var card_type: String
@export var description: String
@export var is_joker: bool = false
@export var joker_effect: String = ""

func _init(name: String = "", c: int = 1, dmg: int = 0, h: int = 0, s: int = 0, type: String = "attack", desc: String = "", joker: bool = false, j_effect: String = ""):
	card_name = name
	cost = c
	damage = dmg
	heal = h
	shield = s
	card_type = type
	description = desc
	is_joker = joker
	joker_effect = j_effect

func apply_joker_effect(player: Player):
	if not is_joker or joker_effect == "":
		return
	
	match joker_effect:
		"attack_bonus":
			player.active_buffs["attack_bonus"] = 4
			player.buff_applied.emit("attack_bonus", 4)
			print("   Joker effect applied: Next attack card +4 damage")
		
		"heal_bonus":
			player.active_buffs["heal_bonus"] = 0.5
			player.buff_applied.emit("heal_bonus", 0.5)
			print("   Joker effect applied: Next heal card +50%")
		
		"cost_reduction":
			player.active_buffs["cost_reduction"] = 1
			player.buff_applied.emit("cost_reduction", 1)
			print("   Joker effect applied: Next card -1 mana")
		
		"hybrid_bonus":
			player.active_buffs["hybrid_bonus"] = 0.50
			player.buff_applied.emit("hybrid_bonus", 0.50)
			print("   Joker effect applied: Next hybrid card +50% effects")
