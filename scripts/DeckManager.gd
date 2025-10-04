class_name DeckManager
extends RefCounted

static func create_basic_deck() -> Array:
	return DeckGenerator.create_balanced_deck(30, 0.8, 0.12, 0.08)

static func create_random_deck() -> Array:
	return DeckGenerator.create_random_deck(30)

static func create_discard_pile_deck(discard_pile: Array) -> Array:
	var new_deck = discard_pile.duplicate()
	new_deck.shuffle()
	return new_deck

static func get_playable_cards(hand: Array, current_mana: int) -> Array:
	var playable = []
	for card in hand:
		if card is CardData and card.cost <= current_mana:
			playable.append(card)
	return playable

static func get_cards_by_type(cards: Array, type: String) -> Array:
	var filtered = []
	for card in cards:
		if card is CardData and card.card_type == type:
			filtered.append(card)
	return filtered

static func get_strongest_attack_card(cards: Array) -> CardData:
	var attack_cards = get_cards_by_type(cards, "attack")
	if attack_cards.size() == 0:
		return null
	
	var strongest = attack_cards[0]
	for card in attack_cards:
		if card.damage > strongest.damage:
			strongest = card
	
	return strongest

static func should_restart_game(player_deck_size: int, ai_deck_size: int, player_hand_size: int, ai_hand_size: int) -> bool:
	var player_no_cards = player_deck_size == 0 and player_hand_size == 0
	var ai_no_cards = ai_deck_size == 0 and ai_hand_size == 0
	return player_no_cards and ai_no_cards

static func get_card_rarity_text(card: CardData) -> String:
	var rarity_enum = RaritySystem.calculate_card_rarity(card.damage, card.heal, card.shield)
	var rarity = RaritySystem.get_rarity_string(rarity_enum)
	match rarity:
		"common":
			return "[Common]"
		"uncommon":
			return "[Uncommon]"
		"rare":
			return "[Rare]"
		"epic":
			return "[Epic]"
		_:
			return ""
			
static func refill_hand(hand: Array, deck: Array, discard_pile: Array, max_hand_size: int, joker_chance: float, is_ai: bool) -> Dictionary:
	var result = {
		"cards_drawn": 0,
		"joker_added": false,
		"deck_reshuffled": false
	}
	
	print("Hand size: ", hand.size(), " / ", max_hand_size)
	print("Joker chance: ", joker_chance)
	print("Is AI: ", is_ai)
	
	var joker_already_in_hand = false
	for card in hand:
		if card is CardData and card.is_joker:
			joker_already_in_hand = true
			print("Joker already in hand, skipping")
			break
	
	var roll = randf()
	print("Random roll: ", roll, " (need < ", joker_chance, ")")
	print("Joker already in hand: ", joker_already_in_hand)
	print("Space available: ", hand.size() < max_hand_size)
	
	if not joker_already_in_hand and roll < joker_chance and hand.size() < max_hand_size:
		print("CONDITIONS MET - Adding joker!")
		var joker_templates = CardDatabase.get_joker_templates()
		print("Available joker templates: ", joker_templates.size())
		
		if joker_templates.size() > 0:
			var random_joker = joker_templates[randi() % joker_templates.size()]
			print("Selected joker template: ", random_joker.get("name", "unknown"))
			
			var joker_card = CardBuilder.from_template(random_joker)
			if joker_card:
				print("Joker card created: ", joker_card.card_name)
				print("Card is_joker: ", joker_card.is_joker)
				print("Card joker_effect: ", joker_card.joker_effect)
				
				hand.append(joker_card)
				result.joker_added = true
				print("Joker added to ", "AI" if is_ai else "Player", " hand: ", joker_card.card_name)
			else:
				print("ERROR: Failed to create joker card")
		else:
			print("ERROR: No joker templates available")
	else:
		print("CONDITIONS NOT MET - Joker not added")
		if joker_already_in_hand:
			print("  Reason: Already has joker")
		elif roll >= joker_chance:
			print("  Reason: Roll failed (", roll, " >= ", joker_chance, ")")
		elif hand.size() >= max_hand_size:
			print("  Reason: Hand full")
	
	while hand.size() < max_hand_size:
		if deck.size() == 0:
			if discard_pile.size() > 0:
				deck.append_array(discard_pile)
				discard_pile.clear()
				deck.shuffle()
				result.deck_reshuffled = true
				print("Deck reshuffled")
			else:
				print("No more cards to draw")
				break
		
		if deck.size() > 0:
			hand.append(deck.pop_back())
			result.cards_drawn += 1
	
	print("Cards drawn: ", result.cards_drawn)
	print("Final hand size: ", hand.size())
	
	return result
