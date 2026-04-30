extends Node2D

# ── Config ────────────────────────────────────────────────────────────────────
const CAMPAIGN_DURATION := 600.0   # 10 minutes
const TOTAL_VILLAGERS   := 14
const MAX_RESISTANCE    := 8.0
const CONVERT_RANGE     := 75.0
const CONVERT_RATE      := 0.85    # resistance drained per second while in range
const FIGHT_DURATION    := 4.0     # seconds soldier fights at blockade
const MAP_W             := 2200
const MAP_H             := 1100
const ZOOM_MIN          := 0.40
const ZOOM_MAX          := 2.50
const ZOOM_FACTOR       := 1.12

# Palette
const COL_GROUND := Color(0.72, 0.65, 0.50)
const COL_PATH   := Color(0.60, 0.53, 0.38)
const COL_WALL   := Color(0.75, 0.63, 0.45)
const COL_ROOF   := Color(0.45, 0.32, 0.14)
const COL_WINDOW := Color(0.70, 0.82, 0.90)
const COL_DOOR   := Color(0.35, 0.22, 0.10)
# Key positions
const CAMP_DOOR_POS  := Vector2(130, 558)   # converted villagers walk here then vanish
const PREACHER_START := Vector2(260, 535)
const SOLDIER_START  := Vector2(275, 558)
const BLOCKADE_POS   := Vector2(1110, 550)
const WELL_POS       := Vector2(680, 550)

# Village houses {pos, w, h}
const HOUSES := [
	{"pos": Vector2(320,  295), "w": 95,  "h": 75},
	{"pos": Vector2(430,  420), "w": 85,  "h": 70},
	{"pos": Vector2(320,  645), "w": 95,  "h": 75},
	{"pos": Vector2(680,  215), "w": 100, "h": 80},
	{"pos": Vector2(840,  175), "w": 95,  "h": 75},
	{"pos": Vector2(985,  265), "w": 100, "h": 80},
	{"pos": Vector2(680,  695), "w": 100, "h": 80},
	{"pos": Vector2(840,  748), "w": 95,  "h": 75},
	{"pos": Vector2(985,  645), "w": 100, "h": 80},
	{"pos": Vector2(1300, 240), "w": 100, "h": 80},
	{"pos": Vector2(1490, 170), "w": 95,  "h": 75},
	{"pos": Vector2(1680, 240), "w": 100, "h": 80},
	{"pos": Vector2(1300, 660), "w": 100, "h": 80},
	{"pos": Vector2(1490, 730), "w": 95,  "h": 75},
	{"pos": Vector2(1680, 645), "w": 100, "h": 80},
]

# Villager wander centres — left cluster (0-2), central (3-7), right behind blockade (8-13)
const VILLAGER_HOMES := [
	Vector2(368, 370),
	Vector2(473, 492),
	Vector2(368, 720),
	Vector2(730, 295),
	Vector2(888, 250),
	Vector2(1035, 345),
	Vector2(730, 775),
	Vector2(888, 823),
	Vector2(1350, 320),
	Vector2(1538, 248),
	Vector2(1730, 320),
	Vector2(1350, 740),
	Vector2(1538, 808),
	Vector2(1730, 725),
]

# ── Runtime state ─────────────────────────────────────────────────────────────
var timer_remaining  : float = CAMPAIGN_DURATION
var converted_count  : int   = 0
var campaign_ended   : bool  = false
var blockade_alive   : bool  = true
var soldier_fighting : bool  = false
var fight_timer      : float = 0.0
var conversion_mult  : float = 1.0   # hero passive bonus

# Node refs
var cam             : Camera2D       = null
var ui_layer        : CanvasLayer    = null
var timer_label     : Label          = null
var converted_label : Label          = null
var result_panel    : PanelContainer = null
var fight_label     : Label          = null

var preacher_node  : CharacterBody2D = null
var soldier_node   : CharacterBody2D = null
var villager_nodes : Array = []
var villager_resist: Array = []   # float  — current resistance (MAX → 0)
var villager_done  : Array = []   # bool   — converted and sent home
var villager_active: Array = []   # bool   — preacher has touched this villager at least once
var bar_bgs          : Array = []
var bar_fills        : Array = []
var blockade_guards  : Array = []

var is_panning   : bool    = false
var pan_last_pos : Vector2 = Vector2.ZERO
var base_camp_btn: Button  = null

# ── Ready ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_apply_hero_bonus()
	_build_camera()
	_build_ui()
	_spawn_trees()
	_spawn_village_houses()
	_spawn_well()
	_spawn_camp_building()
	_spawn_villagers()
	_spawn_preacher()
	_spawn_soldier()
	_spawn_blockade_guards()
	if GameData.mission_active:
		_restore_mission_state()
	else:
		GameData.mission_active = true

func _apply_hero_bonus() -> void:
	# Placeholder: wire to GameData hero selection when hero system is ready
	conversion_mult = 1.0

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	draw_rect(Rect2(0, 0, MAP_W, MAP_H), COL_GROUND)
	_draw_roads()
	if blockade_alive:
		_draw_blockade()

func _draw_roads() -> void:
	# Main east-west road
	draw_rect(Rect2(0, 515, MAP_W, 70), COL_PATH)
	# Vertical branches (N and S of main road)
	draw_rect(Rect2(375,  0,   70, 515),            COL_PATH)
	draw_rect(Rect2(375,  585, 70, MAP_H - 585),    COL_PATH)
	draw_rect(Rect2(875,  0,   70, 515),            COL_PATH)
	draw_rect(Rect2(875,  585, 70, MAP_H - 585),    COL_PATH)
	draw_rect(Rect2(1490, 0,   70, 515),            COL_PATH)
	draw_rect(Rect2(1490, 585, 70, MAP_H - 585),    COL_PATH)

func _draw_blockade() -> void:
	var bx : float = BLOCKADE_POS.x
	var by : float = BLOCKADE_POS.y
	# Wooden planks across the road
	for i in range(5):
		var px : float = bx - 58.0 + float(i) * 28.0
		draw_rect(Rect2(px, by - 40.0, 22.0, 80.0), Color(0.48, 0.34, 0.14))
		draw_rect(Rect2(px + 2.0, by - 38.0, 18.0, 76.0), Color(0.58, 0.42, 0.18))
	# Crossbeams
	draw_rect(Rect2(bx - 62.0, by - 8.0, 124.0, 10.0), Color(0.40, 0.28, 0.10))
	draw_rect(Rect2(bx - 62.0, by + 6.0, 124.0, 10.0), Color(0.40, 0.28, 0.10))
	# Guards are spawned as real soldier nodes (see _spawn_blockade_guards)

# ── Camera ────────────────────────────────────────────────────────────────────

func _build_camera() -> void:
	cam = Camera2D.new()
	cam.position     = Vector2(380, MAP_H / 2.0)
	cam.limit_left   = 0
	cam.limit_right  = MAP_W
	cam.limit_top    = 0
	cam.limit_bottom = MAP_H
	add_child(cam)

func _zoom_camera(screen_pivot: Vector2, direction: int) -> void:
	var old_zoom := cam.zoom.x
	var new_zoom: float = clampf(
		old_zoom * (ZOOM_FACTOR if direction > 0 else 1.0 / ZOOM_FACTOR),
		ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(new_zoom, old_zoom):
		return
	var vp_center   := get_viewport().get_visible_rect().size * 0.5
	var world_pivot := cam.position + (screen_pivot - vp_center) / old_zoom
	cam.zoom        = Vector2(new_zoom, new_zoom)
	cam.position    = world_pivot - (screen_pivot - vp_center) / new_zoom

# ── UI ────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	timer_label = Label.new()
	timer_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	timer_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	timer_label.offset_top    = 8
	timer_label.offset_bottom = 42
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.40))
	timer_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.80))
	timer_label.add_theme_constant_override("shadow_offset_x", 2)
	timer_label.add_theme_constant_override("shadow_offset_y", 2)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_layer.add_child(timer_label)

	converted_label = Label.new()
	converted_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	converted_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	converted_label.offset_left   = 10
	converted_label.offset_top    = 10
	converted_label.offset_right  = 240
	converted_label.offset_bottom = 40
	converted_label.add_theme_font_size_override("font_size", 16)
	converted_label.add_theme_color_override("font_color", Color(0.70, 1.0, 0.55))
	converted_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.80))
	converted_label.add_theme_constant_override("shadow_offset_x", 2)
	converted_label.add_theme_constant_override("shadow_offset_y", 2)
	ui_layer.add_child(converted_label)
	_refresh_converted_label()

	var loc_label := Label.new()
	loc_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	loc_label.text = "Village of Ashford"
	loc_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	loc_label.offset_top    = 12
	loc_label.offset_left   = -230
	loc_label.offset_right  = -10
	loc_label.offset_bottom = 40
	loc_label.add_theme_font_size_override("font_size", 13)
	loc_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
	loc_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.80))
	loc_label.add_theme_constant_override("shadow_offset_x", 2)
	loc_label.add_theme_constant_override("shadow_offset_y", 2)
	loc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_layer.add_child(loc_label)

	# Per-villager conversion bars (hidden until preacher activates them)
	for i in range(TOTAL_VILLAGERS):
		var bg := ColorRect.new()
		bg.color               = Color(0.12, 0.10, 0.08, 0.90)
		bg.custom_minimum_size = Vector2(48, 8)
		bg.size                = Vector2(48, 8)
		bg.visible             = false
		bg.mouse_filter        = Control.MOUSE_FILTER_STOP
		bg.connect("gui_input", _on_bar_input.bind(i))
		ui_layer.add_child(bg)
		bar_bgs.append(bg)

		var fill := ColorRect.new()
		fill.color        = Color(0.85, 0.22, 0.12)
		fill.size         = Vector2(0, 8)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(fill)
		bar_fills.append(fill)

		villager_resist.append(MAX_RESISTANCE)
		villager_done.append(false)
		villager_active.append(false)

	# Fight label (shows over blockade while soldier fights)
	fight_label = Label.new()
	fight_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	fight_label.text    = "⚔ Fighting!"
	fight_label.visible = false
	fight_label.add_theme_font_size_override("font_size", 14)
	fight_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.16))
	ui_layer.add_child(fight_label)

	# Bottom hint bar
	var bot_bg := ColorRect.new()
	bot_bg.color = Color(0.08, 0.06, 0.04, 0.85)
	bot_bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot_bg.offset_top = -42
	ui_layer.add_child(bot_bg)

	var hint := Label.new()
	hint.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hint.text = "Tap villager → send preacher  ·  Tap bar → instant convert  ·  Tap blockade → send soldier"
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_bottom = -6
	hint.offset_top    = -40
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.58, 0.54, 0.44))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_layer.add_child(hint)

	# Base Camp button — lets player switch back to base while mission runs
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color     = Color(0.14, 0.22, 0.38, 0.95)
	btn_style.border_color = Color(0.42, 0.72, 1.0)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(8)
	btn_style.content_margin_left   = 12
	btn_style.content_margin_right  = 12
	btn_style.content_margin_top    = 6
	btn_style.content_margin_bottom = 6
	var btn_hover := btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.20, 0.32, 0.55, 0.95)
	base_camp_btn = Button.new()
	base_camp_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	base_camp_btn.text = "⌂  Base Camp"
	base_camp_btn.add_theme_font_size_override("font_size", 14)
	base_camp_btn.add_theme_color_override("font_color", Color(0.70, 0.90, 1.0))
	base_camp_btn.add_theme_stylebox_override("normal",   btn_style)
	base_camp_btn.add_theme_stylebox_override("hover",    btn_hover)
	base_camp_btn.add_theme_stylebox_override("pressed",  btn_hover)
	base_camp_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	base_camp_btn.offset_left   = 248
	base_camp_btn.offset_right  = 390
	base_camp_btn.offset_top    = 8
	base_camp_btn.offset_bottom = 40
	base_camp_btn.connect("pressed", _go_to_base)
	ui_layer.add_child(base_camp_btn)

	_build_result_panel()

func _on_bar_input(event: InputEvent, idx: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if villager_active[idx] and not villager_done[idx]:
		villager_resist[idx] = 0.0
		_convert_villager(idx)

func _build_result_panel() -> void:
	result_panel = PanelContainer.new()
	result_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.offset_left   = -215
	result_panel.offset_right  =  215
	result_panel.offset_top    = -185
	result_panel.offset_bottom =  185
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

# ── Base-camp switch ──────────────────────────────────────────────────────────

func _go_to_base() -> void:
	_save_mission_state()
	get_tree().change_scene_to_file("res://game.tscn")

func _save_mission_state() -> void:
	GameData.mission_active            = not campaign_ended
	GameData.mission_exit_ticks_msec   = Time.get_ticks_msec()
	GameData.mission_timer_remaining   = timer_remaining
	GameData.mission_converted_count   = converted_count
	GameData.mission_campaign_ended    = campaign_ended
	GameData.mission_blockade_alive    = blockade_alive
	GameData.mission_villager_resist   = villager_resist.duplicate()
	GameData.mission_villager_done     = villager_done.duplicate()
	GameData.mission_villager_active   = villager_active.duplicate()
	var positions: Array = []
	for v: CharacterBody2D in villager_nodes:
		positions.append(v.global_position)
	GameData.mission_villager_positions = positions

func _restore_mission_state() -> void:
	var elapsed := float(Time.get_ticks_msec() - GameData.mission_exit_ticks_msec) / 1000.0
	timer_remaining = maxf(0.0, GameData.mission_timer_remaining - elapsed)
	converted_count = GameData.mission_converted_count
	campaign_ended  = GameData.mission_campaign_ended
	blockade_alive  = GameData.mission_blockade_alive
	villager_resist  = GameData.mission_villager_resist.duplicate()
	villager_done    = GameData.mission_villager_done.duplicate()
	villager_active  = GameData.mission_villager_active.duplicate()
	for i in range(mini(villager_nodes.size(), GameData.mission_villager_positions.size())):
		var pos := GameData.mission_villager_positions[i] as Vector2
		villager_nodes[i].global_position = pos
		if villager_done[i]:
			villager_nodes[i].visible = false
			villager_nodes[i].park()
		elif villager_active[i]:
			bar_bgs[i].visible = true
	if not blockade_alive:
		queue_redraw()
	if campaign_ended:
		_end_campaign()
	elif timer_remaining <= 0.0:
		_end_campaign()
	_refresh_converted_label()

# ── Spawning ──────────────────────────────────────────────────────────────────

func _spawn_trees() -> void:
	var tex15 : Texture2D = load("res://Comp15.png")
	var tex16 : Texture2D = load("res://Comp16.png")
	if tex15 == null or tex16 == null:
		return
	# [type(15|16), world_x, world_y_center, size_scale]
	# Placed to avoid roads (x=375-445, 875-945, 1490-1560; y=515-585) and houses
	var data := [
		# Far top-left corner
		[15,   30,   80,  1.00], [16,  130,   45,  0.88], [16,  250,   95,  0.85],
		# Left strip / mid
		[16,  270,  420,  0.75], [15,   80,  900,  0.88], [16,  200,  970,  0.85],
		# Top — between road1 and road2
		[15,  500,   80,  0.92], [16,  680,   70,  0.85], [15,  800,   60,  0.90],
		[16,  490,  360,  0.80],
		# Top — between road2 and road3
		[15, 1000,   90,  0.90], [16, 1150,   70,  0.85],
		[16, 1280,   90,  0.88], [15, 1420,  100,  0.82],
		# Top — right of road3
		[16, 1620,   80,  0.90], [15, 1760,   55,  0.95],
		[16, 1930,   80,  0.88], [15, 2100,  120,  0.92], [16, 2180,  280,  0.85],
		# Far-right strip
		[15, 2150,  460,  0.90], [16, 2150,  700,  0.85],
		# Bottom — between road1 and road2
		[15,  510,  950,  0.88], [16,  700,  980,  0.82], [15,  820,  960,  0.90],
		# Bottom — between road2 and road3
		[16, 1010,  950,  0.88], [15, 1200,  980,  0.90], [16, 1380,  960,  0.85],
		# Bottom — right of road3
		[15, 1620,  980,  0.92], [16, 1820, 1000,  0.88],
		[15, 2050,  960,  0.90], [16, 2150,  820,  0.85],
	]
	var base_w := 92.0
	for t in data:
		var tex : Texture2D = tex15 if t[0] == 15 else tex16
		var s := Sprite2D.new()
		s.texture = tex
		var sc := (base_w * float(t[3])) / float(tex.get_width())
		s.scale = Vector2(sc, sc)
		s.position = Vector2(float(t[1]), float(t[2]))
		add_child(s)

func _spawn_village_houses() -> void:
	var tex : Texture2D = load("res://Comp1.png")
	if tex == null:
		return
	var target_w := 92.0
	var sc := target_w / float(tex.get_width())
	var scaled_h := float(tex.get_height()) * sc
	for h in HOUSES:
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2(sc, sc)
		# Align bottom of sprite with house ground level; offset so chimney clears
		var hp  := h["pos"] as Vector2
		var cx  : float = hp.x + (h["w"] as int) * 0.5
		var cy  : float = hp.y + (h["h"] as int) - scaled_h * 0.5 + 12.0
		s.position = Vector2(cx, cy)
		add_child(s)

func _spawn_well() -> void:
	var tex : Texture2D = load("res://Comp10.png")
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	var sc := 78.0 / float(tex.get_width())
	s.scale = Vector2(sc, sc)
	s.position = WELL_POS
	add_child(s)

func _spawn_camp_building() -> void:
	var b := StaticBody2D.new()
	b.set_script(load("res://building.gd"))
	b.building_type = "preacher_shelter"
	b.position = Vector2(130, 510)
	add_child(b)

func _spawn_blockade_guards() -> void:
	for gx in [BLOCKADE_POS.x - 78.0, BLOCKADE_POS.x + 64.0]:
		var g : CharacterBody2D = preload("res://believer.tscn").instantiate()
		g.is_soldier = true
		add_child(g)
		g.setup(Vector2(gx, BLOCKADE_POS.y - 10.0), 0)
		g.park()
		g.scale.x = -1   # face left (toward the player's side)
		blockade_guards.append(g)

func _spawn_villagers() -> void:
	for i in range(TOTAL_VILLAGERS):
		var v : CharacterBody2D = preload("res://believer.tscn").instantiate()
		v.setup(VILLAGER_HOMES[i], i)
		add_child(v)
		villager_nodes.append(v)

func _spawn_preacher() -> void:
	preacher_node = preload("res://believer.tscn").instantiate()
	preacher_node.is_preacher = true
	preacher_node.move_speed  = 58.0
	add_child(preacher_node)
	preacher_node.setup(PREACHER_START, 0)

func _spawn_soldier() -> void:
	soldier_node = preload("res://believer.tscn").instantiate()
	soldier_node.is_soldier = true
	soldier_node.move_speed = 62.0
	add_child(soldier_node)
	soldier_node.setup(SOLDIER_START, 1)

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if campaign_ended:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(event.position, 1)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(event.position, -1)
			return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var world_pos : Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
			# Villager tap → direct preacher
			var best_idx  : int   = -1
			var best_dist : float = 68.0
			for i in range(TOTAL_VILLAGERS):
				if villager_done[i]:
					continue
				var d : float = (villager_nodes[i].global_position - world_pos).length()
				if d < best_dist:
					best_dist = d
					best_idx  = i
			if best_idx >= 0:
				preacher_node.walk_to(villager_nodes[best_idx].global_position)
				return
			# Blockade tap → send soldier
			if blockade_alive and not soldier_fighting:
				var bd : float = (BLOCKADE_POS - world_pos).length()
				if bd < 88.0:
					_send_soldier_to_blockade()
					return
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			is_panning   = true
			pan_last_pos = event.position
		elif not event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			is_panning = false
	elif event is InputEventMouseMotion and is_panning:
		var delta : Vector2 = pan_last_pos - event.position
		pan_last_pos = event.position
		cam.position += delta / cam.zoom.x

# ── Process ───────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
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
	_tick_fight(delta)

func _update_timer_label() -> void:
	var mins : int = int(timer_remaining) / 60
	var secs : int = int(timer_remaining) % 60
	timer_label.text = "⏱  %d:%02d" % [mins, secs]
	if timer_remaining < 60.0:
		var t : float = timer_remaining / 60.0
		timer_label.add_theme_color_override("font_color", Color(1.0, t * 0.70, t * 0.20))

func _refresh_converted_label() -> void:
	if converted_label:
		converted_label.text = "Converted:  %d / %d" % [converted_count, TOTAL_VILLAGERS]

func _tick_conversion(delta: float) -> void:
	if preacher_node == null:
		return
	var p_pos : Vector2 = preacher_node.global_position
	for i in range(TOTAL_VILLAGERS):
		if villager_done[i]:
			continue
		var dist : float = (villager_nodes[i].global_position - p_pos).length()
		if dist <= CONVERT_RANGE:
			if not villager_active[i]:
				villager_active[i]  = true
				bar_bgs[i].visible  = true
			villager_resist[i] -= CONVERT_RATE * conversion_mult * delta
			if villager_resist[i] <= 0.0:
				villager_resist[i] = 0.0
				_convert_villager(i)
				continue
		if not villager_active[i]:
			continue
		# Update bar fill — grows from left as resistance drains
		var progress : float    = 1.0 - (villager_resist[i] / MAX_RESISTANCE)
		var fill     : ColorRect = bar_fills[i]
		fill.size  = Vector2(48.0 * progress, fill.size.y)
		fill.color = Color(0.85, 0.22, 0.12).lerp(Color(0.20, 0.88, 0.22), progress)

func _convert_villager(idx: int) -> void:
	villager_done[idx]           = true
	bar_bgs[idx].visible         = false
	villager_nodes[idx].modulate = Color(1.0, 0.90, 0.40)
	villager_nodes[idx].walk_to(CAMP_DOOR_POS)
	villager_nodes[idx].reached_forced_target.connect(_on_villager_home.bind(idx), CONNECT_ONE_SHOT)

func _on_villager_home(idx: int) -> void:
	villager_nodes[idx].visible = false
	converted_count += 1
	_refresh_converted_label()
	if converted_count >= TOTAL_VILLAGERS:
		_end_campaign()

func _update_bar_positions() -> void:
	var ct : Transform2D = get_viewport().get_canvas_transform()
	for i in range(TOTAL_VILLAGERS):
		if not villager_active[i] or villager_done[i]:
			continue
		var screen_pos : Vector2 = ct * villager_nodes[i].global_position
		bar_bgs[i].position = screen_pos + Vector2(-24.0, -48.0)

func _tick_fight(delta: float) -> void:
	if not soldier_fighting:
		return
	if fight_timer <= 0.0:
		return
	fight_timer -= delta
	# Update fight label position above blockade
	var ct : Transform2D = get_viewport().get_canvas_transform()
	var sp : Vector2 = ct * BLOCKADE_POS
	fight_label.position = sp + Vector2(-38.0, -58.0)
	if fight_timer <= 0.0:
		soldier_fighting         = false
		blockade_alive           = false
		fight_label.visible      = false
		soldier_node.is_attacking = false
		queue_redraw()
		soldier_node.park()
		for g in blockade_guards:
			g.queue_free()
		blockade_guards.clear()

func _send_soldier_to_blockade() -> void:
	soldier_fighting    = true
	fight_label.visible = true
	# Stop 130px left — leaves a visible gap from the left guard at -78
	soldier_node.walk_to(BLOCKADE_POS + Vector2(-130.0, 0.0))
	soldier_node.reached_forced_target.connect(_on_soldier_at_blockade, CONNECT_ONE_SHOT)

func _on_soldier_at_blockade() -> void:
	fight_timer = FIGHT_DURATION
	# Park soldier, force flip_h=false so attack row (naturally faces right) shows correctly
	soldier_node.park()
	soldier_node.call("set_attack_flip", false)  # flip_h=false → attack faces right toward guards
	soldier_node.is_attacking = true
	# Guards stay in place — scale.x=-1 + flip_h=false already faces them left toward soldier
	for g in blockade_guards:
		g.call("set_attack_flip", false)
		g.is_attacking = true

# ── Campaign end ──────────────────────────────────────────────────────────────

func _end_campaign() -> void:
	if campaign_ended:
		return
	campaign_ended = true
	GameData.mission_active = false
	if base_camp_btn:
		base_camp_btn.visible = false
	if preacher_node:
		preacher_node.park()
	if soldier_node:
		soldier_node.park()

	var pct   : float = float(converted_count) / float(TOTAL_VILLAGERS)
	var stars : int
	if pct >= 0.80:
		stars = 3
	elif pct >= 0.50:
		stars = 2
	else:
		stars = 1

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
		Color(0.96, 0.84, 0.16) if stars >= 2 else Color(0.50, 0.46, 0.36))

	result_panel.visible = true

func _return_home() -> void:
	get_tree().change_scene_to_file("res://game.tscn")
