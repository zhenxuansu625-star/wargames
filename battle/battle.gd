extends Node2D
## Battle scene root. Loads the battle data, builds the map and units, steps
## the BattleSim on the fixed-tick BattleClock and renders it.
##
## Time controls live here: Space pauses (the clock stops ticking but orders
## can still be given), +/- change game speed.

const SQUAD_SCENE := preload("res://battle/units/squad.tscn")
const DEFAULT_BATTLE: StringName = &"sandbox"
const HELP_TEXT := "LMB select / box   Shift+LMB add   RMB move   Shift+RMB queue move   X stop\nSpace pause   +/- speed   WASD/arrows or MMB drag pan   wheel zoom   Esc menu"

@onready var _map: BattleMap = $Map
@onready var _units_layer: Node2D = $Units
@onready var _markers_layer: Node2D = $Markers
@onready var _camera: BattleCamera = $Camera
@onready var _selection_controller: SelectionController = %SelectionController
@onready var _info_label: Label = %InfoLabel
@onready var _time_controls: TimeControls = %TimeControls
@onready var _pause_overlay: PauseOverlay = %PauseOverlay

var battle_id: StringName
var clock := BattleClock.new()
var sim := BattleSim.new()
var selection := Selection.new()

var _views: Dictionary[StringName, SquadView] = {}


func _ready() -> void:
	battle_id = GameState.pending_battle_id if GameState.pending_battle_id != &"" else DEFAULT_BATTLE
	var data := DataLoader.load_entry("battles", battle_id)
	_build(data)

	selection.changed.connect(_on_selection_changed)
	_selection_controller.sim = sim
	_selection_controller.selection = selection
	_selection_controller.camera = _camera
	_selection_controller.move_requested.connect(_on_move_requested)
	_time_controls.pause_pressed.connect(toggle_pause)
	_time_controls.speed_step_requested.connect(step_speed)
	_refresh_time_ui()

	EventBus.battle_started.emit(battle_id)


func _build(data: Dictionary) -> void:
	_map.setup(data.get("map", {}))
	sim.path_finder = _map.find_path
	sim.formation_spacing = float(data.get("formation_spacing_m", 8.0)) * _map.pixels_per_meter

	var template_cache: Dictionary = {}
	for entry: Dictionary in data.get("units", []):
		var template_id := StringName(entry.get("template", ""))
		if not template_cache.has(template_id):
			template_cache[template_id] = DataLoader.load_entry("units", template_id)
		var template: Dictionary = template_cache[template_id]
		var unit := SimUnit.from_template(StringName(entry.get("id", "")), template,
				DataLoader.to_vector2(entry.get("position")), _map.pixels_per_meter)
		unit.side = StringName(entry.get("side", template.get("side", "allies")))
		if entry.has("name"):
			unit.display_name = entry.name
		sim.add_unit(unit)
		_spawn_view(unit)

	_camera.bounds = _map.bounds()
	_camera.position = DataLoader.to_vector2(data.get("camera_start"), _map.bounds().get_center())
	_camera.clamp_to_bounds()


func _spawn_view(unit: SimUnit) -> void:
	var view: SquadView = SQUAD_SCENE.instantiate()
	view.bind(unit)
	_units_layer.add_child(view)
	_views[unit.id] = view


func _process(delta: float) -> void:
	var ticks := clock.advance(delta)
	for i in ticks:
		sim.tick(clock.tick_length())
	var alpha := clock.interpolation_alpha()
	for view: SquadView in _views.values():
		view.sync(alpha)
	_info_label.text = "%s   |   t = %.1f s%s   |   selected: %d\n%s" % [
		data_name(), clock.elapsed_seconds(), "  (paused)" if clock.paused else "",
		selection.size(), HELP_TEXT
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		EventBus.battle_ended.emit(battle_id, &"abandoned")
		GameState.go_to_main_menu()
	elif event.is_action_pressed(&"battle_pause"):
		get_viewport().set_input_as_handled()
		toggle_pause()
	elif event.is_action_pressed(&"game_speed_up"):
		get_viewport().set_input_as_handled()
		step_speed(1)
	elif event.is_action_pressed(&"game_speed_down"):
		get_viewport().set_input_as_handled()
		step_speed(-1)
	elif event.is_action_pressed(&"order_stop"):
		get_viewport().set_input_as_handled()
		sim.issue_stop(selection.ids())


func is_paused() -> bool:
	return clock.paused


func set_paused(paused: bool) -> void:
	if clock.paused == paused:
		return
	clock.paused = paused
	_refresh_time_ui()
	EventBus.battle_paused_changed.emit(paused)


func toggle_pause() -> void:
	set_paused(not clock.paused)


## Steps game speed faster (+1) or slower (-1).
func step_speed(direction: int) -> void:
	var before := clock.speed
	clock.step_speed(direction)
	if clock.speed != before:
		_refresh_time_ui()
		EventBus.battle_speed_changed.emit(clock.speed)


func _refresh_time_ui() -> void:
	_time_controls.show_state(clock.paused, clock.speed)
	_pause_overlay.visible = clock.paused


func data_name() -> String:
	return String(battle_id).capitalize()


func _on_selection_changed() -> void:
	for id in _views:
		_views[id].selected = selection.has(id)


func _on_move_requested(target: Vector2, queued: bool) -> void:
	sim.issue_move(selection.ids(), target, queued)
	var marker := MoveMarker.new()
	marker.position = target
	_markers_layer.add_child(marker)
