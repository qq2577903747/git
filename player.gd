extends CharacterBody2D

# 手感参数：Godot 的 Y 轴向下，所以向上的跳跃速度是负数。
const SPEED := 280.0
const GRAVITY := 1400.0
const JUMP_VELOCITY := -580.0


func _physics_process(delta: float) -> void:
	# 空中持续累加重力，落地时清零竖直速度，避免一直往下加速。
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	# 左右输入直接决定水平速度，返回值是 -1、0 或 1。
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	# 只有踩在地面上时才能起跳，从而禁止空中二段跳。
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 按当前速度移动并处理碰撞。
	move_and_slide()


func _draw() -> void:
	# 占位外观：在角色中心画一个 32×48 的矩形，和碰撞体大小一致。
	draw_rect(Rect2(-16.0, -24.0, 32.0, 48.0), Color(0.28, 0.62, 0.98))
