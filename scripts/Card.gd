class_name Card
extends Control

@export var card_data: CardData
@onready var name_label = $CardBackground/CardBorder/CardInner/VBox/HeaderContainer/NameLabel
@onready var cost_label = $CardBackground/CardBorder/CardInner/VBox/HeaderContainer/CostContainer/CostLabel
@onready var cost_bg = $CardBackground/CardBorder/CardInner/VBox/HeaderContainer/CostContainer
@onready var description_label = $CardBackground/CardBorder/CardInner/VBox/DescriptionContainer/DescriptionLabel
@onready var card_background = $CardBackground
@onready var card_bg = $CardBackground
@onready var card_border = $CardBackground/CardBorder
@onready var card_inner = $CardBackground/CardBorder/CardInner
@onready var card_icon = $CardBackground/CardBorder/CardInner/VBox/ArtContainer/CardIcon
@onready var stat_value = $CardBackground/CardBorder/CardInner/VBox/StatsContainer/StatValue
@onready var rarity_label = $CardBackground/CardBorder/CardInner/VBox/RarityContainer/RarityLabel
@onready var rarity_bg = $CardBackground/CardBorder/CardInner/VBox/RarityContainer
@onready var art_bg = $CardBackground/CardBorder/CardInner/VBox/ArtContainer

@export var card_images_folder: String = "res://assets/card_illustrations/"
@export var number_of_images: int = 10
@export var image_extension: String = ".jpg"

signal card_clicked(card: Card)
signal card_played(card: Card)
signal card_hovered(card: Card)
signal card_unhovered(card: Card)

var cached_rarity_string: String = ""
var original_scale: Vector2
var is_hovered: bool = false
var is_playable: bool = true
var is_being_played: bool = false
var gamepad_selected: bool = false
var current_tween: Tween

var cached_type_colors: Dictionary = {}
var cached_rarity_multiplier: float = 1.0
var cached_styles: Dictionary = {}
var base_stat_modulate: Color = Color.WHITE

const HOVER_SCALE = 1.07
const GAMEPAD_SCALE = 1.07
const ANIMATION_SPEED = 0.15

func _ready():
	original_scale = scale
	
	if card_data:
		_cache_card_colors()
		update_display()
	
	_setup_unique_shader_material()
	disable_shine_effect()
	animate_cardicon()
	_setup_signals()
	_optimize_mouse_filter()
	
func animate_cardicon():
	$AnimationPlayer.seek(randf() * 5.0)
	$AnimationPlayer.play("cardicon_movement")
	
func _setup_unique_shader_material():
	if not card_icon:
		return
		
	var material = card_icon.material
	if not material or not material is ShaderMaterial:
		return
	
	card_icon.material = material.duplicate()
	
	(card_icon.material as ShaderMaterial).set_shader_parameter("time_offset", randf() * 10.0)

func _setup_signals():
	gui_input.connect(_on_card_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
func enable_shine_effect():
	if card_icon and card_icon.material and card_icon.material is ShaderMaterial:
		var shader_material = card_icon.material as ShaderMaterial
		shader_material.set_shader_parameter("shine_enabled", true)

func disable_shine_effect():
	if card_icon and card_icon.material and card_icon.material is ShaderMaterial:
		var shader_material = card_icon.material as ShaderMaterial
		shader_material.set_shader_parameter("shine_enabled", false)

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
	var rarity_enum = RaritySystem.calculate_card_rarity(card_data.damage, card_data.heal, card_data.shield)
	cached_rarity_string = RaritySystem.get_rarity_string(rarity_enum)
	var rarity_colors = _get_rarity_colors()
	cached_rarity_multiplier = rarity_colors.get(cached_rarity_string, 1.0)

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
	
	var cost_style = cost_bg.get_theme_stylebox("panel")
	if cost_style is StyleBoxFlat:
		var original_color = cost_style.bg_color
		current_tween.tween_method(func(color): cost_style.bg_color = color, original_color, Color.RED, 0.1)
		current_tween.tween_method(func(color): cost_style.bg_color = color, Color.RED, original_color, 0.1).set_delay(0.1)

func apply_gamepad_selection_style():
	if gamepad_selected or is_being_played:
		return
	
	gamepad_selected = true
	is_hovered = false
	
	_apply_selection_effects()

func remove_gamepad_selection_style():
	if not gamepad_selected:
		return
	
	gamepad_selected = false
	_remove_selection_effects()

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
	
func _apply_selection_effects():
	enable_shine_effect()
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "scale", original_scale * HOVER_SCALE, ANIMATION_SPEED)
	current_tween.tween_property(self, "z_index", 10, ANIMATION_SPEED)
	current_tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.0, 1.0), ANIMATION_SPEED)
	current_tween.tween_property(card_border, "modulate", Color(1.2, 1.2, 1.0, 1.0), ANIMATION_SPEED)

func _remove_selection_effects():
	disable_shine_effect()
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "scale", original_scale, ANIMATION_SPEED)
	current_tween.tween_property(self, "z_index", 0, ANIMATION_SPEED)
	current_tween.tween_property(card_border, "modulate", Color.WHITE, ANIMATION_SPEED)
	
	var target_modulate = Color.WHITE if is_playable else Color(0.4, 0.4, 0.4, 0.7)
	current_tween.tween_property(self, "modulate", target_modulate, ANIMATION_SPEED)
	
func _on_mouse_entered():
	if is_being_played or gamepad_selected or mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return
	
	if GameState.gamepad_mode:
		return
	
	if not is_hovered and is_playable:
		is_hovered = true
		card_hovered.emit(self)
		_apply_selection_effects()

func _on_mouse_exited():
	if is_being_played or not is_hovered or gamepad_selected:
		return
	
	is_hovered = false
	card_unhovered.emit(self)
	_remove_selection_effects()

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
			_remove_selection_effects()
			is_hovered = false

func force_reset_visual_state():
	_stop_current_tween()
	
	gamepad_selected = false
	is_hovered = false

	disable_shine_effect()
	
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
	
	_update_panel_color(card_bg, cached_type_colors.background)
	_update_panel_color(card_border, cached_type_colors.border * cached_rarity_multiplier)
	_update_panel_color(card_inner, cached_type_colors.inner)
	_update_panel_color(cost_bg, cached_type_colors.cost_bg)
	_update_panel_color(art_bg, cached_type_colors.art_bg)
	_update_panel_color(rarity_bg, cached_type_colors.border * 0.8)
	
	_apply_rarity_effects(cached_rarity_string)
	_load_card_illustration()
	_update_stat_display()

func _update_panel_color(panel: Panel, color: Color):
	if not panel:
		return
	
	var cache_key = panel.get_instance_id()
	var style: StyleBoxFlat
	
	if cached_styles.has(cache_key):
		style = cached_styles[cache_key]
	else:
		var original_style = panel.get_theme_stylebox("panel")
		if original_style is StyleBoxFlat:
			style = original_style.duplicate()
			cached_styles[cache_key] = style
			panel.add_theme_stylebox_override("panel", style)
	
	if style:
		style.bg_color = color

func _update_stat_display():
	match card_data.card_type:
		"attack":
			stat_value.text = str(card_data.damage)
			base_stat_modulate = Color.ORANGE_RED
		"heal":
			stat_value.text = str(card_data.heal)
			base_stat_modulate = Color.LIME_GREEN
		"shield":
			stat_value.text = str(card_data.shield)
			base_stat_modulate = Color.CYAN
		"hybrid":
			var total_power = card_data.damage + card_data.heal + card_data.shield
			stat_value.text = str(total_power)
			base_stat_modulate = Color.GOLD
		_:
			stat_value.text = "?"
			base_stat_modulate = Color.GRAY
	
	stat_value.modulate = base_stat_modulate

func _load_card_illustration():
	var random_index = randi() % number_of_images + 1
	var image_path = card_images_folder + str(random_index) + image_extension
	var texture = load(image_path)
	
	if card_icon is TextureRect and texture:
		card_icon.texture = texture

	else:
		push_warning("No se pudo cargar la imagen: " + image_path)

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
			stat_value.modulate = base_stat_modulate * Color(0.7, 1.0, 1.8, 1.0)
			card_icon.modulate = Color(0.9, 1.0, 1.4, 1.0)
			card_border.modulate = Color(1.0, 1.15, 1.5, 1.0)
		"epic":
			name_label.modulate = Color(1.6, 1.1, 1.8, 1.0)
			cost_label.modulate = Color(1.7, 1.2, 1.6, 1.0)
			stat_value.modulate = base_stat_modulate * Color(2.2, 1.3, 2.0, 1.0)
			card_icon.modulate = Color(1.5, 1.2, 1.7, 1.0)
			modulate = Color(1.15, 1.05, 1.2, 1.0)
			card_border.modulate = Color(1.6, 1.2, 1.5, 1.0)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		is_being_played = true
		_stop_current_tween()
		cached_styles.clear()
