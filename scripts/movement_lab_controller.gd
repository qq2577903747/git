extends Node2D

# Movement Lab 调试控制器：生成标尺地形，并提供 HUD、重置和分区跳转。
# 只用于移动调参，不参与正式关卡玩法。

const TILE_SIZE := 16.0
const LAB_BOUNDS := Rect2(0.0, 0.0, 1280.0, 720.0)

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var state_label: Label = $HUD/StateLabel

var _solid_layer: TileMapLayer
var _one_way_layer: TileMapLayer
var _current_station := 1
var _measuring_wall_jump := false
var _wall_jump_origin := Vector2.ZERO
var _wall_jump_distance := 0.0

var _station_spawns := {
	1: Vector2(112.0, 616.0),
	2: Vector2(432.0, 616.0),
	3: Vector2(752.0, 616.0),
	4: Vector2(1120.0, 616.0),
}

var _station_names := {
	1: "JUMP",
	2: "DOUBLE",
	3: "DASH",
	4: "WALL",
}


func _ready() -> void:
	player.z_index = 10
	_create_tile_layers()
	_build_geometry()
	_build_markers()
	_build_station_labels()

	camera.limit_left = int(LAB_BOUNDS.position.x)
	camera.limit_top = int(LAB_BOUNDS.position.y)
	camera.limit_right = int(LAB_BOUNDS.end.x)
	camera.limit_bottom = int(LAB_BOUNDS.end.y)
	camera.position = LAB_BOUNDS.get_center()
	camera.make_current()

	_teleport_to_station(1)


func _process(_delta: float) -> void:
	_update_wall_jump_measurement()
	_update_state_label()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_R:
			_teleport_to_station(_current_station)
		KEY_1:
			_teleport_to_station(1)
		KEY_2:
			_teleport_to_station(2)
		KEY_3:
			_teleport_to_station(3)
		KEY_4:
			_teleport_to_station(4)


func _create_tile_layers() -> void:
	var tile_set := preload("res://assets/tileset.tres")

	_solid_layer = TileMapLayer.new()
	_solid_layer.name = "SolidLayer"
	_solid_layer.tile_set = tile_set
	_solid_layer.z_index = -1
	add_child(_solid_layer)

	_one_way_layer = TileMapLayer.new()
	_one_way_layer.name = "OneWayLayer"
	_one_way_layer.tile_set = tile_set
	_one_way_layer.z_index = -1
	add_child(_one_way_layer)


func _build_geometry() -> void:
	# 左右边界、连续地面和 WALL 区的两面墙。
	_add_rect(_solid_layer, 0, 1, 0, 44, 1)
	_add_rect(_solid_layer, 78, 79, 0, 44, 1)
	_add_rect(_solid_layer, 2, 77, 40, 44, 1)

	_add_rect(_solid_layer, 65, 67, 20, 39, 1)
	_add_rect(_solid_layer, 77, 79, 20, 39, 1)

	# DOUBLE 区的一向平台，放在地面以上 192px，验证顶点二跳。
	_add_rect(_one_way_layer, 27, 35, 28, 28, 2)


func _build_markers() -> void:
	var marker_color := Color(0.9, 0.9, 0.9, 0.65)

	# JUMP：以 x=112 为起点，标记 96px 和 192px 的跳跃距离与高度。
	_add_line(Vector2(112.0, 640.0), Vector2(112.0, 448.0), marker_color)
	_add_line(Vector2(112.0, 660.0), Vector2(304.0, 660.0), marker_color)

	# DOUBLE：以 x=432 为起点，标记到 192px 的距离和顶点平台。
	_add_line(Vector2(432.0, 640.0), Vector2(432.0, 448.0), marker_color)
	_add_line(Vector2(432.0, 660.0), Vector2(624.0, 660.0), marker_color)

	# DASH：以 x=752 为起点，标记 160px 冲刺距离。
	_add_line(Vector2(752.0, 640.0), Vector2(912.0, 640.0), marker_color)
	_add_line(Vector2(752.0, 660.0), Vector2(912.0, 660.0), marker_color)

	# WALL：标出两面墙之间 192px 的水平距离。
	_add_line(Vector2(1056.0, 660.0), Vector2(1248.0, 660.0), marker_color)


func _build_station_labels() -> void:
	_add_hud_label("JUMP", Vector2(180.0, 370.0))
	_add_hud_label("DOUBLE", Vector2(500.0, 370.0))
	_add_hud_label("DASH", Vector2(800.0, 370.0))
	_add_hud_label("WALL", Vector2(1120.0, 300.0))
	_add_hud_label("R reset | 1-4 station", Vector2(16.0, 150.0), Color(0.7, 0.8, 1.0))


func _teleport_to_station(index: int) -> void:
	_current_station = index
	_measuring_wall_jump = false
	_wall_jump_distance = 0.0
	player.call("respawn", _station_spawns[index])


func _update_wall_jump_measurement() -> void:
	if Input.is_action_just_pressed("jump") and player.is_on_wall() and not player.is_on_floor():
		_wall_jump_origin = player.global_position
		_measuring_wall_jump = true

	if not _measuring_wall_jump:
		return

	_wall_jump_distance = absf(player.global_position.x - _wall_jump_origin.x)
	if player.is_on_floor():
		_measuring_wall_jump = false


func _update_state_label() -> void:
	var double_used := bool(player.get("_double_jump_used"))
	var dash_timer := float(player.get("_dash_timer"))
	var dash_cooldown := float(player.get("_dash_cooldown_timer"))

	state_label.text = (
		"Station %d  %s\n"
		+ "Vel: %.0f, %.0f\n"
		+ "Floor: %s  Wall: %s\n"
		+ "Double: %s  Dash: %.2f  CD: %.2f\n"
		+ "Wall jump: %.0f px"
	) % [
		_current_station,
		_station_names[_current_station],
		player.velocity.x,
		player.velocity.y,
		str(player.is_on_floor()),
		str(player.is_on_wall()),
		str(double_used),
		dash_timer,
		dash_cooldown,
		_wall_jump_distance,
	]


func _add_rect(layer: TileMapLayer, x0: int, x1: int, y0: int, y1: int, source: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			layer.set_cell(Vector2i(x, y), source, Vector2i.ZERO, 0)


func _add_line(from: Vector2, to: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.width = 2.0
	line.default_color = color
	line.z_index = -2
	add_child(line)


func _add_hud_label(text: String, position: Vector2, color := Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 20)
	hud.add_child(label)
