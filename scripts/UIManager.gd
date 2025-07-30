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

var card_instances: Array = []
var selected_card_index: int = 0
var original_ui_position: Vector2
var is_screen_shaking: bool = false
var original_turn_label_y: float
var floating_damage_count: int = 0

var player_turn_color = Color(0.08, 0.13, 0.18, 0.9)
var ai_turn_color = Color(0.15, 0.08, 0.08, 0.9)
var transition_time = 0.8

func setup(main: Control):
	main_scene = main
	_get_ui_references()
	original_ui_position = ui_layer.position
	original_turn_label_y = turn_label.position.y

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
		
		await main_scene.get_tree().create_timer(0.2).timeout
		
		var return_tween = main_scene.create_tween()
		return_tween.set_parallel(true)
		return_tween.tween_property(hp_label, "scale", Vector2(1.0, 1.0), 0.3)
		
		var final_color = Color.WHITE
		if new_hp <= 5:
			final_color = Color(1.0, 0.3, 0.3, 1.0)
		elif new_hp <= 10:
			final_color = Color(1.0, 0.7, 0.3, 1.0)
		elif new_hp <= 15:
			final_color = Color(1.0, 1.0, 0.3, 1.0)
		else:
			final_color = Color(0.4, 1.0, 0.6, 1.0)
		
		return_tween.tween_property(hp_label, "modulate", final_color, 0.3)
	
	elif new_hp > old_hp:
		var tween = main_scene.create_tween()
		tween.set_parallel(true)
		tween.tween_property(hp_label, "scale", Vector2(1.4, 1.4), 0.25)
		tween.tween_property(hp_label, "modulate", Color(0.5, 1.8, 0.8, 1.0), 0.25)
		
		await main_scene.get_tree().create_timer(0.25).timeout
		
		var return_tween = main_scene.create_tween()
		return_tween.set_parallel(true)
		return_tween.tween_property(hp_label, "scale", Vector2(1.0, 1.0), 0.35)
		
		var final_color = Color.WHITE
		if new_hp <= 5:
			final_color = Color(1.0, 0.3, 0.3, 1.0)
		elif new_hp <= 10:
			final_color = Color(1.0, 0.7, 0.3, 1.0)
		elif new_hp <= 15:
			final_color = Color(1.0, 1.0, 0.3, 1.0)
		else:
			final_color = Color(0.4, 1.0, 0.6, 1.0)
		
		return_tween.tween_property(hp_label, "modulate", final_color, 0.35)

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
		tween.tween_property(player_mana_label, "modulate", Color(0.5, 0.8, 1.5, 1.0), 0.2)
		tween.tween_property(player_mana_label, "modulate", Color(0.4, 0.6, 1.0, 1.0), 0.3)
	elif new_mana < old_mana:
		var tween = main_scene.create_tween()
		tween.tween_property(player_mana_label, "modulate", Color(0.6, 0.6, 0.6, 1.0), 0.2)
		tween.tween_property(player_mana_label, "modulate", Color(0.4, 0.6, 1.0, 1.0), 0.5)

func update_ai_mana(new_mana: int):
	ai_mana_label.text = str(new_mana)

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
	tween.tween_property(top_panel_bg, "color", player_turn_color, transition_time)

	var max_cards = player.get_max_cards_per_turn()
	var cards_played = player.get_cards_played()
	
	var difficulty_name = difficulty.to_upper()
	game_info_label.text = "Cards: " + str(cards_played) + "/" + str(max_cards) + " | " + difficulty_name
	
	var end_turn_button = main_scene.end_turn_button
	if end_turn_button:
		end_turn_button.disabled = false

func start_ai_turn(ai: Player):
	animate_turn_transition(false)
	
	var tween = main_scene.create_tween()
	tween.tween_property(top_panel_bg, "color", ai_turn_color, transition_time)
	
	game_info_label.text = "AI is playing..."
	
	var end_turn_button = main_scene.end_turn_button
	if end_turn_button:
		end_turn_button.disabled = true
		end_turn_button.release_focus()

func animate_turn_transition(is_player_turn: bool):
	var text = "Your turn" if is_player_turn else "AI turn"
	var color = Color(0.3, 1.0, 0.8, 1.0) if is_player_turn else Color(1.0, 0.4, 0.4, 1.0)
	
	turn_label.text = text
	turn_label.modulate = Color.WHITE
	turn_label.scale = Vector2(0.5, 0.5)
	
	var tween = main_scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(turn_label, "scale", Vector2(1.3, 1.3), 0.3)
	tween.tween_property(turn_label, "modulate", color, 0.3)
	
	await tween.finished
	
	var bounce_tween = main_scene.create_tween()
	bounce_tween.tween_property(turn_label, "scale", Vector2(1.0, 1.0), 0.2)
	
	await bounce_tween.finished
	
	if is_player_turn:
		var glow_tween = main_scene.create_tween()
		glow_tween.set_loops(3)
		glow_tween.tween_property(turn_label, "modulate", Color(0.5, 1.2, 1.0, 1.0), 0.4)
		glow_tween.tween_property(turn_label, "modulate", color, 0.4)

func update_hand_display(player: Player, card_scene: PackedScene, hand_container: Container):
	for child in hand_container.get_children():
		child.queue_free()
	
	card_instances.clear()
	
	for i in range(player.hand.size()):
		var card_data = player.hand[i]
		var card_instance = card_scene.instantiate()
		card_instance.set_card_data(card_data)
		card_instance.card_clicked.connect(main_scene._on_card_clicked)
		
		if card_instance.has_signal("mouse_entered"):
			card_instance.mouse_entered.connect(_on_card_hover)
		
		hand_container.add_child(card_instance)
		card_instances.append(card_instance)
		
		var can_play = main_scene.is_player_turn and player.can_play_card(card_data)
		card_instance.set_playable(can_play)
	
	selected_card_index = clamp(selected_card_index, 0, max(0, card_instances.size() - 1))
	
	var controls_panel = main_scene.controls_panel
	if controls_panel:
		controls_panel.update_cards_available(card_instances.size() > 0)

func _on_card_hover():
	var input_manager = main_scene.input_manager
	if input_manager and not input_manager.gamepad_mode:
		var audio_helper = main_scene.audio_helper
		if audio_helper:
			audio_helper.play_card_hover_sound()

func update_turn_button_text(player: Player, end_turn_button: Button, gamepad_mode: bool):
	if not end_turn_button or not player:
		return
		
	var cards_played = player.get_cards_played()
	var max_cards = player.get_max_cards_per_turn()
	var playable_cards = DeckManager.get_playable_cards(player.hand, player.current_mana)
	
	if cards_played >= max_cards:
		end_turn_button.text = "Waiting"
	elif playable_cards.size() == 0:
		end_turn_button.text = "No playable cards"
	elif player.get_hand_size() == 0:
		end_turn_button.text = "No cards in hand"
	else:
		if gamepad_mode:
			end_turn_button.text = "🎮 End Turn"
		else:
			end_turn_button.text = "End Turn"

func update_cards_played_info(cards_played: int, max_cards: int, difficulty: String):
	var difficulty_name = difficulty.to_upper()
	game_info_label.text = "Cards: " + str(cards_played) + "/" + str(max_cards) + " | " + difficulty_name

func update_damage_bonus_indicator(player: Player, damage_bonus_label: Label):
	if not damage_bonus_label:
		return
		
	var damage_bonus = player.get_damage_bonus()
	
	if damage_bonus > 0:
		var bonus_text = ""
		var bonus_color = Color.WHITE
		
		match damage_bonus:
			1:
				bonus_text = "⚔️ +1 DMG"
				bonus_color = Color(1.0, 0.8, 0.2, 1.0)
			2:
				bonus_text = "⚔️ +2 DMG"
				bonus_color = Color(1.0, 0.4, 0.2, 1.0)
			3:
				bonus_text = "💀 +3 DMG"
				bonus_color = Color(1.0, 0.2, 0.2, 1.0)
			4:
				bonus_text = "🔥 +4 DMG"
				bonus_color = Color(0.8, 0.2, 0.8, 1.0)
			_:
				bonus_text = "⚔️ +" + str(damage_bonus) + " DMG"
				bonus_color = Color(0.6, 0.2, 0.6, 1.0)
		
		damage_bonus_label.text = bonus_text
		damage_bonus_label.modulate = bonus_color
		damage_bonus_label.visible = true
		print("UI: Damage bonus indicator updated: ", bonus_text)
	else:
		damage_bonus_label.visible = false
		print("UI: Damage bonus indicator hidden (no bonus)")

func reset_damage_bonus_indicator(damage_bonus_label: Label):
	if damage_bonus_label:
		damage_bonus_label.visible = false
		damage_bonus_label.text = ""
		print("UI: Damage bonus indicator reset")

func show_damage_bonus_info(turn_num: int, damage_bonus: int):
	turn_label.text = "Turn " + str(turn_num)
	game_info_label.text = "Damage bonus: +" + str(damage_bonus) + "!"

func show_reshuffle_info(player_name: String):
	turn_label.text = player_name + " reshuffled"
	if player_name == "Player":
		game_info_label.text = "Cards returned to the deck"
	else:
		game_info_label.text = "Some cards returned to their deck"

func play_damage_effects(damage_amount: int):
	if is_screen_shaking:
		return
   
	var shake_intensity = min(damage_amount * 2.0, 8.0)
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
	if not gamepad_mode or not main_scene.is_player_turn:
		return
		
	for i in range(card_instances.size()):
		var card = card_instances[i]
		if i == selected_card_index:
			card.modulate = Color(1.3, 1.3, 1.0, 1.0)
			card.z_index = 15
			card.scale = card.original_scale * 1.1
		else:
			if player.can_play_card(player.hand[i]):
				card.modulate = Color.WHITE
			else:
				card.modulate = Color(0.4, 0.4, 0.4, 0.7)
			card.z_index = 0
			card.scale = card.original_scale

func navigate_cards(direction: int, player: Player):
	if card_instances.size() == 0:
		return false
		
	selected_card_index = (selected_card_index + direction) % card_instances.size()
	if selected_card_index < 0:
		selected_card_index = card_instances.size() - 1
		
	update_card_selection(true, player)
	return true

func get_selected_card():
	if card_instances.size() > 0 and selected_card_index < card_instances.size():
		return card_instances[selected_card_index]
	return null
