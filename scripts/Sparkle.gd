extends Control

@onready var sparkle_core = $SparkleCore
@onready var sparkle_glow = $SparkleGlow
@onready var sparkle_outer = $SparkleOuter
@onready var life_timer = $LifeTimer

enum SparkleType {
	BLUE,
	CYAN,
	GOLD,
	WHITE,
	PURPLE,
	GREEN
}

var sparkle_colors = {
	SparkleType.BLUE: Color(0.15, 0.39, 0.93, 1.0),
	SparkleType.CYAN: Color(0.39, 1.0, 0.85, 1.0),
	SparkleType.GOLD: Color(1.0, 0.84, 0.0, 1.0),
	SparkleType.WHITE: Color(1.0, 1.0, 1.0, 1.0),
	SparkleType.PURPLE: Color(0.49, 0.23, 0.93, 1.0),
	SparkleType.GREEN: Color(0.02, 0.59, 0.41, 1.0)
}

@export var sparkle_type: SparkleType = SparkleType.CYAN
@export var auto_animate: bool = true
@export var life_duration: float = 4.0
@export var movement_speed: float = 50.0

var is_animating: bool = false
var animation_tween: Tween

func _ready():
	await get_tree().process_frame
	setup_sparkle()
	if auto_animate:
		start_animation()

func setup_sparkle():
	if not sparkle_core or not sparkle_glow or not life_timer:
		return
	
	var color = sparkle_colors[sparkle_type]
	sparkle_core.color = color
	sparkle_glow.color = Color(color.r, color.g, color.b, 0.3)
	
	life_timer.wait_time = life_duration
	life_timer.timeout.connect(_on_life_timer_timeout)

	scale = Vector2.ZERO

func set_sparkle_type(new_type: SparkleType):
	sparkle_type = new_type
	if is_node_ready():
		setup_sparkle()

func set_random_type():
	sparkle_type = SparkleType.values()[randi() % SparkleType.size()]
	if is_node_ready():
		setup_sparkle()

func start_animation():
	if is_animating:
		return
	
	is_animating = true

	var screen_size = get_viewport().get_visible_rect().size
	position.x = randf() * screen_size.x
	position.y = screen_size.y + 20
	
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	
	animation_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	
	var target_y = -20
	animation_tween.tween_property(self, "position:y", target_y, life_duration)
	
	var horizontal_drift = randf_range(-30, 30)
	animation_tween.tween_property(self, "position:x", position.x + horizontal_drift, life_duration)

	create_twinkle_effect()
	
	var rotation_amount = randf_range(-180, 180)
	animation_tween.tween_property(self, "rotation_degrees", rotation_amount, life_duration)
	
	life_timer.start()

func create_twinkle_effect():
	if not sparkle_core or not sparkle_glow:
		return
		
	var twinkle_tween = create_tween()
	twinkle_tween.set_loops()
	twinkle_tween.set_parallel(true)
	
	twinkle_tween.tween_property(sparkle_core, "modulate:a", 0.3, 0.2)
	twinkle_tween.tween_property(sparkle_core, "modulate:a", 1.0, 0.2).set_delay(0.2)
	twinkle_tween.tween_property(sparkle_core, "modulate:a", 0.5, 0.3).set_delay(0.4)
	twinkle_tween.tween_property(sparkle_core, "modulate:a", 1.0, 0.3).set_delay(0.7)
	
	twinkle_tween.tween_property(sparkle_glow, "scale", Vector2(1.5, 1.5), 0.5)
	twinkle_tween.tween_property(sparkle_glow, "scale", Vector2(1.0, 1.0), 0.5).set_delay(0.5)
	
	var fade_delay = life_duration - 0.9
	if fade_delay > 0:
		twinkle_tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(fade_delay)

func start_floating_animation():
	if is_animating:
		return
	
	is_animating = true
	
	animation_tween = create_tween()
	animation_tween.set_loops()
	animation_tween.set_parallel(true)
	
	animation_tween.tween_property(self, "position:y", position.y - 15, 1.5)
	animation_tween.tween_property(self, "position:y", position.y + 15, 1.5).set_delay(1.5)
	
	animation_tween.tween_property(self, "position:x", position.x - 10, 2.0)
	animation_tween.tween_property(self, "position:x", position.x + 10, 2.0).set_delay(2.0)
	
	animation_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 1.0)
	animation_tween.tween_property(self, "scale", Vector2(0.8, 0.8), 1.0).set_delay(1.0)
	
	create_twinkle_effect()
	life_timer.start()

func start_burst_animation():
	if is_animating or not sparkle_core:
		return
	
	is_animating = true
	
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	
	scale = Vector2.ZERO
	animation_tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.1)
	animation_tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.3).set_delay(0.1)
	animation_tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_delay(0.4)

	animation_tween.tween_property(sparkle_core, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.1)
	animation_tween.tween_property(sparkle_core, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5).set_delay(0.2)
	
	await animation_tween.finished
	queue_free()

func start_from_position(start_pos: Vector2):
	position = start_pos
	start_animation()

func set_custom_color(color: Color):
	if sparkle_core and sparkle_glow:
		sparkle_core.color = color
		sparkle_glow.color = Color(color.r, color.g, color.b, 0.3)

func stop_animation():
	if animation_tween:
		animation_tween.kill()
	is_animating = false
	life_timer.stop()

func _on_life_timer_timeout():
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	fade_tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	
	await fade_tween.finished
	queue_free()

static func create_sparkle_at(parent: Node, pos: Vector2, type: SparkleType = SparkleType.CYAN) -> Control:
	var sparkle_scene = preload("res://scenes/effects/Sparkle.tscn")
	var sparkle = sparkle_scene.instantiate()
	parent.add_child(sparkle)
	sparkle.position = pos
	sparkle.set_sparkle_type(type)
	sparkle.start_animation()
	return sparkle

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if animation_tween:
			animation_tween.kill()
