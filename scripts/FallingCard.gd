extends Control

@onready var card_background: ColorRect = $CardBackground
@onready var card_border: ColorRect = $CardBorder
@onready var card_shine: ColorRect = $CardShine
@onready var card_symbol: TextureRect = $CardSymbol
@onready var card_cost: Label = $CardCost
@onready var card_value: Label = $CardValue
@onready var fall_timer: Timer = $FallTimer
@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

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
		"icon_path": "res://assets/ui/sword_loading.png",
		"border_color": Color(0.98, 0.65, 0.65, 1.0)
	},
	CardType.DEFENSE: {
		"color": Color(0.15, 0.39, 0.93, 1.0),
		"icon_path": "res://assets/ui/shield_loading.png",
		"border_color": Color(0.58, 0.77, 0.99, 1.0)
	},
	CardType.MAGIC: {
		"color": Color(0.49, 0.23, 0.93, 1.0),
		"icon_path": "res://assets/ui/magic.png",
		"border_color": Color(0.77, 0.71, 0.99, 1.0)
	},
	CardType.HEAL: {
		"color": Color(0.02, 0.59, 0.41, 1.0),
		"icon_path": "res://assets/ui/heal.png",
		"border_color": Color(0.43, 0.91, 0.72, 1.0)
	},
	CardType.SPECIAL: {
		"color": Color(0.85, 0.46, 0.04, 1.0),
		"icon_path": "res://assets/ui/special.png",
		"border_color": Color(0.98, 0.73, 0.16, 1.0)
	},
	CardType.RARE: {
		"color": Color(0.86, 0.15, 0.47, 1.0),
		"icon_path": "res://assets/ui/rare.png",
		"border_color": Color(0.98, 0.66, 0.83, 1.0)
	}
}

var _texture_cache: Dictionary = {}

@export var card_type: CardType = CardType.ATTACK
@export var auto_fall: bool = true
@export var fall_duration: float = 3.0
@export var cost_value: int = 3
@export var damage_value: int = 6

var is_falling: bool = false
var fall_tween: Tween

func _ready():
	await get_tree().process_frame
	_preload_textures()
	setup_card()
	
	if auto_fall:
		start_falling()
		
	if visibility_notifier:
		visibility_notifier.screen_exited.connect(_on_screen_exited)
		
func _on_screen_exited():
	if is_falling:
		stop_falling()
		queue_free()

func stop_falling():
	if fall_tween:
		fall_tween.kill()
		fall_tween = null 
	is_falling = false
	fall_timer.stop()

func _preload_textures():
	for type in CardType.values():
		var icon_path = card_data[type]["icon_path"]
		if not _texture_cache.has(icon_path):
			if ResourceLoader.exists(icon_path):
				_texture_cache[icon_path] = load(icon_path)
			else:
				push_warning("No texture: " + icon_path)

func setup_card():
	if not card_background or not card_border or not card_symbol or not card_cost or not card_value:
		return
	
	var data = card_data[card_type]
	card_background.color = data.color
	card_border.color = data.border_color

	var icon_path = data.icon_path
	if _texture_cache.has(icon_path):
		card_symbol.texture = _texture_cache[icon_path]
	
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
	fall_tween.set_trans(Tween.TRANS_LINEAR)
	
	fall_tween.tween_property(self, "position:y", screen_height + 50, fall_duration)

	var rotation_amount = randf_range(-360, 360)
	fall_tween.tween_property(self, "rotation_degrees", rotation_amount, fall_duration)
	
	modulate.a = 0.0
	fall_tween.tween_property(self, "modulate:a", 0.9, 0.5).set_ease(Tween.EASE_OUT)
	fall_tween.tween_property(self, "modulate:a", 0.0, 1.0).set_delay(fall_duration - 1.5).set_ease(Tween.EASE_IN)
	
	var initial_scale = randf_range(0.8, 1.2)
	scale = Vector2(initial_scale, initial_scale)
	
	fall_timer.start()

func start_falling_from_position(start_pos: Vector2):
	position = start_pos
	start_falling()

func _on_fall_timer_timeout():
	queue_free()

func start_floating():
	if is_falling:
		return
	
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.set_parallel(true)
	float_tween.set_trans(Tween.TRANS_SINE)
	float_tween.set_ease(Tween.EASE_IN_OUT)
	
	float_tween.tween_property(self, "position:y", position.y - 20, 2.0)
	float_tween.tween_property(self, "position:y", position.y + 20, 2.0).set_delay(2.0)

	float_tween.tween_property(self, "rotation_degrees", 5, 3.0)
	float_tween.tween_property(self, "rotation_degrees", -5, 3.0).set_delay(3.0)
	
	float_tween.tween_property(self, "modulate:a", 0.7, 1.5)
	float_tween.tween_property(self, "modulate:a", 1.0, 1.5).set_delay(1.5)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if fall_tween:
			fall_tween.kill()

func _exit_tree():
	if fall_tween:
		fall_tween.kill()
		fall_tween = null
