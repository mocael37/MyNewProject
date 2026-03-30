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
var _anim: AnimatedSprite2D = null


func _ready():
	var shape := CollisionShape2D.new()
	var cap   := CapsuleShape2D.new()
	cap.radius = 6.0
	cap.height = 10.0
	shape.shape = cap
	add_child(shape)

	_anim = AnimatedSprite2D.new()
	_anim.centered = true

	# Build SpriteFrames from the 4-frame horizontal sprite sheet
	var tex: Texture2D = load("res://Marcus Pixel.png")
	var img: Image     = tex.get_image()
	var frame_w: int   = img.get_width() / 4
	var frame_h: int   = img.get_height()

	var frames := SpriteFrames.new()

	# Walk animation — 4 frames at 8 fps, loops
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 8.0)
	frames.set_animation_loop("walk", true)
	for i in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas  = tex
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		frames.add_frame("walk", atlas)

	# Idle — just the first frame, no loop needed
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 1.0)
	frames.set_animation_loop("idle", false)
	var idle_atlas := AtlasTexture.new()
	idle_atlas.atlas  = tex
	idle_atlas.region = Rect2(0, 0, frame_w, frame_h)
	frames.add_frame("idle", idle_atlas)

	_anim.sprite_frames = frames

	# Scale so Marcus is ~30px tall on the map
	var target_height := 30.0
	_anim.scale = Vector2.ONE * (target_height / float(frame_h))

	# Offset so feet sit at node origin
	_anim.position = Vector2(0, -target_height * 0.5)

	add_child(_anim)
	_anim.play("idle")


func setup(pos: Vector2):
	home_pos = pos
	position  = pos
	_pick_target()


func _physics_process(delta: float):
	if has_forced_target:
		var diff := forced_target - position
		if abs(diff.x) > 2:
			_anim.flip_h = diff.x < 0
		if diff.length() < 10.0:
			has_forced_target = false
			velocity = Vector2.ZERO
			move_and_slide()
			_anim.play("idle")
			reached_forced_target.emit()
			return
		velocity = diff.normalized() * move_speed
		_anim.play("walk")
		move_and_slide()
		return

	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
			_pick_target()
		velocity = Vector2.ZERO
		_anim.play("idle")
		move_and_slide()
		return

	var diff := target_pos - position
	if diff.length() < 4.0:
		is_waiting = true
		wait_timer = randf_range(2.0, 5.0)
		velocity   = Vector2.ZERO
		_anim.play("idle")
	else:
		if abs(diff.x) > 2:
			_anim.flip_h = diff.x < 0
		velocity = diff.normalized() * move_speed
		_anim.play("walk")

	move_and_slide()


func walk_to(pos: Vector2):
	forced_target     = pos
	has_forced_target = true
	is_waiting        = false


func park():
	has_forced_target = false
	is_waiting        = true
	wait_timer        = 999999.0
	velocity          = Vector2.ZERO
	if _anim:
		_anim.play("idle")


func start_wandering(new_home: Vector2):
	home_pos   = new_home
	is_waiting = false
	wait_timer = 0.0
	_pick_target()


func _pick_target():
	var angle  := randf() * TAU
	var radius := randf_range(14, 55)
	target_pos = home_pos + Vector2(cos(angle), sin(angle)) * radius
