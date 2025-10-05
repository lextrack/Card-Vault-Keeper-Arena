class_name RobotHead
extends Control

signal speaking_finished
signal mood_changed(new_mood: String)
signal reaction_finished

@onready var head_container: Control = $HeadContainer
@onready var head: ColorRect = $HeadContainer/Head
@onready var left_eye: ColorRect = $HeadContainer/Head/Eyes/LeftEye
@onready var right_eye: ColorRect = $HeadContainer/Head/Eyes/RightEye
@onready var mouth: ColorRect = $HeadContainer/Head/Mouth
@onready var left_antenna: ColorRect = $HeadContainer/Antennas/LeftAntenna
@onready var right_antenna: ColorRect = $HeadContainer/Antennas/RightAntenna
@onready var status_light: ColorRect = $HeadContainer/Head/StatusLight
@onready var neck: ColorRect = $HeadContainer/Neck

const COLORS = {
	"head": Color(0.35, 0.56, 0.94),
	"head_border": Color(0.17, 0.35, 0.63),
	"status": Color(1.0, 0.28, 0.34),
	"eye": Color(0.0, 1.0, 0.53),
	"eye_border": Color(0.0, 0.67, 0.33),
	"pupil": Color(0.0, 0.1, 0.05),
	"mouth": Color(0.05, 0.07, 0.09),
	"mouth_border": Color(0.1, 0.1, 0.1),
	"led": Color(0.0, 1.0, 0.53, 0.8),
	"antenna": Color(0.29, 0.56, 0.88),
	"antenna_light": Color(1.0, 0.28, 0.34)
}

const MOOD_CONFIGS = {
	"happy": {
		"color": Color.CYAN * 1.3,
		"eye_scale": Vector2(1.2, 0.7),
		"head_tilt": 0.05,
		"antenna_speed": 0.5
	},
	"alert": {
		"color": Color.YELLOW * 1.4,
		"eye_scale": Vector2(0.8, 1.3),
		"head_tilt": -0.03,
		"antenna_speed": 0.3
	},
	"error": {
		"color": Color.RED * 1.2,
		"eye_scale": Vector2(1.1, 1.1),
		"head_tilt": 0.0,
		"antenna_speed": 2.0
	},
	"normal": {
		"color": Color(0.0, 1.0, 0.53),
		"eye_scale": Vector2.ONE,
		"head_tilt": 0.0,
		"antenna_speed": 1.0
	}
}

var tweens: Dictionary = {}
var blink_timer: Timer
var speaking_timer: Timer
var current_mood: String = "normal"
var is_speaking: bool = false

func _ready():
	setup_robot_styles()
	setup_timers()
	start_animations()

func create_style(bg_color: Color, corner_radius: int = 0, border_width: int = 0, 
				  border_color: Color = Color.BLACK, shadow_size: int = 0) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	
	if corner_radius > 0:
		style.corner_radius_top_left = corner_radius
		style.corner_radius_top_right = corner_radius
		style.corner_radius_bottom_left = corner_radius
		style.corner_radius_bottom_right = corner_radius
	
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
		style.border_color = border_color
	
	if shadow_size > 0:
		style.shadow_color = Color(0, 0, 0, 0.4)
		style.shadow_size = shadow_size
		style.shadow_offset = Vector2(0, 4)
	
	return style

func apply_style_to_rect(rect: ColorRect, color: Color, style: StyleBoxFlat):
	rect.color = color
	rect.add_theme_stylebox_override("panel", style)

func setup_robot_styles():
	var head_style = create_style(COLORS.head, 25, 3, COLORS.head_border, 8)
	apply_style_to_rect(head, COLORS.head, head_style)
	
	var status_style = create_style(COLORS.status, 6)
	apply_style_to_rect(status_light, COLORS.status, status_style)
	
	setup_symmetric_parts()
	setup_mouth_leds()
	setup_neck_lights()

func setup_symmetric_parts():
	var eye_style = create_style(COLORS.eye, 14, 2, COLORS.eye_border)
	var pupil_style = create_style(COLORS.pupil, 5)
	var antenna_style = create_style(COLORS.antenna, 2)
	var light_style = create_style(COLORS.antenna_light, 4)
	
	for eye in [left_eye, right_eye]:
		apply_style_to_rect(eye, COLORS.eye, eye_style)
		var pupil = eye.get_node(eye.name.replace("Eye", "Pupil"))
		apply_style_to_rect(pupil, COLORS.pupil, pupil_style)
	
	for antenna in [left_antenna, right_antenna]:
		apply_style_to_rect(antenna, COLORS.antenna, antenna_style)
		var light = antenna.get_node(antenna.name + "Light")
		apply_style_to_rect(light, COLORS.antenna_light, light_style)

func setup_mouth_leds():
	var mouth_style = create_style(COLORS.mouth, 12, 2, COLORS.mouth_border)
	apply_style_to_rect(mouth, COLORS.mouth, mouth_style)
	
	var led_style = create_style(COLORS.led, 2)
	for i in range(1, 6):
		var led = mouth.get_node("LED" + str(i))
		apply_style_to_rect(led, COLORS.led, led_style)

func setup_neck_lights():
	var neck_style = create_style(COLORS.head, 12, 3, COLORS.head_border)
	neck_style.corner_radius_top_left = 0
	neck_style.corner_radius_top_right = 0
	neck_style.border_width_top = 0
	apply_style_to_rect(neck, COLORS.head, neck_style)
	
	var light_colors = [Color.GREEN, Color.GREEN, Color.RED, Color.RED]
	for i in range(1, 5):
		var light = neck.get_node("NeckLights/Light" + str(i))
		var light_style = create_style(light_colors[i-1], 3)
		apply_style_to_rect(light, light_colors[i-1], light_style)

func setup_timers():
	blink_timer = Timer.new()
	add_child(blink_timer)
	blink_timer.wait_time = randf_range(2.0, 5.0)
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	blink_timer.start()
	
	speaking_timer = Timer.new()
	speaking_timer.one_shot = true
	speaking_timer.timeout.connect(_on_speaking_timer_timeout)
	add_child(speaking_timer)

func start_animations():
	start_floating_animation()
	start_antenna_pulse()
	start_speaking_animation()

func kill_tween(key: String):
	if tweens.has(key) and tweens[key]:
		tweens[key].kill()

func start_floating_animation():
	kill_tween("float")
	tweens.float = create_tween().set_loops()
	tweens.float.tween_property(head_container, "position:y", -10, 1.8)
	tweens.float.tween_property(head_container, "position:y", 0, 1.8)

func start_antenna_pulse(speed_multiplier: float = 1.0):
	kill_tween("antenna")
	tweens.antenna = create_tween().set_loops()
	
	var pulse_duration = 1.0 / speed_multiplier
	var lights = [
		left_antenna.get_node("LeftAntennaLight"),
		right_antenna.get_node("RightAntennaLight")
	]
	
	for light in lights:
		tweens.antenna.parallel().tween_property(light, "modulate:a", 0.3, pulse_duration)
	for light in lights:
		tweens.antenna.parallel().tween_property(light, "modulate:a", 1.0, pulse_duration)

func start_speaking_animation():
	kill_tween("speak")
	tweens.speak = create_tween().set_loops()
	
	for i in range(1, 6):
		var led = mouth.get_node("LED" + str(i))
		tweens.speak.parallel().tween_property(led, "modulate:a", 0.5, 1.3)
		tweens.speak.parallel().tween_property(led, "modulate:a", 1.0, 0.3)

func _on_blink_timer_timeout():
	var blink_tween = create_tween()
	for eye in [left_eye, right_eye]:
		blink_tween.parallel().tween_property(eye, "modulate:a", 0.1, 0.1)
	for eye in [left_eye, right_eye]:
		blink_tween.parallel().tween_property(eye, "modulate:a", 2.0, 0.5)
	
	blink_timer.wait_time = randf_range(2.0, 3.0)
	blink_timer.start()

func speak(text: String):
	is_speaking = true
	kill_tween("speak")
	start_enhanced_speaking_animation()
	pulse_status_light()
	
	var word_count = text.split(" ").size()
	var duration = max(2.0, word_count * 0.25)
	
	speaking_timer.wait_time = duration
	speaking_timer.start()

func _on_speaking_timer_timeout():
	is_speaking = false
	kill_tween("speak")
	
	for i in range(1, 6):
		var led = mouth.get_node("LED" + str(i))
		if is_instance_valid(led):
			var reset_tween = create_tween()
			reset_tween.tween_property(led, "modulate:a", 1.0, 0.2)
			reset_tween.tween_property(led, "scale", Vector2.ONE, 0.2)
	
	set_mood(current_mood)
	speaking_finished.emit()

func start_enhanced_speaking_animation():
	tweens.speak = create_tween().set_loops()
	tweens.speak.parallel().tween_property(head, "rotation", 0.02, 0.8)
	tweens.speak.parallel().tween_property(head, "rotation", -0.02, 0.8)
	tweens.speak.parallel().tween_property(head, "rotation", 0.0, 0.4)
	
	for i in range(1, 6):
		var led = mouth.get_node("LED" + str(i))
		if is_instance_valid(led):
			var led_tween = create_tween().set_loops()
			led_tween.tween_interval(i * 0.09)
			led_tween.tween_property(led, "modulate:a", 0.3, 0.1)
			led_tween.tween_property(led, "scale", Vector2(1.1, 1.1), 0.1)
			led_tween.tween_property(led, "modulate:a", 1.0, 0.2)
			led_tween.tween_property(led, "scale", Vector2.ONE, 0.2)

func set_active(active: bool):
	if active:
		modulate = Color.WHITE
		start_animations()
	else:
		modulate = Color(0.5, 0.5, 0.5, 0.7)
		kill_tween("float")
		kill_tween("antenna")

func pulse_status_light():
	var pulse_tween = create_tween().set_parallel(true)
	pulse_tween.tween_property(status_light, "modulate", Color.BLUE_VIOLET * 1.5, 0.3)
	pulse_tween.tween_property(status_light, "scale", Vector2(1.3, 1.3), 0.3)
	pulse_tween.tween_property(status_light, "modulate", Color.WHITE, 0.8)
	pulse_tween.tween_property(status_light, "scale", Vector2.ONE, 0.8)
	pulse_tween.tween_property(head, "modulate", Color(1.1, 1.1, 1.2), 0.3)
	pulse_tween.tween_property(head, "modulate", Color.WHITE, 0.8)

func set_mood(new_mood: String):
	if not left_eye or not right_eye or is_speaking:
		return
	
	current_mood = new_mood
	kill_tween("mood")
	tweens.mood = create_tween().set_parallel(true)
	
	var config = MOOD_CONFIGS.get(new_mood, MOOD_CONFIGS.normal)
	
	for eye in [left_eye, right_eye]:
		tweens.mood.tween_property(eye, "modulate", config.color, 0.4)
		tweens.mood.tween_property(eye, "scale", config.eye_scale, 0.4)
	
	tweens.mood.tween_property(head, "rotation", config.head_tilt, 0.4)
	apply_mood_animation(new_mood, tweens.mood)
	start_antenna_pulse(config.antenna_speed)
	
	mood_changed.emit(new_mood)

func apply_mood_animation(mood: String, tween: Tween):
	match mood:
		"happy":
			tween.tween_property(head_container, "scale", Vector2(1.05, 1.05), 0.3)
			tween.tween_property(head_container, "scale", Vector2.ONE, 0.3)
		"alert":
			tween.tween_property(head, "position:y", head.position.y - 3, 0.1)
			tween.tween_property(head, "position:y", head.position.y, 0.2)
		"error":
			for i in range(3):
				tween.tween_property(head_container, "position:x", 2, 0.05)
				tween.tween_property(head_container, "position:x", -2, 0.05)
			tween.tween_property(head_container, "position:x", 0, 0.05)

func flash_neck_lights():
	var neck_lights_container = neck.get_node("NeckLights")
	if not neck_lights_container:
		return
	
	kill_tween("celebration")
	tweens.celebration = create_tween().set_parallel(true)
	
	for round in range(3):
		for i in range(1, 5):
			var light = neck_lights_container.get_node("Light" + str(i))
			if light:
				var delay = round * 0.5 + i * 0.1
				get_tree().create_timer(delay).timeout.connect(func():
					if is_instance_valid(light):
						var light_tween = create_tween().set_parallel(true)
						light_tween.tween_property(light, "modulate", Color.GOLD * 2.0, 0.1)
						light_tween.tween_property(light, "scale", Vector2(1.5, 1.5), 0.1)
						light_tween.tween_property(light, "modulate", Color.WHITE, 0.3)
						light_tween.tween_property(light, "scale", Vector2.ONE, 0.3)
				, CONNECT_ONE_SHOT)
	
	tweens.celebration.tween_property(head_container, "scale", Vector2(1.1, 1.1), 0.2)
	tweens.celebration.tween_property(head_container, "rotation", 0.1, 0.2)
	tweens.celebration.tween_property(head_container, "scale", Vector2.ONE, 0.4)
	tweens.celebration.tween_property(head_container, "rotation", 0.0, 0.4)
	
	await tweens.celebration.finished
	reaction_finished.emit()

func stop_all_animations():
	for key in tweens:
		kill_tween(key)
	if blink_timer:
		blink_timer.stop()
	if speaking_timer:
		speaking_timer.stop()

func react_to_event(event_type: String, intensity: float = 1.0):
	match event_type:
		"unlock":
			dramatic_reaction("excitement")
			flash_neck_lights()
		"hover_unlockable":
			set_mood("alert")
			dramatic_reaction("excitement")
		"hover_locked":
			set_mood("normal")
		"hover_unlocked":
			set_mood("happy")
		"unhover":
			set_mood("normal")
		"error":
			set_mood("error")
		_:
			set_mood("normal")

func dramatic_reaction(reaction_type: String):
	var dramatic_tween = create_tween().set_parallel(true)
	
	match reaction_type:
		"excitement":
			dramatic_tween.tween_property(head_container, "position:y", -20, 0.2)
			dramatic_tween.tween_property(head_container, "position:y", 0, 0.4)
			dramatic_tween.tween_property(head_container, "scale", Vector2(1.1, 1.1), 0.2)
			dramatic_tween.tween_property(head_container, "scale", Vector2.ONE, 0.4)
		"surprise":
			dramatic_tween.tween_property(head, "scale", Vector2(0.9, 1.1), 0.1)
			dramatic_tween.tween_property(head, "scale", Vector2.ONE, 0.3)
			for eye in [left_eye, right_eye]:
				dramatic_tween.tween_property(eye, "scale", Vector2(0.5, 1.5), 0.1)
				dramatic_tween.tween_property(eye, "scale", Vector2.ONE, 0.3)
		"thinking":
			dramatic_tween.tween_property(head, "rotation", 0.15, 0.5)
			for eye in [left_eye, right_eye]:
				dramatic_tween.tween_property(eye, "modulate:a", 0.7, 0.5)
	
	await dramatic_tween.finished
	reaction_finished.emit()
