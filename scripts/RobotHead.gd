class_name RobotHead
extends Control

@onready var head_container: Control = $HeadContainer
@onready var head: ColorRect = $HeadContainer/Head
@onready var left_eye: ColorRect = $HeadContainer/Head/Eyes/LeftEye
@onready var right_eye: ColorRect = $HeadContainer/Head/Eyes/RightEye
@onready var mouth: ColorRect = $HeadContainer/Head/Mouth
@onready var left_antenna: ColorRect = $HeadContainer/Antennas/LeftAntenna
@onready var right_antenna: ColorRect = $HeadContainer/Antennas/RightAntenna
@onready var status_light: ColorRect = $HeadContainer/Head/StatusLight
@onready var neck: ColorRect = $HeadContainer/Neck

var float_tween: Tween
var blink_timer: Timer
var speak_tween: Tween
var antenna_tween: Tween

func _ready():
	setup_robot_styles()
	setup_timers()
	start_animations()

func setup_robot_styles():
	head.color = Color(0.35, 0.56, 0.94)
	
	var head_style = StyleBoxFlat.new()
	head_style.bg_color = Color(0.35, 0.56, 0.94)
	head_style.corner_radius_top_left = 25
	head_style.corner_radius_top_right = 25
	head_style.corner_radius_bottom_left = 25
	head_style.corner_radius_bottom_right = 25
	head_style.border_width_left = 3
	head_style.border_width_right = 3
	head_style.border_width_top = 3
	head_style.border_width_bottom = 3
	head_style.border_color = Color(0.17, 0.35, 0.63)
	head_style.shadow_color = Color(0, 0, 0, 0.4)
	head_style.shadow_size = 8
	head_style.shadow_offset = Vector2(0, 4)
	head.add_theme_stylebox_override("panel", head_style)
	
	status_light.color = Color(1.0, 0.28, 0.34)
	var status_style = StyleBoxFlat.new()
	status_style.bg_color = Color(1.0, 0.28, 0.34)
	status_style.corner_radius_top_left = 6
	status_style.corner_radius_top_right = 6
	status_style.corner_radius_bottom_left = 6
	status_style.corner_radius_bottom_right = 6
	status_light.add_theme_stylebox_override("panel", status_style)
	
	setup_eye_styles()
	setup_mouth_styles()
	setup_antenna_styles()
	setup_neck_styles()

func setup_eye_styles():
	left_eye.color = Color(0.0, 1.0, 0.53)
	right_eye.color = Color(0.0, 1.0, 0.53)
	
	var eye_style = StyleBoxFlat.new()
	eye_style.bg_color = Color(0.0, 1.0, 0.53)
	eye_style.corner_radius_top_left = 14
	eye_style.corner_radius_top_right = 14
	eye_style.corner_radius_bottom_left = 14
	eye_style.corner_radius_bottom_right = 14
	eye_style.border_width_left = 2
	eye_style.border_width_right = 2
	eye_style.border_width_top = 2
	eye_style.border_width_bottom = 2
	eye_style.border_color = Color(0.0, 0.67, 0.33)
	
	left_eye.add_theme_stylebox_override("panel", eye_style)
	right_eye.add_theme_stylebox_override("panel", eye_style)
	
	var left_pupil = $HeadContainer/Head/Eyes/LeftEye/LeftPupil
	var right_pupil = $HeadContainer/Head/Eyes/RightEye/RightPupil
	left_pupil.color = Color(0.0, 0.1, 0.05)
	right_pupil.color = Color(0.0, 0.1, 0.05)
	
	var pupil_style = StyleBoxFlat.new()
	pupil_style.bg_color = Color(0.0, 0.1, 0.05)
	pupil_style.corner_radius_top_left = 5
	pupil_style.corner_radius_top_right = 5
	pupil_style.corner_radius_bottom_left = 5
	pupil_style.corner_radius_bottom_right = 5
	
	left_pupil.add_theme_stylebox_override("panel", pupil_style)
	right_pupil.add_theme_stylebox_override("panel", pupil_style)

func setup_mouth_styles():
	mouth.color = Color(0.05, 0.07, 0.09)
	
	var mouth_style = StyleBoxFlat.new()
	mouth_style.bg_color = Color(0.05, 0.07, 0.09)
	mouth_style.corner_radius_top_left = 12
	mouth_style.corner_radius_top_right = 12
	mouth_style.corner_radius_bottom_left = 12
	mouth_style.corner_radius_bottom_right = 12
	mouth_style.border_width_left = 2
	mouth_style.border_width_right = 2
	mouth_style.border_width_top = 2
	mouth_style.border_width_bottom = 2
	mouth_style.border_color = Color(0.1, 0.1, 0.1)
	mouth.add_theme_stylebox_override("panel", mouth_style)
	
	var led_style = StyleBoxFlat.new()
	led_style.bg_color = Color(0.0, 1.0, 0.53, 0.8)
	led_style.corner_radius_top_left = 2
	led_style.corner_radius_top_right = 2
	led_style.corner_radius_bottom_left = 2
	led_style.corner_radius_bottom_right = 2
	
	for i in range(1, 6):
		var led = mouth.get_node("LED" + str(i))
		led.color = Color(0.0, 1.0, 0.53, 0.8)
		led.add_theme_stylebox_override("panel", led_style)

func setup_antenna_styles():
	left_antenna.color = Color(0.29, 0.56, 0.88)
	right_antenna.color = Color(0.29, 0.56, 0.88)
	
	var antenna_style = StyleBoxFlat.new()
	antenna_style.bg_color = Color(0.29, 0.56, 0.88)
	antenna_style.corner_radius_top_left = 2
	antenna_style.corner_radius_top_right = 2
	antenna_style.corner_radius_bottom_left = 2
	antenna_style.corner_radius_bottom_right = 2
	
	left_antenna.add_theme_stylebox_override("panel", antenna_style)
	right_antenna.add_theme_stylebox_override("panel", antenna_style)
	
	var left_light = $HeadContainer/Antennas/LeftAntenna/LeftAntennaLight
	var right_light = $HeadContainer/Antennas/RightAntenna/RightAntennaLight
	left_light.color = Color(1.0, 0.28, 0.34)
	right_light.color = Color(1.0, 0.28, 0.34)
	
	var light_style = StyleBoxFlat.new()
	light_style.bg_color = Color(1.0, 0.28, 0.34)
	light_style.corner_radius_top_left = 4
	light_style.corner_radius_top_right = 4
	light_style.corner_radius_bottom_left = 4
	light_style.corner_radius_bottom_right = 4
	
	left_light.add_theme_stylebox_override("panel", light_style)
	right_light.add_theme_stylebox_override("panel", light_style)

func setup_neck_styles():
	neck.color = Color(0.35, 0.56, 0.94)
	
	var neck_style = StyleBoxFlat.new()
	neck_style.bg_color = Color(0.35, 0.56, 0.94)
	neck_style.corner_radius_bottom_left = 12
	neck_style.corner_radius_bottom_right = 12
	neck_style.border_width_left = 3
	neck_style.border_width_right = 3
	neck_style.border_width_bottom = 3
	neck_style.border_color = Color(0.17, 0.35, 0.63)
	neck.add_theme_stylebox_override("panel", neck_style)
	
	var light_colors = [Color.GREEN, Color.GREEN, Color.RED, Color.RED]
	for i in range(1, 5):
		var light = neck.get_node("NeckLights/Light" + str(i))
		light.color = light_colors[i-1]
		var light_style = StyleBoxFlat.new()
		light_style.bg_color = light_colors[i-1]
		light_style.corner_radius_top_left = 3
		light_style.corner_radius_top_right = 3
		light_style.corner_radius_bottom_left = 3
		light_style.corner_radius_bottom_right = 3
		light.add_theme_stylebox_override("panel", light_style)

func setup_timers():
	blink_timer = Timer.new()
	add_child(blink_timer)
	blink_timer.wait_time = randf_range(2.0, 5.0)
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	blink_timer.start()

func start_animations():
	start_floating_animation()
	start_antenna_pulse()
	start_speaking_animation()

func start_floating_animation():
	float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(head_container, "position:y", -10, 1.8)
	float_tween.tween_property(head_container, "position:y", 0, 1.8)

func start_antenna_pulse():
	antenna_tween = create_tween()
	antenna_tween.set_loops()
	
	var left_light = $HeadContainer/Antennas/LeftAntenna/LeftAntennaLight
	var right_light = $HeadContainer/Antennas/RightAntenna/RightAntennaLight
	
	antenna_tween.parallel().tween_property(left_light, "modulate:a", 0.3, 1.0)
	antenna_tween.parallel().tween_property(right_light, "modulate:a", 0.3, 1.0)
	antenna_tween.parallel().tween_property(left_light, "modulate:a", 1.0, 1.0)
	antenna_tween.parallel().tween_property(right_light, "modulate:a", 1.0, 1.0)

func start_speaking_animation():
	speak_tween = create_tween()
	speak_tween.set_loops()
	
	for i in range(1, 6):
		var led = mouth.get_node("LED" + str(i))
		speak_tween.parallel().tween_property(led, "modulate:a", 0.5, 1.3)
		speak_tween.parallel().tween_property(led, "modulate:a", 1.0, 0.3)

func _on_blink_timer_timeout():
	var blink_tween = create_tween()
	blink_tween.parallel().tween_property(left_eye, "modulate:a", 0.1, 0.1)
	blink_tween.parallel().tween_property(right_eye, "modulate:a", 0.1, 0.1)
	blink_tween.parallel().tween_property(left_eye, "modulate:a", 2.0, 0.5)
	blink_tween.parallel().tween_property(right_eye, "modulate:a", 2.0, 0.5)
	
	blink_timer.wait_time = randf_range(2.0, 3.0)
	blink_timer.start()

func set_speaking(speaking: bool):
	if speaking:
		start_speaking_animation()
	else:
		if speak_tween:
			speak_tween.kill()
			
		for i in range(1, 6):
			var led = mouth.get_node("LED" + str(i))
			if led:
				led.modulate.a = 1.0

func set_active(active: bool):
	if active:
		modulate = Color.WHITE
		start_animations()
	else:
		modulate = Color(0.5, 0.5, 0.5, 0.7)
		if float_tween:
			float_tween.kill()
		if antenna_tween:
			antenna_tween.kill()

func pulse_status_light():
	var pulse_tween = create_tween()
	pulse_tween.tween_property(status_light, "modulate", Color.BLUE_VIOLET, 1.2)
	pulse_tween.tween_property(status_light, "modulate", Color.WHITE, 0.2)

func set_mood(mood: String):
	if not left_eye or not right_eye:
		return
		
	var target_color: Color
	match mood:
		"happy":
			target_color = Color.CYAN
		"alert":
			target_color = Color.YELLOW
		"error":
			target_color = Color.RED
		"normal":
			target_color = Color(0.0, 1.0, 0.53)
		_:
			target_color = Color(0.0, 1.0, 0.53)
	
	var eye_tween = create_tween()
	eye_tween.parallel().tween_property(left_eye, "modulate", target_color, 0.5)
	eye_tween.parallel().tween_property(right_eye, "modulate", target_color, 0.6)

func flash_neck_lights():
	var neck_lights_container = neck.get_node("NeckLights")
	if not neck_lights_container:
		return
		
	var flash_tween = create_tween()
	
	for i in range(1, 5):
		var light = neck_lights_container.get_node("Light" + str(i))
		if light:
			flash_tween.parallel().tween_property(light, "modulate:a", 0.2, 0.1)
			flash_tween.parallel().tween_property(light, "modulate:a", 1.0, 0.3)

func stop_all_animations():
	if float_tween:
		float_tween.kill()
	if speak_tween:
		speak_tween.kill()
	if antenna_tween:
		antenna_tween.kill()
	if blink_timer:
		blink_timer.stop()
