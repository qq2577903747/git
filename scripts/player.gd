extends CharacterBody2D

@export_group("水平移动")
@export_range(0.0, 600.0, 1.0) var ground_speed := 360.0
@export_range(0.0, 600.0, 1.0) var air_speed := 234.0
@export_range(0.0, 5000.0, 10.0) var ground_acceleration := 4000.0
@export_range(0.0, 5000.0, 10.0) var air_acceleration := 4000.0
@export_range(0.0, 3000.0, 10.0) var ground_friction := 1600.0
@export_range(0.0, 500.0, 1.0) var air_friction := 80.0

@export_group("跳跃")
@export_range(-1000.0, 0.0, 10.0) var jump_velocity := -560.0

@export_group("冲刺")
@export_range(0.0, 2000.0, 10.0) var dash_speed := 1066.6667
@export_range(0.01, 1.0, 0.01) var dash_duration := 0.15

@export_group("墙跳")
@export_range(0.0, 1000.0, 10.0) var wall_jump_horizontal := 420.0
@export_range(-1000.0, 0.0, 10.0) var wall_jump_vertical := -520.0
@export_range(0.0, 0.5, 0.01) var wall_jump_coyote_time := 0.08

const GRAVITY := 1400.0
const MAX_FALL_SPEED := 700.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.1
const DASH_COOLDOWN := 0.2
const AIR_PREINPUT_TIME := 0.1

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _air_jump_preinput_timer := 0.0
var _double_jump_used := false
var _wall_coyote_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_available := true
var _dash_direction := 1.0
var _facing := 1.0
var _touching_wall := false
var _wall_normal := 0.0


func _physics_process(delta: float) -> void:
	_update_timers(delta)

	if _dash_timer <= 0.0:
		_try_start_dash()

	if _dash_timer > 0.0:
		_apply_dash(delta)
	else:
		_apply_horizontal_movement(delta)
		_apply_gravity(delta)

		if is_on_floor():
			_try_jump()
		elif not _try_wall_jump():
			_try_jump()

	move_and_slide()
	_update_wall_state(delta)
	_finish_dash_if_ended()


func respawn(spawn_position: Vector2) -> void:
	# 重置位置和全部动作状态，供关卡控制器在死亡后调用。
	global_position = spawn_position
	velocity = Vector2.ZERO
	_dash_timer = 0.0
	_dash_cooldown_timer = 0.0
	_dash_available = true
	_double_jump_used = false
	_air_jump_preinput_timer = 0.0
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_wall_coyote_timer = 0.0
	_touching_wall = false
	_wall_normal = 0.0
	_facing = 1.0


func _update_timers(delta: float) -> void:
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_air_jump_preinput_timer = maxf(_air_jump_preinput_timer - delta, 0.0)

	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		_dash_available = true
		_double_jump_used = false
		_air_jump_preinput_timer = 0.0
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		if _dash_timer > 0.0:
			_air_jump_preinput_timer = AIR_PREINPUT_TIME
		else:
			_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		_facing = direction


func _try_start_dash() -> void:
	if not _dash_available or _dash_cooldown_timer > 0.0 or not Input.is_action_just_pressed("dash"):
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction == 0.0:
		return

	_dash_direction = signf(direction)
	_dash_timer = dash_duration
	_dash_available = false
	# 冲刺是主动动作，清掉土狼时间和地面跳跃缓冲。
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	velocity = Vector2(_dash_direction * dash_speed, 0.0)


func _apply_dash(delta: float) -> void:
	# 冲刺期间保持固定水平速度，并暂停重力。
	_dash_timer -= delta
	velocity.x = _dash_direction * dash_speed
	velocity.y = 0.0

	if _dash_timer <= 0.0:
		# 冲刺结束后才开始冷却。
		_dash_cooldown_timer = DASH_COOLDOWN


func _finish_dash_if_ended() -> void:
	if _dash_timer > 0.0:
		return

	# 冲刺结束仍悬空、存在空中预输入且二跳未耗尽时，自动补一个二跳。
	if not is_on_floor() and _air_jump_preinput_timer > 0.0 and not _double_jump_used:
		velocity.y = jump_velocity
		_double_jump_used = true
		_air_jump_preinput_timer = 0.0


func _try_wall_jump() -> bool:
	if not _touching_wall or _wall_coyote_timer <= 0.0:
		return false
	if not Input.is_action_just_pressed("jump"):
		return false

	var away := -_wall_normal
	if away == 0.0:
		away = -_facing

	_facing = away
	velocity.x = away * wall_jump_horizontal
	velocity.y = wall_jump_vertical
	_dash_available = true
	_dash_cooldown_timer = 0.0
	_jump_buffer_timer = 0.0
	_wall_coyote_timer = 0.0
	return true


func _update_wall_state(delta: float) -> void:
	# 记录上一帧移动后的墙面接触状态，供下一帧判断墙跳。
	if is_on_wall():
		_touching_wall = true
		_wall_normal = get_wall_normal().x
		_wall_coyote_timer = wall_jump_coyote_time
	else:
		_touching_wall = false
		_wall_coyote_timer = maxf(_wall_coyote_timer - delta, 0.0)


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
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		return

	# 二段跳只在空中、未耗尽时按下瞬间触发，不吃地面缓冲。
	if not is_on_floor() and not _double_jump_used and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		_double_jump_used = true
		_air_jump_preinput_timer = 0.0


func _approach(current: float, target: float, amount: float) -> float:
	if current < target:
		return minf(current + amount, target)
	return maxf(current - amount, target)


func _draw() -> void:
	# 占位外观：与 32×48 碰撞盒一致的蓝色矩形。
	draw_rect(Rect2(-16.0, -24.0, 32.0, 48.0), Color(0.28, 0.62, 0.98))
