class_name LevelProgression extends Resource
## Handles the level progression

## A flag set when a level is fully completed
@export var _complete_100_percent: bool
## A flag set when a level is completed 
@export var _level_finished: bool
## The score of the level 
@export var _score: float:
		set(val):
			_score = val
			_score = max(0, _score)
## The high score of the level
var _high_score: float
## The name of the level
@export var name: String
## The UID of the level that this is attached to [br]
## Should be set in the [method Level._ready] or the [method Level.run_event] function of the Level itself
var level_UID: String

var _progression_flags: Dictionary

## Writes progress to the [File] resource
func _save_progress(extra_progress_flags: Dictionary = {}):
	Utils.print("saving progress")
	_update_high_score()
	assert(name, "Name must not be null or empty")
	File.progress.all_levels_progressions[name] = _update_progression_flags(extra_progress_flags)
	Utils.print(File.progress.all_levels_progressions, " progress saved")
	File.progress.available_levels[name] = level_UID
	assert(level_UID, "Level UID must not be null or empty")

# Loads any saved progress. Loads UID of level
func load_progress(level: Level):
	if not level_UID:
		level_UID = str(ResourceUID.path_to_uid(level.scene_file_path))
		Utils.print("Updated UID")
		File.save_game()
	if File.progress.all_levels_progressions.get(name):
		_progression_flags = File.progress.all_levels_progressions[name]
		_complete_100_percent = _progression_flags["complete_100_percent"]
		_level_finished = _progression_flags["level_finished"]
		_high_score = _progression_flags["high_score"]
		Utils.print(_progression_flags, " progress loaded")
		return
	print("Looks like nothing was saved. Is this a new game?")
	
## Called when a level is finished, updates available levels and saves progress
func level_finished():
	_level_finished = true
	_save_progress()

## Updates score
## @experimental: might decide to call this in the score manager
func add_to_score(amt: float):
	_score += amt

## Removes from score
## @experimental: might decide to call this in the score manager
func sub_from_score(amt: float):
	_score -= amt

## Returns current score
## @experimental: might decide to call this in the score manager
func get_score():
	return str(int(_score))

func get_high_score():
	return _high_score

func _update_high_score():
	if _score > _high_score:
		print("Updating high score progress")
		_high_score = _score

func _update_progression_flags(flags: Dictionary = {}) -> Dictionary:
	for key in flags.keys():
		_progression_flags[key] = flags[key]
		
	_progression_flags =  {
		"complete_100_percent": _complete_100_percent,
		"level_finished": _level_finished,
		"high_score": _high_score,
	} 
	return _progression_flags
	
func show_bonus_text():
	# TODO
	pass
