class_name CardDatabase
extends RefCounted

static var _all_cards_cache: Array[Dictionary] = []
static var _cards_by_name_cache: Dictionary = {}
static var _cards_by_type_cache: Dictionary = {}
static var _cards_by_rarity_cache: Dictionary = {}
static var _cache_initialized: bool = false

static func _ensure_cache_initialized():
	if _cache_initialized:
		return
	
	_initialize_card_data()
	_build_lookup_caches()
	_cache_initialized = true

static func _initialize_card_data():
	_all_cards_cache = [
		# ATTACK CARDS - Common
		{"name": "Basic Strike", "cost": 1, "damage": 2, "type": "attack", "rarity": RaritySystem.Rarity.COMMON, "weight": 100},
		{"name": "Quick Strike", "cost": 1, "damage": 2, "type": "attack", "rarity": RaritySystem.Rarity.COMMON, "weight": 80},
		{"name": "Slash", "cost": 2, "damage": 3, "type": "attack", "rarity": RaritySystem.Rarity.COMMON, "weight": 70},
		{"name": "Sword", "cost": 3, "damage": 4, "type": "attack", "rarity": RaritySystem.Rarity.COMMON, "weight": 60},
		{"name": "Blade Strike", "cost": 1, "damage": 2, "type": "attack", "rarity": RaritySystem.Rarity.COMMON, "weight": 95},
		{"name": "Swift Cut", "cost": 2, "damage": 3, "type": "attack", "rarity": RaritySystem.Rarity.COMMON, "weight": 75},
		
		# ATTACK CARDS - Uncommon
		{"name": "Sharp Sword", "cost": 4, "damage": 6, "type": "attack", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 40},
		{"name": "War Axe", "cost": 4, "damage": 6, "type": "attack", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 35},
		{"name": "Fierce Attack", "cost": 5, "damage": 7, "type": "attack", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 30},
		{"name": "Power Strike", "cost": 4, "damage": 5, "type": "attack", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 42},
		{"name": "Heavy Blow", "cost": 5, "damage": 7, "type": "attack", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 32},
		
		# ATTACK CARDS - Rare
		{"name": "Deep Cut", "cost": 7, "damage": 8, "type": "attack", "rarity": RaritySystem.Rarity.RARE, "weight": 20},
		{"name": "Critical Strike", "cost": 9, "damage": 22, "type": "attack", "rarity": RaritySystem.Rarity.RARE, "weight": 11},
		{"name": "Piercing Blow", "cost": 5, "damage": 9, "type": "attack", "rarity": RaritySystem.Rarity.RARE, "weight": 19},
		
		# ATTACK CARDS - Epic
		{"name": "Devastating Blow", "cost": 7, "damage": 12, "type": "attack", "rarity": RaritySystem.Rarity.EPIC, "weight": 8},
		{"name": "Berserker Fury", "cost": 8, "damage": 14, "type": "attack", "rarity": RaritySystem.Rarity.EPIC, "weight": 6},
		{"name": "Execution", "cost": 9, "damage": 16, "type": "attack", "rarity": RaritySystem.Rarity.EPIC, "weight": 4},
		{"name": "Annihilation", "cost": 8, "damage": 20, "type": "attack", "rarity": RaritySystem.Rarity.EPIC, "weight": 2},
		
		# HEAL CARDS - Common
		{"name": "Bandage", "cost": 1, "heal": 2, "type": "heal", "rarity": RaritySystem.Rarity.COMMON, "weight": 50},
		{"name": "Minor Potion", "cost": 2, "heal": 3, "type": "heal", "rarity": RaritySystem.Rarity.COMMON, "weight": 40},
		{"name": "First Aid", "cost": 2, "heal": 3, "type": "heal", "rarity": RaritySystem.Rarity.COMMON, "weight": 48},
		{"name": "Herb Salve", "cost": 3, "heal": 4, "type": "heal", "rarity": RaritySystem.Rarity.COMMON, "weight": 35},
		
		# HEAL CARDS - Uncommon
		{"name": "Potion", "cost": 4, "heal": 5, "type": "heal", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 25},
		{"name": "Healing", "cost": 4, "heal": 6, "type": "heal", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 20},
		{"name": "Restoration", "cost": 4, "heal": 5, "type": "heal", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 22},
		
		# HEAL CARDS - Rare
		{"name": "Major Healing", "cost": 8, "heal": 16, "type": "heal", "rarity": RaritySystem.Rarity.RARE, "weight": 12},
		{"name": "Divine Cure", "cost": 6, "heal": 10, "type": "heal", "rarity": RaritySystem.Rarity.RARE, "weight": 10},
		
		# HEAL CARDS - Epic
		{"name": "Regeneration", "cost": 5, "heal": 12, "type": "heal", "rarity": RaritySystem.Rarity.EPIC, "weight": 5},
		
		# SHIELD CARDS - Common
		{"name": "Block", "cost": 1, "shield": 2, "type": "shield", "rarity": RaritySystem.Rarity.COMMON, "weight": 45},
		{"name": "Enhanced Blocking", "cost": 5, "shield": 6, "type": "shield", "rarity": RaritySystem.Rarity.COMMON, "weight": 40},
		{"name": "Guard", "cost": 3, "shield": 4, "type": "shield", "rarity": RaritySystem.Rarity.COMMON, "weight": 38},
		
		# SHIELD CARDS - Uncommon
		{"name": "Basic Shield", "cost": 3, "shield": 4, "type": "shield", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 25},
		{"name": "Shield", "cost": 4, "shield": 5, "type": "shield", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 20},
		{"name": "Iron Defense", "cost": 5, "shield": 6, "type": "shield", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 18},
		
		# SHIELD CARDS - Rare
		{"name": "Reinforced Shield", "cost": 5, "shield": 6, "type": "shield", "rarity": RaritySystem.Rarity.RARE, "weight": 10},
		{"name": "Steel Wall", "cost": 6, "shield": 8, "type": "shield", "rarity": RaritySystem.Rarity.RARE, "weight": 8},
		
		# SHIELD CARDS - Epic
		{"name": "Fortress", "cost": 7, "shield": 9, "type": "shield", "rarity": RaritySystem.Rarity.EPIC, "weight": 5},
		
		# HYBRID CARDS - Common
		{"name": "Quick Recovery", "cost": 4, "damage": 2, "heal": 3, "type": "hybrid", "rarity": RaritySystem.Rarity.COMMON, "weight": 45},
		{"name": "Defensive Jab", "cost": 3, "damage": 3, "shield": 2, "type": "hybrid", "rarity": RaritySystem.Rarity.COMMON, "weight": 40},
		{"name": "Healing Ward", "cost": 5, "heal": 2, "shield": 2, "type": "hybrid", "rarity": RaritySystem.Rarity.COMMON, "weight": 35},
		{"name": "Combat Medic", "cost": 5, "damage": 3, "heal": 3, "type": "hybrid", "rarity": RaritySystem.Rarity.COMMON, "weight": 42},
		{"name": "Shield Strike", "cost": 4, "damage": 2, "shield": 3, "type": "hybrid", "rarity": RaritySystem.Rarity.COMMON, "weight": 38},
		
		# HYBRID CARDS - Uncommon
		{"name": "Life Strike", "cost": 6, "damage": 8, "heal": 10, "type": "hybrid", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 25},
		{"name": "Shield Bash", "cost": 4, "damage": 3, "shield": 2, "type": "hybrid", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 20},
		{"name": "Guardian's Touch", "cost": 6, "heal": 4, "shield": 6, "type": "hybrid", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 18},
		{"name": "Blessed Strike", "cost": 5, "damage": 3, "heal": 2, "type": "hybrid", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 15},
		{"name": "Vampire Blade", "cost": 6, "damage": 3, "heal": 10, "type": "hybrid", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 22},
		{"name": "Armored Strike", "cost": 4, "damage": 3, "shield": 3, "type": "hybrid", "rarity": RaritySystem.Rarity.UNCOMMON, "weight": 19},
		
		# HYBRID CARDS - Rare
		{"name": "Paladin's Resolve", "cost": 4, "damage": 4, "heal": 3, "type": "hybrid", "rarity": RaritySystem.Rarity.RARE, "weight": 12},
		{"name": "Divine Retribution", "cost": 6, "damage": 4, "heal": 5, "type": "hybrid", "rarity": RaritySystem.Rarity.RARE, "weight": 10},
		{"name": "Fortress Guard", "cost": 7, "damage": 2, "shield": 5, "type": "hybrid", "rarity": RaritySystem.Rarity.RARE, "weight": 8},
		{"name": "Battle Healer", "cost": 5, "damage": 3, "heal": 4, "type": "hybrid", "rarity": RaritySystem.Rarity.RARE, "weight": 11},
		
		# HYBRID CARDS - Epic
		{"name": "Warrior Saint", "cost": 6, "damage": 5, "heal": 4, "type": "hybrid", "rarity": RaritySystem.Rarity.EPIC, "weight": 5},
		{"name": "Divine Champion", "cost": 7, "damage": 5, "shield": 6, "type": "hybrid", "rarity": RaritySystem.Rarity.EPIC, "weight": 4},
		{"name": "Sacred Guardian", "cost": 7, "heal": 7, "shield": 5, "type": "hybrid", "rarity": RaritySystem.Rarity.EPIC, "weight": 3}
	]

static func _build_lookup_caches():
	_cards_by_name_cache.clear()
	_cards_by_type_cache = {"attack": [], "heal": [], "shield": [], "hybrid": []}
	_cards_by_rarity_cache = {}
	
	for rarity in RaritySystem.get_all_rarities():
		_cards_by_rarity_cache[rarity] = []
	
	for card in _all_cards_cache:
		var name = card.get("name", "")
		var type = card.get("type", "")
		var rarity = card.get("rarity", RaritySystem.Rarity.COMMON)
		
		_cards_by_name_cache[name] = card
		
		if type in _cards_by_type_cache:
			_cards_by_type_cache[type].append(card)
		
		if rarity in _cards_by_rarity_cache:
			_cards_by_rarity_cache[rarity].append(card)

static func get_all_card_templates() -> Array[Dictionary]:
	_ensure_cache_initialized()
	return _all_cards_cache.duplicate()

static func get_attack_cards() -> Array[Dictionary]:
	_ensure_cache_initialized()
	return _cards_by_type_cache["attack"].duplicate()

static func get_heal_cards() -> Array[Dictionary]:
	_ensure_cache_initialized()
	return _cards_by_type_cache["heal"].duplicate()

static func get_shield_cards() -> Array[Dictionary]:
	_ensure_cache_initialized()
	return _cards_by_type_cache["shield"].duplicate()

static func get_hybrid_cards() -> Array[Dictionary]:
	_ensure_cache_initialized()
	return _cards_by_type_cache["hybrid"].duplicate()

static func get_cards_by_type(card_type: String) -> Array[Dictionary]:
	_ensure_cache_initialized()
	var type_key = card_type.to_lower()
	if type_key in _cards_by_type_cache:
		return _cards_by_type_cache[type_key].duplicate()
	push_error("Unknown card type: " + card_type)
	return []

static func get_cards_by_rarity(rarity: RaritySystem.Rarity) -> Array[Dictionary]:
	_ensure_cache_initialized()
	if rarity in _cards_by_rarity_cache:
		return _cards_by_rarity_cache[rarity].duplicate()
	return []

static func find_card_by_name(name: String) -> Dictionary:
	_ensure_cache_initialized()
	if name in _cards_by_name_cache:
		return _cards_by_name_cache[name].duplicate()
	push_warning("Card not found: " + name)
	return {}

static func get_available_card_templates() -> Array[Dictionary]:
	if not UnlockManagers:
		push_warning("UnlockManagers not available, returning all cards")
		return get_all_card_templates()
	
	_ensure_cache_initialized()
	var available_cards = UnlockManagers.get_available_cards()
	var available_templates: Array[Dictionary] = []
	
	for card_name in available_cards:
		if card_name in _cards_by_name_cache:
			available_templates.append(_cards_by_name_cache[card_name].duplicate())
	
	if available_templates.size() == 0:
		push_error("No available card templates found! Check unlock system.")
		return get_starter_fallback_templates()
	
	return available_templates

static func get_available_cards_by_type(card_type: String) -> Array[Dictionary]:
	_ensure_cache_initialized()
	var type_key = card_type.to_lower()
	
	if not type_key in _cards_by_type_cache:
		return []
	
	if not UnlockManagers:
		return _cards_by_type_cache[type_key].duplicate()
	
	var available_cards = UnlockManagers.get_available_cards()
	var filtered_cards: Array[Dictionary] = []
	
	for card in _cards_by_type_cache[type_key]:
		if card.get("name", "") in available_cards:
			filtered_cards.append(card.duplicate())
	
	return filtered_cards

static func get_available_cards_by_rarity(rarity: RaritySystem.Rarity) -> Array[Dictionary]:
	_ensure_cache_initialized()
	
	if not rarity in _cards_by_rarity_cache:
		return []
	
	if not UnlockManagers:
		return _cards_by_rarity_cache[rarity].duplicate()
	
	var available_cards = UnlockManagers.get_available_cards()
	var filtered_cards: Array[Dictionary] = []
	
	for card in _cards_by_rarity_cache[rarity]:
		if card.get("name", "") in available_cards:
			filtered_cards.append(card.duplicate())
	
	return filtered_cards

static func is_card_available(card_name: String) -> bool:
	if not UnlockManagers:
		return true
	return UnlockManagers.is_card_available(card_name)

static func get_starter_fallback_templates() -> Array[Dictionary]:
	const STARTER_NAMES = [
		"Basic Strike", "Quick Strike", "Slash", "Sword", "Blade Strike", "Swift Cut",
		"Bandage", "Minor Potion", "First Aid", "Herb Salve", "Potion",
		"Block", "Enhanced Blocking", "Guard", "Basic Shield",
		"Quick Recovery", "Defensive Jab", "Combat Medic", "Shield Strike"
	]
	
	_ensure_cache_initialized()
	var fallback_templates: Array[Dictionary] = []
	
	for name in STARTER_NAMES:
		if name in _cards_by_name_cache:
			fallback_templates.append(_cards_by_name_cache[name].duplicate())
	
	return fallback_templates

static func get_card_count() -> Dictionary:
	_ensure_cache_initialized()
	return {
		"attack": _cards_by_type_cache["attack"].size(),
		"heal": _cards_by_type_cache["heal"].size(),
		"shield": _cards_by_type_cache["shield"].size(),
		"hybrid": _cards_by_type_cache["hybrid"].size(),
		"total": _all_cards_cache.size()
	}

static func get_availability_stats() -> Dictionary:
	_ensure_cache_initialized()
	var all_count = _all_cards_cache.size()
	var available_cards = get_available_card_templates()
	var available_count = available_cards.size()
	
	var stats = {
		"total_cards": all_count,
		"available_cards": available_count,
		"locked_cards": all_count - available_count,
		"availability_percentage": 0.0,
		"by_type": {},
		"by_rarity": {}
	}
	
	if all_count > 0:
		stats.availability_percentage = float(available_count) / float(all_count) * 100.0
	
	for type in ["attack", "heal", "shield", "hybrid"]:
		var total_of_type = _cards_by_type_cache[type].size()
		var available_of_type = get_available_cards_by_type(type).size()
		stats.by_type[type] = {
			"total": total_of_type,
			"available": available_of_type,
			"locked": total_of_type - available_of_type
		}
	
	for rarity in RaritySystem.get_all_rarities():
		var rarity_str = RaritySystem.get_rarity_string(rarity)
		var total_of_rarity = _cards_by_rarity_cache[rarity].size()
		var available_of_rarity = get_available_cards_by_rarity(rarity).size()
		stats.by_rarity[rarity_str] = {
			"total": total_of_rarity,
			"available": available_of_rarity,
			"locked": total_of_rarity - available_of_rarity
		}
	
	return stats

static func validate_database() -> Dictionary:
	_ensure_cache_initialized()
	var validation = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"total_cards": _all_cards_cache.size()
	}
	
	var card_names = {}
	
	for card in _all_cards_cache:
		var name = card.get("name", "")
		
		if name == "":
			validation.errors.append("Nameless card found")
			validation.valid = false
		
		if not card.has("type") or card.get("type", "") == "":
			validation.errors.append("Card without type: " + name)
			validation.valid = false
		
		if not card.has("cost") or card.get("cost", 0) <= 0:
			validation.errors.append("Invalid cost for: " + name)
			validation.valid = false
		
		if name in card_names:
			validation.errors.append("Duplicate name: " + name)
			validation.valid = false
		else:
			card_names[name] = true
		
		var power = card.get("damage", 0) + card.get("heal", 0) + card.get("shield", 0)
		if power == 0:
			validation.warnings.append("Card with no effect: " + name)
		elif power > 25:
			validation.warnings.append("Card possibly too powerful: " + name + " (power: " + str(power) + ")")
	
	return validation
	
static func get_joker_templates() -> Array[Dictionary]:
	return [
		{
			"name": "Coringa Strike",
			"cost": 1,
			"damage": 4,
			"type": "attack",
			"is_joker": true,
			"joker_effect": "attack_bonus",
			"description": "4 damage + next attack +4 damage"
		},
		{
			"name": "Coringa Heal",
			"cost": 1,
			"heal": 4,
			"type": "heal",
			"is_joker": true,
			"joker_effect": "heal_bonus",
			"description": "4 heal + next heal +50%"
		},
		{
			"name": "Coringa Shield",
			"cost": 1,
			"shield": 4,
			"type": "shield",
			"is_joker": true,
			"joker_effect": "cost_reduction",
			"description": "4 shield + next card -1 mana"
		},
		{
			"name": "Coringa Hybrid",
			"cost": 2,
			"damage": 3,
			"heal": 3,
			"type": "hybrid",
			"is_joker": true,
			"joker_effect": "hybrid_bonus",
			"description": "3 damage + 3 heal + next hybrid +70%"
		}
	]

static func clear_cache():
	_all_cards_cache.clear()
	_cards_by_name_cache.clear()
	_cards_by_type_cache.clear()
	_cards_by_rarity_cache.clear()
	_cache_initialized = false
