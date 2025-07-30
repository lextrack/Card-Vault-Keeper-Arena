class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var damage: int
@export var heal: int
@export var shield: int
@export var card_type: String # "attack", "heal", "shield"
@export var description: String

func _init(name: String = "", c: int = 1, dmg: int = 0, h: int = 0, s: int = 0, type: String = "attack", desc: String = ""):
	card_name = name
	cost = c
	damage = dmg
	heal = h
	shield = s
	card_type = type
	description = desc
