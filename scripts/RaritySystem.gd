class_name RaritySystem
extends RefCounted

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC
}

static func calculate_rarity_from_power(power: int) -> Rarity:
	if power >= 15:
		return Rarity.EPIC
	elif power >= 8:
		return Rarity.RARE
	elif power >= 5:
		return Rarity.UNCOMMON
	else:
		return Rarity.COMMON

static func calculate_card_rarity(damage: int, heal: int, shield: int) -> Rarity:
	var power = damage + heal + shield
	return calculate_rarity_from_power(power)

static func get_rarity_string(rarity: Rarity) -> String:
	match rarity:
		Rarity.COMMON:
			return "common"
		Rarity.UNCOMMON:
			return "uncommon"
		Rarity.RARE:
			return "rare"
		Rarity.EPIC:
			return "epic"
		_:
			return "common"

static func string_to_rarity(rarity_str: String) -> Rarity:
	match rarity_str.to_lower():
		"common":
			return Rarity.COMMON
		"uncommon":
			return Rarity.UNCOMMON
		"rare":
			return Rarity.RARE
		"epic":
			return Rarity.EPIC
		_:
			return Rarity.COMMON

static func get_weight(rarity: Rarity) -> int:
	match rarity:
		Rarity.COMMON:
			return 100
		Rarity.UNCOMMON:
			return 40
		Rarity.RARE:
			return 15
		Rarity.EPIC:
			return 5
		_:
			return 50

static func get_rarity_color(rarity: Rarity) -> Color:
	match rarity:
		Rarity.COMMON:
			return Color.WHITE
		Rarity.UNCOMMON:
			return Color.GREEN
		Rarity.RARE:
			return Color.BLUE
		Rarity.EPIC:
			return Color.PURPLE
		_:
			return Color.GRAY

static func get_rarity_text(rarity: Rarity) -> String:
	match rarity:
		Rarity.COMMON:
			return "[Común]"
		Rarity.UNCOMMON:
			return "[Poco Común]"
		Rarity.RARE:
			return "[Rara]"
		Rarity.EPIC:
			return "[ÉPICA]"
		_:
			return "[Desconocida]"

static func get_rarity_multiplier(rarity: Rarity) -> float:
	match rarity:
		Rarity.COMMON:
			return 1.0
		Rarity.UNCOMMON:
			return 2.5
		Rarity.RARE:
			return 3.2
		Rarity.EPIC:
			return 4.0
		_:
			return 1.0

static func should_guarantee_rarity(rarity: Rarity, current_count: int) -> bool:
	match rarity:
		Rarity.EPIC:
			return current_count == 0
		Rarity.RARE:
			return current_count < 2
		Rarity.UNCOMMON:
			return current_count < 5
		_:
			return false

static func get_all_rarities() -> Array[Rarity]:
	return [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE, Rarity.EPIC]

static func validate_rarity_distribution(deck: Array) -> Dictionary:
	var counts = {
		Rarity.COMMON: 0,
		Rarity.UNCOMMON: 0,
		Rarity.RARE: 0,
		Rarity.EPIC: 0
	}
	
	for card in deck:
		if card is CardData:
			var rarity = calculate_card_rarity(card.damage, card.heal, card.shield)
			counts[rarity] += 1
	
	return {
		"total_cards": deck.size(),
		"common": counts[Rarity.COMMON],
		"uncommon": counts[Rarity.UNCOMMON],
		"rare": counts[Rarity.RARE],
		"epic": counts[Rarity.EPIC],
		"is_balanced": _is_distribution_balanced(counts, deck.size())
	}

static func _is_distribution_balanced(counts: Dictionary, total: int) -> bool:
	var common_ratio = float(counts[Rarity.COMMON]) / total
	var epic_ratio = float(counts[Rarity.EPIC]) / total
	
	return common_ratio >= 0.4 and epic_ratio <= 0.15
