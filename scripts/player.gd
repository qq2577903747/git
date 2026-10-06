extends CharacterBody2D

# 水平移动参数可在检查器中直接调整。
@export_group("水平移动")
@export_range(0.0, 600.0, 1.0) var ground_speed := 360.0
@export_range(0.0, 600.0, 1.0) var air_speed := 360.0
@export_range(0.0, 5000.0, 10.0) var ground_acceleration := 4000.0
@export_range(0.0, 3000.0, 10.0) var air_acceleration := 2000.0
@export_range(0.0, 3000.0, 10.0) var ground_friction := 1600.0
@export_range(0.0, 500.0, 1.0) var air_friction := 80.0

# 重力与最大下落速度。
const GRAVITY := 1400.0
const MAX_FALL_SPEED := 700.0
# 满跳初速与松手截断速度。Godot 的 Y 轴向下，所以向上是负数。
const JUMP_VELOCITY := -560.0
const JUMP_CUT_VELOCITY := -300.0
# 跳跃辅助窗口：土狼时间与输入缓冲。
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.1

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_apply_horizontal_movement(delta)
	_apply_gravity(delta)
	_try_jump()
	_apply_jump_cut()

	move_and_slide()


func _update_timers(delta: float) -> void:
	# 落地刷新土狼时间，离开地面后逐帧减少。
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	# 按下跳跃写入缓冲，未按下时逐帧减少。
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)


func _apply_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if is_on_floor():
		if direction != 0.0:
			velocity.x = _approach(velocity.x, direction * ground_speed, ground_acceleration * delta)
		else:
			velocity.x = _approach(velocity.x, 0.0, ground_friction * delta)
	else:
		if direction != 0.0:
			velocity.x = _approach(velocity.x, direction * air_speed, air_acceleration * delta)
		else:
			velocity.x = _approach(velocity.x, 0.0, air_friction * delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	else:
		velocity.y = 0.0


func _try_jump() -> void:
	# 土狼时间允许离地瞬间起跳，输入缓冲允许落地前提前按下。
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0


func _apply_jump_cut() -> void:
	# 上升途中松开跳跃就截断竖直速度，实现长按高跳、短按低跳。
	if Input.is_action_just_released("jump") and velocity.y < JUMP_CUT_VELOCITY:
		velocity.y = JUMP_CUT_VELOCITY


func _approach(current: float, target: float, amount: float) -> float:
	if current < target:
		return minf(current + amount, target)
	return maxf(current - amount, target)


func _draw() -> void:
	# 占位外观：与 32×48 碰撞盒一致的蓝色矩形。
	draw_rect(Rect2(-16.0, -24.0, 32.0, 48.0), Color(0.28, 0.62, 0.98))
