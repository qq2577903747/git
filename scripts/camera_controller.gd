extends Camera2D

# 场景里通过 player_path 指定跟随的玩家节点。
@export var player_path: NodePath
# 垂直死区：玩家偏离镜头中心超过该值时才上下移动。
@export var vertical_deadzone := 64.0
# 水平跟随的指数平滑速度。
@export var horizontal_smoothing := 8.0

@onready var _player: Node2D = get_node_or_null(player_path) as Node2D


func _ready() -> void:
	# 手动控制水平平滑，关闭引擎内置平滑避免叠加。
	position_smoothing_enabled = false
	# 限制镜头范围，防止画面越过关卡边界。
	limit_left = -1280
	limit_right = 1248
	limit_top = 0
	limit_bottom = 960
	make_current()


func _process(delta: float) -> void:
	if _player == null:
		return

	var target := position
	target.x = _player.global_position.x

	# 垂直方向使用死区，避免小幅跳跃造成镜头抖动。
	var delta_y := _player.global_position.y - position.y
	if delta_y > vertical_deadzone:
		target.y = _player.global_position.y - vertical_deadzone
	elif delta_y < -vertical_deadzone:
		target.y = _player.global_position.y + vertical_deadzone

	# 水平方向使用指数平滑。
	var weight := 1.0 - exp(-horizontal_smoothing * delta)
	position.x = lerpf(position.x, target.x, weight)
	position.y = target.y

	_clamp_position_to_limits()


func _clamp_position_to_limits() -> void:
	var viewport_size := get_viewport_rect().size
	var half := viewport_size * 0.5

	# 限制范围小于视口时居中，否则把镜头中心夹在范围内。
	if limit_right - limit_left <= viewport_size.x:
		position.x = (limit_left + limit_right) * 0.5
	else:
		position.x = clampf(position.x, limit_left + half.x, limit_right - half.x)

	if limit_bottom - limit_top <= viewport_size.y:
		position.y = (limit_top + limit_bottom) * 0.5
	else:
		position.y = clampf(position.y, limit_top + half.y, limit_bottom - half.y)
