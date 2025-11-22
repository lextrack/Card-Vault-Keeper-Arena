extends Node

var _minion_pool: Array[Dictionary] = [
	{"name": "Goblin Scout", "difficulty": "normal"},
	{"name": "Wild Beast", "difficulty": "normal"},
	{"name": "Bandit Thug", "difficulty": "normal"},
	{"name": "Skeleton Warrior", "difficulty": "normal"},
	{"name": "Cave Troll", "difficulty": "normal"},
	{"name": "Dark Cultist", "difficulty": "hard"},
	{"name": "Blood Mage", "difficulty": "hard"},
	{"name": "Iron Golem", "difficulty": "hard"},
	{"name": "Shadow Assassin", "difficulty": "hard"},
	{"name": "Corrupted Knight", "difficulty": "hard"}
]

var _boss_pool: Array[Dictionary] = [
	{
		"name": "Cursed Warlord",
		"difficulty": "hard",
		"effect": "no_shield",
		"description": "You cannot use Shield cards"
	},
	{
		"name": "Plague Doctor",
		"difficulty": "hard",
		"effect": "no_heal",
		"description": "You cannot use Heal cards"
	},
	{
		"name": "Time Warden",
		"difficulty": "hard",
		"effect": "time_limit",
		"description": "Defeat the boss in 90 seconds or lose"
	},
	{
		"name": "Void Reaper",
		"difficulty": "hard",
		"effect": "increased_cost",
		"description": "All your cards cost +1 mana"
	},
	{
		"name": "Soul Devourer",
		"difficulty": "expert",
		"effect": "boss_lifesteal",
		"description": "Boss heals 2 HP each turn"
	},
	{
		"name": "Ancient Dragon",
		"difficulty": "expert",
		"effect": "reduced_damage",
		"description": "Your Attack cards deal -3 damage"
	},
	{
		"name": "Demon Lord",
		"difficulty": "expert",
		"effect": "no_heal",
		"description": "You cannot use Heal cards"
	},
	{
		"name": "Necromancer King",
		"difficulty": "expert",
		"effect": "time_limit",
		"description": "Defeat the boss before time runs out."
	}
]

var _used_minions: Array[String] = []
var _used_bosses: Array[String] = []

func reset_used_enemies():
	_used_minions.clear()
	_used_bosses.clear()

func get_random_minion() -> EnemyData:
	var available_minions = _minion_pool.filter(func(m): return not m.name in _used_minions)
	
	if available_minions.size() == 0:
		_used_minions.clear()
		available_minions = _minion_pool.duplicate()
	
	var selected = available_minions[randi() % available_minions.size()]
	_used_minions.append(selected.name)
	
	return EnemyData.new(
		selected.name,
		false,
		selected.difficulty,
		"",
		""
	)

func get_random_boss() -> EnemyData:
	var available_bosses = _boss_pool.filter(func(b): return not b.name in _used_bosses)
	
	if available_bosses.size() == 0:
		_used_bosses.clear()
		available_bosses = _boss_pool.duplicate()
	
	var selected = available_bosses[randi() % available_bosses.size()]
	_used_bosses.append(selected.name)
	
	return EnemyData.new(
		selected.name,
		true,
		selected.difficulty,
		selected.effect,
		selected.description
	)

func get_minion_count() -> int:
	return _minion_pool.size()

func get_boss_count() -> int:
	return _boss_pool.size()

func get_all_minion_names() -> Array[String]:
	var names: Array[String] = []
	for minion in _minion_pool:
		names.append(minion.name)
	return names

func get_all_boss_names() -> Array[String]:
	var names: Array[String] = []
	for boss in _boss_pool:
		names.append(boss.name)
	return names

func get_effect_types() -> Array[String]:
	return ["no_shield", "no_heal", "reduced_damage", "increased_cost", "boss_lifesteal", "time_limit"]

func get_time_limit_for_boss(boss_name: String) -> float:
	for boss in _boss_pool:
		if boss.name == boss_name and boss.effect == "time_limit":
			if boss.difficulty == "hard":
				return 115.0
			elif boss.difficulty == "expert":
				return 95.0
	return 115.0
