class_name Formation
extends RefCounted
## Spreads a group move order into one destination per unit, so units don't
## all stack on the clicked point.


## Returns [param count] offsets in a roughly square grid centred on (0, 0),
## [param spacing] apart. Rows are perpendicular to [param facing] (radians),
## so a group moving east forms a line facing east.
static func grid_offsets(count: int, spacing: float, facing: float = 0.0) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	if count <= 0:
		return offsets
	var columns := int(ceil(sqrt(float(count))))
	var rows := int(ceil(float(count) / columns))
	for i in count:
		var col := i % columns
		var row := i / columns
		# Last row may be short: centre it.
		var in_row := columns if row < rows - 1 else count - row * columns
		var x := (col - (in_row - 1) / 2.0) * spacing
		var y := (row - (rows - 1) / 2.0) * spacing
		# x runs across the frontage, y runs front-to-back.
		offsets.append(Vector2(-y, x).rotated(facing))
	return offsets
