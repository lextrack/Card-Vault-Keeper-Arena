class_name GameNotification
extends Control

@onready var background = $Background
@onready var notification_title = $Background/VBox/NotificationTitle
@onready var notification_text = $Background/VBox/NotificationText
@onready var notification_detail = $Background/VBox/NotificationDetail

var tween: Tween
var is_showing: bool = false

signal notification_shown(title: String)
signal notification_hidden

func _ready():
	if not _validate_nodes():
		push_error("GameNotification: Critical nodes missing")
		return
   
	_initialize_notification()

func _validate_nodes() -> bool:
	if not background:
		push_error("GameNotification: Background node missing")
		return false
	if not notification_title:
		push_error("GameNotification: NotificationTitle node missing")
		return false
	if not notification_text:
		push_error("GameNotification: NotificationText node missing")
		return false
	if not notification_detail:
		push_error("GameNotification: NotificationDetail node missing")
		return false
   
	return true

func _initialize_notification():
	modulate.a = 0.0
	scale = Vector2(0.7, 0.7)
	rotation = deg_to_rad(5)
	background.color = Color(0.15, 0.15, 0.25, 0.95)
   
	if not tree_exiting.is_connected(_cleanup):
		tree_exiting.connect(_cleanup)

func _cleanup():
	clear_all_notifications()
	if tween and tween.is_valid():
		tween.kill()

func show_notification(title: String, text: String, detail: String, color: Color, duration: float):
	if is_showing:
		await hide_notification()
   
	is_showing = true
   
	_setup_notification_content(title, text, detail, color)
   
	if tween:
		tween.kill()
   
	visible = true
	modulate.a = 0.0
	scale = Vector2(0.7, 0.7)
	rotation = deg_to_rad(5)
   
	tween = create_tween()
	tween.set_parallel(true)
   
	tween.tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "rotation", deg_to_rad(0), 0.25)
   
	await tween.finished
   
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

	await tween.finished

	notification_shown.emit(title)
	
	await get_tree().create_timer(duration).timeout
   
	notification_hidden.emit()
   
	await hide_notification()

func _setup_notification_content(title: String, text: String, detail: String, color: Color):
	notification_title.text = title
	notification_text.text = text
	notification_detail.text = detail
	background.color = color

func hide_notification():
	if not is_showing:
		return
   
	if tween:
		tween.kill()
   
	tween = create_tween()
	tween.set_parallel(true)
   
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", deg_to_rad(-3), 0.2).set_trans(Tween.TRANS_SINE)
   
	await tween.finished
	is_showing = false
	visible = false

func force_hide():
	if tween:
		tween.kill()
   
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	rotation = 0.0
	is_showing = false
	visible = false

func show_damage_bonus_notification(turn_number: int, bonus: int):
	var title = "Damage bonus activated!"
	var text = "⚔️ +" + str(bonus) + " damage to all attacks"
	var detail = "Turn " + str(turn_number)
	var color = Color(0.9, 0.3, 0.1, 0.95)
   
	show_notification(title, text, detail, color, GameBalance.get_timer_delay("notification_bonus"))

func show_game_end_notification(winner: String, reason: String):
	var title = winner + " has won"
	var text = ""
	var detail = "New match starting..."
	var color = Color(0.2, 0.8, 0.2, 0.95)
   
	match reason:
		"hp_zero":
			text = "💀 HP reduced to 0"
		"no_cards":
			text = "🃏 No cards available"
		_:
			text = "🏆 Game completed"
   
	if winner == "Defeat":
		color = Color(0.8, 0.2, 0.2, 0.95)
   
	show_notification(title, text, detail, color, GameBalance.get_timer_delay("notification_end"))

func show_success(message: String, detail: String = ""):
	var title = "✅ Success"
	var color = Color(0.15, 0.6, 0.15, 0.95)
	show_notification(title, message, detail, color, 2.0)

func clear_all_notifications():
	if tween:
		tween.kill()
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	rotation = 0.0
	is_showing = false
	visible = false
