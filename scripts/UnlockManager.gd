class_name UnlockManager
extends Node

signal bundle_unlocked(bundle_id: String, cards: Array)
signal card_unlocked(card_name: String)
signal progress_updated(bundle_id: String, current: int, required: int)

var unlocked_bundles: Array = []
var bundle_progress: Dictionary = {}
var save_file_path: String = "user://card_unlocks.save"

var bundles: Dictionary = {
	"starter_pack": {
		"name": "Starter Pack",
		"description": "Essential cards for new fighters",
		"requirement_text": "FREE - Always available",
		"requirement_type": "free",
		"requirement_value": 0,
		"cards": ["Power Strike", "Heavy Blow", "Restoration"],
		"rarity_info": "3 Uncommon",
		"unlocked_by_default": true
	},
	
	"warrior_arsenal": {
		"name": "Warrior's Arsenal",
		"description": "Powerful offensive capabilities",
		"requirement_text": "Win 5 Normal difficulty games",
		"requirement_type": "wins_normal",
		"requirement_value": 5,
		"cards": ["Piercing Blow", "Berserker Fury", "Steel Wall"],
		"rarity_info": "1 Rare Attack, 1 Epic Attack, 1 Rare Shield"
	},
	
	"mystic_defense": {
		"name": "Mystic Defense",
		"description": "Advanced protective magic",
		"requirement_text": "Survive 15+ turns in any game",
		"requirement_type": "survive_turns",
		"requirement_value": 15,
		"cards": ["Iron Defense", "Armored Strike", "Battle Healer"],
		"rarity_info": "1 Uncommon Shield, 1 Uncommon Hybrid, 1 Rare Hybrid"
	},
	
	"speed_runner": {
		"name": "Speed Fighter",
		"description": "Cards for quick victories",
		"requirement_text": "Win a Hard game in under 8 minutes",
		"requirement_type": "speed_win_hard",
		"requirement_value": 480,
		"cards": ["Divine Cure", "Vampire Blade", "Combat Medic"],
		"rarity_info": "1 Rare Heal, 1 Uncommon Hybrid, 1 Common Hybrid"
	},
	
	"hybrid_mastery": {
		"name": "Hybrid Mastery",
		"description": "Versatile combination effects",
		"requirement_text": "Play 25 hybrid cards total",
		"requirement_type": "hybrid_cards_played",
		"requirement_value": 25,
		"cards": ["Paladin's Resolve", "Divine Retribution", "Fortress Guard"],
		"rarity_info": "3 Rare Hybrid"
	},
	
	"tactical_master": {
		"name": "Tactical Master",
		"description": "Rewards for strategic excellence",
		"requirement_text": "Win 10 games with 10+ HP remaining",
		"requirement_type": "high_hp_victories",
		"requirement_value": 10,
		"cards": ["Execution", "Regeneration", "Fortress"],
		"rarity_info": "3 Epic"
	},

	"endurance_fighter": {
		"name": "Endurance Fighter",
		"description": "Built for long battles",
		"requirement_text": "Win 3 Expert difficulty games",
		"requirement_type": "wins_expert",
		"requirement_value": 3,
		"cards": ["Warrior Saint", "Divine Champion", "Sacred Guardian"],
		"rarity_info": "3 Epic Hybrid"
	},
	
	"learning_fighter": {
		"name": "Learning Fighter",
		"description": "For those who persist through trial and error",
		"requirement_text": "Complete 3 games (win or lose)",
		"requirement_type": "games_completed",
		"requirement_value": 3,
		"cards": ["Sharp Sword", "Potion", "Basic Shield"],
		"rarity_info": "3 Uncommon"
	},

	"survivor_champion": {
		"name": "Survivor Champion",
		"description": "Victory through resilience and determination",
		"requirement_text": "Win 3 games after being reduced to 5 HP or less",
		"requirement_type": "low_hp_recoveries",
		"requirement_value": 3,
		"cards": ["Life Strike", "Major Healing", "Critical Strike", "Deep Cut", "Annihilation", "Guardian's Touch", "Blessed Strike"],
		"rarity_info": "3 Uncommon, 3 Rare, 1 Epic"
	},
	"berserker_warrior": {
		"name": "Berserker Warrior",
		"description": "Devastating attacks for the fearless fighter",
		"requirement_text": "Deal 500+ total damage across all games",
		"requirement_type": "total_damage_dealt",
		"requirement_value": 500,
		"cards": ["War Axe", "Fierce Attack", "Devastating Blow", "Healing"],
		"rarity_info": "2 Uncommon Attacks, 1 Epic Attack, 1 Uncommon"
	},

	"fortress_defender": {
		"name": "Fortress Defender",
		"description": "Ultimate protection and tactical strikes",
		"requirement_text": "Block 200+ total damage with shields",
		"requirement_type": "total_damage_blocked",
		"requirement_value": 200,
		"cards": ["Shield", "Reinforced Shield", "Shield Bash"],
		"rarity_info": "1 Uncommon Shield, 1 Rare Shield, 1 Uncommon Hybrid"
	}
}

func _ready():
	print("UnlockManager autoload initializing...")
	load_progress()
	var integrity = verify_system_integrity()
	if not integrity.card_validation.valid:
		push_error("Bundle cards validation failed: " + str(integrity.card_validation.missing_cards))
	_validate_unlocks()
	debug_validate_all_bundles()
	debug_full_card_diagnosis()
	
func fix_missing_starter_cards():
	var starter_cards = _get_starter_cards()
	var available_cards = get_available_cards()
	var fixed_count = 0
	
	for card_name in starter_cards:
		if not card_name in available_cards:
			print("Adding missing starter card: ", card_name)
			fixed_count += 1
	if not is_bundle_unlocked("starter_pack"):
		unlock_bundle("starter_pack", false)
		fixed_count += 1
		print("Re-unlocked starter_pack")
	
	if fixed_count > 0:
		save_progress()
		print("Fixed ", fixed_count, " starter card issues")
	
	return fixed_count

func debug_full_card_diagnosis():
	print("\n=== FULL CARD DIAGNOSIS ===")
	
	var stats = get_unlock_stats()
	print("Unlocked bundles: ", stats.unlocked_bundles, "/", stats.total_bundles)
	print("Completion: ", "%.1f" % stats.completion_percentage, "%")
	
	var available = get_available_cards()
	print("Available cards: ", available.size())
	
	var starter = _get_starter_cards()
	print("Starter cards defined: ", starter.size())
	
	var missing_starters = []
	for card in starter:
		if not card in available:
			missing_starters.append(card)
	
	if missing_starters.size() > 0:
		print("Missing starter cards: ", missing_starters)
	else:
		print("All starter cards available")
	
	var all_db_cards = []
	for template in CardDatabase.get_all_card_templates():
		all_db_cards.append(template.get("name", ""))
	
	print("Total cards in database: ", all_db_cards.size())
	print("Cards available to player: ", available.size())
	print("Cards locked: ", all_db_cards.size() - available.size())
	
	print("============================\n")
	
func debug_validate_all_bundles():
	print("=== VALIDATING ALL BUNDLES ===")
	var validation = validate_bundle_cards()
	
	if validation.valid:
		print("All bundle cards exist in database")
	else:
		print("Missing cards found:")
		for missing in validation.missing_cards:
			print("  Bundle '", missing.bundle, "' references missing card: ", missing.card)
	
	if validation.duplicate_cards.size() > 0:
		print("Duplicate cards found:")
		for card_name in validation.duplicate_cards.keys():
			print("  '", card_name, "' appears in bundles: ", validation.duplicate_cards[card_name])
	else:
		print("No duplicate cards between bundles")
	
func debug_print_status():
	print("=== UNLOCK MANAGER STATUS ===")
	print("Unlocked bundles: ", unlocked_bundles)
	print("Available cards: ", get_available_cards().size())
	var stats = get_unlock_stats()
	print("Completion: ", "%.1f" % stats.completion_percentage, "%")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_progress()

func _validate_unlocks():
	if not "starter_pack" in unlocked_bundles:
		unlock_bundle("starter_pack", false)
	
	for bundle_id in bundles.keys():
		if not bundle_progress.has(bundle_id):
			bundle_progress[bundle_id] = 0

	var available_cards = get_available_cards()
	if available_cards.size() < 15:
		push_error("Too few starter cards available: " + str(available_cards.size()))
		debug_unlock_all()

func get_available_cards() -> Array[String]:
	var available: Array[String] = []
	
	var starter_cards = _get_starter_cards()
	for card in starter_cards:
		available.append(card as String)
	
	for bundle_id in unlocked_bundles:
		if bundles.has(bundle_id):
			var bundle_cards = bundles[bundle_id].cards
			for card in bundle_cards:
				available.append(card as String)
	
	return available
	
func debug_validate_starter_system():
	print("=== STARTER SYSTEM VALIDATION ===")
	
	var starter_cards = _get_starter_cards()
	var available_cards = get_available_cards()
	var all_card_names = []
	
	for template in CardDatabase.get_all_card_templates():
		all_card_names.append(template.get("name", ""))
	
	print("Starter cards defined: ", starter_cards.size())
	print("Available cards total: ", available_cards.size())

	var missing_from_db = []
	for card_name in starter_cards:
		if not card_name in all_card_names:
			missing_from_db.append(card_name)
	
	if missing_from_db.size() > 0:
		print("Starter cards NOT in database: ", missing_from_db)
	else:
		print("All starter cards exist in database")
	
	var missing_from_available = []
	for card_name in starter_cards:
		if not card_name in available_cards:
			missing_from_available.append(card_name)
	
	if missing_from_available.size() > 0:
		print("Starter cards NOT available: ", missing_from_available)
	else:
		print("All starter cards are available")
	
	var starter_distribution = {"attack": 0, "heal": 0, "shield": 0, "hybrid": 0}
	for card_name in starter_cards:
		var template = CardDatabase.find_card_by_name(card_name)
		if not template.is_empty():
			var type = template.get("type", "unknown")
			if starter_distribution.has(type):
				starter_distribution[type] += 1
	
	print("Starter distribution: ", starter_distribution)
	
	var total_starter = starter_cards.size()
	if total_starter < 15:
		print("WARNING: Only ", total_starter, " starter cards (need at least 15 for viable deck)")
	else:
		print("Sufficient starter cards: ", total_starter)
	
	print("================================")

func _get_starter_cards() -> Array[String]:
	var starter_cards: Array[String] = [
		"Basic Strike",
		"Quick Strike",
		"Slash",
		"Sword",
		"Blade Strike",
		"Swift Cut",
		"Bandage",
		"Minor Potion",
		"Herb Salve",
		"First Aid",
		"Block",
		"Parry",
		"Guard",
		"Quick Recovery",
		"Defensive Jab",
		"Healing Ward",
		"Shield Strike"
	]
	
	return starter_cards

func is_card_available(card_name: String) -> bool:
	return card_name in get_available_cards()

func is_bundle_unlocked(bundle_id: String) -> bool:
	return bundle_id in unlocked_bundles

func get_bundle_info(bundle_id: String) -> Dictionary:
	if not bundles.has(bundle_id):
		return {}
	
	var info = bundles[bundle_id].duplicate()
	info["id"] = bundle_id
	info["unlocked"] = is_bundle_unlocked(bundle_id)
	info["progress"] = bundle_progress.get(bundle_id, 0)
	info["can_unlock"] = can_unlock_bundle(bundle_id)
	
	return info

func get_all_bundles_info() -> Array[Dictionary]:
	var all_bundles: Array[Dictionary] = []
	
	for bundle_id in bundles.keys():
		all_bundles.append(get_bundle_info(bundle_id))
	
	return all_bundles

func can_unlock_bundle(bundle_id: String) -> bool:
	if is_bundle_unlocked(bundle_id):
		return false
	
	if not bundles.has(bundle_id):
		return false
	
	var bundle = bundles[bundle_id]
	var current_progress = bundle_progress.get(bundle_id, 0)
	
	match bundle.requirement_type:
		"free":
			return true
		"all_bundles":
			var unlocked_count = 0
			for other_id in bundles.keys():
				if other_id != bundle_id and other_id != "starter_pack" and is_bundle_unlocked(other_id):
					unlocked_count += 1
			return unlocked_count >= bundle.requirement_value
		_:
			return current_progress >= bundle.requirement_value

func unlock_bundle(bundle_id: String, should_save: bool = true) -> Array[String]:
	if is_bundle_unlocked(bundle_id):
		return []
	
	if not can_unlock_bundle(bundle_id):
		return []
	
	unlocked_bundles.append(bundle_id)
	var new_cards: Array[String] = []
	
	var bundle_cards = bundles[bundle_id].cards
	for card in bundle_cards:
		new_cards.append(card as String)
	
	if should_save:
		save_progress()
	
	bundle_unlocked.emit(bundle_id, new_cards)
	
	for card_name in new_cards:
		card_unlocked.emit(card_name)
	
	print("Bundle unlocked: ", bundle_id, " | Cards: ", new_cards)
	
	_check_cascade_unlocks()
	
	return new_cards

func _check_cascade_unlocks():
	for bundle_id in bundles.keys():
		if not is_bundle_unlocked(bundle_id) and can_unlock_bundle(bundle_id):
			var bundle = bundles[bundle_id]
			if bundle.requirement_type == "all_bundles":
				unlock_bundle(bundle_id)

func track_progress(progress_type: String, value: int = 1, extra_data: Dictionary = {}):
	var progress_made = false
	
	for bundle_id in bundles.keys():
		if is_bundle_unlocked(bundle_id):
			continue
			
		var bundle = bundles[bundle_id]
		var old_progress = bundle_progress.get(bundle_id, 0)
		
		match bundle.requirement_type:
			"wins_normal":
				if progress_type == "game_won" and extra_data.get("difficulty") == "normal":
					bundle_progress[bundle_id] = min(old_progress + value, bundle.requirement_value)
					progress_made = true
			
			"wins_hard":
				if progress_type == "game_won" and extra_data.get("difficulty") == "hard":
					bundle_progress[bundle_id] = min(old_progress + value, bundle.requirement_value)
					progress_made = true
			
			"wins_expert":
				if progress_type == "game_won" and extra_data.get("difficulty") == "expert":
					bundle_progress[bundle_id] = min(old_progress + value, bundle.requirement_value)
					progress_made = true
			
			"survive_turns":
				if progress_type == "game_ended":
					var turns = extra_data.get("turns", 0)
					if turns >= bundle.requirement_value:
						bundle_progress[bundle_id] = bundle.requirement_value
						progress_made = true
			
			"speed_win_hard":
				if progress_type == "game_won" and extra_data.get("difficulty") == "hard":
					var game_time = extra_data.get("time", 999)
					if game_time <= bundle.requirement_value:
						bundle_progress[bundle_id] = 1
						progress_made = true
			
			"hybrid_cards_played":
				if progress_type == "card_played" and extra_data.get("card_type") == "hybrid":
					bundle_progress[bundle_id] = min(old_progress + value, bundle.requirement_value)
					progress_made = true
			
			"high_hp_victories":
				if progress_type == "game_won":
					var final_hp = extra_data.get("final_hp", 0)
					if final_hp >= 10:
						bundle_progress[bundle_id] = min(old_progress + 1, bundle.requirement_value)
						progress_made = true
					
			"games_completed":
				if progress_type == "game_ended":
					bundle_progress[bundle_id] = min(old_progress + 1, bundle.requirement_value)
					progress_made = true
			
			"low_hp_recoveries":
				if progress_type == "game_won":
					var was_low_hp = extra_data.get("was_at_low_hp", false)
					if was_low_hp:
						bundle_progress[bundle_id] = min(old_progress + 1, bundle.requirement_value)
						progress_made = true
			
			"total_wins":
				if progress_type == "game_won":
					bundle_progress[bundle_id] = min(old_progress + 1, bundle.requirement_value)
					progress_made = true
					
			"total_damage_dealt":
				if progress_type == "damage_dealt":
					bundle_progress[bundle_id] = min(old_progress + value, bundle.requirement_value)
					progress_made = true

			"total_damage_blocked":
				if progress_type == "damage_blocked":
					bundle_progress[bundle_id] = min(old_progress + value, bundle.requirement_value)
					progress_made = true
		
		var new_progress = bundle_progress.get(bundle_id, 0)
		if new_progress != old_progress:
			progress_updated.emit(bundle_id, new_progress, bundle.requirement_value)
			
			if can_unlock_bundle(bundle_id):
				unlock_bundle(bundle_id)
	
	if progress_made:
		save_progress()

func get_progress_text(bundle_id: String) -> String:
	if is_bundle_unlocked(bundle_id):
		return "UNLOCKED"
	
	if not bundles.has(bundle_id):
		return "ERROR"
	
	var bundle = bundles[bundle_id]
	var current = bundle_progress.get(bundle_id, 0)
	var required = bundle.requirement_value
	
	var displayed_current = min(current, required)
	
	match bundle.requirement_type:
		"free":
			return "FREE"
		"wins_normal", "wins_hard", "wins_expert":
			return str(displayed_current) + "/" + str(required) + " wins"
		"survive_turns":
			if displayed_current >= required:
				return "COMPLETED (" + str(required) + "+ turns)"
			else:
				return str(displayed_current) + "/" + str(required) + " turns survived"
		"speed_win_hard":
			if current > 0:
				return "COMPLETED"
			else:
				return "0/1 speed wins"
		"hybrid_cards_played":
			return str(displayed_current) + "/" + str(required) + " hybrid cards"
		"high_hp_victories":
			return str(displayed_current) + "/" + str(required) + " high HP wins"
		"all_bundles":
			var unlocked_count = 0
			for other_id in bundles.keys():
				if other_id != bundle_id and other_id != "starter_pack" and is_bundle_unlocked(other_id):
					unlocked_count += 1
			var displayed_unlocked = min(unlocked_count, required)
			return str(displayed_unlocked) + "/" + str(required) + " bundles"
		"games_completed":
			return str(displayed_current) + "/" + str(required) + " games"
		"low_hp_recoveries":
			return str(displayed_current) + "/" + str(required) + " comeback wins"
		"total_wins":
			return str(displayed_current) + "/" + str(required) + " total wins"
		"total_damage_dealt":
			return str(displayed_current) + "/" + str(required) + " damage dealt"

		"total_damage_blocked":
			return str(displayed_current) + "/" + str(required) + " damage blocked"
		_:
			return str(displayed_current) + "/" + str(required)

func save_progress():
	var save_data = {
		"version": "1.0",
		"unlocked_bundles": unlocked_bundles,
		"bundle_progress": bundle_progress
	}
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Card unlocks saved")
	else:
		push_error("Failed to save card unlocks")

func load_progress():
	if not FileAccess.file_exists(save_file_path):
		print("No unlock save found, starting fresh")
		return
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		push_error("Failed to load card unlocks")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse unlock save JSON")
		return
	
	var data = json.get_data()
	
	unlocked_bundles = data.get("unlocked_bundles", [])
	bundle_progress = data.get("bundle_progress", {})
	
	print("Card unlocks loaded - Bundles: ", unlocked_bundles.size())

func reset_all_progress():
	unlocked_bundles.clear()
	bundle_progress.clear()
	
	for bundle_id in bundles.keys():
		bundle_progress[bundle_id] = 0

	unlock_bundle("starter_pack", false)
	
	save_progress()
	print("All unlock progress reset - only starter pack remains")

func debug_unlock_all():
	print("DEBUG: Unlocking all bundles...")
	
	var unlocked_count = 0
	for bundle_id in bundles.keys():
		if not is_bundle_unlocked(bundle_id):
			unlocked_bundles.append(bundle_id)
			unlocked_count += 1

			var bundle = bundles[bundle_id]
			bundle_progress[bundle_id] = bundle.requirement_value
	
	save_progress()
	print("DEBUG: ", unlocked_count, " bundles unlocked")

func get_unlock_stats() -> Dictionary:
	return {
		"total_bundles": bundles.size(),
		"unlocked_bundles": unlocked_bundles.size(),
		"available_cards": get_available_cards().size(),
		"completion_percentage": float(unlocked_bundles.size()) / float(bundles.size()) * 100.0
	}
	
func validate_bundle_cards() -> Dictionary:
	var validation = {
		"valid": true,
		"missing_cards": [],
		"duplicate_cards": {}
	}
	
	var all_card_names = []
	for template in CardDatabase.get_all_card_templates():
		all_card_names.append(template.get("name", ""))

	for bundle_id in bundles.keys():
		var bundle_cards = bundles[bundle_id].cards
		for card_name in bundle_cards:
			if not card_name in all_card_names:
				validation.missing_cards.append({
					"bundle": bundle_id,
					"card": card_name
				})
				validation.valid = false
	
	var card_sources = {}
	for bundle_id in bundles.keys():
		for card_name in bundles[bundle_id].cards:
			if not card_sources.has(card_name):
				card_sources[card_name] = []
			card_sources[card_name].append(bundle_id)
	
	for card_name in card_sources.keys():
		if card_sources[card_name].size() > 1:
			validation.duplicate_cards[card_name] = card_sources[card_name]
	
	return validation
	
func debug_print_progress():
	print("=== UNLOCK PROGRESS DEBUG ===")
	for bundle_id in bundles.keys():
		var bundle = bundles[bundle_id]
		var progress = bundle_progress.get(bundle_id, 0)
		var required = bundle.requirement_value
		var can_unlock = can_unlock_bundle(bundle_id)
		var is_unlocked = is_bundle_unlocked(bundle_id)
		
		var status = "LOCKED"
		if is_unlocked:
			status = "UNLOCKED"
		elif can_unlock:
			status = "READY"
		
		print("  ", bundle["name"], ": ", status)
		print("    Progress: ", progress, "/", required, " (", bundle.requirement_type, ")")
		print("    Can unlock: ", can_unlock)
		
func _count_unlocked_non_special_bundles() -> int:
	var special_bundles = ["starter_pack", "card_master", "legendary_fighter"]
	var count = 0
	
	for bundle_id in unlocked_bundles:
		if not bundle_id in special_bundles:
			count += 1
	
	return count
		
func verify_system_integrity() -> Dictionary:
	var report = {
		"card_validation": validate_bundle_cards(),
		"progress_validation": {},
		"unlock_validation": {}
	}
	
	for bundle_id in bundles.keys():
		if not bundle_progress.has(bundle_id):
			if not report.progress_validation.has("missing_progress"):
				report.progress_validation["missing_progress"] = []
			report.progress_validation["missing_progress"].append(bundle_id)
	
	var starter_cards = _get_starter_cards()
	var available_cards = get_available_cards()
	var missing_starters = []
	
	for card in starter_cards:
		if not card in available_cards:
			missing_starters.append(card)
	
	if missing_starters.size() > 0:
		report.unlock_validation["missing_starter_cards"] = missing_starters
	
	return report

func reset_bundle_progress(bundle_id: String):
	if bundle_progress.has(bundle_id):
		bundle_progress[bundle_id] = 0
		save_progress()
		print("Reset progress for bundle: ", bundle_id)
