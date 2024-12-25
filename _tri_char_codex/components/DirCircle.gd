tool
extends Node2D


const R = 10.0
const CIRCLE = PoolVector2Array([
	Vector2(R,      0.0),
	Vector2(R*0.7,  R*0.7),
	Vector2(0.0,    R),
	Vector2(-R*0.7, R*0.7),
	Vector2(-R,     0.0),
	Vector2(-R*0.7, -R*0.7),
	Vector2(0.0,    -R),
	Vector2(R*0.7,  -R*0.7),
	Vector2(R,      0.0),
	Vector2(R*0.7,  R*0.7)
])

var point_to : Vector2 = Vector2() setget set_point, get_point


func set_point(value : Vector2):
	point_to = value
	update()

func get_point() -> Vector2:
	return point_to


func _draw():
	draw_polyline(CIRCLE, Color(0,0,0), 2.75)
	draw_polyline(CIRCLE, Color(1,1,1), 1.0)
	draw_line(Vector2(), point_to * 10.0, Color(1,1,1), 1.0)
