class_name CardProbability
extends RefCounted

static func get_all_card_templates() -> Array:
	var templates = CardDatabase.get_all_card_templates()
	var old_format = []
	
	for template in templates:
		var old_template = CardTemplate.new(
			template.get("name", ""),
			template.get("cost", 1),
			template.get("damage", 0),
			template.get("heal", 0),
			template.get("shield", 0),
			template.get("type", "attack"),
			_generate_old_description(template),
			RaritySystem.get_rarity_string(template.get("rarity", RaritySystem.Rarity.COMMON)),
			template.get("weight", 50)
		)
		old_format.append(old_template)
	
	return old_format

static func create_weighted_deck(deck_size: int = 30) -> Array:
	return DeckGenerator.create_random_deck(deck_size)

static func create_balanced_deck(
	deck_size: int = 30,
	attack_ratio: float = 0.8,
	heal_ratio: float = 0.12,
	shield_ratio: float = 0.08
) -> Array:
	return DeckGenerator.create_balanced_deck(deck_size, attack_ratio, heal_ratio, shield_ratio)

static func get_rarity_color(rarity: String) -> Color:
	var rarity_enum = RaritySystem.string_to_rarity(rarity)
	return RaritySystem.get_rarity_color(rarity_enum)

static func calculate_card_rarity(damage: int, heal: int, shield: int) -> String:
	var rarity_enum = RaritySystem.calculate_card_rarity(damage, heal, shield)
	return RaritySystem.get_rarity_string(rarity_enum)

static func get_deck_stats(deck: Array) -> Dictionary:
	var analysis = DeckGenerator.analyze_deck(deck)
	
	return {
		"total_cards": analysis.total_cards,
		"common": analysis.rarity_distribution.get("common", 0),
		"uncommon": analysis.rarity_distribution.get("uncommon", 0),
		"rare": analysis.rarity_distribution.get("rare", 0),
		"epic": analysis.rarity_distribution.get("epic", 0),
		"attack_cards": analysis.type_distribution.get("attack", 0),
		"heal_cards": analysis.type_distribution.get("heal", 0),
		"shield_cards": analysis.type_distribution.get("shield", 0)
	}

static func create_deck_for_difficulty(difficulty: String, deck_size: int = 30) -> Array:
	return DeckGenerator.create_difficulty_deck(difficulty, deck_size)

static func create_themed_deck(theme: String, deck_size: int = 30) -> Array:
	return DeckGenerator.create_themed_deck(theme, deck_size)

static func analyze_deck_balance(deck: Array) -> Dictionary:
	return DeckGenerator.analyze_deck(deck)

static func get_deck_suggestions(deck: Array) -> Array:
	return DeckGenerator.suggest_deck_improvements(deck)

static func create_starter_deck() -> Array:
	return DeckGenerator.create_starter_deck()

static func validate_card_database() -> Dictionary:
	return CardDatabase.validate_database()

static func get_card_by_name(name: String) -> Dictionary:
	return CardDatabase.find_card_by_name(name)

static func get_cards_by_type(card_type: String) -> Array:
	var templates = CardDatabase.get_cards_by_type(card_type)
	var old_format = []
	
	for template in templates:
		var old_template = CardTemplate.new(
			template.get("name", ""),
			template.get("cost", 1),
			template.get("damage", 0),
			template.get("heal", 0),
			template.get("shield", 0),
			template.get("type", "attack"),
			_generate_old_description(template),
			RaritySystem.get_rarity_string(template.get("rarity", RaritySystem.Rarity.COMMON)),
			template.get("weight", 50)
		)
		old_format.append(old_template)
	
	return old_format

static func create_optimized_deck(difficulty: String, player_stats: Dictionary = {}) -> Array:
	var config = DeckConfig.create_for_difficulty(difficulty)
	
	if player_stats.has("preferred_style"):
		match player_stats.preferred_style:
			"aggressive":
				config.attack_ratio = 0.85
				config.heal_ratio = 0.10
				config.shield_ratio = 0.05
			"defensive":
				config.attack_ratio = 0.50
				config.heal_ratio = 0.30
				config.shield_ratio = 0.20
	
	return DeckGenerator.create_deck(config)

static func get_pool_statistics() -> Dictionary:
	var pool = WeightedCardPool.new()
	pool.add_templates(CardDatabase.get_all_card_templates())
	return pool.get_pool_stats()

static func simulate_deck_draws(deck: Array, draws: int = 1000) -> Dictionary:
	var simulation = {
		"total_draws": draws,
		"rarity_draws": {},
		"type_draws": {},
		"cost_distribution": {},
		"average_cost": 0.0
	}
	
	for rarity in ["common", "uncommon", "rare", "epic"]:
		simulation.rarity_draws[rarity] = 0
	
	for type in ["attack", "heal", "shield"]:
		simulation.type_draws[type] = 0
	
	var total_cost = 0
	
	for i in range(draws):
		if deck.size() == 0:
			break
			
		var random_card = deck[randi() % deck.size()]
		if not random_card is CardData:
			continue
		
		var rarity = calculate_card_rarity(random_card.damage, random_card.heal, random_card.shield)
		simulation.rarity_draws[rarity] += 1
		
		if simulation.type_draws.has(random_card.card_type):
			simulation.type_draws[random_card.card_type] += 1
		
		total_cost += random_card.cost
		if not simulation.cost_distribution.has(random_card.cost):
			simulation.cost_distribution[random_card.cost] = 0
		simulation.cost_distribution[random_card.cost] += 1
	
	simulation.average_cost = float(total_cost) / draws if draws > 0 else 0.0
	
	return simulation

# Clase de compatibilidad
class CardTemplate:
	var name: String
	var cost: int
	var damage: int
	var heal: int
	var shield: int
	var type: String
	var description: String
	var rarity: String
	var weight: int
	
	func _init(n: String, c: int, dmg: int, h: int, s: int, t: String, desc: String, r: String, w: int):
		name = n
		cost = c
		damage = dmg
		heal = h
		shield = s
		type = t
		description = desc
		rarity = r
		weight = w

# Métodos privados para compatibilidad
static func _generate_old_description(template: Dictionary) -> String:
	var effects = []
	
	if template.get("damage", 0) > 0:
		effects.append("Damage: " + str(template.damage))
	
	if template.get("heal", 0) > 0:
		effects.append("Heal: " + str(template.heal))
	
	if template.get("shield", 0) > 0:
		effects.append("Shield: " + str(template.shield))
	
	return " | ".join(effects) if effects.size() > 0 else "No effect"

static func _generate_cards_from_templates(templates: Array, count: int) -> Array:
	var pool = WeightedCardPool.new()
	
	for template in templates:
		if template is CardTemplate:
			var dict_template = {
				"name": template.name,
				"cost": template.cost,
				"damage": template.damage,
				"heal": template.heal,
				"shield": template.shield,
				"type": template.type,
				"rarity": RaritySystem.string_to_rarity(template.rarity),
				"weight": template.weight
			}
			pool.add_template(dict_template)
	
	return pool.generate_cards(count)

static func benchmark_deck_generation(iterations: int = 100) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	for i in range(iterations):
		DeckGenerator.create_random_deck()
	
	var end_time = Time.get_ticks_msec()
	var total_time = end_time - start_time
	
	return {
		"iterations": iterations,
		"total_time_ms": total_time,
		"average_time_ms": float(total_time) / iterations,
		"decks_per_second": float(iterations) / (total_time / 1000.0)
	}

static func find_optimal_deck_config(target_winrate: float = 0.6) -> DeckConfig:
	var best_config = DeckConfig.new()
	var best_score = 0.0
	
	var test_configs = [
		DeckConfig.new(30, 0.70, 0.20, 0.10),  # Balanceado
		DeckConfig.new(30, 0.80, 0.15, 0.05),  # Agresivo
		DeckConfig.new(30, 0.60, 0.25, 0.15),  # Controlador
		DeckConfig.new(30, 0.75, 0.15, 0.10),  # Híbrido
	]
	
	for config in test_configs:
		var test_deck = DeckGenerator.create_deck(config)
		var analysis = DeckGenerator.analyze_deck(test_deck)
		
		var score = analysis.balance_score
		if analysis.balance_score >= target_winrate * 10:
			score += 2.0
		
		if score > best_score:
			best_score = score
			best_config = config
	
	return best_config

static func export_deck_to_json(deck: Array) -> String:
	var deck_data = []
	
	for card in deck:
		if card is CardData:
			deck_data.append({
				"name": card.card_name,
				"cost": card.cost,
				"damage": card.damage,
				"heal": card.heal,
				"shield": card.shield,
				"type": card.card_type,
				"description": card.description
			})
	
	return JSON.stringify(deck_data)

static func import_deck_from_json(json_string: String) -> Array:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Error parsing deck JSON")
		return []
	
	var deck_data = json.get_data()
	var deck: Array[CardData] = []
	
	if deck_data is Array:
		for card_data in deck_data:
			if card_data is Dictionary:
				var card = CardBuilder.from_template(card_data)
				if card:
					deck.append(card)
	
	return deck

static func get_meta_analysis() -> Dictionary:
	var all_templates = CardDatabase.get_all_card_templates()
	var meta = {
		"most_efficient_cards": [],
		"power_creep_analysis": {},
		"cost_efficiency_by_type": {},
		"rarity_value_analysis": {}
	}
	
	var efficiency_list = []
	for template in all_templates:
		var power = template.get("damage", 0) + template.get("heal", 0) + template.get("shield", 0)
		var cost = template.get("cost", 1)
		var efficiency = float(power) / cost
		
		efficiency_list.append({
			"name": template.get("name", ""),
			"efficiency": efficiency,
			"power": power,
			"cost": cost,
			"type": template.get("type", ""),
			"rarity": RaritySystem.get_rarity_string(template.get("rarity", RaritySystem.Rarity.COMMON))
		})
	
	efficiency_list.sort_custom(func(a, b): return a.efficiency > b.efficiency)
	meta.most_efficient_cards = efficiency_list.slice(0, 10)  # Top 10
	
	var types = ["attack", "heal", "shield"]
	for type in types:
		var type_cards = CardDatabase.get_cards_by_type(type)
		var total_efficiency = 0.0
		var count = 0
		
		for template in type_cards:
			var power = template.get("damage", 0) + template.get("heal", 0) + template.get("shield", 0)
			var cost = template.get("cost", 1)
			total_efficiency += float(power) / cost
			count += 1
		
		meta.cost_efficiency_by_type[type] = total_efficiency / count if count > 0 else 0.0
	
	return meta

static func create_counter_deck(opponent_deck: Array) -> Array:
	var analysis = DeckGenerator.analyze_deck(opponent_deck)
	var config = DeckConfig.new()
	
	var opponent_attack_ratio = float(analysis.type_distribution.get("attack", 0)) / analysis.total_cards
	if opponent_attack_ratio > 0.8:
		config.attack_ratio = 0.50
		config.heal_ratio = 0.30
		config.shield_ratio = 0.20
	elif opponent_attack_ratio < 0.5:
		config.attack_ratio = 0.85
		config.heal_ratio = 0.10
		config.shield_ratio = 0.05
	else:
		config.attack_ratio = 0.70
		config.heal_ratio = 0.20
		config.shield_ratio = 0.10
	
	return DeckGenerator.create_deck(config)

static func generate_random_viable_deck(min_score: float = 6.0, max_attempts: int = 50) -> Array:
	for attempt in range(max_attempts):
		var deck = DeckGenerator.create_random_deck()
		var analysis = DeckGenerator.analyze_deck(deck)
		
		if analysis.balance_score >= min_score:
			return deck
	
	push_warning("Unable to generate a viable randomized deck, creating a balanced deck.")
	return DeckGenerator.create_balanced_deck()

static func test_deck_consistency(deck: Array, simulations: int = 1000) -> Dictionary:
	var results = {
		"simulations": simulations,
		"playable_turn_1": 0,
		"playable_turn_2": 0,
		"playable_turn_3": 0,
		"average_playable_cards": 0.0,
		"consistency_score": 0.0
	}
	
	var total_playable = 0
	
	for i in range(simulations):
		var test_deck = deck.duplicate()
		test_deck.shuffle()
		
		var hand = test_deck.slice(0, 5)
		
		var turn_1_playable = 0
		var turn_2_playable = 0
		var turn_3_playable = 0
		
		for card in hand:
			if card is CardData:
				if card.cost <= 1:
					turn_1_playable += 1
				if card.cost <= 2:
					turn_2_playable += 1
				if card.cost <= 3:
					turn_3_playable += 1
		
		if turn_1_playable > 0:
			results.playable_turn_1 += 1
		if turn_2_playable > 0:
			results.playable_turn_2 += 1
		if turn_3_playable > 0:
			results.playable_turn_3 += 1
		
		total_playable += turn_1_playable + turn_2_playable + turn_3_playable
	
	results.average_playable_cards = float(total_playable) / (simulations * 3)
	
	var turn_1_rate = float(results.playable_turn_1) / simulations
	var turn_2_rate = float(results.playable_turn_2) / simulations
	var turn_3_rate = float(results.playable_turn_3) / simulations
	
	results.consistency_score = (turn_1_rate * 0.5) + (turn_2_rate * 0.3) + (turn_3_rate * 0.2)
	
	return results

static func debug_print_deck_info(deck: Array):
	print("=== DECK INFORMATION ===")
	var analysis = DeckGenerator.analyze_deck(deck)
	
	print("Size: ", analysis.total_cards)
	print("Average cost: ", "%.2f" % analysis.average_cost)
	print("Total power: ", analysis.power_level)
	print("Balance score: ", "%.2f" % analysis.balance_score)
	
	print("\nType distribution:")
	for type in analysis.type_distribution:
		print("  ", type, ": ", analysis.type_distribution[type])
	
	print("\nRarity distribution:")
	for rarity in analysis.rarity_distribution:
		print("  ", rarity, ": ", analysis.rarity_distribution[rarity])
	
	print("\nSuggestions:")
	var suggestions = DeckGenerator.suggest_deck_improvements(deck)
	for suggestion in suggestions:
		print("  - ", suggestion)

static func run_full_validation() -> Dictionary:
	var validation = {
		"database_valid": true,
		"generation_working": true,
		"errors": [],
		"warnings": []
	}
	
	var db_validation = CardDatabase.validate_database()
	if not db_validation.valid:
		validation.database_valid = false
		validation.errors.append_array(db_validation.errors)
	validation.warnings.append_array(db_validation.warnings)
	
	var test_deck = DeckGenerator.create_random_deck()
	if test_deck == null or test_deck.size() == 0:
		validation.generation_working = false
		validation.errors.append("Deck generation not producing cards")
	
	return validation
