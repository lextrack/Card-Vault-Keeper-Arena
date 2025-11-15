extends Node

var _tree: SceneTree
var menu_music_player: AudioStreamPlayer
var challenge_music_player: AudioStreamPlayer
var game_music_player: AudioStreamPlayer
var current_music_type: String = ""
var active_tweens: Array = []

var game_music_playlist: Array = []
var current_playlist_index: int = 0
var shuffled_playlist: Array = []
var is_playlist_mode: bool = false

var default_menu_volume: float = -4.0
var default_challenge_volume: float = -4.0  
var default_game_volume: float = -4.0

var master_music_volume: float = 1.0
var music_muted: bool = false
var difficulty_music_player: AudioStreamPlayer
var default_difficulty_volume: float = -1.0

func _ready():
	_tree = get_tree()
	_create_music_players()
	_load_music_settings()

func _load_music_settings():
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err == OK:
		var master_volume = config.get_value("audio", "master_volume", 1.0)
		var music_volume = config.get_value("audio", "music_volume", 1.0)
		music_muted = config.get_value("audio", "music_muted", false)
		
		master_music_volume = master_volume * music_volume
		_update_all_volumes()

func _create_music_players():
	menu_music_player = AudioStreamPlayer.new()
	menu_music_player.name = "GlobalMenuMusicPlayer"
	menu_music_player.volume_db = default_menu_volume
	menu_music_player.bus = "Music"
	menu_music_player.finished.connect(_on_menu_music_finished)
	add_child(menu_music_player)
	
	challenge_music_player = AudioStreamPlayer.new()
	challenge_music_player.name = "GlobalChallengeMusicPlayer"
	challenge_music_player.volume_db = default_challenge_volume
	challenge_music_player.bus = "Music"
	challenge_music_player.finished.connect(_on_challenge_music_finished)
	add_child(challenge_music_player)
	
	game_music_player = AudioStreamPlayer.new()
	game_music_player.name = "GlobalGameMusicPlayer"
	game_music_player.volume_db = default_game_volume
	game_music_player.bus = "Music"
	game_music_player.finished.connect(_on_game_music_finished)
	add_child(game_music_player)
	
	difficulty_music_player = AudioStreamPlayer.new()
	difficulty_music_player.name = "GlobalDifficultyMusicPlayer"
	difficulty_music_player.volume_db = default_difficulty_volume
	difficulty_music_player.bus = "Music"
	difficulty_music_player.finished.connect(_on_difficulty_music_finished)
	add_child(difficulty_music_player)
	
func _on_difficulty_music_finished():
	if current_music_type == "difficulty" and difficulty_music_player.stream:
		difficulty_music_player.play()

func _on_menu_music_finished():
	if current_music_type == "menu" and menu_music_player.stream:
		menu_music_player.play()

func _on_challenge_music_finished():
	if current_music_type == "challenge" and challenge_music_player.stream:
		challenge_music_player.play()

func _on_game_music_finished():
	if current_music_type == "game" and is_playlist_mode:
		_play_next_in_playlist()
	elif current_music_type == "game" and game_music_player.stream:
		game_music_player.play()

func set_master_music_volume(volume: float):
	master_music_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

func get_master_music_volume() -> float:
	return master_music_volume

func set_music_muted(muted: bool):
	music_muted = muted
	_update_all_volumes()

func is_music_muted() -> bool:
	return music_muted

func _update_all_volumes():
	var volume_multiplier = 0.0 if music_muted else master_music_volume
	
	if menu_music_player:
		menu_music_player.volume_db = _calculate_final_volume(default_menu_volume, volume_multiplier)
	
	if challenge_music_player:
		challenge_music_player.volume_db = _calculate_final_volume(default_challenge_volume, volume_multiplier)
	
	if game_music_player:
		game_music_player.volume_db = _calculate_final_volume(default_game_volume, volume_multiplier)
	
	if difficulty_music_player:
		difficulty_music_player.volume_db = _calculate_final_volume(default_difficulty_volume, volume_multiplier)

func _calculate_final_volume(base_volume: float, multiplier: float) -> float:
	if multiplier <= 0.0:
		return -80.0
	
	var volume_adjustment = 20.0 * log(multiplier) / log(10.0)
	return base_volume + volume_adjustment

func set_menu_volume(volume_db: float):
	default_menu_volume = volume_db
	if menu_music_player:
		menu_music_player.volume_db = _calculate_final_volume(default_menu_volume, master_music_volume if not music_muted else 0.0)

func set_challenge_volume(volume_db: float):
	default_challenge_volume = volume_db
	if challenge_music_player:
		challenge_music_player.volume_db = _calculate_final_volume(default_challenge_volume, master_music_volume if not music_muted else 0.0)

func set_game_volume(volume_db: float):
	default_game_volume = volume_db
	if game_music_player:
		game_music_player.volume_db = _calculate_final_volume(default_game_volume, master_music_volume if not music_muted else 0.0)

func set_menu_music_stream(stream: AudioStream):
	if menu_music_player and not menu_music_player.stream:
		menu_music_player.stream = stream

func set_challenge_music_stream(stream: AudioStream):
	if challenge_music_player:
		challenge_music_player.stream = stream

func set_game_music_playlist(playlist: Array):
	if playlist.size() == 0:
		return
		
	game_music_playlist = playlist.duplicate()
	is_playlist_mode = playlist.size() > 1
	
	if is_playlist_mode:
		_shuffle_playlist()
	else:
		game_music_player.stream = playlist[0]

func set_game_music_stream(stream: AudioStream):
	if not stream:
		return
		
	game_music_playlist = [stream]
	is_playlist_mode = false
	game_music_player.stream = stream

func _shuffle_playlist():
	shuffled_playlist = game_music_playlist.duplicate()
	shuffled_playlist.shuffle()
	current_playlist_index = 0

func _play_next_in_playlist():
	if not is_playlist_mode or shuffled_playlist.size() == 0:
		return
		
	if current_playlist_index >= shuffled_playlist.size():
		_shuffle_playlist()
	
	var next_stream = shuffled_playlist[current_playlist_index]
	current_playlist_index += 1
	
	_transition_to_next_track(next_stream)

func _transition_to_next_track(next_stream: AudioStream):
	if not game_music_player:
		return
		
	var current_volume = game_music_player.volume_db
	
	_kill_all_tweens()
	
	var fade_out_tween = create_tween()
	active_tweens.append(fade_out_tween)
	fade_out_tween.tween_property(game_music_player, "volume_db", -60.0, 0.3)
	await fade_out_tween.finished
	
	game_music_player.stream = next_stream
	game_music_player.play()
	
	var fade_in_tween = create_tween()
	active_tweens.append(fade_in_tween)
	fade_in_tween.tween_property(game_music_player, "volume_db", current_volume, 0.5)

func start_menu_music(fade_duration: float = 1.5):
	if current_music_type == "menu" and menu_music_player and menu_music_player.playing:
		return

	if current_music_type == "game" and game_music_player and game_music_player.playing:
		stop_all_music(0.5)
		await _tree.create_timer(0.3).timeout
	elif current_music_type == "challenge" and challenge_music_player and challenge_music_player.playing:
		stop_all_music(0.5)
		await _tree.create_timer(0.3).timeout
	
	if not menu_music_player or not menu_music_player.stream:
		return
	
	current_music_type = "menu"
	
	menu_music_player.volume_db = -40.0
	menu_music_player.play()
	
	_kill_all_tweens()
	
	var tween = create_tween()
	active_tweens.append(tween)
	var target_volume = _calculate_final_volume(default_menu_volume, master_music_volume if not music_muted else 0.0)
	tween.tween_property(menu_music_player, "volume_db", target_volume, fade_duration)

func start_challenge_music(fade_duration: float = 1.5):
	if current_music_type == "challenge" and challenge_music_player and challenge_music_player.playing:
		return

	stop_all_music(0.5)
	await _tree.create_timer(0.3).timeout
	
	if not challenge_music_player or not challenge_music_player.stream:
		return
	
	current_music_type = "challenge"
	
	challenge_music_player.volume_db = -40.0
	challenge_music_player.play()
	
	_kill_all_tweens()
	
	var tween = create_tween()
	active_tweens.append(tween)
	var target_volume = _calculate_final_volume(default_challenge_volume, master_music_volume if not music_muted else 0.0)
	tween.tween_property(challenge_music_player, "volume_db", target_volume, fade_duration)

func start_game_music(fade_duration: float = 1.5, force_new_track: bool = false):
	if current_music_type == "game" and game_music_player.playing and not force_new_track:
		return
	
	stop_all_music(0.5)
	await _tree.create_timer(0.3).timeout
	
	if is_playlist_mode:
		if force_new_track:
			_shuffle_playlist()
		
		if shuffled_playlist.size() > 0:
			game_music_player.stream = shuffled_playlist[current_playlist_index]
			current_playlist_index += 1
		else:
			return
	elif not game_music_player.stream:
		return
	
	current_music_type = "game"
	
	game_music_player.volume_db = -40.0
	game_music_player.play()
	
	_kill_all_tweens()
	
	var tween = create_tween()
	active_tweens.append(tween)
	var target_volume = _calculate_final_volume(default_game_volume, master_music_volume if not music_muted else 0.0)
	tween.tween_property(game_music_player, "volume_db", target_volume, fade_duration)
	
func set_difficulty_volume(volume_db: float):
	default_difficulty_volume = volume_db
	if difficulty_music_player:
		difficulty_music_player.volume_db = _calculate_final_volume(default_difficulty_volume, master_music_volume if not music_muted else 0.0)

func set_difficulty_music_stream(stream: AudioStream):
	if difficulty_music_player:
		difficulty_music_player.stream = stream

func start_difficulty_music(fade_duration: float = 1.5):
	if current_music_type == "difficulty" and difficulty_music_player and difficulty_music_player.playing:
		return

	stop_all_music(0.5)
	await _tree.create_timer(0.3).timeout
	
	if not difficulty_music_player or not difficulty_music_player.stream:
		return
	
	current_music_type = "difficulty"
	
	difficulty_music_player.volume_db = -40.0
	difficulty_music_player.play()
	
	_kill_all_tweens()
	
	var tween = create_tween()
	active_tweens.append(tween)
	var target_volume = _calculate_final_volume(default_difficulty_volume, master_music_volume if not music_muted else 0.0)
	tween.tween_property(difficulty_music_player, "volume_db", target_volume, fade_duration)

func stop_difficulty_music_for_menu(fade_duration: float = 0.8):
	if current_music_type != "difficulty":
		return
	
	_kill_all_tweens()
	
	var tween = create_tween()
	active_tweens.append(tween)
	tween.tween_property(difficulty_music_player, "volume_db", -60.0, fade_duration)
	
	await tween.finished
	difficulty_music_player.stop()
	current_music_type = ""

func stop_all_music(fade_duration: float = 1.0):
	_kill_all_tweens()
	
	var players_to_stop = []
	
	if menu_music_player and menu_music_player.playing:
		players_to_stop.append(menu_music_player)
	
	if challenge_music_player and challenge_music_player.playing:
		players_to_stop.append(challenge_music_player)
	
	if game_music_player and game_music_player.playing:
		players_to_stop.append(game_music_player)
	
	if difficulty_music_player and difficulty_music_player.playing:
		players_to_stop.append(difficulty_music_player)
	
	if players_to_stop.size() == 0:
		current_music_type = ""
		return
	
	var tween = create_tween()
	active_tweens.append(tween)
	tween.set_parallel(true)
	
	for player in players_to_stop:
		tween.tween_property(player, "volume_db", -60.0, fade_duration)
	
	await tween.finished
	
	for player in players_to_stop:
		player.stop()
	
	current_music_type = ""

func is_difficulty_music_playing() -> bool:
	return current_music_type == "difficulty" and difficulty_music_player and difficulty_music_player.playing

func stop_menu_music_for_game(fade_duration: float = 0.8):
	if current_music_type != "menu":
		return
	
	_kill_all_tweens()
	
	var tween = create_tween()
	active_tweens.append(tween)
	tween.tween_property(menu_music_player, "volume_db", -60.0, fade_duration)
	
	await tween.finished
	menu_music_player.stop()
	current_music_type = ""

func stop_challenge_music_for_menu(fade_duration: float = 0.8):
	if current_music_type != "challenge":
		return
	
	_kill_all_tweens()
	
	var tween = create_tween()
	active_tweens.append(tween)
	tween.tween_property(challenge_music_player, "volume_db", -60.0, fade_duration)
	
	await tween.finished
	challenge_music_player.stop()
	current_music_type = ""

func _kill_all_tweens():
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	active_tweens.clear()

func is_menu_music_playing() -> bool:
	return current_music_type == "menu" and menu_music_player and menu_music_player.playing

func is_challenge_music_playing() -> bool:
	return current_music_type == "challenge" and challenge_music_player and challenge_music_player.playing

func is_game_music_playing() -> bool:
	return current_music_type == "game" and game_music_player and game_music_player.playing

func get_current_music_type() -> String:
	return current_music_type

func get_playlist_info() -> Dictionary:
	return {
		"is_playlist_mode": is_playlist_mode,
		"total_tracks": game_music_playlist.size(),
		"current_index": current_playlist_index,
		"shuffled_size": shuffled_playlist.size(),
		"master_volume": master_music_volume,
		"is_muted": music_muted
	}
