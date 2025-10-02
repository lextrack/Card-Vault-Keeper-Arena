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
	
	card.description = ""
	
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

static func batch_create_cards(templates: Array) -> Array[CardData]:
	var cards: Array[CardData] = []
	
	for item in templates:
		if item is Dictionary:
			if item.has("template") and item.has("count"):
				var template = item.get("template")
				var count = item.get("count", 1)
				for i in range(count):
					var card = from_template(template)
					if card:
						cards.append(card)
			else:
				var card = from_template(item)
				if card:
					cards.append(card)
	
	return cards
