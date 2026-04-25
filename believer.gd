extends CharacterBody2D

var home_pos: Vector2
var target_pos: Vector2
var move_speed: float = 35.0
var wait_timer: float = 0.0
var is_waiting: bool = false
var is_preacher: bool = false   # set true when converted
var is_soldier: bool = false    # set true when trained

# Forced movement — walk to a specific position, emit signal on arrival
var has_forced_target: bool = false
var forced_target: Vector2 = Vector2.ZERO
signal reached_forced_target

var needs_shelter: bool = false   # draw "house" icon when true

var _stuck_timer: float = 0.0
var _prev_pos: Vector2 = Vector2.ZERO

# Visuals — set via setup()
var skin_color: Color
var hair_color: Color
var tunic_color: Color
var pants_color: Color

var anim_sprite: AnimatedSprite2D

const FRAME_W := 68
const FRAME_H := 96

# 5 distinct regular villager looks
const VARIANTS = [
	{
		"skin":  Color(0.95, 0.82, 0.68),
		"hair":  Color(0.35, 0.20, 0.07),
		"tunic": Color(0.65, 0.28, 0.18),
		"pants": Color(0.30, 0.22, 0.14),
	},
	{
		"skin":  Color(0.78, 0.58, 0.40),
		"hair":  Color(0.12, 0.10, 0.09),
		"tunic": Color(0.28, 0.42, 0.65),
		"pants": Color(0.22, 0.18, 0.12),
	},
	{
		"skin":  Color(0.96, 0.84, 0.70),
		"hair":  Color(0.85, 0.68, 0.18),
		"tunic": Color(0.32, 0.58, 0.30),
		"pants": Color(0.28, 0.20, 0.14),
	},
	{
		"skin":  Color(0.45, 0.30, 0.18),
		"hair":  Color(0.10, 0.08, 0.07),
		"tunic": Color(0.70, 0.38, 0.15),
		"pants": Color(0.20, 0.16, 0.10),
	},
	{
		"skin":  Color(0.88, 0.72, 0.56),
		"hair":  Color(0.60, 0.22, 0.10),
		"tunic": Color(0.48, 0.44, 0.52),
		"pants": Color(0.25, 0.20, 0.14),
	},
]

func setup(pos: Vector2, variant: int):
	home_pos = pos
	position = pos
	var v = VARIANTS[variant % VARIANTS.size()]
	skin_color  = v["skin"]
	hair_color  = v["hair"]
	tunic_color = v["tunic"]
	pants_color = v["pants"]
	_pick_target()

func _ready():
	# Collision shape so CharacterBody2D can move
	var shape = CollisionShape2D.new()
	var cap = CapsuleShape2D.new()
	cap.radius = 5.0
	cap.height = 8.0
	shape.shape = cap
	add_child(shape)

	# Build AnimatedSprite2D from sprite sheet (believers only)
	_setup_anim_sprite()

func _setup_anim_sprite():
	if is_preacher or is_soldier:
		return
	if anim_sprite != null:
		return
	var texture = load("res://believer_sheet_v2.png")
	if texture == null:
		return

	var frames = SpriteFrames.new()

	# [animation_name, row_index, frame_count, fps]
	# Row 0: walk toward (front), Row 2: side profile (flip_h for left), Row 3: walk away
	var anims = [
		["walk_toward", 0, 10, 8],
		["walk_right",  2, 10, 8],
		["walk_away",   3, 10, 8],
		["idle",        0,  1, 4],
	]

	for anim in anims:
		var anim_name: String = anim[0]
		var row: int = anim[1]
		var count: int = anim[2]
		var fps: int = anim[3]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, float(fps))
		frames.set_animation_loop(anim_name, true)
		for i in range(count):
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
			atlas.filter_clip = true
			frames.add_frame(anim_name, atlas)

	anim_sprite = AnimatedSprite2D.new()
	anim_sprite.sprite_frames = frames
	# 86x96px frame at scale 0.6 gives ~52x58px display size (only 1.7x downscale — no ghosting)
	anim_sprite.scale = Vector2(0.6, 0.6)
	# Offset up so feet sit at the character's ground point
	anim_sprite.position = Vector2(0, -29)
	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(anim_sprite)
	anim_sprite.play("idle")

func _physics_process(_delta):
	# Forced walk overrides everything
	if has_forced_target:
		var diff = forced_target - position
		if is_preacher or is_soldier:
			if abs(diff.x) > 2:
				scale.x = sign(diff.x)
		if diff.length() < 10.0:
			has_forced_target = false
			velocity = Vector2.ZERO
			move_and_slide()
			_update_anim(Vector2.ZERO)
			reached_forced_target.emit()
			return
		velocity = diff.normalized() * move_speed
		move_and_slide()
		_update_anim(velocity)
		if is_preacher or is_soldier:
			queue_redraw()
		return

	if is_waiting:
		wait_timer -= _delta
		if wait_timer <= 0:
			is_waiting = false
			_pick_target()
		velocity = Vector2.ZERO
		move_and_slide()
		_update_anim(Vector2.ZERO)
		return

	var diff = target_pos - position
	if diff.length() < 12.0:
		is_waiting = true
		wait_timer = randf_range(1.5, 4.5)
		velocity = Vector2.ZERO
		_stuck_timer = 0.0
	else:
		if is_preacher or is_soldier:
			if abs(diff.x) > 2:
				scale.x = sign(diff.x)
		velocity = diff.normalized() * move_speed

	move_and_slide()

	# Repick target if pinned against a building wall
	var moved := position.distance_to(_prev_pos)
	if moved < 0.5 and velocity.length() > 1.0:
		_stuck_timer += _delta
		if _stuck_timer > 1.5:
			_pick_target()
			_stuck_timer = 0.0
	else:
		_stuck_timer = 0.0
	_prev_pos = position

	_update_anim(velocity)
	if is_preacher or is_soldier:
		queue_redraw()


func _update_anim(vel: Vector2):
	if anim_sprite == null or is_preacher or is_soldier:
		return
	var new_anim: String
	if vel.length() < 5.0:
		new_anim = "idle"
	elif abs(vel.x) >= abs(vel.y):
		anim_sprite.flip_h = vel.x > 0
		new_anim = "walk_right"
	else:
		anim_sprite.flip_h = false
		new_anim = "walk_toward" if vel.y > 0 else "walk_away"
	if anim_sprite.animation != new_anim:
		anim_sprite.play(new_anim)


func walk_to(pos: Vector2):
	forced_target = pos
	has_forced_target = true
	is_waiting = false


func park():
	# Stop and wait indefinitely (used when hidden inside a building)
	has_forced_target = false
	is_waiting = true
	wait_timer = 999999.0
	velocity = Vector2.ZERO


func start_wandering(new_home: Vector2):
	home_pos = new_home
	is_waiting = false
	wait_timer = 0.0
	_pick_target()


func _pick_target():
	var angle = randf() * TAU
	var radius = randf_range(12, 65)
	target_pos = home_pos + Vector2(cos(angle), sin(angle)) * radius

func _draw():
	# Believers use AnimatedSprite2D — only draw for preachers and soldiers
	if is_soldier:
		_draw_soldier()
	elif is_preacher:
		_draw_preacher()


func _draw_preacher():
	const ROBE    := Color(0.96, 0.94, 0.90)
	const ROBE_S  := Color(0.82, 0.80, 0.76)
	const ROPE    := Color(0.82, 0.65, 0.18)
	const CROSS_C := Color(0.95, 0.78, 0.12)
	const OUTLINE := Color(0.55, 0.52, 0.48)

	draw_ellipse_approx(Vector2(0, 13), 8, 3, Color(0, 0, 0, 0.20))
	draw_rect(Rect2(-8, -10, 16, 24), OUTLINE)
	draw_rect(Rect2(-7, -9,  14, 22), ROBE)
	draw_rect(Rect2(-9, 10, 18, 3), OUTLINE)
	draw_rect(Rect2(-8, 11, 16, 2), ROBE)
	draw_rect(Rect2(-1, -8, 2, 20), ROBE_S)
	draw_rect(Rect2(-8, -2, 16, 3), ROPE)
	draw_rect(Rect2(-13, -9, 5, 8), OUTLINE)
	draw_rect(Rect2(-12, -8, 4, 7), ROBE)
	draw_rect(Rect2(8, -9, 5, 8), OUTLINE)
	draw_rect(Rect2(8, -8, 4, 7), ROBE)
	draw_rect(Rect2(-12, -2, 4, 3), skin_color)
	draw_rect(Rect2(8, -2, 4, 3), skin_color)
	draw_rect(Rect2(-1, -8, 2, 6), CROSS_C)
	draw_rect(Rect2(-3, -6, 6, 2), CROSS_C)
	draw_rect(Rect2(-2, -12, 4, 4), skin_color)
	draw_rect(Rect2(-6, -22, 12, 12), skin_color)
	draw_rect(Rect2(-7, -24, 14, 14), OUTLINE)
	draw_rect(Rect2(-6, -23, 12, 13), ROBE_S)
	var hood_pts := PackedVector2Array([
		Vector2(-6, -23), Vector2(6, -23), Vector2(2, -30), Vector2(-2, -30)
	])
	draw_colored_polygon(hood_pts, ROBE_S)
	draw_polyline(hood_pts, OUTLINE, 1.0)
	draw_rect(Rect2(-4, -21, 8, 9), skin_color)
	draw_rect(Rect2(-3, -17, 2, 2), Color(0.12, 0.10, 0.10))
	draw_rect(Rect2(2, -17, 2, 2), Color(0.12, 0.10, 0.10))
	draw_rect(Rect2(-2, -12, 2, 1), Color(0.60, 0.30, 0.28))
	draw_rect(Rect2(0, -12, 2, 1), Color(0.60, 0.30, 0.28))
	var halo_pts := PackedVector2Array()
	for i in range(16):
		var a = i * TAU / 16
		halo_pts.append(Vector2(cos(a) * 9, sin(a) * 4 - 28))
	draw_polyline(halo_pts + PackedVector2Array([halo_pts[0]]), Color(0.95, 0.82, 0.15, 0.70), 1.5)

	if needs_shelter:
		draw_rect(Rect2(-14, -46, 28, 18), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(-13, -45, 26, 16), Color(0.95, 0.92, 0.80))
		draw_colored_polygon(PackedVector2Array([
			Vector2(-4, -28), Vector2(4, -28), Vector2(0, -24)
		]), Color(0.95, 0.92, 0.80))
		draw_rect(Rect2(-8, -43, 16, 10), Color(0.72, 0.20, 0.08))
		draw_colored_polygon(PackedVector2Array([
			Vector2(-10, -43), Vector2(10, -43), Vector2(0, -50)
		]), Color(0.72, 0.20, 0.08))
		draw_rect(Rect2(-5, -36, 10, 7), Color(0.98, 0.95, 0.88))
		draw_rect(Rect2(-2, -34, 4, 5), Color(0.32, 0.16, 0.06))

func _draw_soldier():
	const MAIL   := Color(0.55, 0.57, 0.62)
	const MAIL_D := Color(0.38, 0.40, 0.44)
	const HELM   := Color(0.62, 0.65, 0.70)
	const SHIELD := Color(0.62, 0.18, 0.12)
	const SWORD  := Color(0.78, 0.80, 0.85)

	draw_ellipse_approx(Vector2(0, 13), 8, 3, Color(0, 0, 0, 0.22))
	draw_rect(Rect2(-7, 8, 6, 4), Color(0.20, 0.14, 0.07))
	draw_rect(Rect2(1, 8, 6, 4), Color(0.20, 0.14, 0.07))
	draw_rect(Rect2(-7, 0, 5, 10), MAIL_D)
	draw_rect(Rect2(2, 0, 5, 10), MAIL_D)
	draw_rect(Rect2(-8, -11, 16, 13), MAIL_D)
	draw_rect(Rect2(-7, -10, 14, 11), MAIL)
	for i in range(3):
		draw_line(Vector2(-7, -8 + i * 3), Vector2(7, -8 + i * 3), MAIL_D, 1)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, -10), Vector2(-8, -10), Vector2(-8, 4), Vector2(-11, 8), Vector2(-14, 4)
	]), MAIL_D)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13, -9), Vector2(-9, -9), Vector2(-9, 3), Vector2(-11, 7), Vector2(-13, 3)
	]), SHIELD)
	draw_circle(Vector2(-11, -1), 2, Color(0.95, 0.80, 0.18))
	draw_rect(Rect2(8, -9, 4, 9), skin_color)
	draw_rect(Rect2(10, -22, 2, 22), SWORD)
	draw_rect(Rect2(7, -13, 8, 2), MAIL_D)
	draw_rect(Rect2(10, -11, 2, 4), Color(0.50, 0.35, 0.15))
	draw_rect(Rect2(-2, -12, 4, 3), skin_color)
	draw_rect(Rect2(-5, -21, 10, 9), skin_color)
	draw_rect(Rect2(-7, -25, 14, 7), MAIL_D)
	draw_rect(Rect2(-6, -24, 12, 6), HELM)
	draw_rect(Rect2(-1, -23, 2, 9), HELM.darkened(0.22))
	draw_rect(Rect2(-7, -21, 3, 7), MAIL_D)
	draw_rect(Rect2(4, -21, 3, 7), MAIL_D)
	draw_rect(Rect2(-4, -19, 2, 2), Color(0.12, 0.10, 0.10))
	draw_rect(Rect2(2, -19, 2, 2), Color(0.12, 0.10, 0.10))


func draw_ellipse_approx(center: Vector2, rx: float, ry: float, color: Color):
	var pts := PackedVector2Array()
	var steps := 12
	for i in range(steps):
		var angle = i * TAU / steps
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, color)
