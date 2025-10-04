extends Control

@onready var session_info = $MainContainer/HeaderContainer/SessionInfo

@onready var games_played_label = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/BasicStatsContainer/GamesPlayedLabel
@onready var win_rate_label = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/BasicStatsContainer/WinRateLabel
@onready var total_time_label = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/BasicStatsContainer/TotalTimeLabel
@onready var avg_game_time_label = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/BasicStatsContainer/AvgGameTimeLabel

@onready var normal_stats = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/DifficultyContainer/NormalStats
@onready var hard_stats = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/DifficultyContainer/HardStats
@onready var expert_stats = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/DifficultyContainer/ExpertStats

@onready var current_streak_label = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/StreaksContainer/CurrentStreakLabel
@onready var best_streak_label = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/StreaksContainer/BestStreakLabel
@onready var shortest_game_label = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/StreaksContainer/ShortestGameLabel
@onready var longest_game_label = $MainContainer/ContentContainer/LeftPanel/LeftScrollContainer/LeftContent/StreaksContainer/LongestGameLabel

@onready var total_cards_label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CardsOverview/TotalCardsLabel
@onready var favorite_type_label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CardsOverview/FavoriteTypeLabel

@onready var attack_type_label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CardsOverview/TypeBreakdown/AttackTypeLabel
@onready var heal_type_label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CardsOverview/TypeBreakdown/HealTypeLabel
@onready var shield_type_label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CardsOverview/TypeBreakdown/ShieldTypeLabel
@onready var hybrid_type_label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CardsOverview/TypeBreakdown/HybridTypeLabel

@onready var most_used_container = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/MostUsedContainer
@onready var most_effective_container = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/MostEffectiveContainer

@onready var damage_per_game_label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CombatContainer/DamagePerGameLabel
@onready var healing_per_game_label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CombatContainer/HealingPerGameLabel
@onready var shield_per_game_label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CombatContainer/ShieldPerGameLabel
@onready var mana_efficiency_label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CombatContainer/ManaEfficiencyLabel
@onready var jokers_played_label: Label = $MainContainer/ContentContainer/RightPanel/RightScrollContainer/RightContent/CardsOverview/JokersPlayedLabel

@onready var back_button = $MainContainer/ButtonsContainer/BackButton
@onready var refresh_button = $MainContainer/ButtonsContainer/RefreshButton
@onready var reset_button = $MainContainer/ButtonsContainer/ResetButton

@onready var ui_player = $AudioManager/UIPlayer
@onready var hover_player = $AudioManager/HoverPlayer

var statistics_manager: StatisticsManager
var is_transitioning: bool = false

func _ready():
	setup_buttons()
	setup_statistics_manager()
	
	await handle_scene_entrance()
	
	refresh_statistics()
	back_button.grab_focus()

func setup_statistics_manager():
	statistics_manager = get_node("/root/StatisticsManagers")
	if not statistics_manager:
		print("StatisticsManager not found, creating temporary instance")
		statistics_manager = StatisticsManagers.new()
		add_child(statistics_manager)
	
	if statistics_manager.stats_updated.is_connected(refresh_statistics):
		statistics_manager.stats_updated.disconnect(refresh_statistics)
	statistics_manager.stats_updated.connect(refresh_statistics)

func setup_buttons():
	back_button.pressed.connect(_on_back_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	var buttons = [back_button, refresh_button, reset_button]
	for button in buttons:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.focus_entered.connect(_on_button_focus.bind(button))

func handle_scene_entrance():
	await get_tree().process_frame
	
	if TransitionManager and TransitionManager.current_overlay:
		if (TransitionManager.current_overlay.has_method("is_ready") and 
			TransitionManager.current_overlay.is_ready() and 
			TransitionManager.current_overlay.has_method("is_covering") and
			TransitionManager.current_overlay.is_covering()):
			
			await TransitionManager.current_overlay.fade_out(0.3)
		else:
			play_entrance_animation()
	else:
		play_entrance_animation()

func play_entrance_animation():
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)

func refresh_statistics():
	if not statistics_manager:
		print("StatisticsManager not available")
		return
	
	var stats = statistics_manager.get_comprehensive_stats()
	
	var session = stats.session
	session_info.text = "Current session: %d games played (%d won) - %.1f%% win rate" % [
		session.games_played, 
		session.games_won, 
		session.win_rate * 100.0
	]
	
	var basic = stats.basic
	games_played_label.text = "Games Played: %d (%d won, %d lost)" % [basic.games_played, statistics_manager.games_won, statistics_manager.games_lost]
	win_rate_label.text = "Win Rate: %.1f%%" % (basic.win_rate * 100.0)
	total_time_label.text = "Total Play Time: %s" % statistics_manager.format_time(basic.total_play_time)
	avg_game_time_label.text = "Average Game: %s" % statistics_manager.format_time(basic.average_game_time)
	
	var difficulty = stats.difficulty
	normal_stats.text = "NORMAL: %d games (%.1f%% win rate)" % [
		difficulty.normal.played, 
		statistics_manager.get_win_rate_by_difficulty("normal") * 100.0
	]
	hard_stats.text = "HARD: %d games (%.1f%% win rate)" % [
		difficulty.hard.played, 
		statistics_manager.get_win_rate_by_difficulty("hard") * 100.0
	]
	expert_stats.text = "EXPERT: %d games (%.1f%% win rate)" % [
		difficulty.expert.played, 
		statistics_manager.get_win_rate_by_difficulty("expert") * 100.0
	]
	
	var streaks = stats.streaks
	var streak_text = "wins" if streaks.current_win > 0 else "losses"
	var streak_count = streaks.current_win if streaks.current_win > 0 else streaks.current_loss
	current_streak_label.text = "Current Streak: %d %s" % [streak_count, streak_text]
	best_streak_label.text = "Best Win Streak: %d" % streaks.best_win
	
	if basic.games_played > 0:
		if statistics_manager.shortest_game_time < 999999.0:
			shortest_game_label.text = "Fastest Win: %s (%d turns)" % [
				statistics_manager.format_time(statistics_manager.shortest_game_time),
				statistics_manager.shortest_game_turns
			]
		else:
			shortest_game_label.text = "Fastest Win: --"
			
		if statistics_manager.longest_game_time > 0:
			longest_game_label.text = "Longest Game: %s (%d turns)" % [
				statistics_manager.format_time(statistics_manager.longest_game_time),
				statistics_manager.longest_game_turns
			]
		else:
			longest_game_label.text = "Longest Game: --"
	else:
		shortest_game_label.text = "Fastest Win: --"
		longest_game_label.text = "Longest Game: --"
	
	var cards = stats.cards
	total_cards_label.text = "Total Cards Played: %d" % cards.total_played
	favorite_type_label.text = "Favorite Type: %s" % cards.favorite_type.capitalize()
	
	var total_cards = max(1, cards.total_played)
	attack_type_label.text = "Attack: %d (%.1f%%)" % [
		cards.by_type.get("attack", 0),
		float(cards.by_type.get("attack", 0)) / total_cards * 100.0
	]
	heal_type_label.text = "Heal: %d (%.1f%%)" % [
		cards.by_type.get("heal", 0),
		float(cards.by_type.get("heal", 0)) / total_cards * 100.0
	]
	shield_type_label.text = "Shield: %d (%.1f%%)" % [
		cards.by_type.get("shield", 0),
		float(cards.by_type.get("shield", 0)) / total_cards * 100.0
	]
	hybrid_type_label.text = "Hybrid: %d (%.1f%%)" % [
		cards.by_type.get("hybrid", 0),
		float(cards.by_type.get("hybrid", 0)) / total_cards * 100.0
	]
	jokers_played_label.text = "Total Jokers used: %d (%.1f%%)" % [
	cards.jokers_played,
	float(cards.jokers_played) / max(1, cards.total_played) * 100.0
	]
	
	for child in most_used_container.get_children():
		child.queue_free()
	for child in most_effective_container.get_children():
		child.queue_free()
	
	var most_used = cards.most_used
	if most_used.size() == 0:
		var no_data_label = Label.new()
		no_data_label.text = "No card usage data yet"
		no_data_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		no_data_label.add_theme_font_size_override("font_size", 16)
		most_used_container.add_child(no_data_label)
	else:
		for i in range(min(5, most_used.size())):
			var card = most_used[i]
			var label = Label.new()
			label.text = "%d. %s (%d times, %.1f%%)" % [
				i + 1, 
				card.name, 
				card.count, 
				card.percentage
			]
			label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
			label.add_theme_font_size_override("font_size", 16)
			most_used_container.add_child(label)
	
	var most_effective = cards.most_effective
	if most_effective.size() == 0:
		var no_data_label = Label.new()
		no_data_label.text = "No effectiveness data yet (need 5+ uses per card)"
		no_data_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		no_data_label.add_theme_font_size_override("font_size", 16)
		most_effective_container.add_child(no_data_label)
	else:
		for i in range(min(5, most_effective.size())):
			var card = most_effective[i]
			var label = Label.new()
			label.text = "%d. %s (%.1f%% win rate, %d uses)" % [
				i + 1, 
				card.name, 
				card.win_rate * 100.0, 
				card.total_uses
			]
			label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
			label.add_theme_font_size_override("font_size", 16)
			most_effective_container.add_child(label)
	
	var combat = stats.combat
	damage_per_game_label.text = "Damage per Game: %.1f" % combat.damage_per_game
	healing_per_game_label.text = "Healing per Game: %.1f" % combat.healing_per_game
	shield_per_game_label.text = "Shield per Game: %.1f" % combat.shield_per_game
	mana_efficiency_label.text = "Mana Efficiency: %.2f" % combat.mana_efficiency

func _on_back_pressed():
	if is_transitioning:
		return
	
	is_transitioning = true
	play_ui_sound("button_click")
	
	TransitionManager.fade_to_main_menu(0.8)

func _on_refresh_pressed():
	play_ui_sound("button_click")
	refresh_statistics()

func _on_reset_pressed():
	play_ui_sound("button_click")
	show_custom_reset_dialog()

func show_custom_reset_dialog():
	var dialog = AcceptDialog.new()
	dialog.title = "Reset Statistics"
	dialog.dialog_text = "Are you sure you want to reset all statistics?\nThis action cannot be undone."
	dialog.initial_position = 2
	
	dialog.add_cancel_button("Cancel")
	
	var confirm_button = dialog.get_ok_button()
	confirm_button.text = "Yes, Reset All"
	
	add_child(dialog)
	dialog.popup_centered(Vector2i(400, 150))
	
	dialog.confirmed.connect(_on_reset_confirmed)
	dialog.close_requested.connect(func(): dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())

func _on_reset_confirmed():
	if statistics_manager:
		statistics_manager.reset_statistics()
		refresh_statistics()
		
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 0.8, 0.8, 1), 0.2)
		tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func _on_button_hover(button: Button):
	play_hover_sound()
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	
	if not button.mouse_exited.is_connected(_on_button_unhover):
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_focus(button: Button):
	play_hover_sound()

func play_ui_sound(sound_type: String):
	match sound_type:
		"button_click":
			ui_player.stream = preload("res://audio/ui/button_click.wav")
			ui_player.play()
		_:
			pass

func play_hover_sound():
	pass

func _input(event):
	if is_transitioning:
		return
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_back"):
		_on_back_pressed()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("game_select"):
		if back_button.has_focus():
			_on_back_pressed()
		elif refresh_button.has_focus():
			_on_refresh_pressed()
		elif reset_button.has_focus():
			_on_reset_pressed()

func get_win_rate_color(win_rate: float) -> Color:
	if win_rate >= 0.8:
		return Color(0.2, 1.0, 0.2, 1.0)
	elif win_rate >= 0.6:
		return Color(0.6, 1.0, 0.4, 1.0)
	elif win_rate >= 0.4:
		return Color(1.0, 1.0, 0.4, 1.0)
	elif win_rate >= 0.2:
		return Color(1.0, 0.6, 0.2, 1.0)
	else:
		return Color(1.0, 0.3, 0.3, 1.0)

func _on_stat_hover(stat_type: String):
	#tooltips
	pass
