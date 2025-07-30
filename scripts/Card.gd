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
@onready var card_shadow = $CardShadow

const ATTACK_VIDEO = preload("res://assets/backgrounds/attack1.ogv")
const HEAL_VIDEO = preload("res://assets/backgrounds/heal1.ogv")
const SHIELD_VIDEO = preload("res://assets/backgrounds/shield1.ogv")
const HYBRID_VIDEO = preload("res://assets/backgrounds/hybrid1.ogv")

signal card_clicked(card: Card)
signal card_played(card: Card)

var original_scale: Vector2
var original_position: Vector2
var original_shadow_position: Vector2
var original_shadow_color: Color
var is_hovered: bool = false
var is_playable: bool = true
var hover_tween: Tween
var entrance_tween: Tween
var epic_border_tween: Tween
var playable_tween: Tween
var shadow_tween: Tween
var idle_shadow_tween: Tween
var play_tween: Tween
var has_played_epic_animation: bool = false
var has_played_entrance: bool = false

func _ready():
	original_scale = scale
	original_position = position
	
	if card_shadow:
		original_shadow_position = Vector2(card_shadow.offset_left, card_shadow.offset_top)
		original_shadow_color = card_shadow.color
	
	play_entrance_animation()
	
	if card_data:
		update_display()
	
	gui_input.connect(_on_card_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	set_mouse_filter_recursive(self)
	
	start_idle_shadow_animation()

func start_idle_shadow_animation():
	if not card_shadow or not is_playable:
		return
	
	if idle_shadow_tween:
		idle_shadow_tween.kill()
	
	idle_shadow_tween = create_tween()
	idle_shadow_tween.set_loops()
	idle_shadow_tween.set_parallel(true)

	var shadow_offset = 1.5
	var base_x = original_shadow_position.x
	var base_y = original_shadow_position.y
	
	idle_shadow_tween.tween_method(
		_update_shadow_idle_position,
		0.0,
		2.0 * PI,
		4.0
	)
	
	idle_shadow_tween.tween_method(
		_update_shadow_idle_opacity,
		0.0,
		2.0 * PI,
		3.5
	)

func _update_shadow_idle_position(angle: float):
	if not card_shadow:
		return
	
	var shadow_offset = 0.8
	var offset_x = sin(angle) * shadow_offset
	var offset_y = cos(angle * 0.7) * shadow_offset * 0.5
	
	card_shadow.offset_left = original_shadow_position.x + offset_x
	card_shadow.offset_top = original_shadow_position.y + offset_y

func _update_shadow_idle_opacity(angle: float):
	if not card_shadow:
		return
	
	var opacity_variation = sin(angle * 1.3) * 0.1
	var target_alpha = original_shadow_color.a + opacity_variation
	target_alpha = clamp(target_alpha, 0.3, 0.8)
	
	card_shadow.color.a = target_alpha

func stop_idle_shadow_animation():
	if idle_shadow_tween:
		idle_shadow_tween.kill()
		idle_shadow_tween = null

func animate_shadow_on_hover():
	if not card_shadow:
		return
	
	stop_idle_shadow_animation()
	
	if shadow_tween:
		shadow_tween.kill()
	
	shadow_tween = create_tween()
	shadow_tween.set_parallel(true)

	var hover_offset_x = original_shadow_position.x + 6
	var hover_offset_y = original_shadow_position.y + 6
	
	shadow_tween.tween_property(card_shadow, "offset_left", hover_offset_x, 0.15)
	shadow_tween.tween_property(card_shadow, "offset_top", hover_offset_y, 0.15)
	
	var hover_color = original_shadow_color
	hover_color.a = 0.4
	shadow_tween.tween_property(card_shadow, "color", hover_color, 0.15)

	shadow_tween.tween_property(card_shadow, "scale", Vector2(1.05, 1.05), 0.15)

func animate_shadow_on_unhover():
	if not card_shadow:
		return
	
	if shadow_tween:
		shadow_tween.kill()
	
	shadow_tween = create_tween()
	shadow_tween.set_parallel(true)
	shadow_tween.tween_property(card_shadow, "offset_left", original_shadow_position.x, 0.2)
	shadow_tween.tween_property(card_shadow, "offset_top", original_shadow_position.y, 0.2)
	shadow_tween.tween_property(card_shadow, "color", original_shadow_color, 0.2)
	shadow_tween.tween_property(card_shadow, "scale", Vector2(1.0, 1.0), 0.2)
	
	await shadow_tween.finished
	
	start_idle_shadow_animation()

func animate_shadow_on_click():
	if not card_shadow:
		return
	
	stop_idle_shadow_animation()
	
	if shadow_tween:
		shadow_tween.kill()
	
	shadow_tween = create_tween()
	shadow_tween.set_parallel(true)

	var click_offset_x = original_shadow_position.x + 2
	var click_offset_y = original_shadow_position.y + 2
	
	shadow_tween.tween_property(card_shadow, "offset_left", click_offset_x, 0.06)
	shadow_tween.tween_property(card_shadow, "offset_top", click_offset_y, 0.06)
	
	var click_color = original_shadow_color
	click_color.a = 0.8
	shadow_tween.tween_property(card_shadow, "color", click_color, 0.06)
	
	await shadow_tween.finished
	
	if is_hovered:
		animate_shadow_on_hover()
	else:
		animate_shadow_on_unhover()

func play_entrance_animation():
	if has_played_entrance:
		return
		
	has_played_entrance = true
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	position.y += 15
	
	if card_shadow:
		card_shadow.modulate.a = 0.0
		card_shadow.scale = Vector2(0.8, 0.8)
	
	if entrance_tween:
		entrance_tween.kill()
	
	entrance_tween = create_tween()
	entrance_tween.set_parallel(true)
	entrance_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	entrance_tween.tween_property(self, "scale", original_scale, 0.15)
	entrance_tween.tween_property(self, "position:y", original_position.y, 0.15)

	if card_shadow:
		entrance_tween.tween_property(card_shadow, "modulate:a", 1.0, 0.25)
		entrance_tween.tween_property(card_shadow, "scale", Vector2(1.0, 1.0), 0.15)
	
	await entrance_tween.finished

	start_idle_shadow_animation()

func play_selection_animation():
	if not is_playable:
		play_disabled_animation()
		return
	
	animate_shadow_on_click()
	
	if hover_tween:
		hover_tween.kill()
	
	var select_tween = create_tween()
	select_tween.set_parallel(true)
	
	select_tween.tween_property(self, "scale", original_scale * 1.15, 0.06)
	select_tween.tween_property(self, "rotation", 0.04, 0.06)
	
	await select_tween.finished
	
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(self, "scale", original_scale, 0.12)
	return_tween.tween_property(self, "rotation", 0.0, 0.12)

func play_disabled_animation():
	var shake_tween = create_tween()
	shake_tween.set_parallel(true)
	
	shake_tween.tween_property(self, "position:x", original_position.x + 3, 0.05)
	shake_tween.tween_property(self, "position:x", original_position.x - 3, 0.05)
	shake_tween.tween_property(self, "position:x", original_position.x + 2, 0.05)
	shake_tween.tween_property(self, "position:x", original_position.x, 0.05)

func play_card_animation():
	if not card_data:
		_fallback_play_animation()
		return
	
	var rarity = CardProbability.calculate_card_rarity(card_data.damage, card_data.heal, card_data.shield)
	
	match rarity:
		"common":
			_play_common_animation()
		"uncommon":
			_play_uncommon_animation()
		"rare":
			_play_rare_animation()
		"epic":
			_play_epic_animation()
		_:
			_fallback_play_animation()

func _play_common_animation():
	card_played.emit(self)
	_cleanup_tweens()
	
	play_tween = create_tween()
	play_tween.set_parallel(true)
	
	play_tween.tween_property(self, "position", position + Vector2(0, -40), 0.4)
	play_tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.4)
	play_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	
	if card_shadow:
		play_tween.tween_property(card_shadow, "modulate:a", 0.0, 0.3)
	
	await play_tween.finished
	queue_free()

func _play_uncommon_animation():
	card_played.emit(self)
	_cleanup_tweens()
	
	var flash_effect = create_tween()
	flash_effect.tween_property(self, "modulate", Color(1.4, 1.4, 1.4, 1.0), 0.1)
	flash_effect.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	await flash_effect.finished
	
	play_tween = create_tween()
	play_tween.set_parallel(true)
	
	play_tween.tween_property(self, "position", position + Vector2(0, -50), 0.5)
	play_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)
	play_tween.tween_property(self, "scale", Vector2(0.7, 0.7), 0.35)
	
	play_tween.tween_method(_animate_uncommon_fade, 1.0, 0.0, 0.5)
	
	if card_shadow:
		play_tween.tween_property(card_shadow, "modulate:a", 0.0, 0.4)
	
	await play_tween.finished
	queue_free()

func _animate_uncommon_fade(alpha: float):
	modulate.a = alpha
	var green_tint = 0.3 * (1.0 - alpha)
	modulate = Color(1.0 - green_tint, 1.0 + green_tint, 1.0 - green_tint, alpha)

func _play_rare_animation():
	card_played.emit(self)
	_cleanup_tweens()
	
	var pulse_tween = create_tween()
	pulse_tween.set_loops(2)
	pulse_tween.tween_property(self, "scale", original_scale * 1.2, 0.15)
	pulse_tween.tween_property(self, "scale", original_scale, 0.15)
	pulse_tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.8, 1.0), 0.15)
	pulse_tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	
	await pulse_tween.finished
	
	play_tween = create_tween()
	play_tween.set_parallel(true)
	
	play_tween.tween_property(self, "position", position + Vector2(0, -60), 0.6)
	play_tween.tween_method(_animate_rare_effects, 0.0, 1.0, 0.6)
	
	if card_shadow:
		play_tween.tween_property(card_shadow, "modulate:a", 0.0, 0.5)
	
	await play_tween.finished
	queue_free()

func _animate_rare_effects(progress: float):
	var pulse_scale = 1.0 + sin(progress * PI * 4) * 0.15
	scale = original_scale * pulse_scale * (1.0 - progress * 0.4)
	
	var blue_intensity = sin(progress * PI * 3) * 0.4 + 0.6
	var alpha = 1.0 - progress
	modulate = Color(1.0 - blue_intensity * 0.2, 1.0 - blue_intensity * 0.1, 1.0 + blue_intensity * 0.6, alpha)

func _play_epic_animation():
	card_played.emit(self)
	_cleanup_tweens()
	
	var epic_start = create_tween()
	epic_start.set_loops(3)
	epic_start.tween_property(self, "scale", original_scale * 1.3, 0.1)
	epic_start.tween_property(self, "scale", original_scale * 1.1, 0.1)
	epic_start.tween_property(self, "modulate", Color(1.8, 1.4, 2.0, 1.0), 0.1)
	epic_start.tween_property(self, "modulate", Color(1.4, 1.2, 1.6, 1.0), 0.1)
	
	await epic_start.finished
	
	play_tween = create_tween()
	play_tween.set_parallel(true)
	
	play_tween.tween_property(self, "position", position + Vector2(0, -80), 0.8)
	play_tween.tween_method(_animate_epic_effects, 0.0, 1.0, 0.8)
	
	if card_shadow:
		play_tween.tween_property(card_shadow, "modulate", Color(0.6, 0.3, 0.9, 0.0), 0.7)
	
	await play_tween.finished
	queue_free()

func _animate_epic_effects(progress: float):
	var pulse_intensity = sin(progress * PI * 6) * 0.25 + 1.0
	scale = original_scale * pulse_intensity * (1.0 - progress * 0.3)
	
	rotation = sin(progress * PI * 2) * 0.2
	
	var purple_wave = sin(progress * PI * 4) * 0.5 + 0.5
	var alpha = 1.0 - pow(progress, 0.6)
	
	modulate = Color(
		1.0 + purple_wave * 0.8,
		1.0 + purple_wave * 0.4,
		1.0 + purple_wave * 1.2,
		alpha
	)

func _fallback_play_animation():
	card_played.emit(self)
	_cleanup_tweens()
	
	play_tween = create_tween()
	play_tween.set_parallel(true)
	
	play_tween.tween_property(self, "position", position + Vector2(0, -25), 0.2)
	play_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12)
	play_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	
	if card_shadow:
		play_tween.tween_property(card_shadow, "modulate:a", 0.0, 0.2)
		play_tween.tween_property(card_shadow, "scale", Vector2(0.8, 0.8), 0.2)
	
	await play_tween.finished
	queue_free()

func _cleanup_tweens():
	stop_idle_shadow_animation()
	
	var tweens_to_kill = [hover_tween, entrance_tween, epic_border_tween, playable_tween, shadow_tween]
	for tween in tweens_to_kill:
		if tween:
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
				effects.append("Heals " + str(card_data.heal) + " HP")
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

func _on_card_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		play_selection_animation()
		if is_playable:
			card_clicked.emit(self)

func _on_mouse_entered():
	if not is_hovered and is_playable:
		is_hovered = true
		
		animate_shadow_on_hover()
		
		if hover_tween:
			hover_tween.kill()
		
		hover_tween = create_tween()
		hover_tween.set_parallel(true)
		hover_tween.tween_property(self, "scale", original_scale * 1.08, 0.12)
		hover_tween.tween_property(self, "z_index", 10, 0.06)

func _on_mouse_exited():
	if is_hovered:
		is_hovered = false
		
		animate_shadow_on_unhover()
		
		if hover_tween:
			hover_tween.kill()
		
		hover_tween = create_tween()
		hover_tween.set_parallel(true)
		hover_tween.tween_property(self, "scale", original_scale, 0.12)
		hover_tween.tween_property(self, "z_index", 0, 0.06)

func set_card_data(data: CardData):
	card_data = data
	if is_inside_tree():
		update_display()
		if not has_played_epic_animation:
			call_deferred("play_epic_entrance_animation")

func set_playable(playable: bool):
	is_playable = playable
	
	if playable_tween:
		playable_tween.kill()
	
	playable_tween = create_tween()
	
	if playable:
		playable_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		mouse_filter = Control.MOUSE_FILTER_PASS
		start_idle_shadow_animation()
	else:
		playable_tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4, 0.7), 0.15)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		stop_idle_shadow_animation()

		if card_shadow:
			var restore_tween = create_tween()
			restore_tween.set_parallel(true)
			restore_tween.tween_property(card_shadow, "offset_left", original_shadow_position.x, 0.2)
			restore_tween.tween_property(card_shadow, "offset_top", original_shadow_position.y, 0.2)
			restore_tween.tween_property(card_shadow, "color", original_shadow_color * Color(1, 1, 1, 0.3), 0.2)
		
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
			
func play_epic_entrance_animation():
	if not card_data or has_played_epic_animation:
		return
	
	var rarity = CardProbability.calculate_card_rarity(card_data.damage, card_data.heal, card_data.shield)
	if rarity == "epic":
		has_played_epic_animation = true
		
		var epic_tween = create_tween()
		epic_tween.set_loops(3)
		epic_tween.set_parallel(true)
		
		epic_tween.tween_property(self, "scale", original_scale * 1.12, 0.18)
		epic_tween.tween_property(self, "scale", original_scale, 0.18)
		
		var original_modulate = modulate
		epic_tween.tween_property(self, "modulate", Color(1.25, 1.08, 1.3, 1.0), 0.18)
		epic_tween.tween_property(self, "modulate", original_modulate, 0.18)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		stop_idle_shadow_animation()
		if shadow_tween:
			shadow_tween.kill()
		if hover_tween:
			hover_tween.kill()
		if entrance_tween:
			entrance_tween.kill()
		if epic_border_tween:
			epic_border_tween.kill()
		if playable_tween:
			playable_tween.kill()
		if play_tween:
			play_tween.kill()
