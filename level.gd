class_name Level extends Node3D
## The base class for a level

#region Paremeters
## Emmited when a level loops on its track.
## @experimental: Currently only using it for debugging purposes
signal level_looped

## Emited when the player leaves the bounds
signal player_out_of_bounds

## Emitted when the mode is changed
signal mode_changed(prev_mode: LevelEnums.mode ,mode : LevelEnums.mode)

## The mode the level is in
@export var _mode: LevelEnums.mode = LevelEnums.mode.on_rails:
	set(val):
		if val == _mode:
			return
		mode_changed.emit(_mode, val)
		_mode = val


@export var _level_type: LevelEnums.level_type = LevelEnums.level_type.empty:
	set(val):
		assert(_level_type != LevelEnums.level_type.empty, "Level type not assigned. Should not be empty")
		_level_type = val


## The bounds that a player can play in. Defined as a center point in 3D Space and a radius to define it
@export var bounds_dict: Dictionary[Vector3, float]

## The background audio track
@export var _background_track: AudioStream

## Cutscene to play on ready
## @experimental
#@export var _opening_cutscene: Cutscene

## Reference to the game manager
@export var _gm: Node 

## The default rails character
@export var default_rails_character : PackedScene

## The default walking character
@export var default_walk_character : PackedScene

## The path that the player will follow in the rails component
@onready var _player_path_follow: PathFollow3D = get_node_or_null("RailComponent/PlayerPathFollow")

## The events in children
## @experimental
@onready var proximity_events: Array = find_children("*", "ProximityEvent", true)
@onready var camera_events: Array = find_children("*", "CameraEvent", true)

## A resource to keep track of level progression for this level
@export var _progress: LevelProgression

## cached value of where current rail progress
var current_player_progress_ratio: float

## The number 
var path_follows_in_children: Dictionary

## Whether or not the player should be moving while on rails
var move_flag: bool

## Keeps track of every one in level and their rails progress (if any)
# var entities_in_level: Dictionary[Actor, PathFollow3D]
## Used to cache whether or not the player is in bounds
var _player_out_of_bounds: bool
var _last_frame_character_position: Vector3

#endregion


## Sets up the opening cutscene and components, starts background track
func _ready() -> void:
	assert(_progress, "No progress resource assigned. It doesn't make sense to not have a progress measure")
	_gm = Utils.find_game_manager()
	if _background_track:
		if _background_track is AudioStreamOggVorbis or _background_track is AudioStreamWAV:
			_background_track.loop = true
			
		Music.play_track(_background_track)
		
	#if _opening_cutscene:
		#_gm.start_event(_opening_cutscene)
	mode_changed.connect(_on_mode_changed)
	_progress.load_progress(self)
	_set_bounds()

## Starts default event
func start_event():
	if not _gm:
		push_error("No GameManager Found. Cannot Operate like this")
		return
	_gm.start_event(self)

## Moves things on rails, if allowed
func _physics_process(delta: float) -> void:
	if not _gm.player.character:
		return
	if move_flag:
		_move_on_rail(_player_path_follow, _gm.player.character._rail_speed, delta)
	_handle_player_in_bounds()
	
## Returns if same mode as player
func _player_and_level_are_same_mode() -> bool:
	return _gm.player.character.get_mode() == _mode

## Childs player to rail component
func _assign_player_to_rail():
	assert(_player_path_follow)
	_player_path_follow.progress = 0
	_gm.player.character.reparent(_player_path_follow)
	print("Character %s assigned to rail" , _gm.player.character)

func _unassign_player_from_rail():
	assert(_player_path_follow)
	_gm.player.character.reparent(_gm)

## Loads a player to the level
func _load_player_in_level(_character: PackedScene) -> CharacterBody3D:
	var _updated_character = _character.instantiate()
	if not File.progress.current_character or File.progress.current_character != _updated_character:
		print("No character loaded in the file system. Loading ", _updated_character.name)
		File.progress.current_character = _updated_character
	Utils.print("Loaded %s in %s" % [File.progress.current_character.name, self.name])
	
	File.progress.current_character.mode_changed.connect(_on_character_mode_changed)
	File.progress.current_character.update_mode(_mode as Enums.mode)
	return File.progress.current_character

## Moves player along the provided rail path
func _move_on_rail(_rail_path: PathFollow3D, rail_speed: float, delta: float):
	if not _player_path_follow:
		print("Cannot move player on rails where none exist")
		return
	current_player_progress_ratio = _rail_path.progress_ratio
	_rail_path.progress += rail_speed * delta
	if _rail_path.progress_ratio < current_player_progress_ratio:
		print("Level looping around")
		level_looped.emit()
		current_player_progress_ratio = _rail_path.progress_ratio

## The event to run
func run_event(_event_manager):
	match _mode:
		LevelEnums.mode.on_rails:
			_default_rails_setup(_event_manager)
		LevelEnums.mode.free:
			_default_free_setup(_event_manager)
		_:
			assert(false, "No mode selected. How did you even do that?")
	
	
## if run_event not provided in inherited children, this is called when mode is on rails
func _default_rails_setup(_event_manager):
	_event_manager.load_player(_load_player_in_level(default_rails_character))
	_assign_player_to_rail()
	_event_manager.snap_player_to_position(Vector3.ZERO)
	move_flag = true
	_gm.end_event()

## if run_event not provided in inherited children, this is called when mode is free
func _default_free_setup(_event_manager):
	_event_manager.load_player(_load_player_in_level(default_walk_character))
	_event_manager.snap_player_to_position(Vector3.ZERO)
	move_flag = false
	_gm.end_event()

func _switch_mode_rails():
	_gm.player.character.update_mode(LevelEnums.mode.on_rails)
	_assign_player_to_rail()
	
func _switch_mode_free():
	move_flag = false
	_gm.player.character.update_mode(LevelEnums.mode.free)
	_unassign_player_from_rail()

func _on_mode_changed(_prev_mode: LevelEnums.mode, mode: LevelEnums.mode):
	match mode:
		LevelEnums.mode.on_rails:
			_switch_mode_rails()
		LevelEnums.mode.free:
			_switch_mode_free()
		_:
			assert(false, "Not even sure how you managed to do this.")

## The sequence of events that should happen when the Player has changed modes.[br]
## By default, updates the level mode, but it should be overwritten on a per-level basis for events that should follow the change.
## @experimental
func _on_character_mode_changed(new_mode: LevelEnums.mode):
	update_level_mode(new_mode)

## Updates the mode that the character is in
func update_character_mode(new_mode: LevelEnums.mode):
	_gm.player.character.update_mode(new_mode)

## Updates this level's current mode.
func update_level_mode(new_mode: LevelEnums.mode):
	_mode = new_mode

func _handle_player_in_bounds():
	if _mode != LevelEnums.mode.free:
		return
	if _player_in_bounds():
		return
	_reset_player_to_bounds()
	
## @experimental TODO
func _player_in_bounds() -> bool:
	for bound: Vector3 in bounds_dict:
		if abs(_gm.player.character.global_position.distance_squared_to(bound)) < bounds_dict[bound]:
			_player_out_of_bounds = false
			return true
	if !_player_out_of_bounds:
		_player_out_of_bounds = true
		player_out_of_bounds.emit()
	return false

## @experimental
## is this an event? TODO
func _reset_player_to_bounds():
	_last_frame_character_position = _gm.player.character.global_position
	#assert(_gm.player.character.animation_component, "Can't reset bounds on character that doesn't have the animation component")

## @experimental Might force the bounds fit around a mesh with an assert instead of passing it in
func _set_bounds(mesh: MeshInstance3D = null):
	if !bounds_dict.is_empty() or !mesh:
		printerr("Mesh not set or dictionary had things in it already")
		return
	var aabb: AABB = mesh.get_aabb()
	var center: Vector3 = aabb.position + aabb.size / 2
	bounds_dict[center] = center.x

	
	
	
	
