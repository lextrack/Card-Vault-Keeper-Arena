class_name CardDatabase
extends RefCounted

static func get_attack_cards() -> Array[Dictionary]:
	return [
		# COMMON ATTACKS
		{
			"name": "Basic Strike",
			"cost": 1,
			"damage": 2,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 100
		},
		{
			"name": "Quick Strike",
			"cost": 1,
			"damage": 2,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 80
		},
		{
			"name": "Slash",
			"cost": 2,
			"damage": 3,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 70
		},
		{
			"name": "Sword",
			"cost": 2,
			"damage": 4,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 60
		},
		{
			"name": "Blade Strike",
			"cost": 1,
			"damage": 2,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 95
		},
		{
			"name": "Swift Cut",
			"cost": 2,
			"damage": 3,
			"type": "attack",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 75
		},
		
		# UNCOMMON ATTACKS
		{
			"name": "Sharp Sword",
			"cost": 3,
			"damage": 6,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 40
		},
		{
			"name": "War Axe",
			"cost": 3,
			"damage": 6,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 35
		},
		{
			"name": "Fierce Attack",
			"cost": 4,
			"damage": 7,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 30
		},
		{
			"name": "Power Strike",
			"cost": 3,
			"damage": 5,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 42
		},
		{
			"name": "Heavy Blow",
			"cost": 4,
			"damage": 7,
			"type": "attack",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 32
		},
		
		# RARE ATTACKS
		{
			"name": "Deep Cut",
			"cost": 4,
			"damage": 8,
			"type": "attack",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 20
		},
		{
			"name": "Critical Strike",
			"cost": 6,
			"damage": 22,
			"type": "attack",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 15
		},
		{
			"name": "Piercing Blow",
			"cost": 4,
			"damage": 9,
			"type": "attack",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 18
		},
		
		# EPIC ATTACKS
		{
			"name": "Devastating Blow",
			"cost": 5,
			"damage": 12,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 8
		},
		{
			"name": "Berserker Fury",
			"cost": 6,
			"damage": 14,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 6
		},
		{
			"name": "Execution",
			"cost": 6,
			"damage": 16,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 4
		},
		{
			"name": "Annihilation",
			"cost": 7,
			"damage": 20,
			"type": "attack",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 2
		}
	]

static func get_heal_cards() -> Array[Dictionary]:
	return [
		# COMMON HEALS
		{
			"name": "Bandage",
			"cost": 1,
			"heal": 2,
			"type": "heal",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 50
		},
		{
			"name": "Minor Potion",
			"cost": 2,
			"heal": 3,
			"type": "heal",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 40
		},
		{
			"name": "First Aid",
			"cost": 1,
			"heal": 3,
			"type": "heal",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 48
		},
		{
			"name": "Herb Salve",
			"cost": 2,
			"heal": 4,
			"type": "heal",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 35
		},
		
		# UNCOMMON HEALS
		{
			"name": "Potion",
			"cost": 2,
			"heal": 5,
			"type": "heal",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 25
		},
		{
			"name": "Healing",
			"cost": 3,
			"heal": 6,
			"type": "heal",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 20
		},
		{
			"name": "Restoration",
			"cost": 3,
			"heal": 5,
			"type": "heal",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 22
		},
		
		# RARE HEALS
		{
			"name": "Major Healing",
			"cost": 4,
			"heal": 16,
			"type": "heal",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 12
		},
		{
			"name": "Divine Cure",
			"cost": 4,
			"heal": 9,
			"type": "heal",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 10
		},
		
		# EPIC HEALS
		{
			"name": "Regeneration",
			"cost": 5,
			"heal": 12,
			"type": "heal",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 5
		}
	]

static func get_shield_cards() -> Array[Dictionary]:
	return [
		# COMMON SHIELDS
		{
			"name": "Block",
			"cost": 1,
			"shield": 2,
			"type": "shield",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 45
		},
		{
			"name": "Parry",
			"cost": 1,
			"shield": 3,
			"type": "shield",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 40
		},
		{
			"name": "Guard",
			"cost": 2,
			"shield": 4,
			"type": "shield",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 38
		},
		
		# UNCOMMON SHIELDS
		{
			"name": "Basic Shield",
			"cost": 2,
			"shield": 4,
			"type": "shield",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 25
		},
		{
			"name": "Shield",
			"cost": 2,
			"shield": 4,
			"type": "shield",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 20
		},
		{
			"name": "Iron Defense",
			"cost": 3,
			"shield": 5,
			"type": "shield",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 18
		},
		
		# RARE SHIELDS
		{
			"name": "Reinforced Shield",
			"cost": 3,
			"shield": 6,
			"type": "shield",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 10
		},
		{
			"name": "Steel Wall",
			"cost": 4,
			"shield": 8,
			"type": "shield",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 8
		},
		
		# EPIC SHIELDS
		{
			"name": "Fortress",
			"cost": 4,
			"shield": 9,
			"type": "shield",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 5
		}
	]

static func get_hybrid_cards() -> Array[Dictionary]:
	return [
		# COMMON HYBRIDS
		{
			"name": "Quick Recovery",
			"cost": 2,
			"damage": 2,
			"heal": 3,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 45
		},
		{
			"name": "Defensive Jab",
			"cost": 2,
			"damage": 3,
			"shield": 2,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 40
		},
		{
			"name": "Healing Ward",
			"cost": 3,
			"heal": 2,
			"shield": 1,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 35
		},
		{
			"name": "Combat Medic",
			"cost": 3,
			"damage": 3,
			"heal": 2,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 42
		},
		{
			"name": "Shield Strike",
			"cost": 2,
			"damage": 2,
			"shield": 1,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.COMMON,
			"weight": 38
		},
		
		# UNCOMMON HYBRIDS
		{
			"name": "Life Strike",
			"cost": 4,
			"damage": 8,
			"heal": 10,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 25
		},
		{
			"name": "Shield Bash",
			"cost": 3,
			"damage": 3,
			"shield": 2,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 20
		},
		{
			"name": "Guardian's Touch",
			"cost": 4,
			"heal": 3,
			"shield": 3,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 18
		},
		{
			"name": "Blessed Strike",
			"cost": 4,
			"damage": 3,
			"heal": 1,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 15
		},
		{
			"name": "Vampire Blade",
			"cost": 3,
			"damage": 3,
			"heal": 10,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 22
		},
		{
			"name": "Armored Strike",
			"cost": 3,
			"damage": 2,
			"shield": 3,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.UNCOMMON,
			"weight": 19
		},
		
		# RARE HYBRIDS
		{
			"name": "Paladin's Resolve",
			"cost": 4,
			"damage": 3,
			"heal": 3,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 12
		},
		{
			"name": "Divine Retribution",
			"cost": 5,
			"damage": 4,
			"heal": 2,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 10
		},
		{
			"name": "Fortress Guard",
			"cost": 5,
			"damage": 2,
			"shield": 5,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 8
		},
		{
			"name": "Battle Healer",
			"cost": 4,
			"damage": 2,
			"heal": 4,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.RARE,
			"weight": 11
		},
		
		# EPIC HYBRIDS
		{
			"name": "Warrior Saint",
			"cost": 6,
			"damage": 5,
			"heal": 4,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 5
		},
		{
			"name": "Divine Champion",
			"cost": 6,
			"damage": 4,
			"shield": 6,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 4
		},
		{
			"name": "Sacred Guardian",
			"cost": 7,
			"heal": 6,
			"shield": 5,
			"type": "hybrid",
			"rarity": RaritySystem.Rarity.EPIC,
			"weight": 3
		}
	]

static func get_all_card_templates() -> Array[Dictionary]:
	var all_cards: Array[Dictionary] = []
	all_cards.append_array(get_attack_cards())
	all_cards.append_array(get_heal_cards())
	all_cards.append_array(get_shield_cards())
	all_cards.append_array(get_hybrid_cards())
	return all_cards

static func get_available_card_templates() -> Array[Dictionary]:
	if not UnlockManagers:
		push_warning("UnlockManagers not available, returning all cards")
		return get_all_card_templates()
	
	var available_cards = UnlockManagers.get_available_cards()
	var all_templates = get_all_card_templates()
	var available_templates: Array[Dictionary] = []
	
	for template in all_templates:
		var card_name = template.get("name", "")
		if card_name in available_cards:
			available_templates.append(template)
		else:
			if OS.is_debug_build():
				print("CardDatabase: Filtering out locked card: ", card_name)
	
	if available_templates.size() == 0:
		push_error("No available card templates found! Check unlock system.")
		push_error("Available cards count: " + str(available_cards.size()))
		push_error("All templates count: " + str(all_templates.size()))
		return get_starter_fallback_templates()
	
	return available_templates
	
static func get_starter_fallback_templates() -> Array[Dictionary]:
	var starter_names = [
		"Basic Strike", "Quick Strike", "Slash", "Sword", "Blade Strike", "Swift Cut",
		"Bandage", "Minor Potion", "First Aid", "Herb Salve", "Potion",
		"Block", "Parry", "Guard", "Basic Shield",
		"Quick Recovery", "Defensive Jab", "Combat Medic", "Shield Strike"
	]
	
	var fallback_templates: Array[Dictionary] = []
	var all_templates = get_all_card_templates()
	
	for template in all_templates:
		if template.get("name", "") in starter_names:
			fallback_templates.append(template)
	
	return fallback_templates

static func is_card_available(card_name: String) -> bool:
	if not UnlockManagers:
		return true
	
	return UnlockManagers.is_card_available(card_name)

static func get_cards_by_type(card_type: String) -> Array[Dictionary]:
	match card_type.to_lower():
		"attack":
			return get_attack_cards()
		"heal":
			return get_heal_cards()
		"shield":
			return get_shield_cards()
		"hybrid":
			return get_hybrid_cards()
		_:
			push_error("Tipo de carta desconocido: " + card_type)
			return []

static func get_available_cards_by_type(card_type: String) -> Array[Dictionary]:
	var available_templates = get_available_card_templates()
	var filtered_cards: Array[Dictionary] = []
	
	for template in available_templates:
		if template.get("type", "") == card_type:
			filtered_cards.append(template)
	
	return filtered_cards

static func get_cards_by_rarity(rarity: RaritySystem.Rarity) -> Array[Dictionary]:
	var filtered_cards: Array[Dictionary] = []
	var all_cards = get_all_card_templates()
	
	for card in all_cards:
		if card.get("rarity", RaritySystem.Rarity.COMMON) == rarity:
			filtered_cards.append(card)
	
	return filtered_cards

static func get_available_cards_by_rarity(rarity: RaritySystem.Rarity) -> Array[Dictionary]:
	var available_templates = get_available_card_templates()
	var filtered_cards: Array[Dictionary] = []
	
	for template in available_templates:
		if template.get("rarity", RaritySystem.Rarity.COMMON) == rarity:
			filtered_cards.append(template)
	
	return filtered_cards

static func get_cards_by_type_and_rarity(card_type: String, rarity: RaritySystem.Rarity) -> Array[Dictionary]:
	var type_cards = get_cards_by_type(card_type)
	var filtered_cards: Array[Dictionary] = []
	
	for card in type_cards:
		if card.get("rarity", RaritySystem.Rarity.COMMON) == rarity:
			filtered_cards.append(card)
	
	return filtered_cards

static func find_card_by_name(name: String) -> Dictionary:
	var all_cards = get_all_card_templates()
	
	for card in all_cards:
		if card.get("name", "") == name:
			return card
	
	push_warning("Card not found: " + name)
	return {}

static func get_card_count() -> Dictionary:
	return {
		"attack": get_attack_cards().size(),
		"heal": get_heal_cards().size(),
		"shield": get_shield_cards().size(),
		"hybrid": get_hybrid_cards().size(),
		"total": get_all_card_templates().size()
	}

static func get_availability_stats() -> Dictionary:
	var all_cards = get_all_card_templates()
	var available_cards = get_available_card_templates()
	
	var stats = {
		"total_cards": all_cards.size(),
		"available_cards": available_cards.size(),
		"locked_cards": all_cards.size() - available_cards.size(),
		"availability_percentage": 0.0,
		"by_type": {},
		"by_rarity": {}
	}
	
	if all_cards.size() > 0:
		stats.availability_percentage = float(available_cards.size()) / float(all_cards.size()) * 100.0
	
	var types = ["attack", "heal", "shield", "hybrid"]
	for type in types:
		var total_of_type = get_cards_by_type(type).size()
		var available_of_type = get_available_cards_by_type(type).size()
		stats.by_type[type] = {
			"total": total_of_type,
			"available": available_of_type,
			"locked": total_of_type - available_of_type
		}
	
	for rarity in RaritySystem.get_all_rarities():
		var rarity_str = RaritySystem.get_rarity_string(rarity)
		var total_of_rarity = get_cards_by_rarity(rarity).size()
		var available_of_rarity = get_available_cards_by_rarity(rarity).size()
		stats.by_rarity[rarity_str] = {
			"total": total_of_rarity,
			"available": available_of_rarity,
			"locked": total_of_rarity - available_of_rarity
		}
	
	return stats

static func validate_database() -> Dictionary:
	var all_cards = get_all_card_templates()
	var validation = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"total_cards": all_cards.size()
	}
	
	var card_names = []
	
	for card in all_cards:
		if not card.has("name") or card.get("name", "") == "":
			validation.errors.append("Nameless card found")
			validation.valid = false
		
		if not card.has("type") or card.get("type", "") == "":
			validation.errors.append("Card without type: " + str(card.get("name", "No name")))
			validation.valid = false
		
		if not card.has("cost") or card.get("cost", 0) <= 0:
			validation.errors.append("Invalid cost for: " + str(card.get("name", "No name")))
			validation.valid = false
		
		var name = card.get("name", "")
		if name in card_names:
			validation.errors.append("Duplicate name: " + name)
			validation.valid = false
		else:
			card_names.append(name)
		
		var power = card.get("damage", 0) + card.get("heal", 0) + card.get("shield", 0)
		if power == 0:
			validation.warnings.append("Card with no effect: " + name)
		elif power > 25:
			validation.warnings.append("Card possibly too powerful: " + name + " (power: " + str(power) + ")")
	
	return validation

static func validate_availability() -> Dictionary:
	var validation = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"availability_issues": []
	}
	
	if not UnlockManagers:
		validation.warnings.append("UnlockManagers not available - cannot validate availability")
		return validation
	
	var stats = get_availability_stats()

	if stats.available_cards < 15:
		validation.availability_issues.append("Too few starter cards available (" + str(stats.available_cards) + "/15)")
		validation.valid = false

	for type in stats.by_type.keys():
		var type_info = stats.by_type[type]
		if type_info.available == 0:
			validation.availability_issues.append("No " + type + " cards available")
			validation.valid = false
		elif type_info.available < 2:
			validation.warnings.append("Very few " + type + " cards available (" + str(type_info.available) + ")")
	
	var starter_cards = UnlockManagers._get_starter_cards()
	var available_cards = UnlockManagers.get_available_cards()
	var missing_starters = []
	
	for starter_card in starter_cards:
		if not starter_card in available_cards:
			missing_starters.append(starter_card)
	
	if missing_starters.size() > 0:
		validation.errors.append("Missing starter cards: " + str(missing_starters))
		validation.valid = false
	
	return validation
