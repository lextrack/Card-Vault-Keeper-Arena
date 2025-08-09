class_name DeckConfig
extends Resource

@export var deck_size: int = 30
@export var attack_ratio: float = 0.7
@export var heal_ratio: float = 0.2
@export var shield_ratio: float = 0.1
@export var hybrid_ratio: float = 0.0
@export var difficulty: String = "normal"
@export var guaranteed_rarities: bool = true
@export var min_heal_cards: int = 2
@export var min_shield_cards: int = 2
@export var min_attack_cards: int = 15
@export var min_hybrid_cards: int = 1

func _init(
	size: int = 30,
	attack: float = 0.7,
	heal: float = 0.2,
	shield: float = 0.1,
	hybrid: float = 0.0,
	diff: String = "normal"
):
	deck_size = size
	attack_ratio = attack
	heal_ratio = heal
	shield_ratio = shield
	hybrid_ratio = hybrid
	difficulty = diff

func get_target_attack_cards() -> int:
	return max(min_attack_cards, int(deck_size * attack_ratio))

func get_target_heal_cards() -> int:
	return max(min_heal_cards, int(deck_size * heal_ratio))

func get_target_shield_cards() -> int:
	return max(min_shield_cards, int(deck_size * shield_ratio))

func get_target_hybrid_cards() -> int:
	return max(min_hybrid_cards, int(deck_size * hybrid_ratio))

func normalize_ratios():
	var total = attack_ratio + heal_ratio + shield_ratio + hybrid_ratio
	if total > 0:
		attack_ratio /= total
		heal_ratio /= total
		shield_ratio /= total
		hybrid_ratio /= total
	else:
		attack_ratio = 0.7
		heal_ratio = 0.2
		shield_ratio = 0.1
		hybrid_ratio = 0.0

func validate() -> bool:
	var total_ratio = attack_ratio + heal_ratio + shield_ratio + hybrid_ratio
	var is_valid = abs(total_ratio - 1.0) < 0.02
	
	if not is_valid:
		print("DeckConfig validation failed. Total ratio: ", total_ratio)
		print("Ratios: attack=", attack_ratio, " heal=", heal_ratio, " shield=", shield_ratio, " hybrid=", hybrid_ratio)
	
	return is_valid

static func create_for_difficulty(difficulty: String):
	var distribution = GameBalance.get_card_distribution(difficulty)
	var player_config = GameBalance.get_player_config(difficulty)
	
	var config = DeckConfig.new()
	config.deck_size = player_config.deck_size
	config.attack_ratio = distribution.attack_ratio
	config.heal_ratio = distribution.heal_ratio
	config.shield_ratio = distribution.shield_ratio
	config.hybrid_ratio = distribution.hybrid_ratio
	config.difficulty = difficulty

	if not config.validate():
		print("Auto-normalizing ratios for difficulty: ", difficulty)
		config.normalize_ratios()
	
	return config

func get_description() -> String:
	return "Size: %d | Attack: %d%% | Heal: %d%% | Shield: %d%% | Hybrid: %d%%" % [
		deck_size,
		int(attack_ratio * 100),
		int(heal_ratio * 100),
		int(shield_ratio * 100),
		int(hybrid_ratio * 100)
	]
