class_name GameNotification
extends Control

@onready var background = $Background
@onready var border_highlight = $Background/BorderHighlight
@onready var inner_background = $Background/BorderHighlight/InnerBackground
@onready var notification_title = $Background/VBox/NotificationTitle
@onready var notification_text = $Background/VBox/NotificationText
@onready var notification_detail = $Background/VBox/NotificationDetail
@onready var particle_effect = $ParticleEffect
@onready var shadow = $Shadow
@onready var progress_bar = $Background/ProgressBar

var tween: Tween
var is_showing: bool = false
var pulse_tween: Tween
var progress_tween: Tween
var original_position: Vector2

signal notification_shown(title: String)
signal notification_hidden

func _ready():
	if not _validate_nodes():
		push_error("GameNotification: Critical nodes missing")
		return
	
	_initialize_notification()

func _validate_nodes() -> bool:
	var base_nodes = background and border_highlight and inner_background and notification_title and notification_text and notification_detail and particle_effect
	if not base_nodes:
		return false
	
	if not shadow:
		push_warning("GameNotification: Shadow node missing, continuing without shadow effect")
	if not progress_bar:
		push_warning("GameNotification: ProgressBar node missing, continuing without progress effect")
	
	return true

func _initialize_notification():
	original_position = position
	modulate.a = 0.0
	scale = Vector2(0.8, 0.6)
	
	if shadow:
		shadow.modulate.a = 0.0
	
	if progress_bar:
		progress_bar.value = 100
	
	if not tree_exiting.is_connected(_cleanup):
		tree_exiting.connect(_cleanup)

func _cleanup():
	_stop_all_tweens()

func _stop_all_tweens():
	if tween and tween.is_valid():
		tween.kill()
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	if progress_tween and progress_tween.is_valid():
		progress_tween.kill()

func show_notification(title: String, text: String, detail: String, highlight_color: Color, inner_color: Color, duration: float):
	if is_showing:
		await hide_notification()
	
	is_showing = true
	_setup_notification_content(title, text, detail, highlight_color, inner_color)
	
	_stop_all_tweens()
	visible = true
	
	if shadow:
		shadow.visible = true
	
	var notification_type = _get_notification_type(title)
	await _animate_entrance(notification_type)
	
	_start_subtle_pulse()
	_setup_particles(highlight_color)
	_animate_progress_bar(duration)
	notification_shown.emit(title)
	
	await get_tree().create_timer(duration).timeout
	notification_hidden.emit()
	await hide_notification()

func _get_notification_type(title: String) -> String:
	if "DAMAGE" in title or "BOOST" in title:
		return "damage"
	elif "DEFEAT" in title:
		return "defeat"
	elif "VICTORY" in title or "SUCCESS" in title:
		return "victory"
	else:
		return "default"

func _animate_entrance(notification_type: String):
	modulate.a = 0.0
	scale = Vector2(0.8, 0.6)
	position.x = original_position.x + 50
	
	if shadow:
		shadow.modulate.a = 0.0
	
	tween = create_tween()
	tween.set_parallel(true)
	
	match notification_type:
		"damage":
			position.x = original_position.x
			scale = Vector2(1.3, 1.3)
			tween.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			
		"victory":
			position.y = original_position.y + 30
			position.x = original_position.x
			tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "position:y", original_position.y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
		"defeat":
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

func _setup_notification_content(title: String, text: String, detail: String, highlight_color: Color, inner_color: Color):
	notification_title.text = title
	notification_text.text = text
	notification_detail.text = detail
	border_highlight.color = highlight_color
	inner_background.color = inner_color
	
	if progress_bar:
		var style = progress_bar.get_theme_stylebox("fill")
		if style:
			style.bg_color = highlight_color

func _start_subtle_pulse():
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(border_highlight, "modulate:a", 0.8, 1.5).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(border_highlight, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)

func _setup_particles(color: Color):
	if not particle_effect:
		return
	
	if not particle_effect.process_material:
		var material = ParticleProcessMaterial.new()
		particle_effect.process_material = material
	
	var material = particle_effect.process_material as ParticleProcessMaterial
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 70.0
	material.gravity = Vector3(0, 20, 0)
	material.scale_min = 1.0
	material.scale_max = 2.0
	material.color = color
	
	particle_effect.amount = 60
	particle_effect.lifetime = 1.5
	particle_effect.emitting = true
	get_tree().create_timer(0.5).timeout.connect(func(): particle_effect.emitting = false)

func hide_notification():
	if not is_showing:
		return
	
	_stop_all_tweens()
	particle_effect.emitting = false
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", original_position.x + 30, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	
	if shadow:
		tween.tween_property(shadow, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	
	await tween.finished
	is_showing = false
	visible = false
	if shadow:
		shadow.visible = false
	position = original_position

func show_damage_bonus_notification(turn_number: int, bonus: int):
	var title = "DAMAGE BOOST"
	var text = "+" + str(bonus) + " damage to all attacks"
	var detail = "Turn " + str(turn_number) + " bonus active"
	var highlight_color = Color(1.0, 0.4, 0.2, 0.8)
	var inner_color = Color(0.2, 0.1, 0.05, 0.95)
	
	show_notification(title, text, detail, highlight_color, inner_color, GameBalance.get_timer_delay("notification_bonus"))

func show_game_end_notification(winner: String, reason: String):
	var title = winner.to_upper()
	var text = ""
	var detail = "Starting new match..."
	var highlight_color = Color(0.3, 0.8, 0.3, 0.8)
	var inner_color = Color(0.05, 0.15, 0.05, 0.95)
	
	match reason:
		"hp_zero":
			text = "Victory by elimination"
		"no_cards":
			text = "Victory by depletion"
		_:
			text = "Match completed"
	
	if winner == "DEFEAT":
		highlight_color = Color(0.9, 0.3, 0.3, 0.8)
		inner_color = Color(0.15, 0.05, 0.05, 0.95)
	
	show_notification(title, text, detail, highlight_color, inner_color, GameBalance.get_timer_delay("notification_end"))

func show_success(message: String, detail: String = ""):
	var title = "SUCCESS"
	var highlight_color = Color(0.2, 0.7, 0.4, 0.8)
	var inner_color = Color(0.05, 0.12, 0.08, 0.95)
	show_notification(title, message, detail, highlight_color, inner_color, 2.5)

func force_hide():
	_stop_all_tweens()
	modulate.a = 0.0
	scale = Vector2(0.8, 0.6)
	position = original_position
	is_showing = false
	visible = false
	if shadow:
		shadow.visible = false
		shadow.modulate.a = 0.0

func clear_all_notifications():
	force_hide()
