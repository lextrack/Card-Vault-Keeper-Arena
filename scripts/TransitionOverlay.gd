extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var loading_container: Control = $LoadingContainer
@onready var card_container: Control = $LoadingContainer/CardContainer
@onready var card_front: ColorRect = $LoadingContainer/CardContainer/CardFront
@onready var card_back: ColorRect = $LoadingContainer/CardContainer/CardBack

var show_duration = 0.2
var flip_duration = 0.5
var float_amplitude = 2.0
var current_face = "front"  # "front" o "back"

var rotation_tween: Tween
var float_tween: Tween
var is_animating: bool = false

func _ready():
	layer = 1000
	overlay.color.a = 0.0
	loading_container.modulate.a = 0.0
	
	_ensure_card_position()

func _ensure_card_position():
	pass

func start_loading_animation():
	_stop_all_tweens()
	
	card_container.rotation = 0.0
	card_container.scale = Vector2(1.0, 1.0)
	
	current_face = "front"
	card_front.visible = true
	card_back.visible = false
	card_front.z_index = 1
	card_back.z_index = 0
	
	is_animating = true
	_start_face_cycle()
	_start_floating_loop()

func _start_face_cycle():
	if not is_animating:
		return
	
	await get_tree().create_timer(show_duration).timeout
	
	if not is_animating:
		return
	
	if current_face == "front":
		await _flip_to_back()
		current_face = "back"
	else:
		await _flip_to_front()
		current_face = "front"
	
	if is_animating:
		_start_face_cycle()

func _flip_to_back():
	rotation_tween = create_tween()
	rotation_tween.set_ease(Tween.EASE_IN_OUT)
	rotation_tween.set_trans(Tween.TRANS_CUBIC)
	
	rotation_tween.tween_method(_update_flip_rotation, 0.0, 90.0, flip_duration * 0.5)
	await rotation_tween.finished
	
	card_front.visible = false
	card_back.visible = true
	card_front.z_index = 0
	card_back.z_index = 1
	
	rotation_tween = create_tween()
	rotation_tween.set_ease(Tween.EASE_IN_OUT)
	rotation_tween.set_trans(Tween.TRANS_CUBIC)
	rotation_tween.tween_method(_update_flip_rotation, 90.0, 180.0, flip_duration * 0.5)
	await rotation_tween.finished
	
	card_container.rotation = 0.0
	card_container.scale = Vector2(1.0, 1.0)

func _flip_to_front():
	rotation_tween = create_tween()
	rotation_tween.set_ease(Tween.EASE_IN_OUT)
	rotation_tween.set_trans(Tween.TRANS_CUBIC)

	rotation_tween.tween_method(_update_flip_rotation, 0.0, 90.0, flip_duration * 0.5)
	await rotation_tween.finished

	card_back.visible = false
	card_front.visible = true
	card_back.z_index = 0
	card_front.z_index = 1

	rotation_tween = create_tween()
	rotation_tween.set_ease(Tween.EASE_IN_OUT)
	rotation_tween.set_trans(Tween.TRANS_CUBIC)
	rotation_tween.tween_method(_update_flip_rotation, 90.0, 180.0, flip_duration * 0.5)
	await rotation_tween.finished
	
	card_container.rotation = 0.0
	card_container.scale = Vector2(1.0, 1.0)

func _update_flip_rotation(degrees: float):
	var radians = deg_to_rad(degrees)
	card_container.rotation = radians

	var scale_factor = abs(cos(radians)) * 0.2 + 0.8
	card_container.scale = Vector2(scale_factor, 1.0)

func _start_floating_loop():
	if not is_animating:
		return
	
	float_tween = create_tween()
	float_tween.set_ease(Tween.EASE_IN_OUT)
	float_tween.set_trans(Tween.TRANS_SINE)
	
	var base_offset_y = card_container.offset_top
	
	float_tween.tween_property(card_container, "offset_top", base_offset_y - float_amplitude, 1.0)
	float_tween.tween_property(card_container, "offset_top", base_offset_y + float_amplitude, 3.0)
	
	await float_tween.finished
	
	if is_animating:
		_start_floating_loop()

func stop_loading_animation():
	is_animating = false
	_stop_all_tweens()
	
	var reset_tween = create_tween()
	reset_tween.set_parallel(true)
	reset_tween.set_ease(Tween.EASE_OUT)
	reset_tween.set_trans(Tween.TRANS_QUART)

	reset_tween.tween_property(card_container, "rotation", 0.0, 0.4)
	reset_tween.tween_property(card_container, "scale", Vector2(1.0, 1.0), 0.4)
	
	var original_offset_top = -95.0 
	reset_tween.tween_property(card_container, "offset_top", original_offset_top, 0.4)
	
	card_front.visible = true
	card_back.visible = false
	card_front.z_index = 1
	card_back.z_index = 0

func _stop_all_tweens():
	if rotation_tween:
		rotation_tween.kill()
		rotation_tween = null
	if float_tween:
		float_tween.kill()
		float_tween = null

func fade_in(duration: float = 0.5):
	start_loading_animation()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "color:a", 1.0, duration)
	tween.tween_property(loading_container, "modulate:a", 1.0, duration * 0.8)
	
	await tween.finished

func fade_out(duration: float = 0.5):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "color:a", 0.0, duration)
	tween.tween_property(loading_container, "modulate:a", 0.0, duration * 0.6)
	
	await tween.finished
	stop_loading_animation()

func instant_black():
	overlay.color.a = 1.0
	loading_container.modulate.a = 1.0
	start_loading_animation()

func instant_clear():
	overlay.color.a = 0.0
	loading_container.modulate.a = 0.0
	stop_loading_animation()

func is_covering() -> bool:
	return overlay.color.a > 0.5

func show_loading():
	instant_black()

func hide_loading():
	await fade_out(0.5)

func is_ready() -> bool:
	return overlay != null and loading_container != null and card_container != null

func set_animation_speed(new_show_duration: float, new_flip_duration: float = 0.6):
	show_duration = new_show_duration
	flip_duration = new_flip_duration

func set_float_intensity(amplitude: float):
	float_amplitude = amplitude
