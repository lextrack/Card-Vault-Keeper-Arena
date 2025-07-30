class_name CardBuilder
extends RefCounted

static func from_template(template: Dictionary) -> CardData:
	var card = CardData.new()
	
	card.card_name = template.get("name", "Unnamed Card")
	card.cost = template.get("cost", 1)
	card.card_type = template.get("type", "attack")
	
	card.damage = template.get("damage", 0)
	card.heal = template.get("heal", 0)
	card.shield = template.get("shield", 0)
	
	card.description = _generate_description(card)
	
	return card

static func create_attack_card(name: String, cost: int, damage: int) -> CardData:
	var template = {
		"name": name,
		"cost": cost,
		"damage": damage,
		"type": "attack"
	}
	return from_template(template)

static func create_heal_card(name: String, cost: int, heal: int) -> CardData:
	var template = {
		"name": name,
		"cost": cost,
		"heal": heal,
		"type": "heal"
	}
	return from_template(template)

static func create_shield_card(name: String, cost: int, shield: int) -> CardData:
	var template = {
		"name": name,
		"cost": cost,
		"shield": shield,
		"type": "shield"
	}
	return from_template(template)

static func create_hybrid_card(name: String, cost: int, damage: int, heal: int, shield: int) -> CardData:
	var template = {
		"name": name,
		"cost": cost,
		"damage": damage,
		"heal": heal,
		"shield": shield,
		"type": "hybrid"
	}
	return from_template(template)

static func create_custom_card(template: Dictionary) -> CardData:
	if not _validate_template(template):
		push_error("Invalid card template: " + str(template))
		return _create_default_card()
	
	return from_template(template)

static func _generate_description(card: CardData) -> String:
	var effects = []
	
	if card.damage > 0:
		effects.append("Damage: " + str(card.damage))
	
	if card.heal > 0:
		effects.append("Heal: " + str(card.heal))
	
	if card.shield > 0:
		effects.append("Shield: " + str(card.shield))
	
	if effects.size() == 0:
		return "No effect"
	elif effects.size() == 1:
		return effects[0]
	else:
		return " | ".join(effects)

static func _validate_template(template: Dictionary) -> bool:
	if not template.has("name") or template.get("name", "") == "":
		return false
	
	if not template.has("cost") or template.get("cost", 0) <= 0:
		return false
	
	if not template.has("type") or template.get("type", "") == "":
		return false

	var damage = template.get("damage", 0)
	var heal = template.get("heal", 0)
	var shield = template.get("shield", 0)
	
	if damage + heal + shield <= 0:
		return false
	
	if damage > 30 or heal > 30 or shield > 20:
		return false
	
	return true

static func _create_default_card() -> CardData:
	var default_template = {
		"name": "Basic Card",
		"cost": 1,
		"damage": 1,
		"type": "attack"
	}
	return from_template(default_template)

static func clone_card(original: CardData) -> CardData:
	var template = {
		"name": original.card_name,
		"cost": original.cost,
		"damage": original.damage,
		"heal": original.heal,
		"shield": original.shield,
		"type": original.card_type
	}
	return from_template(template)

static func modify_card(original: CardData, modifications: Dictionary) -> CardData:
	var template = {
		"name": modifications.get("name", original.card_name),
		"cost": modifications.get("cost", original.cost),
		"damage": modifications.get("damage", original.damage),
		"heal": modifications.get("heal", original.heal),
		"shield": modifications.get("shield", original.shield),
		"type": modifications.get("type", original.card_type)
	}
	return from_template(template)

static func scale_card_power(card: CardData, multiplier: float) -> CardData:
	var template = {
		"name": card.card_name + " (Upgraded)",
		"cost": max(1, int(card.cost * multiplier)),
		"damage": int(card.damage * multiplier),
		"heal": int(card.heal * multiplier),
		"shield": int(card.shield * multiplier),
		"type": card.card_type
	}
	return from_template(template)

static func create_upgraded_version(card: CardData) -> CardData:
	return scale_card_power(card, 1.5)

static func get_card_power(card: CardData) -> int:
	return card.damage + card.heal + card.shield

static func get_card_efficiency(card: CardData) -> float:
	var power = get_card_power(card)
	if card.cost <= 0:
		return 0.0
	return float(power) / float(card.cost)

static func compare_cards(card1: CardData, card2: CardData) -> Dictionary:
	return {
		"card1_power": get_card_power(card1),
		"card2_power": get_card_power(card2),
		"card1_efficiency": get_card_efficiency(card1),
		"card2_efficiency": get_card_efficiency(card2),
		"more_powerful": card1 if get_card_power(card1) > get_card_power(card2) else card2,
		"more_efficient": card1 if get_card_efficiency(card1) > get_card_efficiency(card2) else card2
	}

static func create_cards_from_templates(templates: Array[Dictionary]) -> Array[CardData]:
	var cards: Array[CardData] = []
	
	for template in templates:
		var card = from_template(template)
		if card:
			cards.append(card)
	
	return cards

static func batch_create_cards(card_configs: Array[Dictionary]) -> Array[CardData]:
	var results: Array[CardData] = []
	
	for config in card_configs:
		var count = config.get("count", 1)
		var template = config.get("template", {})
		
		for i in range(count):
			var card = from_template(template)
			if card:
				results.append(card)
	
	return results
