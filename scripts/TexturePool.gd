extends Node

var texture_cache: Dictionary = {}
var is_preloading: bool = false

const CARD_ILLUSTRATIONS_FOLDER = "res://assets/card_illustrations/"
const JOKER_ILLUSTRATIONS_FOLDER = "res://assets/joker_illustrations/"
const CARD_IMAGES_COUNT = 10
const JOKER_IMAGES_COUNT = 5
const IMAGE_EXTENSION = ".jpg"

func _ready():
	preload_all_textures()

func preload_all_textures():
	if is_preloading:
		return
	
	is_preloading = true
	
	_preload_folder_textures(CARD_ILLUSTRATIONS_FOLDER, CARD_IMAGES_COUNT)
	_preload_folder_textures(JOKER_ILLUSTRATIONS_FOLDER, JOKER_IMAGES_COUNT)
	
	is_preloading = false

func _preload_folder_textures(folder: String, count: int):
	for i in range(1, count + 1):
		var image_path = folder + str(i) + IMAGE_EXTENSION
		if not texture_cache.has(image_path):
			var texture = load(image_path)
			if texture:
				texture_cache[image_path] = texture

func get_texture(folder: String, index: int, extension: String = IMAGE_EXTENSION) -> Texture2D:
	var image_path = folder + str(index) + extension
	
	if texture_cache.has(image_path):
		return texture_cache[image_path]
	
	var texture = load(image_path)
	if texture:
		texture_cache[image_path] = texture
		return texture
	
	return null

func get_random_card_texture() -> Texture2D:
	var random_index = randi() % CARD_IMAGES_COUNT + 1
	return get_texture(CARD_ILLUSTRATIONS_FOLDER, random_index)

func get_random_joker_texture() -> Texture2D:
	var random_index = randi() % JOKER_IMAGES_COUNT + 1
	return get_texture(JOKER_ILLUSTRATIONS_FOLDER, random_index)

func clear_cache():
	texture_cache.clear()

func get_cache_size() -> int:
	return texture_cache.size()
