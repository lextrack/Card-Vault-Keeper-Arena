class_name DeckGenerator
extends RefCounted

static func create_deck(config: DeckConfig) -> Array:
	if not config.validate():
		push_warning("Invalid deck configuration, normalizing...")
		config.normalize_ratios()
	
	var pool = _create_balanced_pool(config)
	return pool.generate_deck(config.deck_size, config)

static func create_themed_deck(theme: String, deck_size: int = 30) -> Array:
	var config = _get_theme_config(theme, deck_size)
	return create_deck(config)

static func create_difficulty_deck(difficulty: String, deck_size: int = 30) -> Array:
	var config = DeckConfig.create_for_difficulty(difficulty)
	config.deck_size = deck_size
	return create_deck(config)

static func create_random_deck(deck_size: int = 30) -> Array:
	var pool = WeightedCardPool.new()
	pool.add_templates(CardDatabase.get_available_card_templates())
	return pool.generate_deck(deck_size)

static func create_custom_deck(templates: Array) -> Array:
	var cards: Array = []
	
	for template in templates:
		var card = CardBuilder.from_template(template)
		if card:
			cards.append(card)
	
	cards.shuffle()
	return cards

static func create_balanced_deck(
	deck_size: int = 30,
	attack_ratio: float = 0.7,
	heal_ratio: float = 0.2,
	shield_ratio: float = 0.1
) -> Array:
	var config = DeckConfig.new(deck_size, attack_ratio, heal_ratio, shield_ratio)
	return create_deck(config)

static func create_starter_deck() -> Array:
	if not UnlockManagers:
		return _create_emergency_deck()
	
	var config = DeckConfig.new()
	config.deck_size = 30
	config.attack_ratio = 0.60
	config.heal_ratio = 0.20 
	config.shield_ratio = 0.15
	config.hybrid_ratio = 0.05
	
	var pool = WeightedCardPool.new()
	var available_templates = CardDatabase.get_available_card_templates()
	
	if available_templates.size() < 15:
		push_error("Insufficient available templates! Using emergency deck")
		return _create_emergency_deck()
	
	for template in available_templates:
		var weight = _calculate_starter_weight(template)
		pool.add_template(template, weight)
	
	return pool.generate_deck(30, config)

static func _calculate_starter_weight(template: Dictionary) -> int:
	var card_name = template.get("name", "")
	var rarity = template.get("rarity", RaritySystem.Rarity.COMMON)
	var base_weight = RaritySystem.get_weight(rarity)
	
	var starter_cards = UnlockManagers.get_starter_cards()
	if card_name in starter_cards:
		base_weight = int(base_weight * 1.5)
	
	return base_weight

static func _create_emergency_deck() -> Array:
	var emergency_templates = [
		{"name": "Basic Strike", "cost": 1, "damage": 2, "type": "attack"},
		{"name": "Basic Strike", "cost": 1, "damage": 2, "type": "attack"},
		{"name": "Basic Strike", "cost": 1, "damage": 2, "type": "attack"},
		{"name": "Quick Strike", "cost": 1, "damage": 2, "type": "attack"},
		{"name": "Quick Strike", "cost": 1, "damage": 2, "type": "attack"},
		{"name": "Slash", "cost": 2, "damage": 3, "type": "attack"},
		{"name": "Slash", "cost": 2, "damage": 3, "type": "attack"},
		{"name": "Sword", "cost": 2, "damage": 4, "type": "attack"},
		{"name": "Sword", "cost": 2, "damage": 4, "type": "attack"},
		{"name": "Fierce Attack", "cost": 4, "damage": 7, "type": "attack"},
		{"name": "Deep Cut", "cost": 4, "damage": 8, "type": "attack"},
		{"name": "Bandage", "cost": 1, "heal": 2, "type": "heal"},
		{"name": "Bandage", "cost": 1, "heal": 2, "type": "heal"},
		{"name": "Minor Potion", "cost": 2, "heal": 3, "type": "heal"},
		{"name": "Minor Potion", "cost": 2, "heal": 3, "type": "heal"},
		{"name": "Healing", "cost": 3, "heal": 6, "type": "heal"},
		{"name": "Major Healing", "cost": 4, "heal": 8, "type": "heal"},
		{"name": "Block", "cost": 1, "shield": 2, "type": "shield"},
		{"name": "Block", "cost": 1, "shield": 2, "type": "shield"},
		{"name": "Shield", "cost": 3, "shield": 5, "type": "shield"},
		{"name": "Quick Recovery", "cost": 2, "damage": 2, "heal": 3, "type": "hybrid"},
		{"name": "Defensive Jab", "cost": 2, "damage": 3, "shield": 2, "type": "hybrid"},
		{"name": "Healing Ward", "cost": 3, "heal": 2, "shield": 1, "type": "hybrid"},
		{"name": "Basic Strike", "cost": 1, "damage": 2, "type": "attack"},
		{"name": "Quick Strike", "cost": 1, "damage": 2, "type": "attack"},
		{"name": "Slash", "cost": 2, "damage": 3, "type": "attack"},
		{"name": "Bandage", "cost": 1, "heal": 2, "type": "heal"},
		{"name": "Minor Potion", "cost": 2, "heal": 3, "type": "heal"},
		{"name": "Block", "cost": 1, "shield": 2, "type": "shield"},
		{"name": "Sword", "cost": 2, "damage": 4, "type": "attack"}
	]
	
	return create_custom_deck(emergency_templates)

static func create_arena_deck() -> Array:
	var config = DeckConfig.new()
	config.guaranteed_rarities = true
	config.deck_size = 30
	config.attack_ratio = 0.65
	config.heal_ratio = 0.25
	config.shield_ratio = 0.10
	
	return create_deck(config)

static func create_aggro_deck(deck_size: int = 30) -> Array:
	return create_themed_deck("aggressive", deck_size)

static func create_control_deck(deck_size: int = 30) -> Array:
	return create_themed_deck("defensive", deck_size)

static func create_midrange_deck(deck_size: int = 30) -> Array:
	return create_themed_deck("balanced", deck_size)

static func _create_balanced_pool(config: DeckConfig) -> WeightedCardPool:
	var pool = WeightedCardPool.new()
	
	var target_attacks = config.get_target_attack_cards()
	var target_heals = config.get_target_heal_cards()
	var target_shields = config.get_target_shield_cards()
	var target_hybrids = config.get_target_hybrid_cards()
	
	pool.add_available_cards_by_type("attack", target_attacks)
	pool.add_available_cards_by_type("heal", target_heals)
	pool.add_available_cards_by_type("shield", target_shields)
	pool.add_available_cards_by_type("hybrid", target_hybrids)
	
	return pool

static func analyze_deck(deck: Array) -> Dictionary:
	var analysis = {
		"total_cards": deck.size(),
		"average_cost": 0.0,
		"total_damage": 0,
		"total_heal": 0,
		"total_shield": 0,
		"rarity_distribution": {},
		"type_distribution": {},
		"cost_distribution": {},
		"power_level": 0,
		"balance_score": 0.0
	}
	
	for rarity in RaritySystem.get_all_rarities():
		analysis.rarity_distribution[RaritySystem.get_rarity_string(rarity)] = 0
	
	analysis.type_distribution = {"attack": 0, "heal": 0, "shield": 0, "hybrid": 0}
	
	var total_cost = 0
	var total_power = 0
	
	for card in deck:
		if not card is CardData:
			continue
		
		total_cost += card.cost
		if not analysis.cost_distribution.has(card.cost):
			analysis.cost_distribution[card.cost] = 0
		analysis.cost_distribution[card.cost] += 1
		
		analysis.total_damage += card.damage
		analysis.total_heal += card.heal
		analysis.total_shield += card.shield
		
		var card_power = card.damage + card.heal + card.shield
		total_power += card_power
		
		if analysis.type_distribution.has(card.card_type):
			analysis.type_distribution[card.card_type] += 1
		
		var rarity = RaritySystem.calculate_card_rarity(card.damage, card.heal, card.shield)
		var rarity_str = RaritySystem.get_rarity_string(rarity)
		analysis.rarity_distribution[rarity_str] += 1
	
	if deck.size() > 0:
		analysis.average_cost = float(total_cost) / deck.size()
		analysis.power_level = total_power
		analysis.balance_score = _calculate_balance_score(analysis)
	
	return analysis

static func analyze_available_deck(deck: Array) -> Dictionary:
	var analysis = analyze_deck(deck)
	
	var availability_stats = CardDatabase.get_availability_stats()
	analysis["availability_info"] = availability_stats
	analysis["uses_locked_cards"] = _deck_uses_locked_cards(deck)
	
	return analysis

static func _deck_uses_locked_cards(deck: Array) -> bool:
	if not UnlockManagers:
		return false
		
	for card in deck:
		if card is CardData:
			if not UnlockManagers.is_card_available(card.card_name):
				return true
	return false

static func _get_theme_config(theme: String, deck_size: int) -> DeckConfig:
	match theme.to_lower():
		"aggressive", "aggro":
			return DeckConfig.new(deck_size, 0.85, 0.10, 0.05, 0.0, "aggro")
		"defensive", "control":
			return DeckConfig.new(deck_size, 0.40, 0.35, 0.20, 0.05, "control")
		"balanced", "midrange":
			return DeckConfig.new(deck_size, 0.65, 0.20, 0.10, 0.05, "midrange")
		"combo":
			return DeckConfig.new(deck_size, 0.50, 0.25, 0.15, 0.10, "combo")
		"rush":
			return DeckConfig.new(deck_size, 0.90, 0.05, 0.05, 0.0, "rush")
		"tank":
			return DeckConfig.new(deck_size, 0.30, 0.30, 0.35, 0.05, "tank")
		_:
			push_warning("Unknown theme: " + theme + ", using balanced configuration")
			return DeckConfig.new(deck_size, 0.70, 0.20, 0.10, 0.0, "balanced")

static func _calculate_balance_score(analysis: Dictionary) -> float:
	var score = 5.0
	
	var total_cards = analysis.total_cards
	if total_cards > 0:
		var attack_ratio = float(analysis.type_distribution.get("attack", 0)) / total_cards
		var heal_ratio = float(analysis.type_distribution.get("heal", 0)) / total_cards
		var shield_ratio = float(analysis.type_distribution.get("shield", 0)) / total_cards
		
		if heal_ratio < 0.1:
			score -= 1.0
		if shield_ratio < 0.05:
			score -= 0.5
		
		if attack_ratio > 0.9:
			score -= 0.5
		if attack_ratio < 0.4:
			score -= 0.5
	
	var epic_count = analysis.rarity_distribution.get("epic", 0)
	var rare_count = analysis.rarity_distribution.get("rare", 0)
	
	if epic_count >= 1 and epic_count <= 3:
		score += 0.5
	if rare_count >= 3 and rare_count <= 8:
		score += 0.5
	
	return clamp(score, 0.0, 10.0)

static func suggest_deck_improvements(deck: Array) -> Array:
	var suggestions: Array = []
	var analysis = analyze_deck(deck)
	
	var total_cards = analysis.total_cards
	if total_cards == 0:
		suggestions.append("Deck is empty")
		return suggestions
	
	var attack_ratio = float(analysis.type_distribution.get("attack", 0)) / total_cards
	var heal_ratio = float(analysis.type_distribution.get("heal", 0)) / total_cards
	var shield_ratio = float(analysis.type_distribution.get("shield", 0)) / total_cards
	
	if heal_ratio < 0.1:
		suggestions.append("Consider adding more healing cards")
	
	if shield_ratio < 0.05:
		suggestions.append("Add some defense cards to survive")
	
	if attack_ratio > 0.9:
		suggestions.append("Deck is too aggressive, consider adding support cards")
	
	if analysis.average_cost > 4.0:
		suggestions.append("Average cost is high, add cheaper cards")
	
	if analysis.average_cost < 2.0:
		suggestions.append("Deck is too cheap, consider more powerful cards")
	
	var epic_count = analysis.rarity_distribution.get("epic", 0)
	if epic_count == 0:
		suggestions.append("Adding at least one epic card will improve the deck")
	
	if epic_count > 5:
		suggestions.append("Too many epic cards can make the deck inconsistent")
	
	return suggestions

static func suggest_deck_improvements_available(deck: Array) -> Array:
	var base_suggestions = suggest_deck_improvements(deck)
	var availability_suggestions: Array = []
	
	var stats = CardDatabase.get_availability_stats()
	
	if stats.locked_cards > 0:
		availability_suggestions.append("Unlock more card bundles to expand your strategic options")
	
	var locked_by_type = stats.by_type
	for type in locked_by_type.keys():
		var type_info = locked_by_type[type]
		if type_info.locked > 0:
			availability_suggestions.append("Unlock more " + type + " cards (" + str(type_info.locked) + " still locked)")
	
	var all_suggestions = base_suggestions.duplicate()
	all_suggestions.append_array(availability_suggestions)
	
	return all_suggestions

static func optimize_deck_for_difficulty(deck: Array, difficulty: String) -> Array:
	var config = DeckConfig.create_for_difficulty(difficulty)
	return create_deck(config)

static func find_card_bundle_source(card_name: String) -> String:
	if not UnlockManagers:
		return "unknown"
	
	var starter_cards = UnlockManagers.get_starter_cards()
	if card_name in starter_cards:
		return "starter"
	
	var bundles = UnlockManagers.get_all_bundles_info()
	for bundle in bundles:
		if card_name in bundle.cards:
			return bundle.name
	
	return "unknown"
