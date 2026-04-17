extends Node2D

# ── Campaign config ───────────────────────────────────────────────────────────
const CAMPAIGN_DURATION := 180.0    # 3-minute demo (represents 30 game-minutes)
const TOTAL_VILLAGERS   := 8
const MAX_RESISTANCE    := 8.0
const CONVERT_RANGE     := 70.0     # pixels; preacher must be within this
const CONVERT_RATE      := 0.9      # resistance drained per second while in range
const ABILITY_RANGE     := 160.0
const ABILITY_POWER     := 4.5      # instant resistance hit
const MAP_W             := 1200
const MAP_H             := 860

# ── Palette ───────────────────────────────────────────────────────────────────
const COL_GROUND := Color(0.72, 0.65, 0.50)
const COL_PATH   := Color(0.60, 0.53, 0.38)
const COL_WALL   := Color(0.75, 0.63, 0.45)
const COL_ROOF   := Color(0.45, 0.32, 0.14)
const COL_WINDOW := Color(0.70, 0.82, 0.90)
const COL_DOOR   := Color(0.35, 0.22, 0.10)
const COL_WELL   := Color(0.55, 0.52, 0.48)
const COL_WATER  := Color(0.28, 0.48, 0.70)

const ENTRY_POS  := Vector2(55.0, 430.0)
const RALLY_POS  := Vector2(155.0, 430.0)
const PLAZA_POS  := Vector2(600.0, 430.0)

# Village house data — {pos: top-left of wall, w: int, h: int}
const HOUSES := [
	{"pos": Vector2(430, 190), "w": 100, "h": 80},
	{"pos": Vector2(620, 165), "w": 90,  "h": 75},
	{"pos": Vector2(790, 240), "w": 105, "h": 80},
	{"pos": Vector2(800, 460), "w": 105, "h": 80},
	{"pos": Vector2(620, 545), "w": 90,  "h": 75},
	{"pos": Vector2(430, 510), "w": 100, "h": 80},
	{"pos": Vector2(285, 455), "w": 90,  "h": 75},
	{"pos": Vector2(285, 235), "w": 90,  "h": 75},
]

# Villager wander centres — one per house
const VILLAGER_HOMES := [
	Vector2(480, 270),
	Vector2(665, 250),
	Vector2(843, 310),
	Vector2(853, 530),
	Vector2(665, 620),
	Vector2(480, 590),
	Vector2(330, 525),
	Vector2(330, 305),
]

# ── Runtime state ─────────────────────────────────────────────────────────────
var timer_remaining : float = CAMPAIGN_DURATION
var converted_count : int   = 0
var campaign_ended  : bool  = false
var ability_used    : bool  = false

# ── Node refs ─────────────────────────────────────────────────────────────────
var cam            : Camera2D        = null
var ui_layer       : CanvasLayer     = null
var timer_label    : Label           = null
var converted_label: Label           = null
var ability_btn    : Button          = null
var result_panel   : PanelContainer  = null

var preacher_node  : CharacterBody2D = null
var villager_nodes : Array = []   # CharacterBody2D × TOTAL_VILLAGERS
var villager_resist: Array = []   # float × TOTAL_VILLAGERS
var villager_done  : Array = []   # bool  × TOTAL_VILLAGERS
var bar_bgs        : Array = []   # ColorRect (background) per villager
var bar_fills      : Array = []   # ColorRect (fill) per villager

# ── Ready ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_camera()
	_build_ui()
	_spawn_villagers()
	_spawn_preacher()
	# _draw() fires automatically when the node enters the scene tree

# ── Village drawing ───────────────────────────────────────────────────────────

func _draw() -> void:
	# Ground
	draw_rect(Rect2(0, 0, MAP_W, MAP_H), COL_GROUND)

	# Dirt paths — horizontal + vertical cross through plaza
	draw_rect(Rect2(0,   400, MAP_W, 65), COL_PATH)
	draw_rect(Rect2(560,   0,  80, MAP_H), COL_PATH)

	# Entry lane (left edge → first houses)
	draw_rect(Rect2(0, 395, 285, 75), COL_PATH.darkened(0.08))

	# Plaza stone (slightly lighter than path)
	draw_rect(Rect2(530, 380, 140, 105), COL_PATH.lightened(0.14))
	draw_rect(Rect2(534, 384, 132,  97), COL_PATH.lightened(0.20))

	# Fence posts along the entry lane
	for i in range(6):
		var fx : float = 100.0 + float(i) * 30.0
		draw_rect(Rect2(fx, 390, 5, 20), Color(0.50, 0.38, 0.18))
		draw_rect(Rect2(fx, 425, 5, 20), Color(0.50, 0.38, 0.18))
		if i < 5:
			draw_line(Vector2(fx, 400), Vector2(fx + 30.0, 400), Color(0.44, 0.34, 0.14), 2.0)
			draw_line(Vector2(fx, 435), Vector2(fx + 30.0, 435), Color(0.44, 0.34, 0.14), 2.0)

	# Gate posts at map entry
	draw_rect(Rect2(14, 373, 12, 56), Color(0.50, 0.42, 0.28))
	draw_rect(Rect2(31, 363, 10, 62), Color(0.55, 0.46, 0.30))
	draw_rect(Rect2(9,  358, 38, 18), Color(0.42, 0.30, 0.12))   # sign board
	draw_rect(Rect2(11, 360, 34, 14), Color(0.56, 0.44, 0.22))

	# Village houses
	for house in HOUSES:
		var pos : Vector2 = house["pos"]
		var w   : int     = house["w"]
		var h   : int     = house["h"]
		_draw_house(pos, w, h)

	# Well at plaza
	_draw_well(PLAZA_POS)

func _draw_well(center: Vector2) -> void:
	# Stone ring
	for i in range(12):
		var a   : float   = float(i) * TAU / 12.0
		var sp  : Vector2 = center + Vector2(cos(a) * 22.0, sin(a) * 16.0)
		var dark: float   = 0.15 + 0.10 * float(i % 2)
		draw_rect(Rect2(sp - Vector2(5, 4), Vector2(10, 8)), COL_WELL.darkened(dark))
	draw_circle(center, 16.0, COL_WELL)
	draw_circle(center, 12.0, COL_WELL.darkened(0.2))
	draw_circle(center,  9.0, COL_WATER)
	# Support posts
	draw_rect(Rect2(center + Vector2(-22, -28), Vector2(6, 28)), Color(0.48, 0.34, 0.16))
	draw_rect(Rect2(center + Vector2( 16, -28), Vector2(6, 28)), Color(0.48, 0.34, 0.16))
	# Roof beam
	draw_rect(Rect2(center + Vector2(-25, -32), Vector2(50, 6)), Color(0.42, 0.30, 0.12))

func _draw_house(pos: Vector2, w: int, h: int) -> void:
	# Drop shadow
	draw_rect(Rect2(pos + Vector2(3, 3), Vector2(w, h)), Color(0.28, 0.22, 0.14, 0.40))

	# Wall
	draw_rect(Rect2(pos, Vector2(w, h)), COL_WALL.darkened(0.25))
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2(w - 2, h - 2)), COL_WALL)

	# Stone-row texture
	for row in range(3):
		draw_line(
			pos + Vector2(2.0, 18.0 + float(row) * 20.0),
			pos + Vector2(float(w) - 2.0, 18.0 + float(row) * 20.0),
			COL_WALL.darkened(0.18), 1.0
		)

	# Thatched roof (triangle, overhangs wall)
	var ov : int = 10
	var roof := PackedVector2Array([
		pos + Vector2(-ov, 0),
		pos + Vector2(w + ov, 0),
		pos + Vector2(w / 2, -38)
	])
	draw_colored_polygon(roof, COL_ROOF.darkened(0.12))
	var inner_roof := PackedVector2Array([
		pos + Vector2(-ov + 2, -2),
		pos + Vector2(w + ov - 2, -2),
		pos + Vector2(w / 2, -36)
	])
	draw_colored_polygon(inner_roof, COL_ROOF)
	draw_line(pos + Vector2(w / 2 - 2, -36), pos + Vector2(w / 2 + 2, -36),
		COL_ROOF.lightened(0.18), 2.5)

	# Left window
	draw_rect(Rect2(pos + Vector2(7, 12), Vector2(20, 18)), COL_WALL.darkened(0.30))
	draw_rect(Rect2(pos + Vector2(8, 13), Vector2(18, 16)), COL_WINDOW)
	draw_line(pos + Vector2(17.0, 13.0), pos + Vector2(17.0, 29.0), COL_WALL.darkened(0.2), 1.5)
	draw_line(pos + Vector2(8.0,  21.0), pos + Vector2(26.0, 21.0), COL_WALL.darkened(0.2), 1.5)

	# Right window
	draw_rect(Rect2(pos + Vector2(w - 27, 12), Vector2(20, 18)), COL_WALL.darkened(0.30))
	draw_rect(Rect2(pos + Vector2(w - 26, 13), Vector2(18, 16)), COL_WINDOW)
	draw_line(pos + Vector2(float(w) - 17.0, 13.0), pos + Vector2(float(w) - 17.0, 29.0), COL_WALL.darkened(0.2), 1.5)
	draw_line(pos + Vector2(float(w) - 26.0, 21.0), pos + Vector2(float(w) - 8.0, 21.0),  COL_WALL.darkened(0.2), 1.5)

	# Door (centred at bottom)
	var dx : float = pos.x + float(w) / 2.0 - 11.0
	var dy : float = pos.y + float(h) - 32.0
	draw_rect(Rect2(dx, dy, 22, 32), COL_DOOR.darkened(0.20))
	draw_rect(Rect2(dx + 1, dy + 1, 20, 31), COL_DOOR)
	draw_circle(Vector2(dx + 11.0, dy), 11.0, COL_DOOR)
	draw_circle(Vector2(dx + 11.0, dy),  9.0, COL_DOOR.lightened(0.08))
	draw_circle(Vector2(dx + 16.0, dy + 18.0), 2.0, Color(0.82, 0.68, 0.14))

# ── Camera ────────────────────────────────────────────────────────────────────

func _build_camera() -> void:
	cam = Camera2D.new()
	cam.position = Vector2(MAP_W / 2.0, MAP_H / 2.0)
	add_child(cam)

# ── UI ────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	# Top bar background
	var top_bg := ColorRect.new()
	top_bg.color = Color(0.08, 0.06, 0.04, 0.90)
	top_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bg.custom_minimum_size = Vector2(0, 54)
	ui_layer.add_child(top_bg)

	# Timer (centre)
	timer_label = Label.new()
	timer_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	timer_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	timer_label.offset_top    = 10
	timer_label.offset_bottom = 50
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_layer.add_child(timer_label)

	# Converted count (left)
	converted_label = Label.new()
	converted_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	converted_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	converted_label.offset_left   = 14
	converted_label.offset_top    = 13
	converted_label.offset_right  = 250
	converted_label.offset_bottom = 48
	converted_label.add_theme_font_size_override("font_size", 17)
	converted_label.add_theme_color_override("font_color", Color(0.70, 1.0, 0.55))
	ui_layer.add_child(converted_label)
	_refresh_converted_label()

	# Location name (right)
	var loc_label := Label.new()
	loc_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	loc_label.text = "Village of Ashford"
	loc_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	loc_label.offset_top    = 16
	loc_label.offset_left   = -240
	loc_label.offset_right  = -14
	loc_label.offset_bottom = 48
	loc_label.add_theme_font_size_override("font_size", 14)
	loc_label.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60))
	loc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_layer.add_child(loc_label)

	# Bottom bar background
	var bot_bg := ColorRect.new()
	bot_bg.color = Color(0.08, 0.06, 0.04, 0.90)
	bot_bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot_bg.offset_top = -74
	ui_layer.add_child(bot_bg)

	# Active ability button
	ability_btn = Button.new()
	ability_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	ability_btn.text = "✦ Holy Word  (area conversion)"
	ability_btn.add_theme_font_size_override("font_size", 14)
	ability_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	ability_btn.offset_bottom = -8
	ability_btn.offset_top    = -66
	ability_btn.offset_left   = 14
	ability_btn.offset_right  = 280
	ability_btn.connect("pressed", _use_ability)
	ui_layer.add_child(ability_btn)

	# Tap hint
	var hint := Label.new()
	hint.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hint.text = "Tap a villager to direct your preacher"
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_bottom = -8
	hint.offset_top    = -66
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_layer.add_child(hint)

	# Resistance bars — one per villager
	for i in range(TOTAL_VILLAGERS):
		var bg := ColorRect.new()
		bg.color               = Color(0.12, 0.10, 0.08, 0.88)
		bg.custom_minimum_size = Vector2(46, 7)
		bg.size                = Vector2(46, 7)
		ui_layer.add_child(bg)
		bar_bgs.append(bg)

		var fill := ColorRect.new()
		fill.color = Color(0.22, 0.82, 0.30)
		fill.size  = Vector2(46, 7)
		bg.add_child(fill)
		bar_fills.append(fill)

		villager_resist.append(MAX_RESISTANCE)
		villager_done.append(false)

	_build_result_panel()

func _build_result_panel() -> void:
	result_panel = PanelContainer.new()
	result_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.offset_left   = -215
	result_panel.offset_right  =  215
	result_panel.offset_top    = -190
	result_panel.offset_bottom =  190
	result_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.04, 0.97)
	style.set_border_width_all(2)
	style.border_color = Color(0.82, 0.66, 0.18)
	style.set_corner_radius_all(10)
	style.content_margin_left   = 22
	style.content_margin_right  = 22
	style.content_margin_top    = 20
	style.content_margin_bottom = 20
	result_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 12)
	result_panel.add_child(vbox)

	var title := Label.new()
	title.layout_direction = Control.LAYOUT_DIRECTION_LTR
	title.text = "Mission Complete!"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.96, 0.84, 0.24))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var result_lbl := Label.new()
	result_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	result_lbl.name = "ResultLbl"
	result_lbl.add_theme_font_size_override("font_size", 16)
	result_lbl.add_theme_color_override("font_color", Color(0.90, 0.88, 0.80))
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(result_lbl)

	var stars_lbl := Label.new()
	stars_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	stars_lbl.name = "StarsLbl"
	stars_lbl.add_theme_font_size_override("font_size", 36)
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stars_lbl)

	var ret_btn := Button.new()
	ret_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	ret_btn.text = "Return Home"
	ret_btn.add_theme_font_size_override("font_size", 16)
	ret_btn.connect("pressed", _return_home)
	vbox.add_child(ret_btn)

	ui_layer.add_child(result_panel)

# ── Spawning ──────────────────────────────────────────────────────────────────

func _spawn_villagers() -> void:
	for i in range(TOTAL_VILLAGERS):
		var v : CharacterBody2D = preload("res://believer.tscn").instantiate()
		var home : Vector2 = VILLAGER_HOMES[i]
		v.setup(home, i)
		add_child(v)
		villager_nodes.append(v)

func _spawn_preacher() -> void:
	preacher_node = preload("res://believer.tscn").instantiate()
	preacher_node.is_preacher = true
	preacher_node.move_speed = 58.0
	add_child(preacher_node)
	preacher_node.setup(ENTRY_POS, 0)

# ── Input — tap villager to direct preacher ───────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if campaign_ended:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var world_pos : Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
	var best_idx  : int   = -1
	var best_dist : float = 70.0
	for i in range(TOTAL_VILLAGERS):
		if villager_done[i]:
			continue
		var d : float = (villager_nodes[i].global_position - world_pos).length()
		if d < best_dist:
			best_dist = d
			best_idx  = i
	if best_idx >= 0:
		preacher_node.walk_to(villager_nodes[best_idx].global_position)

# ── Process ───────────────────────────────────────────────────────────────────

func _process(delta) -> void:
	if campaign_ended:
		return
	timer_remaining -= delta
	if timer_remaining <= 0.0:
		timer_remaining = 0.0
		_end_campaign()
		return
	_update_timer_label()
	_tick_conversion(delta)
	_update_bar_positions()

func _update_timer_label() -> void:
	var mins : int = int(timer_remaining) / 60
	var secs : int = int(timer_remaining) % 60
	timer_label.text = "⏱  %d:%02d" % [mins, secs]
	# Shift colour red in last 30 seconds
	if timer_remaining < 30.0:
		var t : float = timer_remaining / 30.0
		timer_label.add_theme_color_override("font_color", Color(1.0, t * 0.70, t * 0.20))

func _refresh_converted_label() -> void:
	if converted_label:
		converted_label.text = "Converted:  %d / %d" % [converted_count, TOTAL_VILLAGERS]

func _tick_conversion(delta) -> void:
	if preacher_node == null:
		return
	var p_pos : Vector2 = preacher_node.global_position
	for i in range(TOTAL_VILLAGERS):
		if villager_done[i]:
			continue
		var dist : float = (villager_nodes[i].global_position - p_pos).length()
		if dist <= CONVERT_RANGE:
			villager_resist[i] -= CONVERT_RATE * delta
			if villager_resist[i] <= 0.0:
				villager_resist[i] = 0.0
				_convert_villager(i)
				continue
		# Update bar fill width and colour
		var pct  : float    = villager_resist[i] / MAX_RESISTANCE
		var fill : ColorRect = bar_fills[i]
		fill.size = Vector2(46.0 * pct, fill.size.y)
		if pct > 0.5:
			fill.color = Color(1.0 - (1.0 - pct) * 2.0, 0.82, 0.22)
		else:
			fill.color = Color(0.92, pct * 2.0 * 0.82, 0.10)

func _convert_villager(idx: int) -> void:
	villager_done[idx] = true
	converted_count += 1
	_refresh_converted_label()
	var bg : ColorRect = bar_bgs[idx]
	bg.visible = false
	# Golden tint — villager has joined your faith
	villager_nodes[idx].modulate = Color(1.0, 0.90, 0.40)
	# Walk to rally point, staggered so they don't pile up
	var rally : Vector2 = RALLY_POS + Vector2(0.0, float(idx - 4) * 22.0)
	villager_nodes[idx].walk_to(rally)
	if converted_count >= TOTAL_VILLAGERS:
		_end_campaign()

func _update_bar_positions() -> void:
	var ct : Transform2D = get_viewport().get_canvas_transform()
	for i in range(TOTAL_VILLAGERS):
		if villager_done[i]:
			continue
		var screen_pos : Vector2 = ct * villager_nodes[i].global_position
		var bg : ColorRect = bar_bgs[i]
		bg.position = screen_pos + Vector2(-23.0, -42.0)

# ── Active ability — Holy Word ────────────────────────────────────────────────

func _use_ability() -> void:
	if ability_used or campaign_ended:
		return
	ability_used = true
	ability_btn.disabled = true
	ability_btn.text = "✦ Holy Word  (used)"
	ability_btn.modulate = Color(0.50, 0.50, 0.50)

	var p_pos : Vector2 = preacher_node.global_position
	for i in range(TOTAL_VILLAGERS):
		if villager_done[i]:
			continue
		var dist : float = (villager_nodes[i].global_position - p_pos).length()
		if dist <= ABILITY_RANGE:
			villager_resist[i] = max(0.0, villager_resist[i] - ABILITY_POWER)
			if villager_resist[i] <= 0.0:
				_convert_villager(i)

# ── Campaign end ──────────────────────────────────────────────────────────────

func _end_campaign() -> void:
	if campaign_ended:
		return
	campaign_ended = true
	if preacher_node:
		preacher_node.park()

	var pct   : float = float(converted_count) / float(TOTAL_VILLAGERS)
	var stars : int
	if pct >= 0.75:
		stars = 3
	elif pct >= 0.40:
		stars = 2
	else:
		stars = 1

	# Store results — game.gd reads and applies these on return
	GameData.campaign_result_believers = converted_count
	GameData.campaign_result_stars     = stars

	var result_lbl : Label = result_panel.get_node("VBox/ResultLbl")
	var stars_lbl  : Label = result_panel.get_node("VBox/StarsLbl")

	result_lbl.text = "You converted %d of %d villagers\n\n+%d gold   +%d believers" % [
		converted_count, TOTAL_VILLAGERS,
		converted_count * 15,
		converted_count,
	]

	var star_str := ""
	for _s in range(stars):
		star_str += "★"
	for _s in range(3 - stars):
		star_str += "☆"
	stars_lbl.text = star_str
	stars_lbl.add_theme_color_override("font_color",
		Color(0.96, 0.84, 0.16) if stars >= 2 else Color(0.50, 0.46, 0.36)
	)

	result_panel.visible = true

func _return_home() -> void:
	get_tree().change_scene_to_file("res://game.tscn")
