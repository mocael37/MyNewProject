extends CharacterBody2D

var home_pos: Vector2
var target_pos: Vector2
var move_speed: float = 28.0
var wait_timer: float = 0.0
var is_waiting: bool = false

# Forced walk (same as believer.gd)
var has_forced_target: bool = false
var forced_target: Vector2 = Vector2.ZERO
signal reached_forced_target

# Animation
var _bob_time: float = 0.0
var _sprite: Sprite2D = null

func _ready():
	var shape := CollisionShape2D.new()
	var cap   := CapsuleShape2D.new()
	cap.radius = 6.0
	cap.height = 10.0
	shape.shape = cap
	add_child(shape)

	_sprite = Sprite2D.new()
	_sprite.texture = load("res://Marcus map.png")
	# Scale the PNG down so Marcus is roughly character-sized on the map
	_sprite.scale    = Vector2(0.09, 0.09)
	_sprite.centered = true
	# Offset so feet sit at node origin (same reference as drawn characters)
	_sprite.position = Vector2(0, -18)
	add_child(_sprite)


func setup(pos: Vector2):
	home_pos = pos
	position  = pos
	_pick_target()


func _process(delta: float):
	_bob_time += delta
	if _sprite:
		# Gentle bob — slightly more energetic when moving
		var bob_amp := 1.5 if is_waiting else 2.5
		_sprite.position.y = -18.0 + sin(_bob_time * 3.2) * bob_amp
		# Cape sway — tiny rotation oscillation
		_sprite.rotation = sin(_bob_time * 2.8) * 0.04


func _physics_process(delta: float):
	if has_forced_target:
		var diff := forced_target - position
		if abs(diff.x) > 2:
			scale.x = sign(diff.x)
		if diff.length() < 10.0:
			has_forced_target = false
			velocity = Vector2.ZERO
			move_and_slide()
			reached_forced_target.emit()
			return
		velocity = diff.normalized() * move_speed
		move_and_slide()
		return

	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
			_pick_target()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var diff := target_pos - position
	if diff.length() < 4.0:
		is_waiting = true
		wait_timer = randf_range(2.0, 5.0)
		velocity   = Vector2.ZERO
	else:
		if abs(diff.x) > 2:
			scale.x = sign(diff.x)
		velocity = diff.normalized() * move_speed

	move_and_slide()


func walk_to(pos: Vector2):
	forced_target    = pos
	has_forced_target = true
	is_waiting       = false


func park():
	has_forced_target = false
	is_waiting        = true
	wait_timer        = 999999.0
	velocity          = Vector2.ZERO


func start_wandering(new_home: Vector2):
	home_pos   = new_home
	is_waiting = false
	wait_timer = 0.0
	_pick_target()


func _pick_target():
	var angle  := randf() * TAU
	var radius := randf_range(14, 55)
	target_pos = home_pos + Vector2(cos(angle), sin(angle)) * radius
