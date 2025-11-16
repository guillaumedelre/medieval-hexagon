extends Node

@export var TILE_SIZE: float = 1.0


## Renvoie un coin d'hexagone orienté "pointy top"
func hex_corner(radius: float, corner: int) -> Vector3:
	var angle_deg: float = 60.0 * float(corner) - 30.0
	var rad: float = deg_to_rad(angle_deg)
	return Vector3(
		radius * cos(rad),
		0.0,
		radius * sin(rad)
	)


## Axial → world
func axial_to_world(q: int, r: int) -> Vector3:
	var x: float = TILE_SIZE * sqrt(3.0) * (float(q) + float(r) * 0.5)
	var z: float = TILE_SIZE * 1.5 * float(r)
	return Vector3(x, 0.0, z)


## World → axial
func world_to_axial(world: Vector3) -> Vector2:
	var qf: float = (sqrt(3.0) / 3.0 * world.x - 1.0 / 3.0 * world.z) / TILE_SIZE
	var rf: float = (2.0 / 3.0 * world.z) / TILE_SIZE
	return _cube_round(qf, -qf - rf, rf)


## Cube rounding
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

	# Conversion finale en entiers proprement typés
	return Vector2(int(rx), int(rz))
