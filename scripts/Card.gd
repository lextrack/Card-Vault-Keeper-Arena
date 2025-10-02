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
var is_hovered: bool = false
var is_playable: bool = true
var is_being_played: bool = false
var gamepad_selected: bool = false
var current_tween: Tween

var cached_type_colors: Dictionary = {}
var cached_rarity_multiplier: float = 1.0

const HOVER_SCALE = 1.07
const GAMEPAD_SCALE = 1.07
const ANIMATION_SPEED = 0.15

func _ready():
	original_scale = scale
	
	if card_data:
		_cache_card_colors()
		update_display()
	
	_setup_signals()
	_optimize_mouse_filter()

func _setup_signals():
	gui_input.connect(_on_card_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _optimize_mouse_filter():
	_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_PASS)

func _set_mouse_filter_recursive(node: Node, filter: int):
	if node is Control:
		(node as Control).mouse_filter = filter
	
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)

func _cache_card_colors():
	if not card_data:
		return
	
	cached_type_colors = _get_card_type_colors(card_data.card_type)
	var rarity = CardProbability.calculate_card_rarity(
		card_data.damage, 
		card_data.heal, 
		card_data.shield
	)
	var rarity_colors = _get_rarity_colors()
	cached_rarity_multiplier = rarity_colors.get(rarity, 1.0)

func get_card_data() -> CardData:
	return card_data

func animate_mana_insufficient():
	if is_being_played:
		return
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "rotation", deg_to_rad(3), 0.05)
	current_tween.tween_property(self, "rotation", deg_to_rad(-3), 0.05).set_delay(0.05)
	current_tween.tween_property(self, "rotation", 0.0, 0.05).set_delay(0.1)
	current_tween.tween_property(cost_bg, "color", Color.RED, 0.1)
	current_tween.tween_property(cost_bg, "color", cached_type_colors.cost_bg, 0.1).set_delay(0.1)

func apply_gamepad_selection_style():
	if gamepad_selected or is_being_played:
		return
	
	gamepad_selected = true
	is_hovered = false
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "scale", original_scale * GAMEPAD_SCALE, ANIMATION_SPEED)
	current_tween.tween_property(self, "z_index", 10, ANIMATION_SPEED)
	current_tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.0, 1.0), ANIMATION_SPEED)
	current_tween.tween_property(card_border, "modulate", Color(1.2, 1.2, 1.0, 1.0), ANIMATION_SPEED)

func remove_gamepad_selection_style():
	if not gamepad_selected:
		return
	
	gamepad_selected = false
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "scale", original_scale, ANIMATION_SPEED)
	current_tween.tween_property(self, "z_index", 0, ANIMATION_SPEED)
	current_tween.tween_property(card_border, "modulate", Color.WHITE, ANIMATION_SPEED)
	
	var target_modulate = Color.WHITE if is_playable else Color(0.4, 0.4, 0.4, 0.7)
	current_tween.tween_property(self, "modulate", target_modulate, ANIMATION_SPEED)

func play_disabled_animation():
	if is_being_played:
		return
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "rotation", deg_to_rad(2), 0.05)
	current_tween.tween_property(self, "rotation", deg_to_rad(-2), 0.05).set_delay(0.05)
	current_tween.tween_property(self, "rotation", 0.0, 0.05).set_delay(0.1)
	
	var flash_color = Color(1.2, 0.8, 0.8, 1.0)
	var return_color = Color.WHITE if is_playable else Color(0.4, 0.4, 0.4, 0.7)
	current_tween.tween_property(self, "modulate", flash_color, 0.1)
	current_tween.tween_property(self, "modulate", return_color, 0.1).set_delay(0.1)

func play_card_animation():
	if is_being_played:
		return
	
	is_being_played = true
	card_played.emit(self)
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.3)
	current_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	current_tween.tween_property(self, "rotation", deg_to_rad(1), 0.2)
	
	await current_tween.finished
	queue_free()

func _on_mouse_entered():
	if is_being_played or gamepad_selected or mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return
	
	var main_scene_node = get_tree().get_first_node_in_group("main_scene")
	if main_scene_node and main_scene_node.has("input_manager"):
		var input_manager = main_scene_node.input_manager
		if input_manager and input_manager.has("gamepad_mode") and input_manager.gamepad_mode:
			return
	
	if not is_hovered and is_playable:
		is_hovered = true
		card_hovered.emit(self)
		_apply_hover_effects()

func _on_mouse_exited():
	if is_being_played or not is_hovered or gamepad_selected:
		return
	
	is_hovered = false
	card_unhovered.emit(self)
	_remove_hover_effects()

func _apply_hover_effects():
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "scale", original_scale * HOVER_SCALE, ANIMATION_SPEED)
	current_tween.tween_property(self, "z_index", 5, ANIMATION_SPEED)
	current_tween.tween_property(self, "modulate", Color(1.05, 1.05, 1.05, 1.0), ANIMATION_SPEED)

func _remove_hover_effects():
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "scale", original_scale, ANIMATION_SPEED)
	current_tween.tween_property(self, "z_index", 0, ANIMATION_SPEED)
	
	var target_modulate = Color.WHITE if is_playable else Color(0.4, 0.4, 0.4, 0.7)
	current_tween.tween_property(self, "modulate", target_modulate, ANIMATION_SPEED)

func has_gamepad_selection_applied() -> bool:
	return gamepad_selected

func set_playable(playable: bool):
	if is_being_played or is_playable == playable:
		return
	
	is_playable = playable
	
	_stop_current_tween()
	current_tween = create_tween()
	
	if playable:
		current_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		mouse_filter = Control.MOUSE_FILTER_PASS
		_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_PASS)
	else:
		current_tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4, 0.7), 0.2)
		if not gamepad_selected:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if is_hovered:
			_remove_hover_effects()
			is_hovered = false

func force_reset_visual_state():
	_stop_current_tween()
	
	gamepad_selected = false
	is_hovered = false
	
	scale = original_scale
	z_index = 0
	rotation = 0.0

	if card_border:
		card_border.modulate = Color.WHITE

	if is_playable:
		modulate = Color.WHITE
		mouse_filter = Control.MOUSE_FILTER_PASS
		_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_PASS)
	else:
		modulate = Color(0.4, 0.4, 0.4, 0.7)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_card_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_being_played:
			return
		
		if is_playable:
			card_clicked.emit(self)
		else:
			animate_mana_insufficient()

func _stop_current_tween():
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null

func _generate_description() -> String:
	match card_data.card_type:
		"attack":
			return "Deals %d damage" % card_data.damage
		"heal":
			return "Restores %d health" % card_data.heal
		"shield":
			return "Grants %d shield" % card_data.shield
		"hybrid":
			var effects: PackedStringArray = []
			if card_data.damage > 0:
				effects.append("Deals %d damage" % card_data.damage)
			if card_data.heal > 0:
				effects.append("Restores %d health" % card_data.heal)
			if card_data.shield > 0:
				effects.append("Grants %d shield" % card_data.shield)
			return " | ".join(effects)
		_:
			return card_data.description

func update_display():
	name_label.text = card_data.card_name
	cost_label.text = str(card_data.cost)
	description_label.text = _generate_description()

	var rarity_text = DeckManager.get_card_rarity_text(card_data)
	rarity_label.text = rarity_text
	
	card_bg.color = cached_type_colors.background
	card_border.color = cached_type_colors.border * cached_rarity_multiplier
	card_inner.color = cached_type_colors.inner
	cost_bg.color = cached_type_colors.cost_bg
	art_bg.color = cached_type_colors.art_bg
	rarity_bg.color = cached_type_colors.border * 0.8

	var rarity = CardProbability.calculate_card_rarity(
		card_data.damage, 
		card_data.heal, 
		card_data.shield
	)
	_apply_rarity_effects(rarity)
	_load_card_illustration()
	_update_stat_display()

func _update_stat_display():
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

func _load_card_illustration():
	var video_stream: VideoStream = null
	match card_data.card_type:
		"attack": video_stream = ATTACK_VIDEO
		"heal": video_stream = HEAL_VIDEO
		"shield": video_stream = SHIELD_VIDEO
		"hybrid": video_stream = HYBRID_VIDEO
	
	if video_stream and card_icon is VideoStreamPlayer:
		card_icon.stream = video_stream
		card_icon.loop = true
		card_icon.autoplay = true
		card_icon.play()

func _get_card_type_colors(card_type: String) -> Dictionary:
	const COLOR_TABLE = {
		"attack": {
			"background": Color(0.2, 0.1, 0.1, 1),
			"border": Color(0.8, 0.2, 0.2, 1),
			"inner": Color(0.3, 0.15, 0.15, 1),
			"cost_bg": Color(0.6, 0.1, 0.1, 1),
			"art_bg": Color(0.4, 0.2, 0.2, 1)
		},
		"heal": {
			"background": Color(0.1, 0.2, 0.1, 1),
			"border": Color(0.2, 0.8, 0.2, 1),
			"inner": Color(0.15, 0.3, 0.15, 1),
			"cost_bg": Color(0.1, 0.6, 0.1, 1),
			"art_bg": Color(0.2, 0.4, 0.2, 1)
		},
		"shield": {
			"background": Color(0.1, 0.1, 0.2, 1),
			"border": Color(0.2, 0.4, 0.8, 1),
			"inner": Color(0.15, 0.15, 0.3, 1),
			"cost_bg": Color(0.1, 0.2, 0.6, 1),
			"art_bg": Color(0.2, 0.2, 0.4, 1)
		},
		"hybrid": {
			"background": Color(0.15, 0.12, 0.05, 1),
			"border": Color(0.8, 0.7, 0.3, 1),
			"inner": Color(0.25, 0.22, 0.15, 1),
			"cost_bg": Color(0.6, 0.5, 0.2, 1),
			"art_bg": Color(0.4, 0.35, 0.25, 1)
		}
	}
	
	return COLOR_TABLE.get(card_type, {
		"background": Color(0.15, 0.15, 0.15, 1),
		"border": Color(0.5, 0.5, 0.5, 1),
		"inner": Color(0.25, 0.25, 0.25, 1),
		"cost_bg": Color(0.4, 0.4, 0.4, 1),
		"art_bg": Color(0.3, 0.3, 0.3, 1)
	})

func _get_rarity_colors() -> Dictionary:
	return {
		"common": 1.0,
		"uncommon": 2.5,
		"rare": 3.2,
		"epic": 4.0
	}

func set_card_data(data: CardData):
	card_data = data
	if is_inside_tree():
		_cache_card_colors()
		update_display()

func _apply_rarity_effects(rarity: String):
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

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		is_being_played = true
		_stop_current_tween()
