class_name BundleCelebration
extends RefCounted

var main_scene: Control
var celebration_queue: Array = []
var is_showing_celebration: bool = false

signal celebration_completed

func setup(main: Control):
	main_scene = main

func queue_celebration(bundle_info: Dictionary, cards: Array):
	celebration_queue.append({
		"bundle_info": bundle_info,
		"cards": cards
	})
	
	if not is_showing_celebration:
		_process_queue()

func clear_all_celebrations():
	celebration_queue.clear()
	is_showing_celebration = false
	
	var active_overlays = main_scene.get_children().filter(func(child):
		return child is Control and child.z_index == 1000
	)
	
	for overlay in active_overlays:
		if is_instance_valid(overlay):
			overlay.queue_free()

func is_celebrations_complete() -> bool:
	return not is_showing_celebration and celebration_queue.size() == 0

func _process_queue():
	if celebration_queue.size() == 0:
		is_showing_celebration = false
		celebration_completed.emit()
		return
	
	is_showing_celebration = true
	var celebration_data = celebration_queue.pop_front()
	
	await _show_celebration(celebration_data.bundle_info, celebration_data.cards)
	
	if celebration_queue.size() > 0:
		await main_scene.get_tree().create_timer(0.3).timeout
		_process_queue()
	else:
		is_showing_celebration = false
		celebration_completed.emit()

func _show_celebration(bundle_info: Dictionary, cards: Array):
	var overlay = _create_overlay()
	var panel = _create_panel()
	overlay.add_child(panel)
	
	_populate_content(panel, bundle_info, cards)
	
	await _animate_entrance(overlay, panel)
	_spawn_particles(overlay)
	
	var timer = Timer.new()
	timer.wait_time = 1.5 
	timer.one_shot = true
	overlay.add_child(timer)
	
	timer.timeout.connect(_close_celebration_safely.bind(overlay))
	timer.start()
	
	await timer.timeout
	
func _close_celebration_safely(overlay: Control):
	if not is_instance_valid(overlay):
		return
		
	var fade_tween = main_scene.create_tween()
	fade_tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
	await fade_tween.finished
	
	if is_instance_valid(overlay):
		overlay.queue_free()

func _create_overlay() -> Control:
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 1000
	main_scene.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.8)
	overlay.add_child(bg)
	
	return overlay

func _create_panel() -> Panel:
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(500, 300)
	panel.position = Vector2(-250, -150)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.15, 0.05, 1)
	style.border_color = Color(1, 0.8, 0.2, 1)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", style)
	
	return panel

func _populate_content(panel: Panel, bundle_info: Dictionary, cards: Array):
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	panel.add_child(vbox)

	var title = _create_label("BUNDLE UNLOCKED!", 28, Color(1, 0.9, 0.2, 1))
	vbox.add_child(title)
	
	var bundle_name = _create_label(bundle_info.name, 20, Color(0.9, 1, 0.9, 1))
	vbox.add_child(bundle_name)

	var description = _create_label(bundle_info.description, 14, Color(0.8, 0.9, 0.8, 1))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(description)
	
	var cards_text = "New Cards: " + ", ".join(cards)
	var cards_label = _create_label(cards_text, 16, Color(0.7, 1, 0.9, 1))
	cards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(cards_label)

func _create_label(text: String, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _animate_entrance(overlay: Control, panel: Panel):
	overlay.modulate.a = 0.0
	panel.scale = Vector2(0.5, 0.5)
	
	var tween = main_scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "scale", Vector2(1.1, 1.1), 0.25)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15)
	
	await tween.finished

func _spawn_particles(overlay: Control):
	for i in range(6):
		var particle = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.color = Color(1, 0.8, 0.2, 1)
		particle.position = Vector2(
			randf_range(50, overlay.size.x - 50),
			randf_range(50, overlay.size.y - 200)
		)
		overlay.add_child(particle)
		
		var tween = main_scene.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position:y", particle.position.y - 100, 1.5)
		tween.tween_property(particle, "modulate:a", 0.0, 1.5)
		tween.tween_property(particle, "rotation", randf_range(-PI, PI), 1.5)

func _cleanup_particle(particle: ColorRect):
	if is_instance_valid(particle) and particle.is_inside_tree():
		particle.queue_free()

func wait_for_celebrations_to_complete() -> void:
	var max_wait = 3.0
	var wait_time = 0.0
	
	while is_showing_celebration and wait_time < max_wait:
		await main_scene.get_tree().create_timer(0.05).timeout
		wait_time += 0.05
	
	if celebration_queue.size() > 0:
		await main_scene.get_tree().create_timer(0.3).timeout

func force_complete_celebrations():
	celebration_queue.clear()
	is_showing_celebration = false
	clear_all_celebrations()
	celebration_completed.emit()

func skip_celebrations_for_game_end():
	if is_showing_celebration or celebration_queue.size() > 0:
		force_complete_celebrations()
