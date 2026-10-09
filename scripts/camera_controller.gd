extends Camera2D

func _ready() -> void:
	# 使用房间硬切，关闭引擎内置平滑，避免镜头额外漂移。
	position_smoothing_enabled = false
	make_current()


func snap_to_room(room_bounds: Rect2) -> void:
	# 把镜头限制并居中到当前房间，实现蔚蓝式短房间硬切。
	limit_left = int(room_bounds.position.x)
	limit_top = int(room_bounds.position.y)
	limit_right = int(room_bounds.end.x)
	limit_bottom = int(room_bounds.end.y)
	position = room_bounds.get_center()
	reset_smoothing()
