class_name BattleMap
extends Node2D
## Battle terrain built from a data/battles map definition: draws the ground
## and obstacles (placeholder shapes) and bakes a navigation polygon so units
## path around obstacles via NavigationServer2D.

## Emitted once the baked navigation polygon is live on the navigation map
## (one or two physics frames after setup()).
signal navigation_ready

const GRID_STEP := 100.0
const GROUND_COLOR := Color(0.36, 0.45, 0.27)
const GRID_COLOR := Color(0, 0, 0, 0.06)
const BORDER_COLOR := Color(0, 0, 0, 0.5)
const OBSTACLE_COLORS := {
	"building": Color(0.45, 0.40, 0.36),
	"water": Color(0.25, 0.42, 0.55),
}
const OBSTACLE_FALLBACK_COLOR := Color(0.3, 0.3, 0.3)

var size: Vector2 = Vector2(2000, 2000)
var pixels_per_meter: float = 8.0
## Each entry: {"kind": String, "polygon": PackedVector2Array}.
var obstacles: Array[Dictionary] = []

var _region: NavigationRegion2D
var _nav_ready := false
## A walkable point of the baked polygon, used to detect when the navigation
## map is actually serving our region (region updates are asynchronous).
var _nav_probe := Vector2.ZERO


## Configures the map from the "map" object of a battle data file.
func setup(map_data: Dictionary) -> void:
	size = DataLoader.to_vector2(map_data.get("size"), size)
	pixels_per_meter = float(map_data.get("pixels_per_meter", pixels_per_meter))
	obstacles.clear()
	for o: Dictionary in map_data.get("obstacles", []):
		obstacles.append({
			"kind": String(o.get("kind", "")),
			"polygon": DataLoader.to_polygon(o.get("polygon")),
		})
	var agent_radius := float(map_data.get("nav_agent_radius_m", 2.0)) * pixels_per_meter
	_bake_navigation(agent_radius)
	queue_redraw()


func bounds() -> Rect2:
	return Rect2(Vector2.ZERO, size)


func is_navigation_ready() -> bool:
	return _nav_ready


## Waypoints from [param from] to [param to] avoiding obstacles. If [param to]
## is unreachable (inside an obstacle / off the map) the path ends at the
## closest reachable point. Returns an empty path until navigation is ready.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if not _nav_ready:
		return PackedVector2Array()
	return NavigationServer2D.map_get_path(get_world_2d().navigation_map, from, to, true)


func _physics_process(_delta: float) -> void:
	if _nav_ready or _region == null:
		set_physics_process(false)
		return
	var nav_map := get_world_2d().navigation_map
	if NavigationServer2D.map_get_iteration_id(nav_map) == 0:
		return
	if NavigationServer2D.map_get_closest_point_owner(nav_map, _nav_probe) == _region.get_rid():
		_nav_ready = true
		set_physics_process(false)
		navigation_ready.emit()


func _bake_navigation(agent_radius: float) -> void:
	var source := NavigationMeshSourceGeometryData2D.new()
	source.add_traversable_outline(PackedVector2Array([
		Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y),
	]))
	for o in obstacles:
		source.add_obstruction_outline(o.polygon)

	_nav_ready = false
	var nav_poly := NavigationPolygon.new()
	nav_poly.agent_radius = agent_radius
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source)
	if nav_poly.get_polygon_count() == 0:
		push_error("BattleMap: navigation bake produced no walkable area")
		return
	_nav_probe = nav_poly.vertices[nav_poly.get_polygon(0)[0]]

	if _region == null:
		_region = NavigationRegion2D.new()
		_region.name = "NavigationRegion"
		add_child(_region)
	_region.navigation_polygon = nav_poly
	set_physics_process(true)


func _draw() -> void:
	draw_rect(bounds(), GROUND_COLOR)
	var x := GRID_STEP
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), GRID_COLOR)
		x += GRID_STEP
	var y := GRID_STEP
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID_COLOR)
		y += GRID_STEP
	for o in obstacles:
		var poly: PackedVector2Array = o.polygon
		if poly.size() < 3:
			continue
		draw_colored_polygon(poly, OBSTACLE_COLORS.get(o.kind, OBSTACLE_FALLBACK_COLOR))
		var outline := poly.duplicate()
		outline.append(poly[0])
		draw_polyline(outline, BORDER_COLOR, 2.0)
	draw_rect(bounds(), BORDER_COLOR, false, 4.0)
