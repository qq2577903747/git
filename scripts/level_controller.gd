extends Node2D

# 关卡控制器：负责在运行时生成瓦片、连接房间/危险区/出口，并处理重生与淡入淡出。

@onready var solid_layer: TileMapLayer = $SolidLayer
@onready var one_way_layer: TileMapLayer = $OneWayLayer
@onready var camera: Node = $Camera2D
@onready var player: Node2D = $Player
@onready var fade_rect: ColorRect = $FadeLayer/ColorRect

@export var initial_bounds := Rect2(0, 0, 1280, 720)
@export var initial_respawn := Vector2(192, 616)

var _current_bounds := Rect2()
var _respawn_point := Vector2.ZERO
var _respawning := false
var _completed := false


func _ready() -> void:
	_build_level()
	_connect_areas()
	_current_bounds = initial_bounds
	_respawn_point = initial_respawn
	camera.call("snap_to_room", initial_bounds)
	fade_rect.modulate.a = 1.0
	_fade_in()


func _build_level() -> void:
	solid_layer.clear()
	one_way_layer.clear()

	# 外围边界和天花板。
	_add_rect(solid_layer, 0, 319, 0, 1, 1)
	_add_rect(solid_layer, 0, 1, 0, 44, 1)
	_add_rect(solid_layer, 318, 319, 0, 44, 1)

	# 房间之间的三面隔墙。
	_add_rect(solid_layer, 80, 80, 0, 44, 1)
	_add_rect(solid_layer, 160, 160, 0, 44, 1)
	_add_rect(solid_layer, 240, 240, 0, 44, 1)

	# 各房间地面。Room2 和 Room4 的缺口用于落坑。
	_add_rect(solid_layer, 2, 79, 40, 44, 1)
	_add_rect(solid_layer, 81, 99, 40, 44, 1)
	_add_rect(solid_layer, 108, 129, 40, 44, 1)
	_add_rect(solid_layer, 138, 159, 40, 44, 1)
	_add_rect(solid_layer, 161, 239, 40, 44, 1)
	_add_rect(solid_layer, 241, 317, 40, 44, 1)

	# Room1 右侧抬高的台阶，以及通往门洞的单向平台。
	_add_rect(solid_layer, 60, 79, 29, 35, 1)
	_add_rect(one_way_layer, 32, 39, 34, 34, 2)
	_add_rect(one_way_layer, 52, 59, 29, 29, 2)

	# Room3 的墙跳竖井。
	_add_rect(solid_layer, 176, 177, 0, 44, 1)
	_add_rect(solid_layer, 184, 185, 0, 44, 1)
	_add_rect(solid_layer, 186, 239, 13, 17, 1)

	# Room4 入口平台、墙跳竖井和出口平台。
	_add_rect(solid_layer, 241, 250, 13, 17, 1)
	_add_rect(solid_layer, 300, 301, 8, 40, 1)
	_add_rect(solid_layer, 308, 309, 8, 40, 1)
	_add_rect(solid_layer, 310, 317, 13, 17, 1)
	_add_rect(one_way_layer, 250, 258, 33, 33, 2)

	# 门洞。
	_remove_rect(solid_layer, 80, 80, 25, 29)
	_remove_rect(solid_layer, 160, 160, 36, 40)
	_remove_rect(solid_layer, 240, 240, 8, 12)

	# Room3 竖井的底部入口和顶部出口。
	_remove_rect(solid_layer, 176, 177, 36, 40)
	_remove_rect(solid_layer, 184, 185, 8, 12)

	# Room4 竖井的底部入口、顶部出口和深坑。
	_remove_rect(solid_layer, 300, 301, 36, 40)
	_remove_rect(solid_layer, 308, 309, 8, 12)
	_remove_rect(solid_layer, 290, 297, 40, 44)


func _add_rect(layer: TileMapLayer, x0: int, x1: int, y0: int, y1: int, source: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			layer.set_cell(Vector2i(x, y), source, Vector2i.ZERO, 0)


func _remove_rect(layer: TileMapLayer, x0: int, x1: int, y0: int, y1: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			layer.set_cell(Vector2i(x, y), -1)


func _connect_areas() -> void:
	for node in get_tree().get_nodes_in_group("room"):
		if node is Area2D:
			node.body_entered.connect(_on_room_body_entered.bind(node))

	for node in get_tree().get_nodes_in_group("hazard"):
		if node is Area2D:
			node.body_entered.connect(_on_hazard_body_entered)

	for node in get_tree().get_nodes_in_group("exit"):
		if node is Area2D:
			node.body_entered.connect(_on_exit_body_entered)


func _on_room_body_entered(body: Node, room: Area2D) -> void:
	if body != player:
		return
	var bounds: Rect2 = room.get_meta("bounds", _current_bounds)
	var respawn: Vector2 = room.get_meta("respawn", player.global_position)
	_current_bounds = bounds
	_respawn_point = respawn
	camera.call("snap_to_room", bounds)


func _on_hazard_body_entered(body: Node) -> void:
	if body == player:
		_die()


func _on_exit_body_entered(body: Node) -> void:
	if body == player:
		_complete()


func _die() -> void:
	if _respawning:
		return
	_respawning = true
	await _fade_to(1.0, 0.2)
	player.call("respawn", _respawn_point)
	camera.call("snap_to_room", _current_bounds)
	await get_tree().create_timer(0.05).timeout
	await _fade_to(0.0, 0.2)
	_respawning = false


func _complete() -> void:
	if _completed:
		return
	_completed = true
	await _fade_to(1.0, 0.2)
	get_tree().reload_current_scene()


func _fade_in() -> void:
	await _fade_to(0.0, 0.2)


func _fade_to(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", target_alpha, duration)
	await tween.finished
