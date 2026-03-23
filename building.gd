extends Area2D

var building_type: String = "shelter"
var building_label: String = ""
var is_interactive: bool = false

signal tapped

const OUTLINE := Color(0.10, 0.05, 0.02, 1.0)

func _ready():
	input_pickable = true
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(120, 110)
	shape.position = Vector2(0, -20)
	shape.shape = rect
	add_child(shape)
	input_event.connect(_on_input_event)

func _on_input_event(_viewport, event, _shape_idx):
	if is_interactive and event is InputEventMouseButton:
		if event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
			tapped.emit()

func _draw():
	match building_type:
		"shelter":
			if has_meta("under_construction"):
				_draw_temple_construction()
			else:
				_draw_shelter()
		"temple":
			if has_meta("under_construction"):
				_draw_temple_construction()
			else:
				_draw_temple()
		"hall_of_devoted":
			if has_meta("under_construction"):
				_draw_temple_construction()
			else:
				_draw_hall_of_devoted()
		"preacher_shelter":
			if has_meta("under_construction"):
				_draw_temple_construction()
			else:
				_draw_preacher_shelter()
		"armory":
			if has_meta("under_construction"):
				_draw_temple_construction()
			else:
				_draw_armory()
		"garrison":
			if has_meta("under_construction"):
				_draw_temple_construction()
			else:
				_draw_garrison()

# ── Helpers ────────────────────────────────────────────────────────────────────
func _o_rect(r: Rect2, fill: Color, t: float = 2.5):
	draw_rect(Rect2(r.position - Vector2(t,t), r.size + Vector2(t*2,t*2)), OUTLINE)
	draw_rect(r, fill)

func _o_poly(pts: PackedVector2Array, fill: Color, expand: float = 2.5):
	var big := PackedVector2Array()
	var cx := 0.0; var cy := 0.0
	for p in pts: cx += p.x; cy += p.y
	cx /= pts.size(); cy /= pts.size()
	for p in pts:
		var d := Vector2(p.x - cx, p.y - cy).normalized()
		big.append(Vector2(p.x + d.x * expand, p.y + d.y * expand))
	draw_colored_polygon(big, OUTLINE)
	draw_colored_polygon(pts, fill)

func _draw_window(x: float, y: float):
	# Outer frame
	draw_rect(Rect2(x-2, y-2, 22, 18), OUTLINE)
	# Glass
	draw_rect(Rect2(x, y, 18, 14), Color(0.50, 0.88, 1.0))
	# Glare
	draw_rect(Rect2(x+1, y+1, 7, 4), Color(0.85, 0.97, 1.0, 0.80))
	# Cross dividers
	draw_rect(Rect2(x, y+6, 18, 2), OUTLINE)
	draw_rect(Rect2(x+8, y, 2, 14), OUTLINE)

func _ellipse_pts(center: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a = i * TAU / n
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	return pts

# ── Humble Shelter ─────────────────────────────────────────────────────────────
func _draw_shelter():
	const ROOF  := Color(0.72, 0.20, 0.08)   # Rich red-brown (like FarmVille barn)
	const WALL  := Color(0.98, 0.95, 0.88)   # Bright cream
	const FOUND := Color(0.70, 0.58, 0.42)   # Warm stone
	const DOOR  := Color(0.32, 0.16, 0.06)   # Dark wood

	# Ground shadow
	draw_colored_polygon(_ellipse_pts(Vector2(6, 24), 58, 10, 14), Color(0,0,0,0.20))

	# Foundation
	_o_rect(Rect2(-48, 14, 96, 10), FOUND)

	# Fake 3D side wall (right face, darker)
	draw_colored_polygon(
		PackedVector2Array([Vector2(44,-28), Vector2(58,-18), Vector2(58,18), Vector2(44,14)]),
		ROOF.darkened(0.55))
	draw_polyline(
		PackedVector2Array([Vector2(44,-28), Vector2(58,-18), Vector2(58,18), Vector2(44,14)]),
		OUTLINE, 2)

	# Front wall
	_o_rect(Rect2(-44, -28, 88, 44), WALL)
	# Wall plank lines
	for i in range(3):
		draw_line(Vector2(-18+i*18, -28), Vector2(-18+i*18, 16), Color(0.84,0.80,0.72), 1)

	# Roof outline then fill
	_o_poly(PackedVector2Array([Vector2(-56,-28), Vector2(56,-28), Vector2(0,-78)]), ROOF, 3)
	# Roof shingle rows
	for i in range(4):
		var y := -64.0 + i * 11
		var w := 8.0 + i * 13
		draw_line(Vector2(-w, y), Vector2(w, y), ROOF.darkened(0.18), 1.5)
	# Roof ridge highlight
	draw_line(Vector2(-54, -28), Vector2(54, -28), ROOF.lightened(0.25), 2)

	# Chimney
	_o_rect(Rect2(18, -76, 14, 34), Color(0.58, 0.42, 0.28))
	_o_rect(Rect2(15, -80, 20, 8), Color(0.48, 0.34, 0.20))
	# Smoke puff hint
	draw_circle(Vector2(25, -84), 4, Color(0.85,0.85,0.85,0.50))
	draw_circle(Vector2(29, -90), 5, Color(0.90,0.90,0.90,0.35))

	# Door
	_o_rect(Rect2(-14, -6, 28, 34), DOOR)
	draw_line(Vector2(0,-6), Vector2(0,28), DOOR.lightened(0.18), 1.5)
	draw_line(Vector2(-14,10), Vector2(14,10), DOOR.lightened(0.18), 1.0)
	draw_circle(Vector2(10, 14), 3, Color(0.95,0.80,0.18))

	# Windows
	_draw_window(-38, -22)
	_draw_window(20, -22)


# ── Small Temple ───────────────────────────────────────────────────────────────
func _draw_temple():
	const STONE  := Color(0.92, 0.90, 0.84)
	const STONE2 := Color(0.82, 0.80, 0.74)
	const PILLAR := Color(0.97, 0.95, 0.90)
	const ROOF_T := Color(0.78, 0.75, 0.68)

	# Ground shadow
	draw_colored_polygon(_ellipse_pts(Vector2(6, 24), 66, 10, 14), Color(0,0,0,0.20))

	# Fake 3D side
	draw_colored_polygon(
		PackedVector2Array([Vector2(40,4), Vector2(56,-4), Vector2(56,-50), Vector2(40,-50)]),
		STONE.darkened(0.30))
	draw_polyline(
		PackedVector2Array([Vector2(40,4), Vector2(56,-4), Vector2(56,-50), Vector2(40,-50)]),
		OUTLINE, 2)

	# Steps
	_o_rect(Rect2(-60, 10, 120, 12), STONE2)
	_o_rect(Rect2(-50, 0, 100, 12), STONE)

	# Main body
	_o_rect(Rect2(-40, -50, 80, 52), STONE)
	# Stone block grid
	for row in range(3):
		draw_line(Vector2(-40,-30+row*16), Vector2(40,-30+row*16), STONE2, 1)
	for col in range(3):
		draw_line(Vector2(-20+col*20,-50), Vector2(-20+col*20,2), STONE2, 1)

	# Columns
	for i in range(4):
		var cx := -28.0 + i * 19
		_o_rect(Rect2(cx-5,-50,10,52), PILLAR, 1.5)
		_o_rect(Rect2(cx-7,-50,14,6), STONE2, 1.5)   # capital
		_o_rect(Rect2(cx-7, 0,14,4), STONE2, 1.5)   # base

	# Pediment
	_o_poly(PackedVector2Array([Vector2(-46,-50), Vector2(46,-50), Vector2(0,-86)]), ROOF_T, 3)
	draw_line(Vector2(-46,-50), Vector2(46,-50), OUTLINE, 2)

	# Door arch
	_o_rect(Rect2(-14,-22,28,34), Color(0.28,0.20,0.14))
	_o_poly(PackedVector2Array([
		Vector2(-14,-22), Vector2(14,-22),
		Vector2(14,-30), Vector2(0,-38), Vector2(-14,-30)]),
		Color(0.28,0.20,0.14), 2)

	# God symbol at peak
	_draw_god_symbol(0, -76)


func _draw_temple_construction():
	const WOOD   := Color(0.65, 0.42, 0.18)
	const WOOD_D := Color(0.44, 0.28, 0.10)
	const CONC   := Color(0.80, 0.78, 0.72)

	# Partial foundation
	draw_rect(Rect2(-60, 8, 120, 14), OUTLINE)
	draw_rect(Rect2(-58, 10, 116, 10), CONC)

	# Scaffolding poles
	for x in [-44, -14, 16, 44]:
		draw_rect(Rect2(x - 3, -80, 6, 96), WOOD_D)
		draw_rect(Rect2(x - 2, -78, 4, 94), WOOD)

	# Horizontal planks
	for y in [-60, -30, 0]:
		draw_rect(Rect2(-47, y - 4, 98, 8), WOOD_D)
		draw_rect(Rect2(-47, y - 3, 98, 6), WOOD)
		for i in range(5):
			draw_line(Vector2(-40+i*18, y-2), Vector2(-34+i*18, y+2), WOOD_D, 1)

	# Diagonal braces
	draw_line(Vector2(-44, -60), Vector2(44, 0),  WOOD_D, 2)
	draw_line(Vector2(44,  -60), Vector2(-44, 0), WOOD_D, 2)

	# Yellow construction sign at top
	draw_rect(Rect2(-2, -88, 4, 14), WOOD_D)
	draw_rect(Rect2(-28, -98, 56, 18), OUTLINE)
	draw_rect(Rect2(-26, -96, 52, 14), Color(0.95, 0.85, 0.20))


# ── Hall of the Devoted ─────────────────────────────────────────────────────────
func _draw_hall_of_devoted():
	const STONE  := Color(0.74, 0.70, 0.62)   # Warm grey stone
	const STONE2 := Color(0.62, 0.58, 0.50)   # Darker mortar
	const TIMBER := Color(0.48, 0.28, 0.10)   # Dark timber roof
	const TIMBER_D := Color(0.34, 0.18, 0.06) # Shadow timber
	const DOOR   := Color(0.20, 0.12, 0.06)   # Dark wood door
	const TORCH  := Color(0.95, 0.72, 0.15)   # Torch flame

	# Ground shadow
	draw_colored_polygon(_ellipse_pts(Vector2(6, 24), 68, 10, 14), Color(0,0,0,0.20))

	# 3D side face
	draw_colored_polygon(
		PackedVector2Array([Vector2(46,14), Vector2(60,4), Vector2(60,-34), Vector2(46,-34)]),
		STONE.darkened(0.35))
	draw_polyline(
		PackedVector2Array([Vector2(46,14), Vector2(60,4), Vector2(60,-34), Vector2(46,-34)]),
		OUTLINE, 2)

	# Foundation steps
	_o_rect(Rect2(-52, 10, 104, 12), STONE2)
	_o_rect(Rect2(-46, 0, 92, 12), STONE)

	# Main body
	_o_rect(Rect2(-46, -34, 92, 36), STONE)
	# Stone block lines
	for row in range(3):
		draw_line(Vector2(-46, -14 + row * 14), Vector2(46, -14 + row * 14), STONE2, 1)
	for col in range(3):
		draw_line(Vector2(-22 + col * 22, -34), Vector2(-22 + col * 22, 2), STONE2, 1)

	# Timber peaked roof
	_o_poly(PackedVector2Array([Vector2(-52,-34), Vector2(52,-34), Vector2(0,-74)]), TIMBER, 3)
	# Roof beam lines
	for i in range(4):
		var y := -64.0 + i * 10
		var w := 6.0 + i * 12
		draw_line(Vector2(-w, y), Vector2(w, y), TIMBER_D, 1.5)
	# Roof ridge
	draw_line(Vector2(-50, -34), Vector2(50, -34), TIMBER.lightened(0.20), 1.5)

	# Torch sconces (left and right of door)
	for tx in [-30.0, 30.0]:
		draw_rect(Rect2(tx-2, -24, 4, 12), STONE2)   # bracket
		draw_circle(Vector2(tx, -28), 7, Color(0.95, 0.55, 0.10, 0.35))  # glow
		draw_circle(Vector2(tx, -28), 4, TORCH)  # flame core
		draw_circle(Vector2(tx, -30), 3, Color(1.0, 0.95, 0.65))  # bright tip

	# Arched windows (left and right) — plain, no cross bars
	for wx in [-34.0, 20.0]:
		draw_rect(Rect2(wx-6, -30, 12, 18), OUTLINE)
		draw_rect(Rect2(wx-5, -29, 10, 16), Color(0.50, 0.88, 1.0))
		draw_rect(Rect2(wx-3, -29, 4, 6), Color(0.85, 0.97, 1.0, 0.70))   # glare

	# Arched doorway
	_o_rect(Rect2(-13, -16, 26, 28), DOOR)
	_o_poly(PackedVector2Array([
		Vector2(-13,-16), Vector2(13,-16),
		Vector2(10,-24), Vector2(0,-30), Vector2(-10,-24)]),
		DOOR, 2)
	draw_circle(Vector2(9, -6), 3, Color(0.95, 0.80, 0.18))  # door handle

	# God symbol on pediment
	_draw_god_symbol(0, -74)


# ── Preacher Shelter ───────────────────────────────────────────────────────────
func _draw_preacher_shelter():
	const WALL   := Color(0.96, 0.93, 0.90)   # Whitewashed stone
	const STONE  := Color(0.68, 0.63, 0.54)   # Grey stone base
	const ROOF   := Color(0.42, 0.32, 0.58)   # Monastic purple-grey
	const DOOR   := Color(0.24, 0.16, 0.08)   # Dark arched door

	# Ground shadow
	draw_colored_polygon(_ellipse_pts(Vector2(6, 24), 58, 10, 14), Color(0,0,0,0.20))

	# 3D side face
	draw_colored_polygon(
		PackedVector2Array([Vector2(44,-28), Vector2(58,-18), Vector2(58,18), Vector2(44,14)]),
		ROOF.darkened(0.50))
	draw_polyline(
		PackedVector2Array([Vector2(44,-28), Vector2(58,-18), Vector2(58,18), Vector2(44,14)]),
		OUTLINE, 2)

	# Stone foundation
	_o_rect(Rect2(-48, 14, 96, 10), STONE)

	# Stone lower walls
	_o_rect(Rect2(-44, -6, 88, 22), STONE)
	draw_line(Vector2(-44, 4), Vector2(44, 4), STONE.darkened(0.15), 1)
	for col in range(3):
		draw_line(Vector2(-18+col*18, -6), Vector2(-18+col*18, 16), STONE.darkened(0.15), 1)

	# Whitewashed upper walls
	_o_rect(Rect2(-44, -28, 88, 24), WALL)

	# Monastic peaked roof
	_o_poly(PackedVector2Array([Vector2(-52,-28), Vector2(52,-28), Vector2(0,-74)]), ROOF, 3)
	# Tile rows
	for i in range(4):
		var y := -64.0 + i * 10
		var w := 8.0 + i * 12
		draw_line(Vector2(-w, y), Vector2(w, y), ROOF.darkened(0.20), 1.5)
	# Ridge highlight
	draw_line(Vector2(-50,-28), Vector2(50,-28), ROOF.lightened(0.22), 2)

	# God symbol at peak
	_draw_god_symbol(0, -68)

	# Arched door

	_o_rect(Rect2(-12, -4, 24, 26), DOOR)
	_o_poly(PackedVector2Array([
		Vector2(-12,-4), Vector2(12,-4),
		Vector2(8,-12), Vector2(0,-18), Vector2(-8,-12)]),
		DOOR, 2)
	draw_circle(Vector2(8, 8), 3, Color(0.95, 0.80, 0.18))  # knob

	# Arched windows with dividers
	for wx in [-34.0, 22.0]:
		draw_rect(Rect2(wx-8, -26, 16, 18), OUTLINE)
		draw_rect(Rect2(wx-7, -25, 14, 16), Color(0.50, 0.88, 1.0))
		draw_rect(Rect2(wx-8, -26, 16, 8), OUTLINE)   # arch top (simplified)
		draw_rect(Rect2(wx-1, -25, 2, 16), DOOR)      # vertical bar
		draw_rect(Rect2(wx-7, -20, 14, 2), DOOR)      # horizontal bar
		draw_rect(Rect2(wx-4, -24, 8, 4), Color(0.70, 0.93, 1.0))  # arch glare


# ── Barracks ───────────────────────────────────────────────────────────────────
func _draw_armory():
	const STONE  := Color(0.42, 0.40, 0.36)   # Dark battlestone
	const STONE2 := Color(0.30, 0.28, 0.25)   # Darker mortar
	const IRON   := Color(0.62, 0.65, 0.70)   # Iron/steel
	const WOOD   := Color(0.28, 0.18, 0.08)   # Heavy door

	# Ground shadow
	draw_colored_polygon(_ellipse_pts(Vector2(6, 24), 68, 10, 14), Color(0,0,0,0.25))

	# 3D side face
	draw_colored_polygon(
		PackedVector2Array([Vector2(46,14), Vector2(60,4), Vector2(60,-48), Vector2(46,-48)]),
		STONE.darkened(0.40))
	draw_polyline(
		PackedVector2Array([Vector2(46,14), Vector2(60,4), Vector2(60,-48), Vector2(46,-48)]),
		OUTLINE, 2)

	# Foundation
	_o_rect(Rect2(-50, 10, 100, 12), STONE2)

	# Main body
	_o_rect(Rect2(-46, -48, 92, 60), STONE)
	# Stone block lines
	for row in range(4):
		draw_line(Vector2(-46, -22 + row * 16), Vector2(46, -22 + row * 16), STONE2, 1)
	for col in range(3):
		draw_line(Vector2(-22 + col * 22, -48), Vector2(-22 + col * 22, 12), STONE2, 1)

	# Battlements (crenellations) — alternating merlons and gaps
	for i in range(6):
		var bx := -44.0 + i * 16
		if i % 2 == 0:
			_o_rect(Rect2(bx, -64, 12, 18), STONE.lightened(0.05))

	# Arrow slit windows (narrow vertical slits)
	for wx in [-28.0, 12.0]:
		draw_rect(Rect2(wx - 2, -40, 4, 16), STONE2)
		draw_rect(Rect2(wx - 1, -39, 2, 14), Color(0.10, 0.08, 0.15))

	# Heavy wooden door
	_o_rect(Rect2(-14, -22, 28, 34), WOOD)
	# Door planks
	for i in range(3):
		draw_line(Vector2(-14, -18 + i * 10), Vector2(14, -18 + i * 10), WOOD.lightened(0.12), 1)
	# Iron banding
	draw_rect(Rect2(-14, -10, 28, 3), IRON.darkened(0.3))
	# Door ring
	draw_circle(Vector2(9, -5), 3, IRON)

	# Crossed swords above door (on wall)
	draw_line(Vector2(-10, -36), Vector2(10, -28), IRON, 2.5)
	draw_line(Vector2(10, -36), Vector2(-10, -28), IRON, 2.5)
	draw_circle(Vector2(0, -32), 3, IRON.lightened(0.3))


# ── Garrison (soldier quarters) ────────────────────────────────────────────────
func _draw_garrison():
	const WALL   := Color(0.50, 0.45, 0.38)   # Rough timber/daub walls
	const WALL_D := Color(0.38, 0.34, 0.28)   # Darker planks
	const ROOF   := Color(0.28, 0.22, 0.14)   # Dark thatched roof
	const ROOF_L := Color(0.38, 0.30, 0.18)   # Lighter thatch
	const BANNER := Color(0.62, 0.18, 0.12)   # Red banner

	# Ground shadow
	draw_colored_polygon(_ellipse_pts(Vector2(6, 24), 64, 10, 14), Color(0,0,0,0.22))

	# 3D side face
	draw_colored_polygon(
		PackedVector2Array([Vector2(44,14), Vector2(58,4), Vector2(58,-26), Vector2(44,-26)]),
		WALL.darkened(0.35))
	draw_polyline(
		PackedVector2Array([Vector2(44,14), Vector2(58,4), Vector2(58,-26), Vector2(44,-26)]),
		OUTLINE, 2)

	# Foundation
	_o_rect(Rect2(-48, 10, 96, 12), WALL_D)

	# Main body (wider, lower — longhouse shape)
	_o_rect(Rect2(-44, -26, 88, 38), WALL)
	# Timber plank verticals
	for i in range(5):
		draw_line(Vector2(-36 + i * 18, -26), Vector2(-36 + i * 18, 12), WALL_D, 1.5)
	# Horizontal beam
	draw_line(Vector2(-44, -8), Vector2(44, -8), WALL_D, 1.5)

	# Low pitched roof (longhouse style)
	_o_poly(PackedVector2Array([Vector2(-50,-26), Vector2(50,-26), Vector2(0,-56)]), ROOF, 3)
	# Thatch rows
	for i in range(3):
		var y := -48.0 + i * 10
		var w := 6.0 + i * 16
		draw_line(Vector2(-w, y), Vector2(w, y), ROOF_L, 2)
	draw_line(Vector2(-48,-26), Vector2(48,-26), ROOF_L, 1.5)

	# Two small windows (arrow loops)
	for wx in [-26.0, 14.0]:
		draw_rect(Rect2(wx-3, -22, 6, 10), WALL_D)
		draw_rect(Rect2(wx-2, -21, 4, 8), Color(0.12, 0.10, 0.16))

	# Door (wider than shelter)
	_o_rect(Rect2(-12, -14, 24, 26), WALL_D)
	draw_line(Vector2(0,-14), Vector2(0,12), WALL.lightened(0.10), 1)
	draw_circle(Vector2(8, 0), 2, Color(0.80, 0.65, 0.15))

	# Red banner hanging on wall (left of door)
	draw_rect(Rect2(-36, -22, 2, 14), WALL_D)    # pole
	draw_rect(Rect2(-34, -22, 10, 10), BANNER)    # banner cloth
	draw_rect(Rect2(-34, -20, 10, 2), BANNER.lightened(0.15))  # highlight


# ── God symbol (replaces cross on temple & preacher shelter) ──────────────────
func _draw_god_symbol(cx: float, cy: float):
	var god: int = GameData.selected_god
	match god:
		0: _draw_sun_symbol(cx, cy)
		1: _draw_leaf_symbol(cx, cy)
		2: _draw_wave_symbol(cx, cy)
		_: _draw_sun_symbol(cx, cy)


func _draw_sun_symbol(cx: float, cy: float):
	const SUN   := Color(0.98, 0.88, 0.10)
	const SUN_D := Color(0.60, 0.38, 0.02)
	const TWO_PI := PI * 2.0
	# 8 triangular rays
	for i in range(8):
		var a := i * TWO_PI / 8.0 - PI / 2.0
		var p1 := Vector2(cx + cos(a - 0.28) * 9,  cy + sin(a - 0.28) * 9)
		var p2 := Vector2(cx + cos(a + 0.28) * 9,  cy + sin(a + 0.28) * 9)
		var p3 := Vector2(cx + cos(a) * 20,         cy + sin(a) * 20)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]), SUN_D)
	# Dark outline circle
	draw_colored_polygon(_ellipse_pts(Vector2(cx, cy), 10, 10, 14), SUN_D)
	# Bright fill circle
	draw_colored_polygon(_ellipse_pts(Vector2(cx, cy), 8,  8,  14), SUN)
	# Shine
	draw_colored_polygon(_ellipse_pts(Vector2(cx - 2, cy - 2), 3, 3, 8),
		Color(1.0, 1.0, 0.90, 0.75))


func _draw_leaf_symbol(cx: float, cy: float):
	const LEAF   := Color(0.22, 0.78, 0.14)
	const LEAF_D := Color(0.08, 0.38, 0.06)
	const VEIN   := Color(0.06, 0.24, 0.04)
	const TWO_PI := PI * 2.0
	var steps := 20
	# Outer leaf (dark outline)
	var outer := PackedVector2Array()
	for i in range(steps):
		var a := float(i) / float(steps) * TWO_PI
		outer.append(Vector2(cx + sin(a) * 8.0, cy - cos(a) * 13.0 + cos(a * 0.5) * 2.5))
	draw_colored_polygon(outer, LEAF_D)
	# Inner bright fill
	var inner := PackedVector2Array()
	for i in range(steps):
		var a := float(i) / float(steps) * TWO_PI
		inner.append(Vector2(cx + sin(a) * 6.0, cy - cos(a) * 11.0 + cos(a * 0.5) * 2.0))
	draw_colored_polygon(inner, LEAF)
	# Centre vein
	draw_line(Vector2(cx, cy + 11), Vector2(cx, cy - 12), VEIN, 1.5)
	# Side veins
	for side in [-1, 1]:
		draw_line(Vector2(cx, cy - 2), Vector2(cx + side * 5, cy - 7), VEIN, 1.0)
		draw_line(Vector2(cx, cy + 3), Vector2(cx + side * 5, cy - 1), VEIN, 1.0)


func _draw_wave_symbol(cx: float, cy: float):
	const WAVE   := Color(0.22, 0.65, 1.0)    # bright blue
	const WAVE_L := Color(0.80, 0.97, 1.0)    # white highlight
	const WAVE_D := Color(0.05, 0.22, 0.65)   # dark border
	var steps := 16
	# Upper wave crest (large arch, single hump using PI)
	var top_o := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		top_o.append(Vector2(cx - 14 + t * 28, cy - sin(t * PI) * 10))
	top_o.append(Vector2(cx + 14, cy + 2))
	top_o.append(Vector2(cx - 14, cy + 2))
	draw_colored_polygon(top_o, WAVE_D)
	var top_i := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		top_i.append(Vector2(cx - 12 + t * 24, cy - sin(t * PI) * 8))
	top_i.append(Vector2(cx + 12, cy + 1))
	top_i.append(Vector2(cx - 12, cy + 1))
	draw_colored_polygon(top_i, WAVE)
	# White crest highlight
	draw_line(Vector2(cx - 5, cy - 7), Vector2(cx + 5, cy - 9), Color(1.0, 1.0, 1.0, 0.90), 2.0)
	# Lower wave crest (smaller, offset down)
	var bot_o := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		bot_o.append(Vector2(cx - 10 + t * 20, cy + 5 - sin(t * PI) * 7))
	bot_o.append(Vector2(cx + 10, cy + 12))
	bot_o.append(Vector2(cx - 10, cy + 12))
	draw_colored_polygon(bot_o, WAVE_D)
	var bot_i := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		bot_i.append(Vector2(cx - 8 + t * 16, cy + 6 - sin(t * PI) * 5))
	bot_i.append(Vector2(cx + 8, cy + 11))
	bot_i.append(Vector2(cx - 8, cy + 11))
	draw_colored_polygon(bot_i, WAVE_L)
