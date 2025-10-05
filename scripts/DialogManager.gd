class_name DialogManager
extends Node

signal dialog_shown(text: String)
signal sequence_finished

enum State { IDLE, QUEUED, SPEAKING, WAITING_RANDOM }

var current_state: State = State.IDLE
var dialog_queue: Array = []
var dialog_pools: Dictionary = {}

var queue_timer: Timer
var random_timer: Timer

const WORDS_PER_SECOND: float = 4.0
const MIN_DIALOG_TIME: float = 3.5
const RANDOM_DIALOG_MIN: float = 8.0
const RANDOM_DIALOG_MAX: float = 15.0

func _ready():
	setup_timers()

func setup_timers():
	queue_timer = Timer.new()
	queue_timer.one_shot = true
	queue_timer.timeout.connect(_process_next_dialog)
	add_child(queue_timer)
	
	random_timer = Timer.new()
	random_timer.one_shot = true
	random_timer.timeout.connect(_show_random_dialog)
	add_child(random_timer)

func queue_sequence(dialogs: Array):
	if dialogs.is_empty():
		return
	
	dialog_queue.clear()
	dialog_queue = dialogs.duplicate()
	
	if current_state == State.IDLE or current_state == State.WAITING_RANDOM:
		_start_sequence()

func _start_sequence():
	if dialog_queue.is_empty():
		return
	
	current_state = State.QUEUED
	random_timer.stop()
	_process_next_dialog()

func _process_next_dialog():
	if dialog_queue.is_empty():
		current_state = State.IDLE
		sequence_finished.emit()
		_schedule_random_dialog()
		return
	
	current_state = State.SPEAKING
	var next_dialog = dialog_queue.pop_front()
	dialog_shown.emit(next_dialog)
	
	var word_count = next_dialog.split(" ").size()
	var duration = max(MIN_DIALOG_TIME, word_count / WORDS_PER_SECOND)
	
	queue_timer.wait_time = duration
	queue_timer.start()

func on_speaking_finished():
	if current_state == State.SPEAKING and not dialog_queue.is_empty():
		current_state = State.QUEUED
		queue_timer.start()

func _schedule_random_dialog():
	if current_state != State.IDLE:
		return
	
	current_state = State.WAITING_RANDOM
	random_timer.wait_time = randf_range(RANDOM_DIALOG_MIN, RANDOM_DIALOG_MAX)
	random_timer.start()

func _show_random_dialog():
	if dialog_pools.is_empty():
		return
	
	var all_dialogs = []
	for pool_name in dialog_pools:
		all_dialogs.append_array(dialog_pools[pool_name])
	
	if all_dialogs.is_empty():
		return
	
	var random_dialog = all_dialogs[randi() % all_dialogs.size()]
	queue_sequence([random_dialog])

func show_random_dialog():
	_show_random_dialog()

func cleanup():
	queue_timer.stop()
	random_timer.stop()
	dialog_queue.clear()
	current_state = State.IDLE
