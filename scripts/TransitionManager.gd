extends Node

var transition_scene = preload("res://scenes/TransitionOverlay.tscn")
var current_overlay = null
var is_creating_overlay = false

func _ready():
	create_overlay.call_deferred()

func create_overlay():
	if current_overlay or is_creating_overlay:
		return
		
	is_creating_overlay = true
	
	current_overlay = transition_scene.instantiate()
	
	if not current_overlay:
		push_error("Failed to instantiate TransitionOverlay")
		is_creating_overlay = false
		return
	
	get_tree().root.add_child.call_deferred(current_overlay)
	
	await wait_for_overlay_ready()
	
	is_creating_overlay = false

func wait_for_overlay_ready():
	var max_attempts = 60
	var attempts = 0
	
	while attempts < max_attempts:
		await get_tree().process_frame
		
		if current_overlay and current_overlay.is_inside_tree():
			await get_tree().process_frame
			
			if current_overlay.has_method("is_ready") and current_overlay.is_ready():
				current_overlay.instant_clear()
				return true
		
		attempts += 1
	
	push_error("Timeout waiting for TransitionOverlay to be ready")
	return false

func fade_to_scene(scene_path: String, duration: float = 1.0):
	await ensure_overlay_exists()
	
	if not current_overlay or not current_overlay.has_method("is_ready") or not current_overlay.is_ready():
		push_error("TransitionOverlay is not available, changing scene directly")
		get_tree().change_scene_to_file(scene_path)
		return
	
	await current_overlay.fade_in(duration * 0.4)
	
	get_tree().change_scene_to_file(scene_path)

	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	await current_overlay.fade_out(duration * 0.6)

func ensure_overlay_exists():
	if not current_overlay and not is_creating_overlay:
		await create_overlay()
	
	while is_creating_overlay:
		await get_tree().process_frame

func instant_to_scene(scene_path: String):
	await ensure_overlay_exists()
	
	if current_overlay and current_overlay.has_method("is_ready") and current_overlay.is_ready():
		current_overlay.instant_black()
	
	get_tree().change_scene_to_file(scene_path)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	if current_overlay and current_overlay.has_method("is_ready") and current_overlay.is_ready():
		await current_overlay.fade_out(0.5)

func fade_to_main_menu(duration: float = 1.0):
	await ensure_overlay_exists()
	
	if not current_overlay or not current_overlay.has_method("is_ready") or not current_overlay.is_ready():
		push_error("TransitionOverlay is not available, changing scene directly")
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	
	await current_overlay.fade_in(duration * 0.5)
	while current_overlay and not current_overlay.is_covering():
		await get_tree().process_frame
	
	var scene_path = "res://scenes/MainMenu.tscn"
	var loader = ResourceLoader.load_threaded_request(scene_path)
	while ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	
	var scene = ResourceLoader.load_threaded_get(scene_path)
	get_tree().change_scene_to_packed(scene)
	
	var main_menu = get_tree().current_scene
	if main_menu and not main_menu.is_inside_tree():
		await main_menu.tree_entered
	
	if main_menu and main_menu.has_method("on_scene_entered"):
		await get_tree().create_timer(0.1).timeout
		main_menu.on_scene_entered()
	
	await current_overlay.fade_out(duration * 0.7)

func recreate_overlay():
	if current_overlay:
		current_overlay.queue_free()
		current_overlay = null
	
	is_creating_overlay = false
	await create_overlay()
