class_name JokerCard
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
@onready var joker_label = $CardBackground/CardBorder/CardInner/VBox/JokerContainer/JokerLabel
@onready var joker_bg = $CardBackground/CardBorder/CardInner/VBox/JokerContainer
@onready var art_bg = $CardBackground/CardBorder/CardInner/VBox/ArtContainer

@export var card_images_folder: String = "res://assets/joker_illustrations/"
@export var number_of_images: int = 5
@export var image_extension: String = ".jpg"

signal card_clicked(card: JokerCard)
signal card_played(card: JokerCard)
signal card_hovered(card: JokerCard)
signal card_unhovered(card: JokerCard)

var original_scale: Vector2
var is_hovered: bool = false
var is_playable: bool = true
var is_being_played: bool = false
var gamepad_selected: bool = false
var current_tween: Tween
var cached_styles: Dictionary = {}

var _critical_children: Array = []

const HOVER_SCALE = 1.07
const GAMEPAD_SCALE = 1.07
const ANIMATION_SPEED = 0.15

const JOKER_COLORS = {
	"background": Color(0.15, 0.08, 0.20, 1.0),
	"border": Color(1.0, 0.84, 0.0, 1.0), 
	"inner": Color(0.25, 0.15, 0.30, 1.0),
	"cost_bg": Color(0.8, 0.6, 0.2, 1.0),
	"art_bg": Color(0.4, 0.25, 0.45, 1.0),
	"joker_bg": Color(0.6, 0.3, 0.8, 1.0)
}

func _ready():
	original_scale = scale
	
	if card_data:
		_cache_all_styles()
		update_display()

	_cache_critical_children()
	_setup_unique_shader_material()
	disable_shine_effect()
	_setup_signals()
	_optimize_mouse_filter()

func _cache_critical_children():
	_critical_children = [
		card_border, card_inner,
		name_label, cost_label, description_label,
		stat_value, joker_label,
		cost_bg, joker_bg, art_bg
	]

func _cache_all_styles():
	var panels = [card_bg, card_border, card_inner, cost_bg, art_bg, joker_bg]
	
	for panel in panels:
		if not panel:
			continue
		
		var cache_key = panel.get_instance_id()
		var original_style = panel.get_theme_stylebox("panel")
		
		if original_style is StyleBoxFlat:
			var style = original_style.duplicate()
			cached_styles[cache_key] = style
			panel.add_theme_stylebox_override("panel", style)

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
		
func _apply_selection_effects():
	if not is_instance_valid(self):
		return
	
	enable_shine_effect()
	
	if has_node("AnimationPlayer"):
		var anim_player = get_node("AnimationPlayer")
		if anim_player and anim_player.has_animation("cardicon_movement"):
			anim_player.seek(randf() * 3.0)
			anim_player.play("cardicon_movement")
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "scale", original_scale * HOVER_SCALE, ANIMATION_SPEED)
	current_tween.tween_property(self, "z_index", 10, ANIMATION_SPEED)
	current_tween.tween_property(self, "modulate", Color(1.15, 1.1, 1.05, 1.0), ANIMATION_SPEED)
	
	if is_instance_valid(card_border):
		current_tween.tween_property(card_border, "modulate", Color(1.4, 1.25, 1.0, 1.0), ANIMATION_SPEED)

func _remove_selection_effects():
	if not is_instance_valid(self):
		return
	
	disable_shine_effect()
	
	if has_node("AnimationPlayer"):
		var anim_player = get_node("AnimationPlayer")
		if anim_player:
			anim_player.stop()
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "scale", original_scale, ANIMATION_SPEED)
	current_tween.tween_property(self, "z_index", 0, ANIMATION_SPEED)
	
	if is_instance_valid(card_border):
		current_tween.tween_property(card_border, "modulate", Color.WHITE, ANIMATION_SPEED)
	
	var target_modulate = Color.WHITE if is_playable else Color(0.4, 0.4, 0.4, 0.7)
	current_tween.tween_property(self, "modulate", target_modulate, ANIMATION_SPEED)

func _optimize_mouse_filter():
	_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_IGNORE)
	mouse_filter = Control.MOUSE_FILTER_PASS

func _set_mouse_filter_recursive(node: Node, filter: int):
	if node is Control and node != self:
		(node as Control).mouse_filter = filter
	
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)

func get_card_data() -> CardData:
	return card_data

func animate_mana_insufficient():
	if is_being_played or not is_instance_valid(self):
		return
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "rotation", deg_to_rad(3), 0.05)
	current_tween.tween_property(self, "rotation", deg_to_rad(-3), 0.05).set_delay(0.05)
	current_tween.tween_property(self, "rotation", 0.0, 0.05).set_delay(0.1)
	
	if is_instance_valid(cost_bg):
		var cost_style = cost_bg.get_theme_stylebox("panel")
		if cost_style is StyleBoxFlat:
			var original_color = cost_style.bg_color
			current_tween.tween_method(func(color): 
				if is_instance_valid(cost_bg):
					cost_style.bg_color = color
			, original_color, Color.RED, 0.1)
			current_tween.tween_method(func(color): 
				if is_instance_valid(cost_bg):
					cost_style.bg_color = color
			, Color.RED, original_color, 0.1).set_delay(0.1)

func apply_gamepad_selection_style():
	if gamepad_selected or is_being_played or not is_instance_valid(self):
		return
	
	gamepad_selected = true
	is_hovered = false
	
	_apply_selection_effects()

func remove_gamepad_selection_style():
	if not gamepad_selected or not is_instance_valid(self):
		return
	
	gamepad_selected = false
	_remove_selection_effects()

func play_disabled_animation():
	if is_being_played or not is_instance_valid(self):
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
	if is_being_played or not is_instance_valid(self):
		return
	
	is_being_played = true
	
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_parallel(true)
	
	current_tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.3)
	current_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	current_tween.tween_property(self, "rotation", deg_to_rad(15), 0.2)
	
	current_tween.finished.connect(func():
		if is_instance_valid(self):
			card_played.emit(self)
			queue_free()
	)

func _on_mouse_entered():
	if is_being_played or gamepad_selected or mouse_filter == Control.MOUSE_FILTER_IGNORE or not is_instance_valid(self):
		return
	
	if GameState.gamepad_mode:
		return
	
	if not is_hovered and is_playable:
		is_hovered = true
		card_hovered.emit(self)
		_apply_selection_effects()

func _on_mouse_exited():
	if is_being_played or not is_hovered or gamepad_selected or not is_instance_valid(self):
		return
	
	is_hovered = false
	card_unhovered.emit(self)
	_remove_selection_effects()

func has_gamepad_selection_applied() -> bool:
	return gamepad_selected

func set_playable(playable: bool):
	if is_being_played or is_playable == playable or not is_instance_valid(self):
		return
	
	is_playable = playable
	
	_stop_current_tween()
	current_tween = create_tween()
	
	if playable:
		current_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		current_tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4, 0.7), 0.2)
		if not gamepad_selected:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if is_hovered:
			_remove_selection_effects()
			is_hovered = false

func force_reset_visual_state():
	if not is_instance_valid(self):
		return
	
	_stop_current_tween()
	
	gamepad_selected = false
	is_hovered = false

	disable_shine_effect()
	
	if has_node("AnimationPlayer"):
		var anim_player = get_node("AnimationPlayer")
		if anim_player:
			anim_player.stop()
	
	scale = original_scale
	z_index = 0
	rotation = 0.0

	if is_instance_valid(card_border):
		card_border.modulate = Color.WHITE

	if is_playable:
		modulate = Color.WHITE
		mouse_filter = Control.MOUSE_FILTER_PASS
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

func update_display():
	name_label.text = card_data.card_name
	cost_label.text = str(card_data.cost)
	description_label.text = card_data.description
	joker_label.text = "JOKER"
	
	_update_panel_color(card_bg, JOKER_COLORS.background)
	_update_panel_color(card_border, JOKER_COLORS.border)
	_update_panel_color(card_inner, JOKER_COLORS.inner)
	_update_panel_color(cost_bg, JOKER_COLORS.cost_bg)
	_update_panel_color(art_bg, JOKER_COLORS.art_bg)
	_update_panel_color(joker_bg, JOKER_COLORS.joker_bg)
	
	name_label.modulate = Color(1.2, 1.018, 0.43, 1.0)
	cost_label.modulate = Color(1.5, 1.3, 0.8, 1.0)
	joker_label.modulate = Color(1.3, 1.0, 1.5, 1.0) 
	
	_load_card_illustration()
	_update_stat_display()

func _update_panel_color(panel: Panel, color: Color):
	if not panel:
		return
	
	var cache_key = panel.get_instance_id()
	
	if cached_styles.has(cache_key):
		var style = cached_styles[cache_key]
		if style:
			style.bg_color = color

func _update_stat_display():
	var total_power = card_data.damage + card_data.heal + card_data.shield
	stat_value.text = str(total_power)
	stat_value.modulate = Color(1.5, 1.2, 0.5, 1.0)

func _load_card_illustration():
	if card_data.illustration_index == -1:
		card_data.illustration_index = randi() % number_of_images + 1
	
	var texture = TexturePool.get_texture(card_images_folder, card_data.illustration_index, image_extension)
	
	if card_icon is TextureRect and texture:
		card_icon.texture = texture
		card_icon.modulate = Color(1.2, 1.1, 0.8, 1.0)

func set_card_data(data: CardData):
	card_data = data
	if is_inside_tree():
		update_display()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		is_being_played = true
		_stop_current_tween()
		cached_styles.clear()
		_critical_children.clear()
