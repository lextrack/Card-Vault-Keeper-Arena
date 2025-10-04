class_name UIManager
extends RefCounted

var main_scene: Control
var player_hp_label: Label
var player_mana_label: Label
var player_shield_label: Label
var ai_hp_label: Label
var ai_mana_label: Label
var ai_shield_label: Label
var turn_label: Label
var game_info_label: Label
var game_over_label: Label
var top_panel_bg: ColorRect
var ui_layer: Control
var joker_card_scene: PackedScene = null
var card_instances: Array = []
var selected_card_index: int = 0
var original_ui_position: Vector2
var is_screen_shaking: bool = false

var current_hand_fingerprint: String = ""
var last_playability_fingerprint: String = ""
var gamepad_selection_active: bool = false

var pending_update_timer: float = 0.0
const UPDATE_DELAY: float = 0.016  # ~1 frame a 60fps

var player_turn_color = Color(0.08, 0.13, 0.18, 0.9)
var ai_turn_color = Color(0.15, 0.08, 0.08, 0.9)

func setup(main: Control, joker_scene: PackedScene = null):
	main_scene = main
	joker_card_scene = joker_scene
	_get_ui_references()
	original_ui_position = ui_layer.position

func _get_ui_references():
	player_hp_label = main_scene.player_hp_label
	player_mana_label = main_scene.player_mana_label
	player_shield_label = main_scene.player_shield_label
	ai_hp_label = main_scene.ai_hp_label
	ai_mana_label = main_scene.ai_mana_label
	ai_shield_label = main_scene.ai_shield_label
	turn_label = main_scene.turn_label
	game_info_label = main_scene.game_info_label
	game_over_label = main_scene.game_over_label
	top_panel_bg = main_scene.top_panel_bg
	ui_layer = main_scene.ui_layer

func _generate_hand_fingerprint(hand: Array) -> String:
	if not hand or hand.size() == 0:
		return "empty"
	
	var parts: PackedStringArray = []
	for card in hand:
		if card is CardData:
			parts.append("%s_%d_%d_%d_%d" % [
				card.card_name,
				card.cost,
				card.damage,
				card.heal,
				card.shield
			])
	
	return ",".join(parts)

func _generate_playability_fingerprint(player: Player) -> String:
	if not player or not player.hand:
		return "none"
	
	var parts: PackedStringArray = []
	for card_data in player.hand:
		parts.append("1" if player.can_play_card(card_data) else "0")
	
	return "".join(parts)

func _has_hand_changed(player: Player) -> bool:
	if not player or not player.hand:
		return true
   
	var new_fingerprint = _generate_hand_fingerprint(player.hand)
	var changed = new_fingerprint != current_hand_fingerprint
	current_hand_fingerprint = new_fingerprint
	return changed

func _has_playability_changed(player: Player) -> bool:
	if not player or not player.hand:
		return true
   
	var new_fingerprint = _generate_playability_fingerprint(player)
	var changed = new_fingerprint != last_playability_fingerprint
	last_playability_fingerprint = new_fingerprint
	return changed

func handle_card_hover_audio(card, hover_type: String):
	var audio_helper = main_scene.audio_helper
	if not audio_helper:
		return
   
	match hover_type:
		"mouse":
			if not gamepad_selection_active:
				audio_helper.play_card_hover_sound()
		"gamepad_navigation", "gamepad_selection":
			audio_helper.play_card_hover_sound()

func update_all_labels(player: Player, ai: Player):
	update_player_hp(player.current_hp)
	update_player_mana(player.current_mana)
	update_player_shield(player.current_shield)
	update_ai_hp(ai.current_hp)
	update_ai_mana(ai.current_mana)
	update_ai_shield(ai.current_shield)

func animate_hp_change(hp_label: Label, new_hp: int, old_hp: int):
	if new_hp < old_hp:
		var tween = main_scene.create_tween()
		tween.set_parallel(true)
		tween.tween_property(hp_label, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(hp_label, "modulate", Color(1.5, 0.5, 0.5, 1.0), 0.2)
   	
		main_scene.get_tree().create_timer(0.2).timeout.connect(func():
			var return_tween = main_scene.create_tween()
			return_tween.set_parallel(true)
			return_tween.tween_property(hp_label, "scale", Vector2(1.0, 1.0), 0.3)
			return_tween.tween_property(hp_label, "modulate", _get_hp_color(new_hp), 0.3)
		)
	elif new_hp > old_hp:
		var tween = main_scene.create_tween()
		tween.set_parallel(true)
		tween.tween_property(hp_label, "scale", Vector2(1.4, 1.4), 0.25)
		tween.tween_property(hp_label, "modulate", Color(0.5, 1.8, 0.8, 1.0), 0.25)
   	
		main_scene.get_tree().create_timer(0.25).timeout.connect(func():
			var return_tween = main_scene.create_tween()
			return_tween.set_parallel(true)
			return_tween.tween_property(hp_label, "scale", Vector2(1.0, 1.0), 0.35)
			return_tween.tween_property(hp_label, "modulate", _get_hp_color(new_hp), 0.35)
		)

func _get_hp_color(hp: int) -> Color:
	if hp <= 5:
		return Color(1.0, 0.3, 0.3, 1.0)
	elif hp <= 10:
		return Color(1.0, 0.7, 0.3, 1.0)
	elif hp <= 15:
		return Color(1.0, 1.0, 0.3, 1.0)
	else:
		return Color(0.4, 1.0, 0.6, 1.0)

func update_player_hp(new_hp: int):
	var old_hp = int(player_hp_label.text) if player_hp_label.text.is_valid_int() else new_hp
	player_hp_label.text = str(new_hp)
	if new_hp != old_hp:
		animate_hp_change(player_hp_label, new_hp, old_hp)

func update_ai_hp(new_hp: int):
	var old_hp = int(ai_hp_label.text) if ai_hp_label.text.is_valid_int() else new_hp
	ai_hp_label.text = str(new_hp)
	if new_hp != old_hp:
		animate_hp_change(ai_hp_label, new_hp, old_hp)

func update_player_mana(new_mana: int):
	var old_text = player_mana_label.text
	var old_mana = int(old_text) if old_text.is_valid_int() else new_mana
	player_mana_label.text = str(new_mana)
   
	if new_mana > old_mana:
		var tween = main_scene.create_tween()
		tween.tween_property(player_mana_label, "modulate", Color(0.7, 0.9, 1.2, 1.0), 0.2)
		tween.tween_property(player_mana_label, "modulate", Color(0.8, 0.9, 1.0, 1.0), 0.3)
	elif new_mana < old_mana:
		var tween = main_scene.create_tween()
		tween.tween_property(player_mana_label, "modulate", Color(0.7, 0.7, 0.8, 1.0), 0.2)
		tween.tween_property(player_mana_label, "modulate", Color(0.8, 0.9, 1.0, 1.0), 0.5)

func update_ai_mana(new_mana: int):
	var old_text = ai_mana_label.text
	var old_mana = int(old_text) if old_text.is_valid_int() else new_mana
	ai_mana_label.text = str(new_mana)
   
	if new_mana > old_mana:
		var tween = main_scene.create_tween()
		tween.tween_property(ai_mana_label, "modulate", Color(0.7, 0.9, 1.2, 1.0), 0.2)
		tween.tween_property(ai_mana_label, "modulate", Color(0.8, 0.9, 1.0, 1.0), 0.3)
	elif new_mana < old_mana:
		var tween = main_scene.create_tween()
		tween.tween_property(ai_mana_label, "modulate", Color(0.7, 0.7, 0.8, 1.0), 0.2)
		tween.tween_property(ai_mana_label, "modulate", Color(0.8, 0.9, 1.0, 1.0), 0.5)

func update_player_shield(new_shield: int):
	var old_text = player_shield_label.text
	var old_shield = int(old_text) if old_text.is_valid_int() else new_shield
	player_shield_label.text = str(new_shield)
   
	if new_shield > old_shield:
		var tween = main_scene.create_tween()
		tween.tween_property(player_shield_label, "modulate", Color(0.3, 1.5, 0.8, 1.0), 0.2)
		tween.tween_property(player_shield_label, "modulate", Color(0.4, 1.0, 0.6, 1.0), 0.3)
		tween.tween_property(player_shield_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(player_shield_label, "scale", Vector2(1.0, 1.0), 0.2)
	elif new_shield < old_shield:
		var tween = main_scene.create_tween()
		tween.tween_property(player_shield_label, "modulate", Color(0.8, 0.8, 0.8, 1.0), 0.2)
		tween.tween_property(player_shield_label, "modulate", Color(0.4, 1.0, 0.6, 1.0), 0.3)

func update_ai_shield(new_shield: int):
	ai_shield_label.text = str(new_shield)

func start_player_turn(player: Player, difficulty: String):
	animate_turn_transition(true)

	var tween = main_scene.create_tween()
	tween.tween_property(top_panel_bg, "color", player_turn_color, 0.4)

	var max_cards = player.get_max_cards_per_turn()
	var cards_played = player.get_cards_played()
	var difficulty_name = difficulty.to_upper()
	game_info_label.text = "Cards: %d/%d | %s" % [cards_played, max_cards, difficulty_name]

	var end_turn_button = main_scene.end_turn_button
	if end_turn_button:
		end_turn_button.disabled = false
		var input_manager = main_scene.input_manager
		var gamepad_mode = input_manager.gamepad_mode if input_manager else false
		update_turn_button_text(player, end_turn_button, gamepad_mode)

	_update_existing_cards_playability(player)
	_restore_gamepad_selection_immediate(player)

func start_ai_turn(ai: Player):
	animate_turn_transition(false)
	gamepad_selection_active = false
	_ensure_clear_all_gamepad_effects()
   
	var tween = main_scene.create_tween()
	tween.tween_property(top_panel_bg, "color", ai_turn_color, 0.4)
	game_info_label.text = "AI is playing..."
   
	var end_turn_button = main_scene.end_turn_button
	if end_turn_button:
		end_turn_button.disabled = true
		end_turn_button.release_focus()

	_darken_player_cards_for_ai_turn()

func _ensure_clear_all_gamepad_effects():
	for card in card_instances:
		if is_instance_valid(card) and card.has_method("force_reset_visual_state"):
			card.force_reset_visual_state()

func _darken_player_cards_for_ai_turn():
	for card in card_instances:
		if is_instance_valid(card):
			card.set_playable(false)

func animate_turn_transition(is_player_turn: bool):
	var text = "Your turn" if is_player_turn else "AI turn"
	var color = Color(0.3, 1.0, 0.8, 1.0) if is_player_turn else Color(1.0, 0.4, 0.4, 1.0)
   
	turn_label.text = text
	turn_label.modulate = color
	turn_label.scale = Vector2(0.7, 0.7)
   
	var tween = main_scene.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(turn_label, "scale", Vector2(1.1, 1.1), 0.15)
	tween.tween_property(turn_label, "modulate", color * 1.2, 0.15)
   
	tween.finished.connect(func():
		var settle_tween = main_scene.create_tween()
		settle_tween.set_parallel(true)
		settle_tween.set_ease(Tween.EASE_OUT)
		settle_tween.set_trans(Tween.TRANS_ELASTIC)
		settle_tween.tween_property(turn_label, "scale", Vector2(1.0, 1.0), 0.15)
		settle_tween.tween_property(turn_label, "modulate", color, 0.15)
	)

func update_hand_display(player: Player, card_scene: PackedScene, hand_container: Container):
	if not player or not card_scene or not hand_container or not player.hand:
		return
   
	var should_preserve_gamepad = gamepad_selection_active and main_scene.is_player_turn
	var old_selected_index = selected_card_index

	var hand_changed = _has_hand_changed(player)
	var playability_changed = _has_playability_changed(player)
	
	if not hand_changed and card_instances.size() == player.hand.size():
		if playability_changed:
			_update_existing_cards_playability(player)
		if should_preserve_gamepad:
			_restore_gamepad_selection_immediate(player)
		return
   
	_rebuild_hand_display(player, card_scene, hand_container, true)  # false para no animar
   
	selected_card_index = clamp(old_selected_index, 0, max(0, card_instances.size() - 1))
   
	var controls_panel = main_scene.controls_panel
	if controls_panel:
		controls_panel.update_cards_available(card_instances.size() > 0)

	if should_preserve_gamepad:
		_restore_gamepad_selection_immediate(player)
		
func _rebuild_hand_display(player: Player, card_scene: PackedScene, hand_container: Container, animate: bool = false):
	for child in hand_container.get_children():
		child.queue_free()
	
	card_instances.clear()
	
	var card_index = 0
	for card_data in player.hand:
		if not card_data:
			continue
		
		var card_instance = null
		
		if card_data.is_joker and joker_card_scene:
			card_instance = joker_card_scene.instantiate()
			print("   Using JokerCard scene for: ", card_data.card_name)
		else:
			card_instance = card_scene.instantiate()
		
		if not card_instance:
			continue
		
		card_instance.set_card_data(card_data)
		
		card_instance.card_clicked.connect(main_scene._on_card_clicked)
		if card_instance.has_signal("card_hovered"):
			card_instance.card_hovered.connect(_on_card_gamepad_hovered)
		if card_instance.has_signal("card_unhovered"):
			card_instance.card_unhovered.connect(_on_card_gamepad_unhovered)
		if card_instance.has_signal("mouse_entered"):
			card_instance.mouse_entered.connect(_on_card_hover)
		
		hand_container.add_child(card_instance)
		card_instances.append(card_instance)
		
		var can_play = main_scene.is_player_turn and player.can_play_card(card_data)
		card_instance.set_playable(can_play)
		
		if animate:
			_animate_card_spawn(card_instance, card_index)
		
		card_index += 1
		
func _animate_card_spawn(card: Control, index: int):
	if not is_instance_valid(card):
		return
	
	card.modulate.a = 0.0
	card.scale = Vector2(0.5, 0.5)
	var initial_y = card.position.y
	card.position.y = initial_y
	
	var delay = index * 0.06
	
	await main_scene.get_tree().create_timer(delay).timeout
	
	if not is_instance_valid(card):
		return
	
	var tween = main_scene.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(card, "modulate:a", 1.0, 0.6)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.6)
	tween.tween_property(card, "position:y", initial_y, 0.6)

func _update_existing_cards_playability(player: Player):
	var hand_size = min(card_instances.size(), player.hand.size())
	
	for i in range(hand_size):
		var card_instance = card_instances[i]
		var card_data = player.hand[i]
   	
		if is_instance_valid(card_instance) and card_data:
			var can_play = main_scene.is_player_turn and player.can_play_card(card_data)
			card_instance.set_playable(can_play)

func _on_card_gamepad_hovered(card):
	if gamepad_selection_active:
		handle_card_hover_audio(card, "gamepad_selection")
	else:
		handle_card_hover_audio(card, "gamepad_navigation")

func _on_card_gamepad_unhovered(card):
	pass

func _restore_gamepad_selection_immediate(player: Player):
	if not gamepad_selection_active or not main_scene.is_player_turn:
		return
   
	if selected_card_index < card_instances.size():
		var selected_card = card_instances[selected_card_index]
		if is_instance_valid(selected_card) and selected_card.has_method("apply_gamepad_selection_style"):
			if not selected_card.has_method("has_gamepad_selection_applied") or not selected_card.has_gamepad_selection_applied():
				selected_card.apply_gamepad_selection_style()
   			
func _on_card_hover():
	handle_card_hover_audio(null, "mouse")

func update_turn_button_text(player: Player, end_turn_button: Button, gamepad_mode: bool):
	if not end_turn_button or not player:
		return

	if not main_scene.is_player_turn:
		end_turn_button.text = "AI Turn"
		end_turn_button.disabled = true
		end_turn_button.modulate = Color(0.6, 0.6, 0.6, 1.0)
		return
   	
	var cards_played = player.get_cards_played()
	var max_cards = player.get_max_cards_per_turn()
	var playable_cards = DeckManager.get_playable_cards(player.hand, player.current_mana)
   
	end_turn_button.disabled = false
   
	if cards_played >= max_cards:
		end_turn_button.text = "Turn Ending..."
		end_turn_button.disabled = true
		end_turn_button.modulate = Color(0.7, 0.7, 0.7, 1.0)
	elif playable_cards.size() == 0:
		end_turn_button.text = "No Playable Cards"
		end_turn_button.modulate = Color(0.8, 0.8, 0.8, 1.0)
	elif player.get_hand_size() == 0:
		end_turn_button.text = "No Cards in Hand"
		end_turn_button.modulate = Color(0.8, 0.8, 0.8, 1.0)
	else:
		end_turn_button.modulate = Color.WHITE
		end_turn_button.text = "🎮 End Turn" if gamepad_mode else "End Turn"

func reset_turn_button(end_turn_button: Button, gamepad_mode: bool = false):
	if not end_turn_button:
		return
	end_turn_button.disabled = false
	end_turn_button.text = "🎮 End Turn" if gamepad_mode else "End Turn"

func update_cards_played_info(cards_played: int, max_cards: int, difficulty: String):
	game_info_label.text = "Cards: %d/%d | %s" % [cards_played, max_cards, difficulty.to_upper()]

func update_damage_bonus_indicator(player: Player, damage_bonus_label: Label):
	if not damage_bonus_label:
		return
   	
	var damage_bonus = player.get_damage_bonus()
   
	if damage_bonus > 0:
		var bonus_data = _get_damage_bonus_data(damage_bonus)
		damage_bonus_label.text = bonus_data.text
		damage_bonus_label.modulate = bonus_data.color
		damage_bonus_label.visible = true
	else:
		damage_bonus_label.visible = false

func _get_damage_bonus_data(bonus: int) -> Dictionary:
	match bonus:
		1: return {"text": "⚔️ +1 DMG", "color": Color(1.0, 0.8, 0.2, 1.0)}
		2: return {"text": "⚔️ +2 DMG", "color": Color(1.0, 0.4, 0.2, 1.0)}
		3: return {"text": "💀 +3 DMG", "color": Color(1.0, 0.2, 0.2, 1.0)}
		4: return {"text": "🔥 +4 DMG", "color": Color(0.8, 0.2, 0.8, 1.0)}
		_: return {"text": "⚔️ +%d DMG" % bonus, "color": Color(0.6, 0.2, 0.6, 1.0)}

func reset_damage_bonus_indicator(damage_bonus_label: Label):
	if damage_bonus_label:
		damage_bonus_label.visible = false
		damage_bonus_label.text = ""

func show_damage_bonus_info(turn_num: int, damage_bonus: int):
	turn_label.text = "Turn %d" % turn_num
	game_info_label.text = "Damage bonus: +%d!" % damage_bonus

func show_reshuffle_info(player_name: String):
	turn_label.text = "%s reshuffled" % player_name
	game_info_label.text = "Cards returned to the deck" if player_name == "Player" else "Some cards returned to their deck"

func play_damage_effects(damage_amount: int):
	if is_screen_shaking:
		return
	var shake_intensity = min(damage_amount * 1.0, 5.0)
	screen_shake(shake_intensity, 0.3)

func screen_shake(intensity: float, duration: float):
	if is_screen_shaking:
		return
	is_screen_shaking = true
	
	var shake_count = 8
	var time_per_shake = duration / shake_count
	
	for i in range(shake_count):
		var current_intensity = intensity * (1.0 - float(i) / shake_count)
		var shake_x = randf_range(-current_intensity, current_intensity)
		var shake_y = randf_range(-current_intensity, current_intensity)
		var shake_position = original_ui_position + Vector2(shake_x, shake_y)
		
		var tween = main_scene.create_tween()
		tween.tween_property(ui_layer, "position", shake_position, time_per_shake)
		await tween.finished
	
	var final_tween = main_scene.create_tween()
	final_tween.tween_property(ui_layer, "position", original_ui_position, 0.1)
	await final_tween.finished
	
	is_screen_shaking = false

func update_card_selection(gamepad_mode: bool, player: Player):
	if not main_scene.is_player_turn or not gamepad_mode:
		gamepad_selection_active = false
		_clear_all_gamepad_selection_styles()
		
		for i in range(card_instances.size()):
			var card = card_instances[i]
			if not is_instance_valid(card) or i >= player.hand.size():
				continue
			card.z_index = 0
			var can_play = player.can_play_card(player.hand[i])
			card.set_playable(can_play)
		return
	
	gamepad_selection_active = true
	_clear_all_gamepad_selection_styles()
	
	if card_instances.size() > 0:
		selected_card_index = clamp(selected_card_index, 0, card_instances.size() - 1)
		var selected_card = card_instances[selected_card_index]
		if is_instance_valid(selected_card) and selected_card_index < player.hand.size():
			selected_card.apply_gamepad_selection_style()
	
	for i in range(card_instances.size()):
		var card = card_instances[i]
		if not is_instance_valid(card) or i >= player.hand.size():
			continue
		if i != selected_card_index:
			card.z_index = 0
			var can_play = player.can_play_card(player.hand[i])
			card.set_playable(can_play)

func _clear_all_gamepad_selection_styles():
	for card in card_instances:
		if is_instance_valid(card) and card.has_method("remove_gamepad_selection_style"):
			card.remove_gamepad_selection_style()

func update_hand_display_no_animation(player: Player, card_scene: PackedScene, hand_container: Container):
	if not player or not card_scene or not hand_container or not player.hand:
		return

	var should_preserve_gamepad = gamepad_selection_active and main_scene.is_player_turn
	var old_selected_index = selected_card_index

	_rebuild_hand_display(player, card_scene, hand_container, true)  # false para no animar
	current_hand_fingerprint = _generate_hand_fingerprint(player.hand)
	
	selected_card_index = clamp(old_selected_index, 0, max(0, card_instances.size() - 1))
	
	var controls_panel = main_scene.controls_panel
	if controls_panel:
		controls_panel.update_cards_available(card_instances.size() > 0)
	
	if should_preserve_gamepad:
		_restore_gamepad_selection_immediate(player)

func update_hand_display_with_new_cards_animation(player: Player, card_scene: PackedScene, hand_container: Container, new_cards_count: int = 0):
	update_hand_display(player, card_scene, hand_container)

func navigate_cards(direction: int, player: Player) -> bool:
	if card_instances.size() == 0:
		return false
	
	var old_index = selected_card_index
	selected_card_index = (selected_card_index + direction) % card_instances.size()
	if selected_card_index < 0:
		selected_card_index = card_instances.size() - 1

	if old_index != selected_card_index:
		_apply_navigation_change(old_index, selected_card_index, player)
		gamepad_selection_active = true
		return true
	
	return false

func _apply_navigation_change(old_index: int, new_index: int, player: Player):
	if old_index < card_instances.size():
		var old_card = card_instances[old_index]
		if is_instance_valid(old_card) and old_card.has_method("force_reset_visual_state"):
			old_card.force_reset_visual_state()

	if new_index < card_instances.size():
		var new_card = card_instances[new_index]
		if is_instance_valid(new_card) and new_card.has_method("apply_gamepad_selection_style"):
			new_card.apply_gamepad_selection_style()

func get_selected_card() -> Card:
	if card_instances.size() > 0 and selected_card_index < card_instances.size():
		var selected_card = card_instances[selected_card_index]
		if is_instance_valid(selected_card):
			return selected_card
	return null

func is_card_selected(card: Card) -> bool:
	if not is_instance_valid(card):
		return false
	var selected_card = get_selected_card()
	return selected_card == card

func select_card_by_index(index: int, player: Player) -> bool:
	if index < 0 or index >= card_instances.size():
		return false
	
	var old_index = selected_card_index
	selected_card_index = index
	
	if old_index != selected_card_index:
		_apply_navigation_change(old_index, selected_card_index, player)
		gamepad_selection_active = true
		return true
	
	return false
