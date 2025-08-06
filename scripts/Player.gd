class_name Player
extends Node

signal ai_damage_dealt(damage: int)

@export var difficulty: String = "normal"
@export var is_ai: bool = false

var max_hp: int
var max_mana: int
var max_hand_size: int
var max_cards_per_turn: int

var current_hp: int
var current_mana: int
var current_shield: int = 0
var hand: Array = []
var deck: Array = []
var discard_pile: Array = []
var cards_played_this_turn: int = 0
var turn_number: int = 0
var was_at_low_hp_this_game: bool = false
var total_damage_this_game: int = 0
var ai_turn_active: bool = false
var should_stop_ai_turn: bool = false

signal hp_changed(new_hp: int)
signal mana_changed(new_mana: int)
signal shield_changed(new_shield: int)
signal player_died
signal hand_changed
signal deck_empty
signal cards_played_changed(cards_played: int, max_cards: int)
signal turn_changed(turn_num: int, damage_bonus: int)
signal ai_card_played(card: CardData)
signal card_drawn(cards_count: int, from_deck: bool)
signal damage_taken(damage_amount: int)

func _ready():
	setup_from_difficulty()
	if is_ai:
		deck = DeckGenerator.create_difficulty_deck(difficulty, 30)
	else:
		deck = create_player_deck_by_difficulty()
	draw_initial_hand()
	
func create_player_deck_by_difficulty() -> Array:
	if is_ai:
		return DeckGenerator.create_difficulty_deck(difficulty, 30)
	else:
		return DeckGenerator.create_starter_deck()
		
func play_card_without_hand_removal(card: CardData, target: Player = null, audio_helper: AudioHelper = null) -> bool:
	if not can_play_card(card):
		print("Cannot play card: ", card.card_name, " | Mana: ", current_mana, "/", card.cost, " | Cards played: ", cards_played_this_turn, "/", get_max_cards_per_turn())
		return false
	
	if cards_played_this_turn >= get_max_cards_per_turn():
		print("Card limit exceeded! Cards played: ", cards_played_this_turn, "/", get_max_cards_per_turn())
		return false
	
	print("Playing card: ", card.card_name, " (", card.card_type, ") | Cost: ", card.cost, " | Turn: ", turn_number)
	
	spend_mana(card.cost)
	discard_pile.append(card)
	cards_played_this_turn += 1
	
	cards_played_changed.emit(cards_played_this_turn, get_max_cards_per_turn())
	
	var damage_dealt = 0
	var bonus_damage = get_damage_bonus()

	print("   DAMAGE CALCULATION DEBUG:")
	print("   Player type: ", "AI" if is_ai else "Player")
	print("   Turn number: ", turn_number)
	print("   Base damage: ", card.damage)
	print("   Calculated bonus: ", bonus_damage)
	
	match card.card_type:
		"attack":
			if target:
				var total_damage = card.damage + bonus_damage
				damage_dealt = total_damage
				print("    FINAL Attack: ", card.damage, " base + ", bonus_damage, " bonus = ", total_damage, " total damage")
				target.take_damage(total_damage)
				
				if not is_ai:
					total_damage_this_game += total_damage
				
				if not is_ai and UnlockManagers:
					UnlockManagers.track_progress("damage_dealt", total_damage)
				
				if not is_ai and StatisticsManagers:
					StatisticsManagers.combat_action("damage_dealt", damage_dealt)
			else:
				print("Attack card played without target!")
		
		"heal":
			print("  Heal: ", card.heal, " HP")
			heal(card.heal)
		
		"shield":
			print("   Shield: ", card.shield, " protection")
			add_shield(card.shield)
			
			if not is_ai and UnlockManagers:
				UnlockManagers.track_progress("damage_blocked", card.shield)
		
		"hybrid":
			print("   Hybrid card effects:")
			if card.damage > 0 and target:
				var total_damage = card.damage + bonus_damage
				damage_dealt = total_damage
				print("    FINAL Hybrid Attack: ", card.damage, " base + ", bonus_damage, " bonus = ", total_damage, " total damage")
				target.take_damage(total_damage)
				
				if not is_ai and UnlockManagers:
					UnlockManagers.track_progress("damage_dealt", total_damage)
				
				if not is_ai and StatisticsManagers:
					StatisticsManagers.combat_action("damage_dealt", damage_dealt)
			elif card.damage > 0 and not target:
				print("Hybrid card with damage played without target!")
			
			if card.heal > 0:
				print("     Heal: ", card.heal, " HP")
				heal(card.heal)
			
			if card.shield > 0:
				print("     Shield: ", card.shield, " protection")
				add_shield(card.shield)
				
				if not is_ai and UnlockManagers:
					UnlockManagers.track_progress("damage_blocked", card.shield)
	
	print("   Cards played after: ", cards_played_this_turn, "/", get_max_cards_per_turn())
	print("   Mana after card: ", current_mana)
	
	if cards_played_this_turn >= get_max_cards_per_turn():
		print("CARD LIMIT REACHED - No more cards can be played this turn")
	
	return true

func remove_card_from_hand(card: CardData):
	hand.erase(card)
	hand_changed.emit()

func setup_from_difficulty():
	GameBalance.setup_player(self, difficulty, is_ai)
	var config = GameBalance.get_ai_config(difficulty) if is_ai else GameBalance.get_player_config(difficulty)
	max_cards_per_turn = config.cards_per_turn
	
func get_all_cards() -> Array:
	var all_cards: Array = []
	all_cards.append_array(deck)
	all_cards.append_array(hand)
	all_cards.append_array(discard_pile)
	return all_cards

func get_max_cards_per_turn() -> int:
	return max_cards_per_turn

func get_damage_bonus() -> int:
	return GameBalance.get_damage_bonus(turn_number)

func draw_initial_hand():
	for i in range(max_hand_size):
		draw_card()
	card_drawn.emit(max_hand_size, false)

func draw_card() -> bool:
	if deck.size() == 0 and discard_pile.size() > 0:
		deck = DeckManager.create_discard_pile_deck(discard_pile)
		discard_pile.clear()
	
	if deck.size() > 0 and hand.size() < max_hand_size:
		hand.append(deck.pop_back())
		hand_changed.emit()
		if not is_ai:
			card_drawn.emit(1, true)
		return true
	elif deck.size() == 0 and discard_pile.size() == 0:
		deck_empty.emit()
		return false
	return false

func take_damage(damage: int, from_ai: bool = false):
	var actual_damage = min(damage, current_shield + current_hp)
	
	if current_shield > 0:
		var shield_damage = min(damage, current_shield)
		current_shield -= shield_damage
		damage -= shield_damage
		shield_changed.emit(current_shield)
	
	if damage > 0:
		current_hp -= damage
		hp_changed.emit(current_hp)
		damage_taken.emit(actual_damage)
		
		if current_hp <= 5 and not was_at_low_hp_this_game:
			was_at_low_hp_this_game = true
	
	if from_ai:
		ai_damage_dealt.emit(actual_damage)
	
	if current_hp <= 0:
		player_died.emit()

func heal(amount: int):
	if amount <= 0:
		return
	
	var old_hp = current_hp
	current_hp += amount
	var actual_healing = current_hp - old_hp
	
	print("Healing: ", amount, " | Old HP: ", old_hp, " | New HP: ", current_hp, " | Actual healing: ", actual_healing)
	
	hp_changed.emit(current_hp)

func add_shield(amount: int):
	if amount <= 0:
		return
	
	var old_shield = current_shield
	current_shield += amount
	var actual_shield_gain = current_shield - old_shield
	
	print("Adding shield: ", amount, " | Old Shield: ", old_shield, " | New Shield: ", current_shield, " | Actual gain: ", actual_shield_gain)
	
	shield_changed.emit(current_shield)

func spend_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana)
		return true
	return false

func start_turn():
	turn_number += 1
	current_mana = max_mana
	cards_played_this_turn = 0
	
	var cards_to_draw = min(get_max_cards_per_turn(), max_hand_size - hand.size())
	var cards_actually_drawn = 0
	
	for i in range(cards_to_draw):
		if draw_card():
			cards_actually_drawn += 1
		else:
			break
	
	if cards_actually_drawn == 0:
		draw_card()
	
	mana_changed.emit(current_mana)
	cards_played_changed.emit(cards_played_this_turn, get_max_cards_per_turn())
	
	var current_bonus = get_damage_bonus()
	turn_changed.emit(turn_number, current_bonus)
	
func sync_turn_with_opponent(opponent: Player):
	if abs(turn_number - opponent.turn_number) > 1:
		print("  TURN DESYNC DETECTED!")
		print("   ", "AI" if is_ai else "Player", " turn: ", turn_number)
		print("   ", "AI" if opponent.is_ai else "Player", " turn: ", opponent.turn_number)

		var target_turn = min(turn_number, opponent.turn_number)
		turn_number = target_turn
		opponent.turn_number = target_turn
		print("   Synced both to turn: ", target_turn)

func can_play_card(card: CardData) -> bool:
	var has_mana = current_mana >= card.cost
	var can_play_more_cards = cards_played_this_turn < get_max_cards_per_turn()
	
	if not has_mana:
		print("Cannot play card: insufficient mana (", current_mana, "/", card.cost, ")")
	if not can_play_more_cards:
		print("Cannot play card: card limit reached (", cards_played_this_turn, "/", get_max_cards_per_turn(), ")")
	
	return has_mana and can_play_more_cards
	
func play_card(card: CardData, target: Player = null) -> bool:
	if not can_play_card(card):
		return false
	
	spend_mana(card.cost)
	hand.erase(card)
	discard_pile.append(card)
	cards_played_this_turn += 1
	
	hand_changed.emit()
	cards_played_changed.emit(cards_played_this_turn, get_max_cards_per_turn())
	
	var damage_dealt = 0
	
	match card.card_type:
		"attack":
			if target:
				var bonus_damage = get_damage_bonus()
				var total_damage = card.damage + bonus_damage
				damage_dealt = total_damage
				target.take_damage(total_damage)
				
				if not is_ai and StatisticsManagers:
					StatisticsManagers.combat_action("damage_dealt", damage_dealt)
		"heal":
			heal(card.heal)
		"shield":
			add_shield(card.shield)
		"hybrid":
			if card.damage > 0 and target:
				var bonus_damage = get_damage_bonus()
				var total_damage = card.damage + bonus_damage
				damage_dealt = total_damage
				target.take_damage(total_damage)
				
				if not is_ai and StatisticsManagers:
					StatisticsManagers.combat_action("damage_dealt", damage_dealt)
			
			if card.heal > 0:
				heal(card.heal)
			
			if card.shield > 0:
				add_shield(card.shield)
	
	return true

func get_hand_size() -> int:
	return hand.size()

func get_deck_size() -> int:
	return deck.size()

func get_total_cards() -> int:
	return deck.size() + discard_pile.size()

func get_cards_played() -> int:
	return cards_played_this_turn

func can_play_more_cards() -> bool:
	var can_play = cards_played_this_turn < get_max_cards_per_turn()
	if not can_play:
		print("Card limit reached: ", cards_played_this_turn, "/", get_max_cards_per_turn())
	return can_play

func set_difficulty(new_difficulty: String):
	difficulty = new_difficulty
	setup_from_difficulty()

func reset_player():
	setup_from_difficulty()
	
	current_hp = max_hp
	current_mana = max_mana
	current_shield = 0
	cards_played_this_turn = 0
	turn_number = 0
	total_damage_this_game = 0
	was_at_low_hp_this_game = false
	hand.clear()
	discard_pile.clear()
	deck = create_player_deck_by_difficulty()
	draw_initial_hand()
	
	hp_changed.emit(current_hp)
	mana_changed.emit(current_mana)
	shield_changed.emit(current_shield)
	hand_changed.emit()
	cards_played_changed.emit(cards_played_this_turn, get_max_cards_per_turn())
	turn_changed.emit(turn_number, get_damage_bonus())

func analyze_deck() -> Dictionary:
	var all_cards = deck + discard_pile + hand
	return DeckGenerator.analyze_deck(all_cards)

func get_deck_suggestions() -> Array:
	var all_cards = deck + discard_pile + hand
	return DeckGenerator.suggest_deck_improvements(all_cards)
		
func play_card_with_audio(card: CardData, target: Player = null, audio_helper: AudioHelper = null) -> bool:
	if not can_play_card(card):
		print("Cannot play card: ", card.card_name, " | Mana: ", current_mana, "/", card.cost, " | Cards played: ", cards_played_this_turn, "/", get_max_cards_per_turn())
		return false
	
	print("Playing card: ", card.card_name, " (", card.card_type, ") | Cost: ", card.cost, " | Turn: ", turn_number)
	
	if audio_helper:
		if is_ai:
			audio_helper.play_ai_card_play_sound(card.card_type)
		else:
			audio_helper.play_card_play_sound(card.card_type)
	
	spend_mana(card.cost)
	hand.erase(card)
	discard_pile.append(card)
	cards_played_this_turn += 1
	
	hand_changed.emit()
	cards_played_changed.emit(cards_played_this_turn, get_max_cards_per_turn())
	
	var damage_dealt = 0
	var bonus_damage = get_damage_bonus()

	print("   DAMAGE CALCULATION DEBUG:")
	print("   Player type: ", "AI" if is_ai else "Player")
	print("   Turn number: ", turn_number)
	print("   Base damage: ", card.damage)
	print("   Calculated bonus: ", bonus_damage)
	
	match card.card_type:
		"attack":
			if target:
				var total_damage = card.damage + bonus_damage
				damage_dealt = total_damage
				print("    FINAL Attack: ", card.damage, " base + ", bonus_damage, " bonus = ", total_damage, " total damage")
				target.take_damage(total_damage)
				
				if not is_ai and UnlockManagers:
					UnlockManagers.track_progress("damage_dealt", total_damage)
				
				if not is_ai and StatisticsManagers:
					StatisticsManagers.combat_action("damage_dealt", damage_dealt)
			else:
				print("Attack card played without target!")
		
		"heal":
			print("  Heal: ", card.heal, " HP")
			heal(card.heal)
		
		"shield":
			print("   Shield: ", card.shield, " protection")
			add_shield(card.shield)
			
			if not is_ai and UnlockManagers:
				UnlockManagers.track_progress("damage_blocked", card.shield)
		
		"hybrid":
			print("   Hybrid card effects:")
			if card.damage > 0 and target:
				var total_damage = card.damage + bonus_damage
				damage_dealt = total_damage
				print("    FINAL Hybrid Attack: ", card.damage, " base + ", bonus_damage, " bonus = ", total_damage, " total damage")
				target.take_damage(total_damage)
				
				if not is_ai and UnlockManagers:
					UnlockManagers.track_progress("damage_dealt", total_damage)
				
				if not is_ai and StatisticsManagers:
					StatisticsManagers.combat_action("damage_dealt", damage_dealt)
			elif card.damage > 0 and not target:
				print("⚠️ Hybrid card with damage played without target!")
			
			if card.heal > 0:
				print("     Heal: ", card.heal, " HP")
				heal(card.heal)
			
			if card.shield > 0:
				print("     Shield: ", card.shield, " protection")
				add_shield(card.shield)
				
				if not is_ai and UnlockManagers:
					UnlockManagers.track_progress("damage_blocked", card.shield)
	
	print("   Mana after card: ", current_mana, " | Cards played this turn: ", cards_played_this_turn)
	return true

func ai_turn(opponent: Player):
	if not is_ai:
		return
	
	var main_scene = get_tree().get_first_node_in_group("main_scene")
	if main_scene and main_scene.game_manager and main_scene.game_manager.is_game_ended():
		print("AI turn cancelled - game already ended")
		return
	
	ai_turn_active = true
	should_stop_ai_turn = false
	
	print("   AI executing turn logic...")
	print("   AI turn number: ", turn_number)
	print("   Available mana: ", current_mana)
	print("   Cards in hand: ", hand.size())
	
	await get_tree().create_timer(GameBalance.get_timer_delay("ai_turn_start")).timeout
	
	if main_scene and main_scene.game_manager and main_scene.game_manager.is_game_ended():
		ai_turn_active = false
		print("AI turn cancelled - game ended during delay")
		return
	
	var ai_config = GameBalance.get_ai_config(difficulty)
	var heal_threshold = ai_config.get("heal_threshold", 0.3)
	var aggression = ai_config.get("aggression", 0.5)
	
	var audio_helper = null
	
	if not main_scene:
		var root = get_tree().current_scene
		if root and root.has_method("get") and root.get("audio_helper"):
			audio_helper = root.audio_helper
			main_scene = root
	
	print("AI turn config - Heal threshold: ", heal_threshold, " | Aggression: ", aggression)
	
	while can_play_more_cards() and not should_stop_ai_turn:
		if main_scene and main_scene.game_manager and main_scene.game_manager.is_game_ended():
			print("AI turn stopped - game ended during turn")
			break
		
		var playable_cards = DeckManager.get_playable_cards(hand, current_mana)
		
		if playable_cards.size() == 0:
			print("AI: No playable cards available (mana: ", current_mana, ", hand: ", hand.size(), ")")
			break
		
		var chosen_card: CardData = null

		if opponent.current_hp <= 12:
			var finisher_cards = []
			for card in playable_cards:
				if (card.card_type == "attack" and card.damage >= 10) or (card.card_type == "hybrid" and card.damage >= 8):
					finisher_cards.append(card)
			if finisher_cards.size() > 0:
				chosen_card = finisher_cards[0]
				print("AI: Choosing finisher card: ", chosen_card.card_name)
				
		if not chosen_card and current_hp < max_hp * heal_threshold:
			var heal_cards = []
			for card in playable_cards:
				if card.card_type == "heal" or (card.card_type == "hybrid" and card.heal > 0):
					heal_cards.append(card)
			if heal_cards.size() > 0:
				chosen_card = heal_cards[0]
				print("AI: Choosing heal card: ", chosen_card.card_name)
		
		if not chosen_card and current_shield == 0 and opponent.current_mana >= 4 and randf() > aggression:
			var shield_cards = []
			for card in playable_cards:
				if card.card_type == "shield" or (card.card_type == "hybrid" and card.shield > 0):
					shield_cards.append(card)
			if shield_cards.size() > 0:
				chosen_card = shield_cards[0]
				print("AI: Choosing shield card: ", chosen_card.card_name)
		
		if not chosen_card:
			var attack_cards = []
			for card in playable_cards:
				if card.card_type == "attack" or (card.card_type == "hybrid" and card.damage > 0):
					attack_cards.append(card)
			if attack_cards.size() > 0:
				var strongest = attack_cards[0]
				for card in attack_cards:
					if card.damage > strongest.damage:
						strongest = card
				chosen_card = strongest
				print("AI: Choosing strongest attack: ", chosen_card.card_name)

		if not chosen_card:
			chosen_card = playable_cards[0]
			print("AI: Choosing fallback card: ", chosen_card.card_name)
		
		if chosen_card and not should_stop_ai_turn:
			var ai_bonus = get_damage_bonus()
			print("   AI chosen card details:")
			print("   Card: ", chosen_card.card_name, " | Type: ", chosen_card.card_type)
			print("   Base damage: ", chosen_card.damage, " | AI turn: ", turn_number, " | AI bonus: ", ai_bonus)
			if chosen_card.card_type == "attack" or (chosen_card.card_type == "hybrid" and chosen_card.damage > 0):
				var expected_total = chosen_card.damage + ai_bonus
				print("   Expected total damage: ", expected_total)
			
			ai_card_played.emit(chosen_card)
			
			await get_tree().create_timer(GameBalance.get_timer_delay("ai_card_notification")).timeout
			
			if main_scene and main_scene.game_manager and main_scene.game_manager.is_game_ended():
				ai_turn_active = false
				print("AI turn stopped - game ended during notification")
				return
			
			if audio_helper:
				print("AI playing sound for: ", chosen_card.card_type)
				audio_helper.play_ai_card_play_sound(chosen_card.card_type)
			else:
				print("AI: No audio_helper available")
			
			match chosen_card.card_type:
				"attack":
					print("AI attacking player with: ", chosen_card.card_name)
					play_card(chosen_card, opponent)
				"heal", "shield":
					print("AI using support card: ", chosen_card.card_name)
					play_card(chosen_card)
				"hybrid":
					print("AI using hybrid card: ", chosen_card.card_name)
					play_card(chosen_card, opponent)
			
			await get_tree().create_timer(GameBalance.get_timer_delay("ai_card_play")).timeout
			
			if main_scene and main_scene.game_manager and main_scene.game_manager.is_game_ended():
				ai_turn_active = false
				print("AI turn stopped - game ended after playing card")
				return
		else:
			print("AI: No card chosen or turn stopped, breaking turn")
			break
	
	ai_turn_active = false
	should_stop_ai_turn = false
	
func stop_ai_turn():
	if is_ai and ai_turn_active:
		should_stop_ai_turn = true

func is_ai_turn_active() -> bool:
	return is_ai and ai_turn_active

func verify_game_state() -> Dictionary:
	return {
		"player_type": "AI" if is_ai else "Player",
		"turn_number": turn_number,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"current_mana": current_mana,
		"max_mana": max_mana,
		"hand_size": hand.size(),
		"cards_played": cards_played_this_turn,
		"max_cards_per_turn": get_max_cards_per_turn(),
		"damage_bonus": get_damage_bonus()
		}
