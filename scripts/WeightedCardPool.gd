class_name WeightedCardPool
extends RefCounted

var _card_pool: Array = []
var _total_weight: int = 0
var _rarity_guaranteed: Dictionary = {}

func clear():
	_card_pool.clear()
	_total_weight = 0
	_rarity_guaranteed.clear()

func add_template(template: Dictionary, weight_override: int = -1):
	var card_name = template.get("name", "")
	
	if UnlockManagers and not UnlockManagers.is_card_available(card_name):
		if OS.is_debug_build():
			print("WeightedCardPool: Skipping locked card: ", card_name)
		return
	
	var weight = weight_override if weight_override > 0 else template.get("weight", 50)
	var rarity = template.get("rarity", RaritySystem.Rarity.COMMON)
	
	var pool_entry = {
		"template": template,
		"weight": weight,
		"rarity": rarity
	}
	
	_card_pool.append(pool_entry)
	_total_weight += weight
	
	if not _rarity_guaranteed.has(rarity):
		_rarity_guaranteed[rarity] = template
		
func add_available_cards_by_type(card_type: String, target_count: int):
	var templates = CardDatabase.get_available_cards_by_type(card_type)
	
	for template in templates:
		var rarity = template.get("rarity", RaritySystem.Rarity.COMMON)
		var base_weight = RaritySystem.get_weight(rarity)
		
		var adjusted_weight = _calculate_adjusted_weight(base_weight, target_count, templates.size())
		
		add_template(template, adjusted_weight)

func add_available_cards_by_rarity(rarity: RaritySystem.Rarity, target_count: int):
	var templates = CardDatabase.get_available_cards_by_rarity(rarity)
	
	for template in templates:
		add_template(template)

func add_available_templates(templates: Array):
	for template in templates:
		var card_name = template.get("name", "")
		if not UnlockManagers or UnlockManagers.is_card_available(card_name):
			add_template(template)
		else:
			if OS.is_debug_build():
				print("Skipping locked card: ", card_name)

func generate_available_deck(deck_size: int, config: DeckConfig = null) -> Array:
	if _card_pool.size() == 0:
		push_error("Empty card pool - no available cards")
		return []
	
	var deck: Array = []
	var rarity_counts: Dictionary = {}
	var locked_attempts = 0
	
	for rarity in RaritySystem.get_all_rarities():
		rarity_counts[rarity] = 0

	if config and config.guaranteed_rarities:
		_add_guaranteed_available_cards(deck, rarity_counts)
	
	while deck.size() < deck_size and locked_attempts < deck_size * 3:
		var template = _select_weighted_template()
		if template.is_empty():
			break
		
		var card_name = template.get("name", "")
		if not CardDatabase.is_card_available(card_name):
			locked_attempts += 1
			if OS.is_debug_build() and locked_attempts % 10 == 0:
				print("WeightedCardPool: ", locked_attempts, " locked card attempts")
			continue
			
		var card = CardBuilder.from_template(template)
		
		if card:
			deck.append(card)
			var rarity = RaritySystem.calculate_card_rarity(card.damage, card.heal, card.shield)
			rarity_counts[rarity] += 1
	
	if locked_attempts >= deck_size * 3:
		push_warning("WeightedCardPool: Excessive locked card attempts (" + str(locked_attempts) + ")")
	
	deck.shuffle()
	
	return deck

func add_templates(templates: Array):
	var filtered_count = 0
	var filtered_names = []
	
	for template in templates:
		var card_name = template.get("name", "")
		if not UnlockManagers or UnlockManagers.is_card_available(card_name):
			add_template(template)
		else:
			filtered_count += 1
			if filtered_names.size() < 5:
				filtered_names.append(card_name)
	
	if OS.is_debug_build() and filtered_count > 0:
		if filtered_count <= 5:
			print("WeightedCardPool: Filtered ", filtered_count, " locked cards: ", filtered_names)
		else:
			print("WeightedCardPool: Filtered ", filtered_count, " locked cards (showing first 5): ", filtered_names, "...")

func add_cards_by_type(card_type: String, target_count: int):
	var templates = CardDatabase.get_cards_by_type(card_type)
	
	for template in templates:
		var rarity = template.get("rarity", RaritySystem.Rarity.COMMON)
		var base_weight = RaritySystem.get_weight(rarity)
		
		var adjusted_weight = _calculate_adjusted_weight(base_weight, target_count, templates.size())
		
		add_template(template, adjusted_weight)

func add_cards_by_rarity(rarity: RaritySystem.Rarity, target_count: int):
	var templates = CardDatabase.get_cards_by_rarity(rarity)
	
	for template in templates:
		add_template(template)
		
func _add_guaranteed_available_cards(deck: Array, rarity_counts: Dictionary):
	for rarity in _rarity_guaranteed.keys():
		if RaritySystem.should_guarantee_rarity(rarity, rarity_counts.get(rarity, 0)):
			var template = _rarity_guaranteed[rarity]
			var card_name = template.get("name", "")
			
			if CardDatabase.is_card_available(card_name):
				var card = CardBuilder.from_template(template)
				
				if card:
					deck.append(card)
					rarity_counts[rarity] += 1

func generate_deck(deck_size: int, config: DeckConfig = null) -> Array:
	return generate_available_deck(deck_size, config)

func generate_cards(count: int) -> Array:
	var cards: Array = []
	
	for i in range(count):
		var template = _select_weighted_template()
		if template.is_empty():
			break
			
		var card = CardBuilder.from_template(template)
		
		if card:
			cards.append(card)
	
	return cards

func get_pool_stats() -> Dictionary:
	var stats = {
		"total_cards": _card_pool.size(),
		"total_weight": _total_weight,
		"rarity_distribution": {},
		"type_distribution": {}
	}
	
	for rarity in RaritySystem.get_all_rarities():
		stats.rarity_distribution[rarity] = 0
	
	var types = ["attack", "heal", "shield"]
	for type in types:
		stats.type_distribution[type] = 0
	
	for entry in _card_pool:
		var template = entry.template
		var rarity = template.get("rarity", RaritySystem.Rarity.COMMON)
		var type = template.get("type", "attack")
		
		stats.rarity_distribution[rarity] += 1
		if type in stats.type_distribution:
			stats.type_distribution[type] += 1
	
	return stats

func get_card_probability(template: Dictionary) -> float:
	if _total_weight <= 0:
		return 0.0
	
	var weight = template.get("weight", 50)
	return float(weight) / float(_total_weight)

func get_rarity_probability(rarity: RaritySystem.Rarity) -> float:
	var rarity_weight = 0
	
	for entry in _card_pool:
		if entry.template.get("rarity", RaritySystem.Rarity.COMMON) == rarity:
			rarity_weight += entry.weight
	
	if _total_weight <= 0:
		return 0.0
	
	return float(rarity_weight) / float(_total_weight)

func _select_weighted_template() -> Dictionary:
	if _card_pool.size() == 0:
		push_error("No cards in the pool")
		return {}
	
	if _total_weight <= 0:
		return _card_pool[randi() % _card_pool.size()].template
	
	var random_value = randi() % _total_weight
	var current_weight = 0
	
	for entry in _card_pool:
		current_weight += entry.weight
		if random_value < current_weight:
			return entry.template
	
	if _card_pool.size() > 0:
		return _card_pool[-1].template
	else:
		return {}

func _add_guaranteed_rarity_cards(deck: Array, rarity_counts: Dictionary):
	for rarity in _rarity_guaranteed.keys():
		if RaritySystem.should_guarantee_rarity(rarity, rarity_counts.get(rarity, 0)):
			var template = _rarity_guaranteed[rarity]
			var card = CardBuilder.from_template(template)
			
			if card:
				deck.append(card)
				rarity_counts[rarity] += 1

func _calculate_adjusted_weight(base_weight: int, target_count: int, available_count: int) -> int:
	if available_count <= 0:
		return base_weight
	
	var ratio = float(target_count) / float(available_count)
	return max(1, int(base_weight * ratio))

func filter_by_type(card_type: String) -> WeightedCardPool:
	var filtered_pool = WeightedCardPool.new()
	
	for entry in _card_pool:
		var template = entry.template
		if template.get("type", "") == card_type:
			filtered_pool.add_template(template, entry.weight)
	
	return filtered_pool

func filter_by_rarity(rarity: RaritySystem.Rarity) -> WeightedCardPool:
	var filtered_pool = WeightedCardPool.new()
	
	for entry in _card_pool:
		var template = entry.template
		if template.get("rarity", RaritySystem.Rarity.COMMON) == rarity:
			filtered_pool.add_template(template, entry.weight)
	
	return filtered_pool

func filter_by_cost_range(min_cost: int, max_cost: int) -> WeightedCardPool:
	var filtered_pool = WeightedCardPool.new()
	
	for entry in _card_pool:
		var template = entry.template
		var cost = template.get("cost", 1)
		
		if cost >= min_cost and cost <= max_cost:
			filtered_pool.add_template(template, entry.weight)
	
	return filtered_pool

func boost_rarity_weight(rarity: RaritySystem.Rarity, multiplier: float):
	_total_weight = 0
	
	for entry in _card_pool:
		if entry.template.get("rarity", RaritySystem.Rarity.COMMON) == rarity:
			entry.weight = int(entry.weight * multiplier)
		_total_weight += entry.weight

func reduce_rarity_weight(rarity: RaritySystem.Rarity, divisor: float):
	boost_rarity_weight(rarity, 1.0 / divisor)

func rebalance_weights():
	_total_weight = 0
	
	for entry in _card_pool:
		var rarity = entry.template.get("rarity", RaritySystem.Rarity.COMMON)
		entry.weight = RaritySystem.get_weight(rarity)
		_total_weight += entry.weight

func validate_pool() -> Dictionary:
	var validation = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"total_weight": _total_weight,
		"total_cards": _card_pool.size(),
		"locked_cards": 0,
		"available_cards": 0
	}
	
	if _card_pool.size() == 0:
		validation.errors.append("Empty card pool")
		validation.valid = false
	
	if _total_weight <= 0:
		validation.errors.append("Total pool weight is 0 or negative")
		validation.valid = false
	
	var types_found = {}
	var locked_count = 0
	var available_count = 0
	
	for entry in _card_pool:
		var template = entry.template
		var type = template.get("type", "")
		var card_name = template.get("name", "")
		
		types_found[type] = true
		
		if UnlockManagers and not UnlockManagers.is_card_available(card_name):
			locked_count += 1
		else:
			available_count += 1
	
	validation.locked_cards = locked_count
	validation.available_cards = available_count
	
	if locked_count > 0:
		validation.warnings.append(str(locked_count) + " locked cards in pool")
	
	var required_types = ["attack", "heal", "shield"]
	for type in required_types:
		if not types_found.has(type):
			validation.warnings.append("No " + type + " cards found")
	
	return validation
