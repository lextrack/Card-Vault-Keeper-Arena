class_name AICardNotification
extends Control

@onready var background = $Background
@onready var border_highlight = $Background/BorderHighlight
@onready var inner_background = $Background/BorderHighlight/InnerBackground
@onready var card_name = $Background/VBox/CardName
@onready var card_effect = $Background/VBox/CardEffect
@onready var card_cost = $Background/VBox/CardCost
@onready var particle_effect = $ParticleEffect
@onready var shadow = $Shadow
@onready var progress_bar = $Background/ProgressBar

var tween: Tween
var is_showing: bool = false
var glow_tween: Tween
var progress_tween: Tween
var original_position: Vector2

signal ai_notification_shown(card_name: String)
signal ai_notification_hidden

func _ready():
	if not _validate_nodes():
		push_error("AICardNotification: Critical nodes missing")
		return
	
	_initialize_notification()
	
	if not tree_exiting.is_connected(_cleanup):
		tree_exiting.connect(_cleanup)

func _validate_nodes() -> bool:
	var base_nodes = background and border_highlight and inner_background and card_name and card_effect and card_cost and particle_effect
	if not base_nodes:
		return false
	
	if not shadow:
		push_warning("AICardNotification: Shadow node missing, continuing without shadow effect")
	if not progress_bar:
		push_warning("AICardNotification: ProgressBar node missing, continuing without progress effect")
	
	return true

func _initialize_notification():
	original_position = position
	modulate.a = 0.0
	scale = Vector2(0.7, 0.5)
	visible = false
	
	if shadow:
		shadow.modulate.a = 0.0
	
	if progress_bar:
		progress_bar.value = 100

func _cleanup():
	_stop_all_tweens()

func _stop_all_tweens():
	if tween and tween.is_valid():
		tween.kill()
	if glow_tween and glow_tween.is_valid():
		glow_tween.kill()
	if progress_tween and progress_tween.is_valid():
		progress_tween.kill()

func show_card_notification(card: CardData, player_name: String = "AI"):
	if not card:
		push_error("AICardNotification: CardData is null")
		return
	
	if is_showing:
		await hide_notification()
	
	is_showing = true
	
	_setup_card_display(card, player_name)
	_setup_card_colors(card)
	
	_stop_all_tweens()
	visible = true
	
	if shadow:
		shadow.visible = true
	
	var duration = GameBalance.get_timer_delay("ai_card_popup")
	
	await _animate_entrance(card.card_type)
	
	_start_card_glow()
	_setup_card_particles(card)
	_animate_progress_bar(duration)
	ai_notification_shown.emit(card.card_name)
	
	await get_tree().create_timer(duration).timeout
	await hide_notification()

func _animate_entrance(card_type: String):
	modulate.a = 0.0
	scale = Vector2(0.7, 0.5)
	position.x = original_position.x - 50
	
	if shadow:
		shadow.modulate.a = 0.0
	
	tween = create_tween()
	tween.set_parallel(true)
	
	match card_type:
		"attack":
			position.x = original_position.x
			scale = Vector2(1.3, 1.3)
			tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			
		"heal":
			position.y = original_position.y + 30
			position.x = original_position.x
			tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "position:y", original_position.y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
		"shield":
			tween.tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "position:x", original_position.x, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
		_:
			tween.tween_property(self, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "position:x", original_position.x, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	if shadow:
		tween.tween_property(shadow, "modulate:a", 0.6, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	await tween.finished

func _animate_progress_bar(duration: float):
	if not progress_bar:
		return
	
	progress_bar.value = 100
	progress_tween = create_tween()
	progress_tween.tween_property(progress_bar, "value", 0, duration).set_trans(Tween.TRANS_LINEAR)

func _setup_card_display(card: CardData, player_name: String):
	card_name.text = player_name + " played: " + card.card_name
	card_cost.text = str(card.cost) + " mana"
	
	match card.card_type:
		"attack":
			card_effect.text = str(card.damage) + " damage"
		"heal":
			card_effect.text = "+" + str(card.heal) + " health"
		"shield":
			card_effect.text = "+" + str(card.shield) + " shield"
		"hybrid":
			var effects = []
			if card.damage > 0:
				effects.append(str(card.damage) + " dmg")
			if card.heal > 0:
				effects.append("+" + str(card.heal) + " hp")
			if card.shield > 0:
				effects.append("+" + str(card.shield) + " shield")
			card_effect.text = " | ".join(effects)
		_:
			card_effect.text = card.description if card.description != "" else "Special effect"

func _setup_card_colors(card: CardData):
	var highlight_color: Color
	var inner_color: Color
	
	match card.card_type:
		"attack":
			highlight_color = Color(1.0, 0.3, 0.2, 0.8)
			inner_color = Color(0.2, 0.08, 0.08, 0.95)
		"heal":
			highlight_color = Color(0.3, 0.8, 0.3, 0.8)
			inner_color = Color(0.08, 0.15, 0.08, 0.95)
		"shield":
			highlight_color = Color(0.2, 0.5, 0.9, 0.8)
			inner_color = Color(0.08, 0.12, 0.18, 0.95)
		"hybrid":
			highlight_color = Color(0.8, 0.6, 0.2, 0.8)
			inner_color = Color(0.15, 0.12, 0.05, 0.95)
		_:
			highlight_color = Color(0.6, 0.6, 0.6, 0.8)
			inner_color = Color(0.12, 0.12, 0.12, 0.95)
	
	border_highlight.color = highlight_color
	inner_background.color = inner_color
	
	if progress_bar:
		var style = progress_bar.get_theme_stylebox("fill")
		if style:
			style.bg_color = highlight_color

func _start_card_glow():
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(border_highlight, "modulate:a", 0.6, 1.2).set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(border_highlight, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)

func _setup_card_particles(card: CardData):
	if not particle_effect:
		return
	
	if not particle_effect.process_material:
		var material = ParticleProcessMaterial.new()
		particle_effect.process_material = material
	
	var material = particle_effect.process_material as ParticleProcessMaterial
	
	match card.card_type:
		"attack":
			material.color = Color(1.0, 0.3, 0.2, 0.8)
			material.direction = Vector3(0, -1, 0)
			material.initial_velocity_min = 30.0
			material.initial_velocity_max = 60.0
			material.gravity = Vector3(0, 20, 0)
		"heal":
			material.color = Color(0.3, 0.8, 0.3, 0.8)
			material.direction = Vector3(0, -1, 0)
			material.initial_velocity_min = 15.0
			material.initial_velocity_max = 35.0
			material.gravity = Vector3(0, 20, 0)
		"shield":
			material.color = Color(0.2, 0.5, 0.9, 0.8)
			material.direction = Vector3(0, 0, 0)
			material.initial_velocity_min = 30.0
			material.initial_velocity_max = 50.0
			material.gravity = Vector3(0, 20, 0)
		"hybrid":
			material.color = Color(0.8, 0.6, 0.2, 0.8)
			material.direction = Vector3(0, -0.5, 0)
			material.initial_velocity_min = 20.0
			material.initial_velocity_max = 45.0
			material.gravity = Vector3(0, 25, 0)
		_:
			material.color = Color(0.6, 0.6, 0.6, 0.8)
			material.direction = Vector3(0, -1, 0)
			material.initial_velocity_min = 20.0
			material.initial_velocity_max = 40.0
			material.gravity = Vector3(0, 30, 0)
	
	material.scale_min = 1.0
	material.scale_max = 2.0
	
	particle_effect.amount = 60
	particle_effect.lifetime = 1.5
	particle_effect.emitting = true
	get_tree().create_timer(0.8).timeout.connect(func(): particle_effect.emitting = false)

func hide_notification():
	if not is_showing:
		return
	
	_stop_all_tweens()
	particle_effect.emitting = false
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", original_position.x - 30, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	
	if shadow:
		tween.tween_property(shadow, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	is_showing = false
	visible = false
	if shadow:
		shadow.visible = false
	position = original_position
	ai_notification_hidden.emit()

func force_close():
	_stop_all_tweens()
	modulate.a = 0.0
	scale = Vector2(0.7, 0.5)
	position = original_position
	is_showing = false
	visible = false
	if shadow:
		shadow.visible = false
		shadow.modulate.a = 0.0
	ai_notification_hidden.emit()

func is_notification_showing() -> bool:
	return is_showing
