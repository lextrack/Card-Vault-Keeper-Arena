extends Control

@onready var card_background = $CardBackground
@onready var card_border = $CardBorder
@onready var card_shine = $CardShine
@onready var card_symbol = $CardSymbol
@onready var card_cost = $CardCost
@onready var card_value = $CardValue
@onready var fall_timer = $FallTimer

enum CardType {
	ATTACK,
	DEFENSE,
	MAGIC,
	HEAL,
	SPECIAL,
	RARE
}

var card_data = {
	CardType.ATTACK: {
		"color": Color(0.86, 0.15, 0.15, 1.0),
		"symbol": "⚔",
		"border_color": Color(0.98, 0.65, 0.65, 1.0)
	},
	CardType.DEFENSE: {
		"color": Color(0.15, 0.39, 0.93, 1.0),
		"symbol": "🛡",
		"border_color": Color(0.58, 0.77, 0.99, 1.0)
	},
	CardType.MAGIC: {
		"color": Color(0.49, 0.23, 0.93, 1.0),
		"symbol": "✨",
		"border_color": Color(0.77, 0.71, 0.99, 1.0)
	},
	CardType.HEAL: {
		"color": Color(0.02, 0.59, 0.41, 1.0),
		"symbol": "❤",
		"border_color": Color(0.43, 0.91, 0.72, 1.0)
	},
	CardType.SPECIAL: {
		"color": Color(0.85, 0.46, 0.04, 1.0),
		"symbol": "💎",
		"border_color": Color(0.98, 0.73, 0.16, 1.0)
	},
	CardType.RARE: {
		"color": Color(0.86, 0.15, 0.47, 1.0),
		"symbol": "👑",
		"border_color": Color(0.98, 0.66, 0.83, 1.0)
	}
}

@export var card_type: CardType = CardType.ATTACK
@export var auto_fall: bool = true
@export var fall_duration: float = 8.0
@export var cost_value: int = 3
@export var damage_value: int = 6

var is_falling: bool = false
var fall_tween: Tween

func _ready():
	await get_tree().process_frame
	setup_card()
	if auto_fall:
		start_falling()

func setup_card():
	if not card_background or not card_border or not card_symbol or not card_cost or not card_value:
		return
	
	var data = card_data[card_type]
	card_background.color = data.color
	card_symbol.text = data.symbol
	card_border.color = data.border_color
	
	card_cost.text = str(cost_value)
	card_value.text = str(damage_value)
	
	if fall_timer:
		fall_timer.wait_time = fall_duration
		fall_timer.timeout.connect(_on_fall_timer_timeout)

func set_card_type(new_type: CardType):
	card_type = new_type
	if is_node_ready():
		setup_card()

func set_random_type():
	card_type = CardType.values()[randi() % CardType.size()]
	if is_node_ready():
		setup_card()

func set_random_values():
	cost_value = randi_range(1, 6)
	damage_value = randi_range(3, 12)
	if card_cost and card_value:
		card_cost.text = str(cost_value)
		card_value.text = str(damage_value)

func start_falling():
	if is_falling:
		return
	
	is_falling = true
	var screen_height = get_viewport().get_visible_rect().size.y
	
	position.y = -size.y - 20
	position.x = randf() * (get_viewport().get_visible_rect().size.x - size.x)
	
	fall_tween = create_tween()
	fall_tween.set_parallel(true)
	
	fall_tween.tween_property(self, "position:y", screen_height + 50, fall_duration)

	var rotation_amount = randf_range(-360, 360)
	fall_tween.tween_property(self, "rotation_degrees", rotation_amount, fall_duration)

	var horizontal_drift = randf_range(-30, 30)
	fall_tween.tween_property(self, "position:x", position.x + horizontal_drift, fall_duration)
	
	modulate.a = 0.0
	fall_tween.tween_property(self, "modulate:a", 0.9, 0.5)
	fall_tween.tween_property(self, "modulate:a", 0.0, 1.0).set_delay(fall_duration - 1.0)
	
	var initial_scale = randf_range(0.8, 1.2)
	scale = Vector2(initial_scale, initial_scale)
	
	fall_timer.start()

func start_falling_from_position(start_pos: Vector2):
	position = start_pos
	start_falling()

func stop_falling():
	if fall_tween:
		fall_tween.kill()
	is_falling = false
	fall_timer.stop()

func _on_fall_timer_timeout():
	queue_free()

func start_floating():
	if is_falling:
		return
	
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.set_parallel(true)
	
	float_tween.tween_property(self, "position:y", position.y - 20, 2.0)
	float_tween.tween_property(self, "position:y", position.y + 20, 2.0).set_delay(2.0)

	float_tween.tween_property(self, "rotation_degrees", 5, 3.0)
	float_tween.tween_property(self, "rotation_degrees", -5, 3.0).set_delay(3.0)
	
	float_tween.tween_property(self, "modulate:a", 0.7, 1.5)
	float_tween.tween_property(self, "modulate:a", 1.0, 1.5).set_delay(1.5)

func add_rare_effect():
	if card_type != CardType.RARE or not card_border or not card_symbol:
		return
	
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.set_parallel(true)
	
	glow_tween.tween_property(card_border, "modulate", Color(1.5, 1.5, 1.5, 0.8), 1.0)
	glow_tween.tween_property(card_border, "modulate", Color(1.0, 1.0, 1.0, 0.3), 1.0).set_delay(1.0)
	
	glow_tween.tween_property(card_symbol, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.8)
	glow_tween.tween_property(card_symbol, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8).set_delay(0.8)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if fall_tween:
			fall_tween.kill()
