extends Node
class_name HexMath

@export var TILE_SIZE: float = 1.0

func axial_to_world(q: int, r: int) -> Vector3:
	var x: float = TILE_SIZE * sqrt(3.0) * (float(q) + float(r) / 2.0)
	var z: float = TILE_SIZE * 1.5 * float(r)
	return Vector3(x, 0.0, z)
	
func world_to_axial(world: Vector3) -> Vector2:
	var qf: float = (sqrt(3.0) / 3.0 * world.x - 1.0 / 3.0 * world.z) / TILE_SIZE
	var rf: float = (2.0 / 3.0 * world.z) / TILE_SIZE
	return _cube_round(qf, -qf - rf, rf)
	
func _cube_round(x: float, y: float, z: float) -> Vector2:
	var rx: float = round(x)
	var ry: float = round(y)
	var rz: float = round(z)
	var x_diff: float = abs(rx - x)
	var y_diff: float = abs(ry - y)
	var z_diff: float = abs(rz - z)
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))
