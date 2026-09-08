class_name WFIso
extends RefCounted

const TILE := 32.0

static func project(point: Vector2) -> Vector2:
	return Vector2(point.x - point.y, (point.x + point.y) * 0.5)

static func unproject(point: Vector2) -> Vector2:
	return Vector2(point.y + point.x * 0.5, point.y - point.x * 0.5)

static func ring(center: Vector2, radius: float, segments: int = 48) -> PackedVector2Array:
	var points := disc(center,radius,segments)
	points.append(points[0])
	return points

static func disc(center: Vector2, radius: float, segments: int = 48) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		points.append(project(center + Vector2.from_angle(TAU * i / segments) * radius))
	return points

static func atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var part := AtlasTexture.new()
	part.atlas = texture
	part.region = region
	part.filter_clip = true
	return part
