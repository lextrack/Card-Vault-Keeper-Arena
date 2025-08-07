class_name ControlsPanel
extends Control

@onready var background = $Background
@onready var border_highlight = $Background/BorderHighlight
@onready var inner_background = $Background/BorderHighlight/InnerBackground
@onready var panel = $Background/Panel
@onready var particle_effect = $GPUParticles2D

@onready var gameplay_section = $Background/Panel/VBoxContainer/GameplaySection
@onready var menu_section = $Background/Panel/VBoxContainer/MenuSection

@onready var play_hint = $Background/Panel/VBoxContainer/GameplaySection/PlayHint
@onready var end_hint = $Background/Panel/VBoxContainer/GameplaySection/EndHint

@onready var restart_hint = $Background/Panel/VBoxContainer/MenuSection/RestartHint
@onready var challenge_hint = $Background/Panel/VBoxContainer/MenuSection/ChallengeHint
@onready var options_hint = $Background/Panel/VBoxContainer/MenuSection/OptionsHint
@onready var main_menu_hint = $Background/Panel/VBoxContainer/MenuSection/MainMenuHint
@onready var show_controls_hint = $Background/Panel/VBoxContainer/MenuSection/ShowControlsHint

@onready var play_icon = $Background/Panel/VBoxContainer/GameplaySection/PlayHint/PlayIcon
@onready var play_label = $Background/Panel/VBoxContainer/GameplaySection/PlayHint/PlayLabel
@onready var end_icon = $Background/Panel/VBoxContainer/GameplaySection/EndHint/EndIcon
@onready var end_label = $Background/Panel/VBoxContainer/GameplaySection/EndHint/EndLabel

@onready var restart_icon = $Background/Panel/VBoxContainer/MenuSection/RestartHint/RestartIcon
@onready var restart_label = $Background/Panel/VBoxContainer/MenuSection/RestartHint/RestartLabel
@onready var challenge_icon = $Background/Panel/VBoxContainer/MenuSection/ChallengeHint/ChallengeIcon
@onready var challenge_label = $Background/Panel/VBoxContainer/MenuSection/ChallengeHint/ChallengeLabel
@onready var options_label = $Background/Panel/VBoxContainer/MenuSection/OptionsHint/OptionsLabel
@onready var options_icon = $Background/Panel/VBoxContainer/MenuSection/OptionsHint/OptionsIcon
@onready var main_menu_icon = $Background/Panel/VBoxContainer/MenuSection/MainMenuHint/MainMenuIcon
@onready var main_menu_label = $Background/Panel/VBoxContainer/MenuSection/MainMenuHint/MainMenuLabel
@onready var show_controls_icon = $Background/Panel/VBoxContainer/MenuSection/ShowControlsHint/ShowControlsIcon
@onready var show_controls_label = $Background/Panel/VBoxContainer/MenuSection/ShowControlsHint/ShowControlsLabel

var gamepad_mode: bool = false
var is_player_turn: bool = true
var has_cards: bool = false
var is_panel_hidden: bool = true
var toggle_tween: Tween
var glow_tween: Tween
var original_position: Vector2

var xbox_a_texture = preload("res://assets/ui/buttons/xbox_a.png")
var xbox_b_texture = preload("res://assets/ui/buttons/xbox_b.png")
var xbox_x_texture = preload("res://assets/ui/buttons/xbox_x.png")
var xbox_y_texture = preload("res://assets/ui/buttons/xbox_y.png")
var key_c_texture = preload("res://assets/ui/buttons/key_c.png")
var key_r_texture = preload("res://assets/ui/buttons/key_r.png")
var mouse_click_texture = preload("res://assets/ui/buttons/mouse_click.png")
var key_space_texture = preload("res://assets/ui/buttons/key_space.png")
var xbox_menu_texture = preload("res://assets/ui/buttons/xbox_button_menu.png")
var key_tab_texture = preload("res://assets/ui/buttons/key_tab.png")
var xbox_back_texture = preload("res://assets/ui/buttons/xbox_button_back.png")
var key_esc_texture = preload("res://assets/ui/buttons/key_esc.png")
var key_h_texture = preload("res://assets/ui/buttons/key_h.png")
var xbox_rb_texture = preload("res://assets/ui/buttons/xbox_rb.png")

func _ready():
	original_position = position
	visible = false
	_setup_particles()

func _setup_particles():
	if not particle_effect:
		return
		
	if not particle_effect.process_material:
		var material = ParticleProcessMaterial.new()
		particle_effect.process_material = material
	
	var material = particle_effect.process_material as ParticleProcessMaterial
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 25.0
	material.gravity = Vector3(0, 15, 0)
	material.scale_min = 0.1
	material.scale_max = 0.4
	material.color = Color(0.4, 0.6, 0.9, 0.6)
	
	particle_effect.amount = 15
	particle_effect.lifetime = 3.0

func _start_glow_effect():
	if glow_tween:
		glow_tween.kill()
		
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(border_highlight, "modulate:a", 0.5, 2.0).set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(border_highlight, "modulate:a", 0.8, 2.0).set_trans(Tween.TRANS_SINE)

func _stop_glow_effect():
	if glow_tween:
		glow_tween.kill()

func update_gamepad_mode(new_gamepad_mode: bool):
	gamepad_mode = new_gamepad_mode
	update_display()

func update_player_turn(new_is_player_turn: bool):
	is_player_turn = new_is_player_turn
	update_display()

func update_cards_available(new_has_cards: bool):
	has_cards = new_has_cards
	update_display()

func update_display():
	if gamepad_mode:
		play_icon.texture = xbox_a_texture
		play_label.text = "Play card"
		
		end_icon.texture = xbox_b_texture
		end_label.text = "End turn"
		
		restart_icon.texture = xbox_x_texture
		restart_label.text = "Restart game"
		
		challenge_icon.texture = xbox_y_texture
		challenge_label.text = "Challenge Hub"
		
		options_icon.texture = xbox_menu_texture
		options_label.text = "Options menu"
		
		main_menu_icon.texture = xbox_back_texture
		main_menu_label.text = "Main menu"

		show_controls_icon.texture = xbox_rb_texture
		show_controls_label.text = "Show/Hide controls panel"
	else:
		play_icon.texture = mouse_click_texture
		play_label.text = "Play card"
		
		end_icon.texture = key_space_texture
		end_label.text = "End turn"
		
		restart_icon.texture = key_r_texture
		restart_label.text = "Restart game"
		
		challenge_icon.texture = key_c_texture
		challenge_label.text = "Challenge Hub"
		
		options_icon.texture = key_tab_texture
		options_label.text = "Options menu"
		
		main_menu_icon.texture = key_esc_texture
		main_menu_label.text = "Main menu"
		
		show_controls_icon.texture = key_h_texture
		show_controls_label.text = "Show/Hide controls panel"
	
	play_hint.visible = is_player_turn and has_cards
	end_hint.visible = is_player_turn
	restart_hint.visible = true
	challenge_hint.visible = true
	options_hint.visible = true
	main_menu_hint.visible = true
	show_controls_hint.visible = true

func toggle_visibility():
	is_panel_hidden = !is_panel_hidden
	
	if toggle_tween:
		toggle_tween.kill()
	
	_stop_glow_effect()
	particle_effect.emitting = false
	
	toggle_tween = create_tween()
	toggle_tween.set_parallel(true)
	
	if is_panel_hidden:
		toggle_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
		toggle_tween.tween_property(self, "scale", Vector2(0.7, 0.7), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		toggle_tween.tween_property(self, "position:y", original_position.y + 30, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
		await toggle_tween.finished
		visible = false
	else:
		visible = true
		modulate.a = 0.0
		scale = Vector2(0.7, 0.7)
		position.y = original_position.y + 30
		
		toggle_tween.tween_property(self, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		toggle_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		toggle_tween.tween_property(self, "position:y", original_position.y, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		await toggle_tween.finished
		
		_start_glow_effect()
		particle_effect.emitting = true
		get_tree().create_timer(1.5).timeout.connect(func(): particle_effect.emitting = false)
		
		var bounce_tween = create_tween()
		bounce_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
		bounce_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func force_show():
	if toggle_tween:
		toggle_tween.kill()
	
	_stop_glow_effect()
	is_panel_hidden = false
	visible = true
	modulate.a = 1.0
	scale = Vector2(1.0, 1.0)
	position = original_position

func force_hide():
	if toggle_tween:
		toggle_tween.kill()
	
	_stop_glow_effect()
	particle_effect.emitting = false
	is_panel_hidden = true
	visible = false
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	position = original_position

func show_with_animation():
	if not is_panel_hidden:
		visible = true
		modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.4)
		_start_glow_effect()

func hide_with_animation():
	_stop_glow_effect()
	particle_effect.emitting = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	visible = false
	is_panel_hidden = true
