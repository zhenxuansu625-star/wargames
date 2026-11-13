extends Node2D
## Battle scene root. Loads the battle data, builds the map and units, steps
## the BattleSim on the fixed-tick BattleClock and renders it.
##
## Milestone 2: friendly squads that can be selected and moved with
## pathfinding, plus camera pan/zoom. Pause and orders arrive in Milestone 3.

const SQUAD_SCENE := preload("res://battle/units/squad.tscn")
const DEFAULT_BATTLE: StringName = &"sandbox"
const HELP_TEXT := "LMB select / drag box   Shift+LMB add   RMB move   WASD/arrows or MMB drag pan   wheel zoom   Esc menu"

@onready var _map: BattleMap = $Map
@onready var _units_layer: Node2D = $Units
@onready var _markers_layer: Node2D = $Markers
@onready var _camera: BattleCamera = $Camera
@onready var _selection_controller: SelectionController = %SelectionController
@onready var _info_label: Label = %InfoLabel

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
	_info_label.text = "%s   |   t = %.1f s   |   selected: %d\n%s" % [
		data_name(), clock.elapsed_seconds(), selection.size(), HELP_TEXT
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		EventBus.battle_ended.emit(battle_id, &"abandoned")
		GameState.go_to_main_menu()


func data_name() -> String:
	return String(battle_id).capitalize()


func _on_selection_changed() -> void:
	for id in _views:
		_views[id].selected = selection.has(id)


func _on_move_requested(target: Vector2) -> void:
	sim.order_move(selection.ids(), target)
	var marker := MoveMarker.new()
	marker.position = target
	_markers_layer.add_child(marker)
