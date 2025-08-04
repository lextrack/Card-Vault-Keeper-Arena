class_name Card
extends Control

@export var card_data: CardData
@onready var name_label = $CardBackground/VBox/HeaderContainer/NameLabel
@onready var cost_label = $CardBackground/VBox/HeaderContainer/CostContainer/CostLabel
@onready var cost_bg = $CardBackground/VBox/HeaderContainer/CostContainer/CostBG
@onready var description_label = $CardBackground/VBox/DescriptionContainer/DescriptionLabel
@onready var card_background = $CardBackground
@onready var card_bg = $CardBackground/CardBG
@onready var card_border = $CardBackground/CardBorder
@onready var card_inner = $CardBackground/CardInner
@onready var card_icon = $CardBackground/VBox/ArtContainer/CardIcon
@onready var stat_value = $CardBackground/VBox/StatsContainer/StatValue
@onready var rarity_label = $CardBackground/VBox/RarityContainer/RarityLabel
@onready var rarity_bg = $CardBackground/VBox/RarityContainer/RarityBG
@onready var art_bg = $CardBackground/VBox/ArtContainer/ArtBG

const ATTACK_VIDEO = preload("res://assets/backgrounds/attack1.ogv")
const HEAL_VIDEO = preload("res://assets/backgrounds/heal1.ogv")
const SHIELD_VIDEO = preload("res://assets/backgrounds/shield1.ogv")
const HYBRID_VIDEO = preload("res://assets/backgrounds/hybrid1.ogv")

signal card_clicked(card: Card)
signal card_played(card: Card)
signal card_hovered(card: Card)
signal card_unhovered(card: Card)

var original_scale: Vector2
var original_position: Vector2
var is_hovered: bool = false
var is_playable: bool = true
var is_being_played: bool = false
var animation_in_progress: bool = false
var has_played_epic_animation: bool = false

var gamepad_selection_applied: bool = false
var gamepad_hover_active: bool = false

var hover_tween: Tween
var gamepad_selection_tween: Tween
var playable_tween: Tween
var play_tween: Tween
var animation_tween: Tween
var epic_border_tween: Tween

const HOVER_SCALE_MULTIPLIER = 1.06
const GAMEPAD_SCALE_MULTIPLIER = 1.08
const GAMEPAD_SELECTION_SCALE_MULTIPLIER = 1.12
const ANIMATION_SPEED_FAST = 0.12
const ANIMATION_SPEED_NORMAL = 0.18
const ANIMATION_SPEED_SLOW = 0.25

func _ready():
	original_scale = scale
	original_position = position
	
	if card_data:
		update_display()
	
	_setup_signals()
	set_mouse_filter_recursive(self)

func _setup_signals():
	gui_input.connect(_on_card_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func get_card_data() -> CardData:
	return card_data

func animate_mana_insufficient():
	if not _can_animate():
		return
	
	_start_animation()
	
	_kill_tween(animation_tween)
	animation_tween = create_tween()
	animation_tween.set_parallel(true)

	var shake_positions = [
		original_position + Vector2(3, 0),
		original_position + Vector2(-3, 0),
		original_position + Vector2(2, 0),
		original_position + Vector2(-2, 0),
		original_position
	]
	
	for i in range(shake_positions.size()):
		var delay = i * 0.04
		animation_tween.tween_property(self, "position", shake_positions[i], 0.04).set_delay(delay)
	
	var error_color = Color.RED
	var original_cost_color = get_card_type_colors(card_data.card_type).cost_bg
	
	animation_tween.tween_property(cost_bg, "color", error_color, 0.1)
	animation_tween.tween_property(cost_label, "modulate", Color(1.5, 0.3, 0.3, 1.0), 0.1)
	animation_tween.tween_property(card_border, "modulate", Color(1.3, 0.5, 0.5, 1.0), 0.1)

	animation_tween.tween_property(cost_bg, "color", original_cost_color, 0.15).set_delay(0.15)
	animation_tween.tween_property(cost_label, "modulate", Color.WHITE, 0.15).set_delay(0.15)
	animation_tween.tween_property(card_border, "modulate", Color.WHITE, 0.15).set_delay(0.15)
	
	await animation_tween.finished
	_end_animation()

func apply_gamepad_selection_style():
	# Verificar si ya está aplicado ANTES de cualquier otra lógica
	if gamepad_selection_applied:
		return
		
	if not _can_animate() or is_being_played:
		return
	
	# Limpiar efectos de hover primero si existen
	if is_hovered:
		_remove_hover_effects()
		is_hovered = false
	
	# CRITICAL: Marcar como aplicado INMEDIATAMENTE para evitar dobles aplicaciones
	gamepad_selection_applied = true
	gamepad_hover_active = true
	
	# Matar cualquier tween previo
	_kill_tween(gamepad_selection_tween)
	
	# Esperar un frame para asegurar que los tweens anteriores han terminado
	await get_tree().process_frame
	
	gamepad_selection_tween = create_tween()
	gamepad_selection_tween.set_parallel(true)
	
	gamepad_selection_tween.tween_property(self, "scale", original_scale * GAMEPAD_SELECTION_SCALE_MULTIPLIER, ANIMATION_SPEED_FAST).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	gamepad_selection_tween.tween_property(self, "z_index", 10, 0.05)
	
	var gamepad_modulate = Color(1.15, 1.15, 1.1, 1.0)
	if not is_playable:
		gamepad_modulate = Color(0.8, 0.8, 0.9, 1.0)
	
	gamepad_selection_tween.tween_property(self, "modulate", gamepad_modulate, ANIMATION_SPEED_FAST)
	
	var border_glow = Color(1.3, 1.3, 1.2, 1.0)
	gamepad_selection_tween.tween_property(card_border, "modulate", border_glow, ANIMATION_SPEED_FAST)

	await gamepad_selection_tween.finished
	
	# Solo iniciar el pulse si todavía tenemos la selección aplicada
	if gamepad_selection_applied and not animation_in_progress:
		_start_gamepad_pulse_animation()

func _start_gamepad_pulse_animation():
	if not gamepad_selection_applied or animation_in_progress:
		return
		
	_kill_tween(gamepad_selection_tween)
	gamepad_selection_tween = create_tween()
	gamepad_selection_tween.set_loops()
	
	var pulse_scale_min = original_scale * 1.06
	var pulse_scale_max = original_scale * 1.10
	
	gamepad_selection_tween.tween_property(self, "scale", pulse_scale_max, 0.8).set_ease(Tween.EASE_IN_OUT)
	gamepad_selection_tween.tween_property(self, "scale", pulse_scale_min, 0.8).set_ease(Tween.EASE_IN_OUT)

func remove_gamepad_selection_style():
	if not gamepad_selection_applied:
		return
	
	# Marcar como no aplicado INMEDIATAMENTE
	gamepad_selection_applied = false
	gamepad_hover_active = false
	
	_kill_tween(gamepad_selection_tween)
	
	# Esperar un frame para evitar conflictos
	await get_tree().process_frame
	
	gamepad_selection_tween = create_tween()
	gamepad_selection_tween.set_parallel(true)
	
	gamepad_selection_tween.tween_property(self, "scale", original_scale, ANIMATION_SPEED_NORMAL).set_ease(Tween.EASE_OUT)
	gamepad_selection_tween.tween_property(self, "z_index", 0, ANIMATION_SPEED_FAST)
	gamepad_selection_tween.tween_property(card_border, "modulate", Color.WHITE, ANIMATION_SPEED_NORMAL)
	
	var target_modulate = Color.WHITE if is_playable else Color(0.4, 0.4, 0.4, 0.7)
	gamepad_selection_tween.tween_property(self, "modulate", target_modulate, ANIMATION_SPEED_NORMAL)

func play_disabled_animation():
	if not _can_animate():
		return
		
	_start_animation()
	
	_kill_tween(animation_tween)
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	
	# Shake más sutil para disabled
	var shake_positions = [
		original_position + Vector2(2, 0),
		original_position + Vector2(-2, 0),
		original_position + Vector2(1, 0),
		original_position + Vector2(-1, 0),
		original_position
	]
	
	for i in range(shake_positions.size()):
		var delay = i * 0.05
		animation_tween.tween_property(self, "position", shake_positions[i], 0.05).set_delay(delay)
	
	# Efecto visual de disabled
	var original_modulate = modulate
	var disabled_color = Color(1.2, 0.8, 0.8, 1.0)
	
	animation_tween.tween_property(self, "modulate", disabled_color, 0.1)
	animation_tween.tween_property(self, "modulate", original_modulate, 0.15).set_delay(0.1)
	
	await animation_tween.finished
	_end_animation()

func play_card_animation():
	if is_being_played:
		return
		
	is_being_played = true
	card_played.emit(self)
	_cleanup_all_tweens()
	
	_kill_tween(play_tween)
	play_tween = create_tween()
	play_tween.set_parallel(true)
	
	play_tween.tween_property(self, "position", position + Vector2(0, -100), 0.12).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	play_tween.tween_property(self, "scale", Vector2(0.6, 0.6), 0.12).set_ease(Tween.EASE_IN)
	play_tween.tween_property(self, "modulate:a", 0.0, 0.18).set_ease(Tween.EASE_IN)
	play_tween.tween_property(self, "rotation", deg_to_rad(5), 0.1).set_ease(Tween.EASE_IN)
	
	await play_tween.finished
	queue_free()
	
func _on_mouse_entered():
	if is_being_played or gamepad_hover_active or gamepad_selection_applied:
		return
	
	if not is_hovered and is_playable and _can_animate():
		is_hovered = true
		card_hovered.emit(self)
		_apply_hover_effects()

func _on_mouse_exited():
	if is_being_played or gamepad_hover_active or gamepad_selection_applied:
		return
		
	if is_hovered:
		is_hovered = false
		card_unhovered.emit(self)
		_remove_hover_effects()

func _apply_hover_effects():
	_kill_tween(hover_tween)
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	
	hover_tween.tween_property(self, "scale", original_scale * HOVER_SCALE_MULTIPLIER, ANIMATION_SPEED_FAST).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	hover_tween.tween_property(self, "z_index", 5, 0.05)
	
	var hover_modulate = Color(1.08, 1.08, 1.08, 1.0)
	hover_tween.tween_property(self, "modulate", hover_modulate, ANIMATION_SPEED_FAST)

func _remove_hover_effects():
	_kill_tween(hover_tween)
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	
	hover_tween.tween_property(self, "scale", original_scale, ANIMATION_SPEED_NORMAL).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "z_index", 0, ANIMATION_SPEED_FAST)
	
	var target_modulate = Color.WHITE if is_playable else Color(0.4, 0.4, 0.4, 0.7)
	hover_tween.tween_property(self, "modulate", target_modulate, ANIMATION_SPEED_NORMAL)


func has_gamepad_selection_applied() -> bool:
	return gamepad_selection_applied

func set_playable(playable: bool):
	if is_being_played:
		return
		
	is_playable = playable
	
	_kill_tween(playable_tween)
	playable_tween = create_tween()
	
	if playable:
		playable_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		playable_tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4, 0.7), 0.15)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if is_hovered:
			_remove_hover_effects()
			is_hovered = false


func _can_animate() -> bool:
	return not is_being_played and not animation_in_progress

func _start_animation():
	animation_in_progress = true

func _end_animation():
	animation_in_progress = false

func _kill_tween(tween: Tween):
	if tween and tween.is_valid():
		tween.kill()

func force_reset_visual_state():
	_cleanup_all_tweens()
	
	# Resetear flags
	gamepad_selection_applied = false
	gamepad_hover_active = false
	is_hovered = false
	animation_in_progress = false
	
	# Resetear propiedades visuales inmediatamente
	scale = original_scale
	z_index = 0
	rotation = 0.0
	
	# Resetear modulación basada en si es jugable
	if is_playable:
		modulate = Color.WHITE
	else:
		modulate = Color(0.4, 0.4, 0.4, 0.7)
	
	# Resetear bordes
	if card_border:
		card_border.modulate = Color.WHITE

func _cleanup_all_tweens():
	var tweens_to_kill = [hover_tween, gamepad_selection_tween, playable_tween, animation_tween, epic_border_tween, play_tween]
	for tween in tweens_to_kill:
		_kill_tween(tween)
	
	# Resetear flags después de limpiar tweens
	gamepad_selection_applied = false
	gamepad_hover_active = false
	is_hovered = false

func _on_card_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _can_animate():
			return
			
		if is_playable:
			card_clicked.emit(self)
		else:
			animate_mana_insufficient()

func update_display():
	name_label.text = card_data.card_name
	cost_label.text = str(card_data.cost)

	var rarity_text = DeckManager.get_card_rarity_text(card_data)
	rarity_label.text = rarity_text
	
	match card_data.card_type:
		"attack":
			description_label.text = "Deals " + str(card_data.damage) + " damage"
		"heal":
			description_label.text = "Restores " + str(card_data.heal) + " health"
		"shield":
			description_label.text = "Grants " + str(card_data.shield) + " shield"
		"hybrid":
			var effects = []
			if card_data.damage > 0:
				effects.append("Deals " + str(card_data.damage) + " damage")
			if card_data.heal > 0:
				effects.append("Restores " + str(card_data.heal) + " health")
			if card_data.shield > 0:
				effects.append("Grants " + str(card_data.shield) + " shield")
			description_label.text = " | ".join(effects)
		_:
			description_label.text = card_data.description
	
	var type_colors = get_card_type_colors(card_data.card_type)
	var rarity_colors = get_rarity_colors()
	var rarity = CardProbability.calculate_card_rarity(card_data.damage, card_data.heal, card_data.shield)
	
	card_bg.color = type_colors.background
	card_border.color = type_colors.border
	card_inner.color = type_colors.inner
	cost_bg.color = type_colors.cost_bg
	art_bg.color = type_colors.art_bg

	var rarity_multiplier = rarity_colors[rarity]
	card_border.color = card_border.color * rarity_multiplier
	rarity_bg.color = type_colors.border * 0.8

	apply_rarity_effects(rarity)
	load_card_illustration()
	
	match card_data.card_type:
		"attack":
			stat_value.text = str(card_data.damage)
			stat_value.modulate = Color.ORANGE_RED
		"heal":
			stat_value.text = str(card_data.heal)
			stat_value.modulate = Color.LIME_GREEN
		"shield":
			stat_value.text = str(card_data.shield)
			stat_value.modulate = Color.CYAN
		"hybrid":
			var total_power = card_data.damage + card_data.heal + card_data.shield
			stat_value.text = str(total_power)
			stat_value.modulate = Color.GOLD
		_:
			stat_value.text = "?"
			stat_value.modulate = Color.GRAY
			
func load_card_illustration():
	var video_stream: VideoStream = null
	match card_data.card_type:
		"attack":
			video_stream = ATTACK_VIDEO
		"heal":
			video_stream = HEAL_VIDEO
		"shield":
			video_stream = SHIELD_VIDEO
		"hybrid":
			video_stream = HYBRID_VIDEO
	
	if video_stream and card_icon is VideoStreamPlayer:
		card_icon.stream = video_stream
		card_icon.loop = true
		card_icon.autoplay = true
		card_icon.play()

func get_card_type_colors(card_type: String) -> Dictionary:
	match card_type:
		"attack":
			return {
				"background": Color(0.2, 0.1, 0.1, 1),
				"border": Color(0.8, 0.2, 0.2, 1),
				"inner": Color(0.3, 0.15, 0.15, 1),
				"cost_bg": Color(0.6, 0.1, 0.1, 1),
				"art_bg": Color(0.4, 0.2, 0.2, 1)
			}
		"heal":
			return {
				"background": Color(0.1, 0.2, 0.1, 1),
				"border": Color(0.2, 0.8, 0.2, 1),
				"inner": Color(0.15, 0.3, 0.15, 1),
				"cost_bg": Color(0.1, 0.6, 0.1, 1),
				"art_bg": Color(0.2, 0.4, 0.2, 1)
			}
		"shield":
			return {
				"background": Color(0.1, 0.1, 0.2, 1),
				"border": Color(0.2, 0.4, 0.8, 1),
				"inner": Color(0.15, 0.15, 0.3, 1),
				"cost_bg": Color(0.1, 0.2, 0.6, 1),
				"art_bg": Color(0.2, 0.2, 0.4, 1)
			}
		"hybrid":
			return {
				"background": Color(0.15, 0.12, 0.05, 1),
				"border": Color(0.8, 0.7, 0.3, 1),
				"inner": Color(0.25, 0.22, 0.15, 1),
				"cost_bg": Color(0.6, 0.5, 0.2, 1),
				"art_bg": Color(0.4, 0.35, 0.25, 1)
			}
		_:
			return {
				"background": Color(0.15, 0.15, 0.15, 1),
				"border": Color(0.5, 0.5, 0.5, 1),
				"inner": Color(0.25, 0.25, 0.25, 1),
				"cost_bg": Color(0.4, 0.4, 0.4, 1),
				"art_bg": Color(0.3, 0.3, 0.3, 1)
			}

func get_rarity_colors() -> Dictionary:
	return {
		"common": 1.0,
		"uncommon": 2.5,
		"rare": 3.2,
		"epic": 4.0
	}

func set_card_data(data: CardData):
	card_data = data
	if is_inside_tree():
		update_display()

func set_mouse_filter_recursive(node: Node):
	if node is Control:
		var control = node as Control
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	
	for child in node.get_children():
		set_mouse_filter_recursive(child)

func apply_rarity_effects(rarity: String):
	match rarity:
		"uncommon":
			name_label.modulate = Color(0.7, 1.4, 0.9, 1.0)
			cost_label.modulate = Color(0.8, 1.5, 1.0, 1.0)
			card_border.modulate = Color(1.05, 1.2, 1.03, 1.0)
		"rare":
			name_label.modulate = Color(0.8, 1.0, 1.6, 1.0)
			cost_label.modulate = Color(0.9, 1.1, 1.7, 1.0)
			stat_value.modulate = stat_value.modulate * Color(0.7, 1.0, 1.8, 1.0)
			card_icon.modulate = Color(0.9, 1.0, 1.4, 1.0)
			card_border.modulate = Color(1.0, 1.15, 1.5, 1.0)
		"epic":
			name_label.modulate = Color(1.6, 1.1, 1.8, 1.0)
			cost_label.modulate = Color(1.7, 1.2, 1.6, 1.0)
			stat_value.modulate = stat_value.modulate * Color(2.2, 1.3, 2.0, 1.0)
			card_icon.modulate = Color(1.5, 1.2, 1.7, 1.0)
			modulate = Color(1.15, 1.05, 1.2, 1.0)
			card_border.modulate = Color(1.6, 1.2, 1.5, 1.0)

			_kill_tween(epic_border_tween)
			epic_border_tween = create_tween()
			epic_border_tween.set_loops()
			epic_border_tween.tween_property(card_border, "modulate", Color(1.4, 1.2, 1.5, 1.0), 0.6)
			epic_border_tween.tween_property(card_border, "modulate", Color(1.2, 1.1, 1.3, 1.0), 0.6)
		_:
			pass

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		is_being_played = true
		_cleanup_all_tweens()
