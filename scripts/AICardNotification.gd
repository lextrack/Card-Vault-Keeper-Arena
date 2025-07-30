class_name AICardNotification
extends Control

@onready var background = $Background
@onready var card_name = $Background/VBox/CardName
@onready var card_effect = $Background/VBox/CardEffect
@onready var card_cost = $Background/VBox/CardCost

var tween: Tween
var is_showing: bool = false
var notification_id: int = 0

signal ai_notification_shown(card_name: String)
signal ai_notification_hidden

func _ready():
	if not _validate_nodes():
		push_error("AICardNotification: Nodos críticos faltantes")
		return
	
	_initialize_notification()
	
	if not tree_exiting.is_connected(_cleanup):
		tree_exiting.connect(_cleanup)

func _validate_nodes() -> bool:
	if not background:
		push_error("AICardNotification: Background node missing")
		return false
	if not card_name:
		push_error("AICardNotification: CardName node missing")
		return false
	if not card_effect:
		push_error("AICardNotification: CardEffect node missing")
		return false
	if not card_cost:
		push_error("AICardNotification: CardCost node missing")
		return false
	
	return true

func _initialize_notification():
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	rotation = deg_to_rad(5)
	background.color = Color(0.1, 0.1, 0.1, 0.95)
	visible = false

func _cleanup():
	if tween and tween.is_valid():
		tween.kill()

func show_card_notification(card: CardData, player_name: String = "IA"):
	if not card:
		push_error("AICardNotification: CardData is null")
		return
	
	if is_showing:
		await hide_notification()
	
	is_showing = true
	notification_id += 1
	
	_setup_card_display(card, player_name)
	_setup_card_colors(card)
	
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
	
	ai_notification_shown.emit(card.card_name)
	
	await get_tree().create_timer(GameBalance.get_timer_delay("ai_card_popup")).timeout
	
	await hide_notification()

func _setup_card_display(card: CardData, player_name: String):
	card_name.text = player_name + " played: " + card.card_name
	card_cost.text = "Cost: " + str(card.cost) + " mana"
	
	match card.card_type:
		"attack":
			card_effect.text = "⚔️ Damage: " + str(card.damage)
		"heal":
			card_effect.text = "💚 Heal: " + str(card.heal)
		"shield":
			card_effect.text = "🛡️ Shield: " + str(card.shield)
		"hybrid":
			var effects = []
			if card.damage > 0:
				effects.append("⚔️" + str(card.damage))
			if card.heal > 0:
				effects.append("💚" + str(card.heal))
			if card.shield > 0:
				effects.append("🛡️" + str(card.shield))
			card_effect.text = " | ".join(effects)
		_:
			card_effect.text = card.description if card.description != "" else "❓ Unknown effect"

func _setup_card_colors(card: CardData):
	match card.card_type:
		"attack":
			background.color = Color(0.9, 0.2, 0.2, 0.95)
		"heal":
			background.color = Color(0.15, 0.6, 0.15, 0.95)
		"shield":
			background.color = Color(0.2, 0.4, 0.9, 0.95)
		"hybrid":
			background.color = Color(0.6, 0.5, 0.2, 0.95)
		_:
			background.color = Color(0.6, 0.6, 0.6, 0.95)

func hide_notification():
	if not is_showing:
		return
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", deg_to_rad(-3), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	is_showing = false
	visible = false
	
	ai_notification_hidden.emit()

func force_close():
	if tween:
		tween.kill()
	
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	rotation = 0.1
	is_showing = false
	visible = false
	
	ai_notification_hidden.emit()

func is_notification_showing() -> bool:
	return is_showing

func get_current_notification_id() -> int:
	return notification_id

func show_custom_ai_notification(title: String, effect: String, cost: String, color: Color = Color.WHITE):
	if is_showing:
		await hide_notification()
	
	is_showing = true
	
	card_name.text = title
	card_effect.text = effect
	card_cost.text = cost
	background.color = color
	
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
	
	ai_notification_shown.emit(title)
	
	await get_tree().create_timer(GameBalance.get_timer_delay("ai_card_popup")).timeout
	await hide_notification()

func get_notification_info() -> Dictionary:
	return {
		"is_showing": is_showing,
		"notification_id": notification_id,
		"visible": visible,
		"modulate_alpha": modulate.a
	}
