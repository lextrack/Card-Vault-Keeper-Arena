class_name GameNotification
extends Control

@onready var background = $Background
@onready var notification_title = $Background/VBox/NotificationTitle
@onready var notification_text = $Background/VBox/NotificationText
@onready var notification_detail = $Background/VBox/NotificationDetail

const MAX_QUEUE_SIZE = 10
const DEFAULT_DURATION = 2.0
const PRIORITY_DURATION = 3.0

enum NotificationPriority {
	LOW,
	NORMAL,
	HIGH,
	CRITICAL
}

var tween: Tween
var is_showing: bool = false
var notification_queue: Array = []
var total_notifications_shown: int = 0
var notification_id_counter: int = 0

signal notification_shown(notification_id: int, title: String)
signal notification_hidden(notification_id: int)
signal queue_emptied
signal queue_overflow

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

func show_notification(title: String, text: String, detail: String, color: Color, duration: float, callback: Callable = Callable()):
	if is_showing:
		await hide_notification()
   
	is_showing = true
	var notification_id = notification_id_counter
	notification_id_counter += 1
   
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

	notification_shown.emit(notification_id, title)
	total_notifications_shown += 1

	await get_tree().create_timer(duration).timeout
   
	if callback.is_valid():
		callback.call()
   
	notification_hidden.emit(notification_id)
   
	await hide_notification()
   
	if notification_queue.size() == 0:
		queue_emptied.emit()
	elif notification_queue.size() > 0:
		await get_tree().create_timer(0.3).timeout
		process_next_notification()

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
   
	var config = NotificationConfig.new(title, text, detail, color, GameBalance.get_timer_delay("notification_bonus"))
	config.priority = NotificationPriority.HIGH
	show_notification_from_config(config)

func show_game_end_notification(winner: String, reason: String):
	var title = winner + " has won"
	var text = ""
	var detail = "New match starting..."
	var color = Color(0.2, 0.8, 0.2, 0.95)
	var priority = NotificationPriority.CRITICAL
   
	match reason:
		"hp_zero":
			text = "💀 HP reduced to 0"
		"no_cards":
			text = "🃏 No cards available"
		_:
			text = "🏆 Game completed"
   
	if winner == "Defeat":
		color = Color(0.8, 0.2, 0.2, 0.95)
   
	var config = NotificationConfig.new(title, text, detail, color, GameBalance.get_timer_delay("notification_end"))
	config.priority = priority
	show_notification_from_config(config)

func show_priority_notification(title: String, text: String, detail: String, color: Color, priority: NotificationPriority = NotificationPriority.HIGH):
	match priority:
		NotificationPriority.CRITICAL:
			clear_all_notifications()
			if is_showing:
				await force_hide()
			await show_notification(title, text, detail, color, PRIORITY_DURATION)
   	
		NotificationPriority.HIGH:
			var notification = _create_notification_data(title, text, detail, color, PRIORITY_DURATION)
			notification_queue.push_front(notification)
			if not is_showing:
				process_next_notification()
   	
		_:
			queue_notification(title, text, detail, color, DEFAULT_DURATION)

class NotificationConfig:
	var title: String
	var text: String
	var detail: String
	var color: Color
	var duration: float
	var priority: NotificationPriority
	var callback: Callable
   
	func _init(t: String, txt: String, det: String = "", c: Color = Color.WHITE, dur: float = 2.0):
		title = t
		text = txt
		detail = det
		color = c
		duration = dur
		priority = NotificationPriority.NORMAL

func show_notification_from_config(config: NotificationConfig):
	match config.priority:
		NotificationPriority.CRITICAL:
			show_priority_notification(config.title, config.text, config.detail, config.color, config.priority)
		NotificationPriority.HIGH:
			show_priority_notification(config.title, config.text, config.detail, config.color, config.priority)
		_:
			queue_notification(config.title, config.text, config.detail, config.color, config.duration, config.callback)

func queue_notification(title: String, text: String, detail: String, color: Color, duration: float, callback: Callable = Callable()):
	if notification_queue.size() >= MAX_QUEUE_SIZE:
		queue_overflow.emit()
		notification_queue.pop_front()
   
	var notification = _create_notification_data(title, text, detail, color, duration, callback)
	notification_queue.append(notification)
   
	if not is_showing:
		process_next_notification()

func _create_notification_data(title: String, text: String, detail: String, color: Color, duration: float, callback: Callable = Callable()) -> Dictionary:
	return {
		"title": title,
		"text": text,
		"detail": detail,
		"color": color,
		"duration": duration,
		"callback": callback,
		"timestamp": Time.get_ticks_msec()
	}

func process_next_notification():
	if notification_queue.size() == 0:
		return
   
	var notification = notification_queue.pop_front()
	show_notification(notification.title, notification.text, notification.detail, notification.color, notification.duration, notification.callback)

func clear_all_notifications():
	notification_queue.clear()
	if tween:
		tween.kill()
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	rotation = 0.0
	is_showing = false
	visible = false

func show_error(message: String, detail: String = ""):
	var config = NotificationConfig.new("❌ Error", message, detail, Color.RED, 4.0)
	config.priority = NotificationPriority.CRITICAL
	show_notification_from_config(config)

func show_success(message: String, detail: String = ""):
	var config = NotificationConfig.new("✅ Success", message, detail, Color(0.15, 0.6, 0.15, 0.95), 2.0)
	show_notification_from_config(config)

func show_warning(message: String, detail: String = ""):
	var config = NotificationConfig.new("⚠️ Warning", message, detail, Color.ORANGE, 3.0)
	config.priority = NotificationPriority.HIGH
	show_notification_from_config(config)

func show_info(message: String, detail: String = ""):
	var config = NotificationConfig.new("ℹ️ Info", message, detail, Color.CYAN, 2.0)
	show_notification_from_config(config)

func get_notification_stats() -> Dictionary:
	return {
		"queue_size": notification_queue.size(),
		"is_showing": is_showing,
		"total_shown": total_notifications_shown,
		"current_id": notification_id_counter,
		"max_queue_size": MAX_QUEUE_SIZE
	}

func has_pending_notifications() -> bool:
	return notification_queue.size() > 0 or is_showing

func is_queue_full() -> bool:
	return notification_queue.size() >= MAX_QUEUE_SIZE
