class_name ControlsPanel
extends Control

@onready var panel = $Panel
@onready var gameplay_section = $Panel/VBoxContainer/GameplaySection
@onready var menu_section = $Panel/VBoxContainer/MenuSection

@onready var play_hint = $Panel/VBoxContainer/GameplaySection/PlayHint
@onready var end_hint = $Panel/VBoxContainer/GameplaySection/EndHint

@onready var restart_hint = $Panel/VBoxContainer/MenuSection/RestartHint
@onready var challenge_hint = $Panel/VBoxContainer/MenuSection/ChallengeHint
@onready var options_hint = $Panel/VBoxContainer/MenuSection/OptionsHint
@onready var main_menu_hint = $Panel/VBoxContainer/MenuSection/MainMenuHint
@onready var show_controls_hint = $Panel/VBoxContainer/MenuSection/ShowControlsHint

@onready var play_icon = $Panel/VBoxContainer/GameplaySection/PlayHint/PlayIcon
@onready var play_label = $Panel/VBoxContainer/GameplaySection/PlayHint/PlayLabel
@onready var end_icon = $Panel/VBoxContainer/GameplaySection/EndHint/EndIcon
@onready var end_label = $Panel/VBoxContainer/GameplaySection/EndHint/EndLabel

@onready var restart_icon = $Panel/VBoxContainer/MenuSection/RestartHint/RestartIcon
@onready var restart_label = $Panel/VBoxContainer/MenuSection/RestartHint/RestartLabel
@onready var challenge_icon = $Panel/VBoxContainer/MenuSection/ChallengeHint/ChallengeIcon
@onready var challenge_label = $Panel/VBoxContainer/MenuSection/ChallengeHint/ChallengeLabel
@onready var options_label = $Panel/VBoxContainer/MenuSection/OptionsHint/OptionsLabel
@onready var options_icon = $Panel/VBoxContainer/MenuSection/OptionsHint/OptionsIcon
@onready var main_menu_icon = $Panel/VBoxContainer/MenuSection/MainMenuHint/MainMenuIcon
@onready var main_menu_label = $Panel/VBoxContainer/MenuSection/MainMenuHint/MainMenuLabel
@onready var show_controls_icon = $Panel/VBoxContainer/MenuSection/ShowControlsHint/ShowControlsIcon
@onready var show_controls_label = $Panel/VBoxContainer/MenuSection/ShowControlsHint/ShowControlsLabel

var gamepad_mode: bool = false
var is_player_turn: bool = true
var has_cards: bool = false
var is_panel_hidden: bool = true
var toggle_tween: Tween

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
	visible = false

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
	
	toggle_tween = create_tween()
	toggle_tween.set_parallel(true)
	
	if is_panel_hidden:
		toggle_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
		toggle_tween.tween_property(self, "scale", Vector2(0.6, 0.6), 0.3).set_trans(Tween.TRANS_BACK)
		toggle_tween.tween_property(self, "rotation", deg_to_rad(-8), 0.25)
		await toggle_tween.finished
		visible = false
	else:
		visible = true
		modulate.a = 0.0
		scale = Vector2(0.6, 0.6)
		rotation = deg_to_rad(8)
		
		toggle_tween.tween_property(self, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUINT)
		toggle_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_ELASTIC)
		toggle_tween.tween_property(self, "rotation", deg_to_rad(0), 0.3)
		
		await toggle_tween.finished
		var bounce_tween = create_tween()
		bounce_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
		bounce_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)

func force_show():
	if toggle_tween:
		toggle_tween.kill()
	
	is_panel_hidden = false
	visible = true
	modulate.a = 1.0
	scale = Vector2(1.0, 1.0)
	rotation = 0.0

func force_hide():
	if toggle_tween:
		toggle_tween.kill()
	
	is_panel_hidden = true
	visible = false
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)

func show_with_animation():
	if not is_panel_hidden:
		visible = true
		modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.4)

func hide_with_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	visible = false
	is_panel_hidden = true
