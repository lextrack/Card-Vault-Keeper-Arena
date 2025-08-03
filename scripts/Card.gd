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

var original_scale: Vector2
var original_position: Vector2
var is_hovered: bool = false
var is_playable: bool = true
var hover_tween: Tween
var epic_border_tween: Tween
var playable_tween: Tween
var play_tween: Tween
var selection_tween: Tween
var has_played_epic_animation: bool = false
var is_being_played: bool = false
var animation_in_progress: bool = false

func _ready():
	original_scale = scale
	original_position = position
	
	if card_data:
		update_display()
	
	gui_input.connect(_on_card_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	set_mouse_filter_recursive(self)

func get_card_data() -> CardData:
	return card_data

func animate_mana_insufficient():
	if animation_in_progress or is_being_played:
		return
	
	animation_in_progress = true
	
	if selection_tween:
		selection_tween.kill()
	
	selection_tween = create_tween()
	selection_tween.set_parallel(true)
	
	var shake_positions = [
		original_position + Vector2(4, 0),
		original_position + Vector2(-4, 0),
		original_position + Vector2(3, 0),
		original_position + Vector2(-3, 0),
		original_position + Vector2(2, 0),
		original_position + Vector2(-2, 0),
		original_position
	]
	
	for i in range(shake_positions.size()):
		var delay = i * 0.03
		selection_tween.tween_property(self, "position", shake_positions[i], 0.03).set_delay(delay)
	
	selection_tween.tween_property(cost_bg, "color", Color.RED, 0.1)
	selection_tween.tween_property(cost_label, "modulate", Color(1.5, 0.3, 0.3, 1.0), 0.1)
	selection_tween.tween_property(card_border, "modulate", Color(1.3, 0.5, 0.5, 1.0), 0.1)
	
	selection_tween.tween_property(cost_bg, "color", get_card_type_colors(card_data.card_type).cost_bg, 0.15).set_delay(0.1)
	selection_tween.tween_property(cost_label, "modulate", Color.WHITE, 0.15).set_delay(0.1)
	selection_tween.tween_property(card_border, "modulate", Color.WHITE, 0.15).set_delay(0.1)
	
	await selection_tween.finished
	animation_in_progress = false
		
func apply_gamepad_selection_style():
	if selection_tween:
		selection_tween.kill()
	
	selection_tween = create_tween()
	selection_tween.set_parallel(true)
	
	selection_tween.tween_property(self, "scale", original_scale * 1.08, 0.15).set_ease(Tween.EASE_OUT)
	selection_tween.tween_property(self, "z_index", 15, 0.05)

	var selected_modulate = modulate * Color(1.12, 1.12, 1.1, 1.0)
	selection_tween.tween_property(self, "modulate", selected_modulate, 0.15)
	
	selection_tween.tween_property(self, "scale", original_scale * 1.06, 0.8).set_delay(0.15)
	selection_tween.tween_property(self, "scale", original_scale * 1.08, 0.8).set_delay(0.95)
	selection_tween.set_loops()

func remove_gamepad_selection_style():
	if selection_tween:
		selection_tween.kill()
	
	selection_tween = create_tween()
	selection_tween.set_parallel(true)
	
	selection_tween.tween_property(self, "scale", original_scale, 0.2).set_ease(Tween.EASE_OUT)
	selection_tween.tween_property(self, "z_index", 0, 0.15)
	
	if is_playable:
		selection_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	else:
		selection_tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4, 0.7), 0.2)

func play_disabled_animation():
	if is_being_played or animation_in_progress:
		return
		
	animation_in_progress = true
	
	var shake_tween = create_tween()
	shake_tween.set_parallel(true)
	
	var shake_positions = [
		original_position + Vector2(3, 0),
		original_position + Vector2(-3, 0),
		original_position + Vector2(2, 0),
		original_position + Vector2(-2, 0),
		original_position
	]
	
	for i in range(shake_positions.size()):
		var delay = i * 0.04
		shake_tween.tween_property(self, "position", shake_positions[i], 0.04).set_delay(delay)
	
	var original_modulate = modulate
	shake_tween.tween_property(self, "modulate", Color(1.3, 0.7, 0.7, 1.0), 0.08)
	shake_tween.tween_property(self, "modulate", original_modulate, 0.12).set_delay(0.08)
	
	await shake_tween.finished
	animation_in_progress = false

func play_card_animation():
	if is_being_played:
		return
		
	is_being_played = true
	card_played.emit(self)
	_cleanup_tweens()
	
	play_tween = create_tween()
	play_tween.set_parallel(true)
	
	play_tween.tween_property(self, "position", position + Vector2(0, -80), 0.1)
	play_tween.tween_property(self, "scale", Vector2(0.7, 0.7), 0.1)
	play_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	
	await play_tween.finished
	queue_free()

func _cleanup_tweens():
	var tweens_to_kill = [hover_tween, epic_border_tween, playable_tween, selection_tween]
	for tween in tweens_to_kill:
		if tween and tween.is_valid():
			tween.kill()

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

func _can_animate() -> bool:
	return not is_being_played and not animation_in_progress

func _on_card_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _can_animate():
			return
			
		if is_playable:
			card_clicked.emit(self)
		else:
			animate_mana_insufficient()

func _on_mouse_entered():
	if not is_hovered and is_playable and _can_animate():
		is_hovered = true
   	
		if hover_tween:
			hover_tween.kill()
   	
		hover_tween = create_tween()
		hover_tween.set_parallel(true)
   	
		hover_tween.tween_property(self, "scale", original_scale * 1.06, 0.12).set_ease(Tween.EASE_OUT)
		hover_tween.tween_property(self, "z_index", 10, 0.05)
   	
		var hover_modulate = modulate * Color(1.08, 1.08, 1.08, 1.0)
		hover_tween.tween_property(self, "modulate", hover_modulate, 0.12)

func _on_mouse_exited():
	if is_hovered and not is_being_played:
		is_hovered = false
   	
		if hover_tween:
			hover_tween.kill()
   	
		hover_tween = create_tween()
		hover_tween.set_parallel(true)
   	
		hover_tween.tween_property(card_background, "rotation", 0.0, 0.18).set_ease(Tween.EASE_OUT)
		hover_tween.tween_property(self, "scale", original_scale, 0.18).set_ease(Tween.EASE_OUT)
		hover_tween.tween_property(self, "z_index", 0, 0.12)
   	
		if is_playable:
			hover_tween.tween_property(self, "modulate", Color.WHITE, 0.18)
		else:
			hover_tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4, 0.7), 0.18)

func set_card_data(data: CardData):
	card_data = data
	if is_inside_tree():
		update_display()

func set_playable(playable: bool):
	if is_being_played:
		return
		
	is_playable = playable
	
	if playable_tween:
		playable_tween.kill()
	
	playable_tween = create_tween()
	
	if playable:
		playable_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		playable_tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4, 0.7), 0.15)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if is_hovered:
			is_hovered = false
			if hover_tween:
				hover_tween.kill()
			hover_tween = create_tween()
			hover_tween.set_parallel(true)
			hover_tween.tween_property(self, "scale", original_scale, 0.12)
			hover_tween.tween_property(self, "z_index", 0, 0.06)
			
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

			if epic_border_tween:
				epic_border_tween.kill()
			epic_border_tween = create_tween()
			epic_border_tween.set_loops()
			epic_border_tween.tween_property(card_border, "modulate", Color(1.4, 1.2, 1.5, 1.0), 0.6)
			epic_border_tween.tween_property(card_border, "modulate", Color(1.2, 1.1, 1.3, 1.0), 0.6)
		_:
			pass

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		is_being_played = true
		_cleanup_tweens()
