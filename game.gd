extends Node

# ── Resources ───────────────────────────────────────────────────────────────
var gold: int = 100
var faith: int = 100        # start with 100
var believers_count: int = 5

# ── Wheel of Faith ──────────────────────────────────────────────────────────
var wheel_available: bool = true
var wheel_spinning:  bool = false
var is_first_spin:   bool = true
var wheel_daily_timer: float = 0.0
const WHEEL_DAILY_COOLDOWN := 86400.0
var wheel_popup: Control = null
var wheel_spinner: Node2D = null
var wheel_spin_btn: Button = null
var wheel_result_label: Label = null
var wheel_result_panel: PanelContainer = null
var wheel_chip_node: PanelContainer = null

const WHEEL_SEGMENTS := [
	{"label": "+50 Gold",        "color": Color(0.90, 0.70, 0.10), "type": "gold",     "amount": 50 },
	{"label": "+20 Faith",       "color": Color(0.35, 0.20, 0.75), "type": "faith",    "amount": 20 },
	{"label": "+100 Gold",       "color": Color(0.85, 0.45, 0.05), "type": "gold",     "amount": 100},
	{"label": "Dark Omen\n-20 Gold","color": Color(0.20, 0.10, 0.30),"type": "bad",   "amount": -20},
	{"label": "+50 Faith",       "color": Color(0.55, 0.18, 0.88), "type": "faith",    "amount": 50 },
	{"label": "Aldric\nThe Prophet", "color": Color(0.10, 0.45, 0.65), "type": "card", "amount": 0 },
	{"label": "+200 Gold",       "color": Color(0.95, 0.80, 0.00), "type": "gold",     "amount": 200},
	{"label": "Blessing\n+100 Faith","color": Color(0.72, 0.28, 0.88),"type": "faith", "amount": 100},
]

# ── Scene refs ──────────────────────────────────────────────────────────────
var world: Node2D
var shelter: Area2D
var temple: Area2D = null
var hall_of_devoted: Area2D = null
var preacher_shelter_building: Area2D = null
var ghost_node: Area2D = null
var believers := []
var preachers := []   # believer nodes that have been converted

# ── UI refs ─────────────────────────────────────────────────────────────────
# ── Armory / soldiers ────────────────────────────────────────────────────────
var armory: Area2D = null
var garrison: Area2D = null
var soldiers_count: int = 0
var soldiers_in_garrison: int = 0
var armory_built: bool = false
var garrison_built: bool = false
var soldier_waiting_at_armory: bool = false
var soldiers := []
var training_panel: PanelContainer
var training_label: Label
var training_bar: ColorRect
var train_btn: Button
var training_rush_btn: Button
var barracks_soldier_label: Label   # unused — kept to avoid null refs
var garrison_panel: PanelContainer
var garrison_soldier_label: Label
var training: bool = false
var training_timer: float = 0.0
var training_node: CharacterBody2D = null

# ── Camera / panning ─────────────────────────────────────────────────────────
var camera: Camera2D = null
var is_panning := false
var pan_start_mouse := Vector2.ZERO
var pan_start_cam := Vector2.ZERO

# ── UI refs ──────────────────────────────────────────────────────────────────
var gold_label: Label
var faith_label: Label
var believers_label: Label
var build_button: Button
var people_panel: PanelContainer
var people_detail_label: Label
var info_popup: PanelContainer
var info_popup_label: Label
var info_popup_timer: float = 0.0
var build_menu: PanelContainer
var tutorial_panel: PanelContainer
var tutorial_label: Label
var tutorial_next_btn: Button
var construction_panel: PanelContainer
var construction_label: Label
var construction_bar: ColorRect
var rush_button: Button
var conversion_panel: PanelContainer
var conversion_label: Label
var conversion_bar: ColorRect
var convert_btn: Button
var conversion_rush_btn: Button
var hall_preacher_label: Label   # unused — kept to avoid null refs
var preacher_shelter_panel: PanelContainer
var shelter_preacher_label: Label
var shelter_panel: PanelContainer
var shelter_believer_label: Label
var extra_shelter_panel: PanelContainer = null
var extra_shelter_label: Label = null
var extra_shelter_buildings: Array = []
var current_extra_shelter_idx: int = 0
var temple_panel: PanelContainer
var temple_praying_label: Label
var temple_prayer_row: VBoxContainer   # dynamic container; session rows are added/removed here
var pray_go_btn: Button
var pray_selector_row: HBoxContainer
var pray_selector_label: Label
var pray_progress_container: VBoxContainer
var pray_status_label: Label
var pray_bar: ColorRect
var pray_rush_btn: Button
# Extra shelter pray UI (shared, repopulated on each tap)
var extra_pray_go_btn: Button = null
var extra_pray_selector_row: HBoxContainer = null
var extra_pray_selector_label: Label = null
var extra_pray_progress_container: VBoxContainer = null
var extra_pray_selector_count: int = 1

# prayer_sessions: Array of { count, timer, accumulator, nodes, home_pos, shelter_idx, row, bar }
# shelter_idx 0 = Humble Shelter, 1+ = extra shelter slot
var prayer_sessions: Array = []
var prayer_selector_count: int = 1
const PRAYER_TIME := 1800.0

# ── Tutorial ─────────────────────────────────────────────────────────────────
enum TutStep { INTRO, BUILD_TEMPLE, PLACE_TEMPLE, RUSH_PROMPT, TEMPLE_COMPLETE, TAP_SHELTER, TAP_GO_PRAY, CHOOSE_BELIEVERS, COMPLETE, WHEEL_HINT, DONE }
var tut_step := TutStep.INTRO
var tut_popup_dismissed: bool = false
var tutorial_overlay: ColorRect = null
var tutorial_popup: PanelContainer = null
var tutorial_popup_text: Label = null

# ── Resources ────────────────────────────────────────────────────────────────
var preachers_count: int = 0
var preachers_in_shelter: int = 0
var preacher_shelter_built: bool = false
var believer_shelter_count: int = 1   # starts with 1 (the initial shelter)
var believer_capacity: int = 5        # 5 per shelter

# Conversion movement tracking
var converting_node: CharacterBody2D = null   # the believer currently being converted
var preacher_waiting_at_hall: bool = false    # converted but no shelter yet

# ── Spread the Faith ─────────────────────────────────────────────────────────
var spreading: bool = false
var spread_timer: float = 0.0
const SPREAD_TIME := 7200.0  # 2 hours
var spread_sent: int = 0
var spread_selector_count: int = 1
var spreading_nodes: Array = []
var spread_go_btn: Button = null
var spread_selector_row: HBoxContainer = null
var spread_selector_label: Label = null
var spread_progress_container: VBoxContainer = null
var spread_bar: ColorRect = null
var spread_label: Label = null
var spread_rush_btn: Button = null
var spread_result_popup: Control = null
var spread_result_label: Label = null

# ── Crusade ───────────────────────────────────────────────────────────────────
var crusading: bool = false
var crusade_timer: float = 0.0
const CRUSADE_TIME := 7200.0   # 2 hours
var crusade_sent: int = 0
var crusade_selector_count: int = 1
var crusading_nodes: Array = []
var crusade_go_btn: Button = null
var crusade_selector_row: HBoxContainer = null
var crusade_selector_label: Label = null
var crusade_progress_container: VBoxContainer = null
var crusade_bar: ColorRect = null
var crusade_timer_label: Label = null
var crusade_rush_btn: Button = null
var crusade_result_popup: Control = null
var crusade_result_title: Label = null
var crusade_result_label: Label = null   # soldier casualty line
var crusade_phase1: Control = null       # chests view
var crusade_phase2: Control = null       # rewards view
var crusade_chests_row: HBoxContainer = null
var crusade_chest_images: Array = []   # TextureRect refs for open animation
var crusade_rewards_label: Label = null
var crusade_marcus_container: Control = null
var crusade_dismiss_btn: Button = null
var crusade_pending: Dictionary = {}     # stores results between phase1 and phase2

# ── Hero Cards ────────────────────────────────────────────────────────────────
var marcus_obtained: bool = false
var hero_deck_chip: PanelContainer = null
var hero_deck_panel: PanelContainer = null
var generals_quarters: Area2D = null
var generals_quarters_built: bool = false
var generals_quarters_build_row: HBoxContainer = null
var generals_quarters_sep: Node = null
var marcus_character_node: CharacterBody2D = null
var marcus_leading_crusade: bool = false
var crusade_bring_marcus_btn: Button = null

# ── Timers / state ────────────────────────────────────────────────────────────
var resource_timer    := 0.0
const RESOURCE_INTERVAL := 3.0
var highlight_pulse   := 0.0
var temple_build_indicator: Label = null
var rush_tutorial_arrow: Label = null
var shelter_arrow: PanelContainer = null
var shelter_arrow_label: Label = null
var pray_tutorial_arrow: Label = null
var wheel_tutorial_arrow: PanelContainer = null
var rush_pulse        := 0.0
var placing_building  := false
var placing_type      := ""    # "temple" / "hall_of_devoted" / "preacher_shelter"
var placing_cost      := 0

# Active construction (one at a time)
var active_construction_node: Area2D = null
var active_construction_type := ""
var active_construction_timer := 0.0
var active_construction_max   := 0.0

const CONSTRUCTION_TIME        := 300.0    # temple: 5 min (prototype speed)
const HALL_CONSTRUCTION_TIME   := 7200.0   # hall: 2 hours
const PREACHER_SHELTER_TIME    := 3600.0   # preacher shelter: 1 hour
const SHELTER_UPGRADE_TIME     := 1800.0   # extra believer shelter: 30 min
const ARMORY_CONSTRUCTION_TIME   := 3600.0   # barracks: 1 hour
const GARRISON_CONSTRUCTION_TIME := 3600.0   # garrison: 1 hour
const TRAINING_TIME              := 1800.0   # soldier training: 30 min
const MAP_WIDTH                := 3000.0
const MAP_HEIGHT               := 2000.0

# Preacher conversion
var converting        := false
var conversion_timer  := 0.0
const CONVERSION_TIME := 3600.0   # 1 hour per conversion

# ── Positions ────────────────────────────────────────────────────────────────
const SHELTER_POS = Vector2(1500, 1000)

# ── Blocked zones (pos, radius) — can't build here ───────────────────────────
var blocked_zones: Array = []


func _ready():
	_build_world()
	_build_ui()
	_spawn_believers()
	_update_tutorial()


func _process(delta):
	# Wheel of Faith daily cooldown
	if not wheel_available:
		wheel_daily_timer += delta
		if wheel_daily_timer >= WHEEL_DAILY_COOLDOWN:
			wheel_available = true
			wheel_daily_timer = 0.0
			if wheel_chip_node != null:
				wheel_chip_node.visible = true

	# Shelter arrow follows shelter position on screen (tutorial TAP_SHELTER step)
	if shelter_arrow and shelter_arrow.visible:
		var sp := get_viewport().get_canvas_transform() * SHELTER_POS
		# Position badge ABOVE the shelter, arrow pointing down at it
		shelter_arrow.offset_left   = sp.x - 90
		shelter_arrow.offset_right  = sp.x + 90
		shelter_arrow.offset_top    = sp.y - 145
		shelter_arrow.offset_bottom = sp.y - 105

	# Ghost follows mouse during placement
	if placing_building and ghost_node:
		ghost_node.position = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()

	# Active construction countdown
	if active_construction_timer > 0.0:
		active_construction_timer -= delta
		if active_construction_timer <= 0.0:
			active_construction_timer = 0.0
			_complete_construction()
		else:
			_update_construction_ui()

	# Preacher conversion countdown
	if converting and conversion_timer > 0.0:
		conversion_timer -= delta
		if conversion_timer <= 0.0:
			conversion_timer = 0.0
			_complete_conversion()
		else:
			_update_conversion_ui()

	# Spread the Faith countdown
	if spreading and spread_timer > 0.0:
		spread_timer -= delta
		_update_spread_ui()
		if spread_timer <= 0.0:
			_complete_spread()

	# Crusade countdown
	if crusading and crusade_timer > 0.0:
		crusade_timer -= delta
		if crusade_timer <= 0.0:
			crusade_timer = 0.0
			_complete_crusade()
		else:
			_update_crusade_ui()

	# Soldier training countdown
	if training and training_timer > 0.0:
		training_timer -= delta
		if training_timer <= 0.0:
			training_timer = 0.0
			_complete_training()
		else:
			_update_training_ui()

	# Prayer countdown — iterate all active sessions
	if prayer_sessions.size() > 0:
		for i in range(prayer_sessions.size() - 1, -1, -1):
			var sess: Dictionary = prayer_sessions[i]
			sess.timer -= delta
			sess.accumulator += delta
			while sess.accumulator >= 60.0:
				faith += sess.count
				sess.accumulator -= 60.0
				_refresh_resource_labels()
			if is_instance_valid(sess.bar):
				sess.bar.anchor_right = sess.accumulator / 60.0
			if sess.timer <= 0.0:
				_complete_prayer_session(i)
		if shelter_panel.visible:
			_update_prayer_ui()
		if extra_shelter_panel != null and extra_shelter_panel.visible:
			_update_extra_prayer_ui()
		if temple_panel.visible:
			_refresh_temple_panel()

	# Info popup auto-hide
	if info_popup_timer > 0.0:
		info_popup_timer -= delta
		if info_popup_timer <= 0.0:
			info_popup.visible = false

	resource_timer += delta
	if resource_timer >= RESOURCE_INTERVAL:
		resource_timer = 0.0
		_tick_resources()
	_refresh_resource_labels()
	_pulse_build_button(delta)


# ── Resource tick ─────────────────────────────────────────────────────────────
func _tick_resources():
	gold += believers_count          # each believer pays 1 gold/tick
	# Faith comes only from prayer (see _on_pray_confirm_pressed)


# ── World ─────────────────────────────────────────────────────────────────────
func _build_world():
	world = Node2D.new()
	add_child(world)

	# Map background — painted grass + stone path texture
	var grass := TextureRect.new()
	grass.texture      = load("res://New Background.png")
	grass.stretch_mode = TextureRect.STRETCH_SCALE
	grass.size         = Vector2(MAP_WIDTH, MAP_HEIGHT)
	grass.mouse_filter = Control.MOUSE_FILTER_IGNORE   # don't block Area2D clicks
	world.add_child(grass)

	# Camera — centered on starting area, limited to map bounds
	camera = Camera2D.new()
	camera.position = SHELTER_POS
	camera.limit_left   = 0
	camera.limit_top    = 0
	camera.limit_right  = int(MAP_WIDTH)
	camera.limit_bottom = int(MAP_HEIGHT)
	add_child(camera)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	# Scattered trees (avoid center area)
	_plant_trees(rng)

	# Dirt path disabled — background texture already has paths baked in
	# _draw_path()

	# Humble Shelter — interactive so you can tap it for capacity info
	shelter = _make_building("shelter", SHELTER_POS, "Humble Shelter", true)
	shelter.tapped.connect(_on_believer_shelter_tapped)
	blocked_zones.append({"pos": SHELTER_POS, "radius": 85.0})


func _plant_trees(rng: RandomNumberGenerator):
	var placed: Array = []
	var attempts := 0
	while placed.size() < 80 and attempts < 2000:
		attempts += 1
		var tp := Vector2(rng.randf_range(60, MAP_WIDTH - 60), rng.randf_range(60, MAP_HEIGHT - 60))
		# Keep clear zone around the village center
		if tp.distance_to(SHELTER_POS) < 300:
			continue
		# Don't cluster trees too close together
		var too_close := false
		for p in placed:
			if tp.distance_to(p) < 90:
				too_close = true
				break
		if too_close:
			continue
		placed.append(tp)
		_draw_tree(tp, rng)
		blocked_zones.append({"pos": tp, "radius": 60.0})


func _draw_tree(pos: Vector2, rng: RandomNumberGenerator):
	var tree := Node2D.new()
	tree.position = pos
	var drawer := _TreeDrawer.new()
	drawer.size_scale = rng.randf_range(0.80, 1.20)
	drawer.green  = Color(
		rng.randf_range(0.18, 0.26),
		rng.randf_range(0.58, 0.68),
		rng.randf_range(0.10, 0.18))
	drawer.green2 = Color(
		rng.randf_range(0.28, 0.38),
		rng.randf_range(0.70, 0.82),
		rng.randf_range(0.18, 0.28))
	tree.add_child(drawer)
	world.add_child(tree)


func _road_corner(from_pos: Vector2, to_pos: Vector2) -> Vector2:
	if abs(to_pos.y - from_pos.y) >= abs(to_pos.x - from_pos.x):
		return Vector2(from_pos.x, to_pos.y)
	else:
		return Vector2(to_pos.x, from_pos.y)


func _walk_via_road(node: CharacterBody2D, from_pos: Vector2, to_pos: Vector2, on_arrive: Callable):
	var corner := _road_corner(from_pos, to_pos)
	if corner.distance_to(to_pos) < 4.0 or corner.distance_to(from_pos) < 4.0:
		node.walk_to(to_pos)
		node.reached_forced_target.connect(on_arrive, CONNECT_ONE_SHOT)
	else:
		node.walk_to(corner)
		node.reached_forced_target.connect(func():
			node.walk_to(to_pos)
			node.reached_forced_target.connect(on_arrive, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)


func _draw_road(from_pos: Vector2, to_pos: Vector2):
	var road := _RoadSegment.new()
	road.from_pos = from_pos
	road.to_pos   = to_pos
	world.add_child(road)
	world.move_child(road, 1)  # just after grass, so road renders below trees and buildings


func _draw_path():
	# Stone tile cross-path centred on the shelter area
	var path := Node2D.new()
	path.position = SHELTER_POS + Vector2(0, 40)
	var pd := _PathDrawer.new()
	path.add_child(pd)
	world.add_child(path)


func _make_building(type: String, pos: Vector2, label: String, interactive: bool) -> Area2D:
	var b := Area2D.new()
	b.set_script(load("res://building.gd"))
	b.building_type  = type
	b.building_label = label
	b.is_interactive = interactive
	b.position       = pos
	world.add_child(b)

	return b


# ── Believers ────────────────────────────────────────────────────────────────
func _spawn_believers():
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(5):
		var b: CharacterBody2D = load("res://believer.tscn").instantiate()
		var offset := Vector2(rng.randf_range(-38, 38), rng.randf_range(-18, 18))
		world.add_child(b)
		b.setup(SHELTER_POS + offset, i)
		believers.append(b)


# ── UI ────────────────────────────────────────────────────────────────────────
func _build_ui():
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)

	_build_top_bar(ui)
	_build_build_button(ui)
	_build_build_menu(ui)
	_build_construction_panel(ui)
	_build_conversion_panel(ui)
	_build_training_panel(ui)
	_build_preacher_shelter_panel(ui)
	_build_garrison_panel(ui)
	_build_shelter_panel(ui)
	_build_extra_shelter_panel(ui)
	_build_temple_panel(ui)
	_build_tutorial_panel(ui)
	_build_info_popup(ui)
	_build_wheel_popup(ui)
	_build_crusade_result_popup(ui)
	_build_hero_deck_panel(ui)


func _build_top_bar(ui: CanvasLayer):
	var bar := ColorRect.new()
	bar.color    = Color(0.08, 0.06, 0.12, 0.92)
	bar.size     = Vector2(1152, 54)
	bar.position = Vector2.ZERO
	ui.add_child(bar)

	# Force LTR — Hebrew RTL system locale would otherwise flip everything
	var hbox := HBoxContainer.new()
	hbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hbox.offset_left = 10
	hbox.offset_top  = 6
	hbox.add_theme_constant_override("separation", 6)
	ui.add_child(hbox)

	# People chip — clickable, shows distribution popup
	var believers_chip := _resource_chip(Color(0.30, 0.80, 0.35), Color(0.14, 0.45, 0.18))
	believers_label = believers_chip[0]
	var people_chip_node: PanelContainer = believers_chip[1]
	people_chip_node.mouse_filter = Control.MOUSE_FILTER_STOP
	people_chip_node.gui_input.connect(_on_people_chip_input)
	hbox.add_child(people_chip_node)

	var faith_chip := _resource_chip(Color(0.72, 0.55, 1.00), Color(0.38, 0.20, 0.65))
	faith_label = faith_chip[0]
	hbox.add_child(faith_chip[1])

	var gold_chip := _resource_chip(Color(1.00, 0.82, 0.15), Color(0.65, 0.45, 0.05))
	gold_label = gold_chip[0]
	hbox.add_child(gold_chip[1])

	# Wheel of Faith chip — only visible when a spin is available
	var wchip_style := StyleBoxFlat.new()
	wchip_style.bg_color     = Color(0.45, 0.30, 0.05)
	wchip_style.border_color = Color(0.95, 0.75, 0.10)
	wchip_style.set_border_width_all(2)
	wchip_style.set_corner_radius_all(8)
	wchip_style.content_margin_left   = 8
	wchip_style.content_margin_right  = 8
	wchip_style.content_margin_top    = 4
	wchip_style.content_margin_bottom = 4
	wheel_chip_node = PanelContainer.new()
	wheel_chip_node.layout_direction = Control.LAYOUT_DIRECTION_LTR
	wheel_chip_node.add_theme_stylebox_override("panel", wchip_style)
	wheel_chip_node.mouse_filter = Control.MOUSE_FILTER_STOP
	wheel_chip_node.visible = wheel_available
	var wchip_lbl := Label.new()
	wchip_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	wchip_lbl.text = "✦ Spin"
	wchip_lbl.add_theme_font_size_override("font_size", 14)
	wchip_lbl.add_theme_color_override("font_color", Color(0.98, 0.88, 0.30))
	wheel_chip_node.add_child(wchip_lbl)
	wheel_chip_node.gui_input.connect(_on_wheel_chip_input)
	hbox.add_child(wheel_chip_node)

	# ── Hero Deck chip ──────────────────────────────────────────────────────
	var hdchip_style := StyleBoxFlat.new()
	hdchip_style.bg_color      = Color(0.55, 0.35, 0.05, 0.90)
	hdchip_style.border_color  = Color(0.95, 0.75, 0.20)
	hdchip_style.set_border_width_all(1)
	hdchip_style.set_corner_radius_all(8)
	hdchip_style.content_margin_left   = 8
	hdchip_style.content_margin_right  = 8
	hdchip_style.content_margin_top    = 4
	hdchip_style.content_margin_bottom = 4
	hero_deck_chip = PanelContainer.new()
	hero_deck_chip.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hero_deck_chip.add_theme_stylebox_override("panel", hdchip_style)
	hero_deck_chip.mouse_filter = Control.MOUSE_FILTER_STOP
	hero_deck_chip.visible = false   # shows only after first hero obtained
	var hdchip_lbl := Label.new()
	hdchip_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hdchip_lbl.text = "🃏 Heroes"
	hdchip_lbl.add_theme_font_size_override("font_size", 14)
	hdchip_lbl.add_theme_color_override("font_color", Color(0.98, 0.88, 0.30))
	hero_deck_chip.add_child(hdchip_lbl)
	hero_deck_chip.gui_input.connect(_on_hero_deck_chip_input)
	hbox.add_child(hero_deck_chip)

	_build_people_panel(ui)

	_refresh_resource_labels()


# Returns [Label, chip_container] — chip = coloured badge + white number
func _resource_chip(light: Color, dark: Color) -> Array:
	var chip := PanelContainer.new()
	chip.layout_direction = Control.LAYOUT_DIRECTION_LTR

	var style := StyleBoxFlat.new()
	style.bg_color = dark.darkened(0.25)
	style.border_color = dark
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left  = 6
	style.content_margin_right = 10
	style.content_margin_top   = 4
	style.content_margin_bottom = 4
	chip.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.add_theme_constant_override("separation", 5)
	chip.add_child(row)

	# Coloured dot icon
	var dot_node := ColorRect.new()
	dot_node.color = light
	dot_node.custom_minimum_size = Vector2(14, 14)
	dot_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot_node)

	# White number label
	var lbl := Label.new()
	lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	return [lbl, chip]


func _resource_label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.layout_direction = Control.LAYOUT_DIRECTION_LTR
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", color)
	return l


func _build_people_panel(ui: CanvasLayer):
	people_panel = PanelContainer.new()
	people_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	people_panel.anchor_left   = 0.0
	people_panel.anchor_right  = 0.0
	people_panel.anchor_top    = 0.0
	people_panel.anchor_bottom = 0.0
	people_panel.offset_left   = 6
	people_panel.offset_top    = 58
	people_panel.offset_right  = 220
	people_panel.offset_bottom = 130
	people_panel.visible = false
	ui.add_child(people_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	people_panel.add_child(vbox)

	var title := Label.new()
	title.layout_direction = Control.LAYOUT_DIRECTION_LTR
	title.text = "Your People"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.40))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	people_detail_label = Label.new()
	people_detail_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	people_detail_label.add_theme_font_size_override("font_size", 13)
	people_detail_label.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	vbox.add_child(people_detail_label)


func _on_people_chip_input(event: InputEvent):
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	people_panel.visible = not people_panel.visible
	if people_panel.visible:
		_refresh_people_panel()


func _refresh_people_panel():
	people_detail_label.text = (
		"Believers:   %d\n" % believers_count +
		"Preachers:  %d\n" % preachers_count +
		"Soldiers:    %d" % soldiers_count
	)


func _build_info_popup(ui: CanvasLayer):
	info_popup = PanelContainer.new()
	info_popup.layout_direction = Control.LAYOUT_DIRECTION_LTR
	info_popup.visible = false
	ui.add_child(info_popup)

	info_popup_label = Label.new()
	info_popup_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	info_popup_label.add_theme_font_size_override("font_size", 15)
	info_popup_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	info_popup.add_child(info_popup_label)


func _show_building_info(building: Area2D, text: String):
	info_popup_label.text = text
	# canvas_transform maps world coords → screen coords (accounts for camera)
	var screen_pos := get_viewport().get_canvas_transform() * building.global_position
	info_popup.position = screen_pos + Vector2(-50, -110)
	info_popup.visible = true
	info_popup_timer = 3.0


func _on_believer_shelter_tapped():
	conversion_panel.visible = false
	training_panel.visible = false
	preacher_shelter_panel.visible = false
	garrison_panel.visible = false
	if extra_shelter_panel:
		extra_shelter_panel.visible = false
	shelter_panel.visible = not shelter_panel.visible
	if shelter_panel.visible:
		shelter_believer_label.text = "%d / 5" % mini(believers_count, 5)
		if _has_session(0):
			_update_prayer_ui()
		else:
			_reset_prayer_ui()
		if tut_step == TutStep.TAP_SHELTER:
			tut_step = TutStep.TAP_GO_PRAY
			tut_popup_dismissed = false
			_update_tutorial()


func _on_preacher_shelter_tapped():
	conversion_panel.visible = false
	training_panel.visible = false
	garrison_panel.visible = false
	shelter_panel.visible = false
	if extra_shelter_panel:
		extra_shelter_panel.visible = false
	preacher_shelter_panel.visible = not preacher_shelter_panel.visible
	if preacher_shelter_panel.visible:
		_refresh_preacher_label()


func _build_build_button(ui: CanvasLayer):
	build_button = Button.new()
	build_button.text = "Build"
	build_button.custom_minimum_size = Vector2(120, 44)
	build_button.add_theme_font_size_override("font_size", 18)
	build_button.layout_direction = Control.LAYOUT_DIRECTION_LTR
	# Anchor to bottom-right corner so it's always in the corner regardless of RTL
	build_button.anchor_left   = 1.0
	build_button.anchor_right  = 1.0
	build_button.anchor_top    = 1.0
	build_button.anchor_bottom = 1.0
	build_button.offset_left   = -130
	build_button.offset_top    = -54
	build_button.offset_right  = 0
	build_button.offset_bottom = 0
	build_button.pressed.connect(_on_build_pressed)
	ui.add_child(build_button)


func _build_build_menu(ui: CanvasLayer):
	build_menu = PanelContainer.new()
	build_menu.layout_direction = Control.LAYOUT_DIRECTION_LTR
	# Top-left anchor — immune to RTL/Hebrew system locale
	build_menu.anchor_left   = 0.0
	build_menu.anchor_right  = 0.0
	build_menu.anchor_top    = 0.0
	build_menu.anchor_bottom = 0.0
	build_menu.offset_left   = 8
	build_menu.offset_right  = 370
	build_menu.offset_top    = 62
	build_menu.offset_bottom = 560
	build_menu.visible = false

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.05, 0.12, 0.97)
	panel_style.border_color = Color(0.60, 0.45, 0.10)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left   = 0
	panel_style.content_margin_right  = 0
	panel_style.content_margin_top    = 0
	panel_style.content_margin_bottom = 8
	build_menu.add_theme_stylebox_override("panel", panel_style)
	ui.add_child(build_menu)

	var outer := VBoxContainer.new()
	outer.layout_direction = Control.LAYOUT_DIRECTION_LTR
	outer.add_theme_constant_override("separation", 0)
	build_menu.add_child(outer)

	# ── Title bar ────────────────────────────────────────────────────────
	var title_bar := ColorRect.new()
	title_bar.color = Color(0.50, 0.36, 0.08, 1.0)
	title_bar.custom_minimum_size = Vector2(0, 40)
	outer.add_child(title_bar)

	var title_row := HBoxContainer.new()
	title_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	title_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_row.add_theme_constant_override("separation", 0)
	title_bar.add_child(title_row)

	var title_lbl := Label.new()
	title_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	title_lbl.text = "  BUILD"
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
	title_row.add_child(title_lbl)

	var close_x := Button.new()
	close_x.layout_direction = Control.LAYOUT_DIRECTION_LTR
	close_x.text = "✕"
	close_x.flat = true
	close_x.custom_minimum_size = Vector2(40, 40)
	close_x.add_theme_font_size_override("font_size", 18)
	close_x.add_theme_color_override("font_color", Color(1.0, 0.75, 0.30))
	close_x.pressed.connect(func(): build_menu.visible = false)
	title_row.add_child(close_x)

	# ── Scrollable building list ──────────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.layout_direction = Control.LAYOUT_DIRECTION_LTR
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var list := VBoxContainer.new()
	list.layout_direction = Control.LAYOUT_DIRECTION_LTR
	list.add_theme_constant_override("separation", 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	# Buildings: name, description, cost, callback, accent colour
	# Temple first — it's the first thing the tutorial asks you to build
	var temple_row := _add_build_row(list, "Small Temple",        "Send Believers to pray\nand earn Faith Points",        "30g", _on_build_temple,            Color(0.72, 0.55, 1.00))
	_add_build_row(list, "Believer Shelter",    "Houses 5 more Believers\n(stackable — build many)",     "40g", _on_build_shelter,          Color(0.85, 0.55, 0.18))
	_add_build_row(list, "Hall of the Devoted",  "Converts Believers\ninto Preachers (1 hr each)",       "70g", _on_build_hall,              Color(0.40, 0.65, 1.00))
	_add_build_row(list, "Preacher Shelter",     "Houses Preachers — they\ngenerate +2 Faith/tick each", "50g", _on_build_preacher_shelter,  Color(0.30, 0.82, 0.75))
	_add_build_row(list, "Barracks",             "Trains Believers into\nSoldiers (30 min each)",        "80g", _on_build_armory,            Color(0.85, 0.28, 0.18))
	_add_build_row(list, "Garrison",             "Houses Soldiers so\nthey are ready to serve",          "60g", _on_build_garrison,          Color(0.65, 0.18, 0.12))
	generals_quarters_build_row = _add_build_row(list, "General's Quarters", "Home for Marcus the Iron Fist\n(Military Hero)", "100g", _on_build_generals_quarters, Color(0.80, 0.55, 0.10))
	generals_quarters_build_row.visible = false   # unlocks when Marcus card is obtained
	# Hide the separator line that _add_build_row added just before this row
	generals_quarters_sep = list.get_child(generals_quarters_build_row.get_index() - 1)
	generals_quarters_sep.visible = false

	# Tutorial arrow — points at the temple row, pulses red, hidden once built
	temple_build_indicator = Label.new()
	temple_build_indicator.text = "◀ Build first!"
	temple_build_indicator.add_theme_font_size_override("font_size", 12)
	temple_build_indicator.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	temple_build_indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	temple_build_indicator.visible = false
	temple_row.add_child(temple_build_indicator)


func _add_build_row(list: VBoxContainer, bname: String, desc: String, cost: String, callback: Callable, accent: Color) -> HBoxContainer:
	# Separator line between rows
	if list.get_child_count() > 0:
		var sep := ColorRect.new()
		sep.color = Color(0.55, 0.42, 0.10, 0.35)
		sep.custom_minimum_size = Vector2(0, 1)
		list.add_child(sep)

	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	row.custom_minimum_size = Vector2(0, 68)
	row.add_theme_constant_override("separation", 0)
	list.add_child(row)

	# Coloured accent strip
	var strip := ColorRect.new()
	strip.color = accent
	strip.custom_minimum_size = Vector2(5, 0)
	strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(strip)

	# Icon dot
	var dot_wrap := CenterContainer.new()
	dot_wrap.layout_direction = Control.LAYOUT_DIRECTION_LTR
	dot_wrap.custom_minimum_size = Vector2(36, 0)
	row.add_child(dot_wrap)
	var dot := ColorRect.new()
	dot.color = accent.lightened(0.15)
	dot.custom_minimum_size = Vector2(14, 14)
	dot_wrap.add_child(dot)

	# Name + description
	var info_vbox := VBoxContainer.new()
	info_vbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_vbox.add_theme_constant_override("separation", 2)
	row.add_child(info_vbox)

	var name_lbl := Label.new()
	name_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	name_lbl.text = bname
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.80))
	info_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.70, 0.68, 0.65))
	info_vbox.add_child(desc_lbl)

	# Right side: cost + button
	var right := VBoxContainer.new()
	right.layout_direction = Control.LAYOUT_DIRECTION_LTR
	right.custom_minimum_size = Vector2(72, 0)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_theme_constant_override("separation", 4)
	row.add_child(right)

	var cost_lbl := Label.new()
	cost_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	cost_lbl.text = cost
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.15))
	right.add_child(cost_lbl)

	var btn := Button.new()
	btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn.text = "Build"
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(callback)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = accent.darkened(0.30)
	btn_style.border_color = accent
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(4)
	btn_style.content_margin_left   = 8
	btn_style.content_margin_right  = 8
	btn_style.content_margin_top    = 5
	btn_style.content_margin_bottom = 5
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = accent.darkened(0.10)
	btn.add_theme_stylebox_override("hover", btn_hover)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	right.add_child(btn)

	# Small right margin
	var margin := ColorRect.new()
	margin.color = Color(0,0,0,0)
	margin.custom_minimum_size = Vector2(8, 0)
	row.add_child(margin)

	return row


func _build_conversion_panel(ui: CanvasLayer):
	conversion_panel = _make_building_panel(ui, Color(0.35, 0.55, 1.00), "Hall of the Devoted")

	var body := _panel_body(conversion_panel)

	# Status + progress
	conversion_label = Label.new()
	conversion_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	conversion_label.text = "Ready to convert"
	conversion_label.add_theme_font_size_override("font_size", 13)
	conversion_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.82))
	body.add_child(conversion_label)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.10, 0.08, 0.18)
	bar_bg.custom_minimum_size = Vector2(0, 8)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(bar_bg)
	conversion_bar = ColorRect.new()
	conversion_bar.color = Color(0.35, 0.55, 1.00)
	conversion_bar.anchor_top = 0.0; conversion_bar.anchor_bottom = 1.0
	conversion_bar.anchor_left = 0.0; conversion_bar.anchor_right = 0.0
	bar_bg.add_child(conversion_bar)

	# Action buttons
	var btn_row := HBoxContainer.new()
	btn_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn_row.add_theme_constant_override("separation", 8)
	body.add_child(btn_row)

	convert_btn = Button.new()
	convert_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	convert_btn.text = "Convert Believer  (1 hr)"
	convert_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	convert_btn.pressed.connect(_on_convert_pressed)
	_style_action_btn(convert_btn, Color(0.35, 0.55, 1.00))
	btn_row.add_child(convert_btn)

	conversion_rush_btn = Button.new()
	conversion_rush_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	conversion_rush_btn.text = "⚡ -10m"
	conversion_rush_btn.custom_minimum_size = Vector2(70, 0)
	conversion_rush_btn.visible = false
	conversion_rush_btn.pressed.connect(_on_conversion_rush_pressed)
	_style_action_btn(conversion_rush_btn, Color(0.85, 0.65, 0.10))
	btn_row.add_child(conversion_rush_btn)

	_panel_sep(body, Color(0.35, 0.55, 1.00))

	# Upgrade button (locked)
	var upg := Button.new()
	upg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	upg.text = "⬆  Upgrade Building   (Coming Soon)"
	upg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upg.disabled = true
	_style_action_btn(upg, Color(0.50, 0.48, 0.44))
	body.add_child(upg)


func _build_training_panel(ui: CanvasLayer):
	training_panel = _make_building_panel(ui, Color(0.85, 0.28, 0.18), "Barracks")

	var body := _panel_body(training_panel)

	# Status + progress
	training_label = Label.new()
	training_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	training_label.text = "Ready to train"
	training_label.add_theme_font_size_override("font_size", 13)
	training_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.82))
	body.add_child(training_label)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.10, 0.08, 0.18)
	bar_bg.custom_minimum_size = Vector2(0, 8)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(bar_bg)
	training_bar = ColorRect.new()
	training_bar.color = Color(0.85, 0.28, 0.18)
	training_bar.anchor_top = 0.0; training_bar.anchor_bottom = 1.0
	training_bar.anchor_left = 0.0; training_bar.anchor_right = 0.0
	bar_bg.add_child(training_bar)

	# Action buttons
	var btn_row := HBoxContainer.new()
	btn_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn_row.add_theme_constant_override("separation", 8)
	body.add_child(btn_row)

	train_btn = Button.new()
	train_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	train_btn.text = "Train Soldier  (30 min)"
	train_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	train_btn.pressed.connect(_on_train_pressed)
	_style_action_btn(train_btn, Color(0.85, 0.28, 0.18))
	btn_row.add_child(train_btn)

	training_rush_btn = Button.new()
	training_rush_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	training_rush_btn.text = "⚡ -10m"
	training_rush_btn.custom_minimum_size = Vector2(70, 0)
	training_rush_btn.visible = false
	training_rush_btn.pressed.connect(_on_training_rush_pressed)
	_style_action_btn(training_rush_btn, Color(0.85, 0.65, 0.10))
	btn_row.add_child(training_rush_btn)

	_panel_sep(body, Color(0.85, 0.28, 0.18))

	# Upgrade button (locked)
	var upg := Button.new()
	upg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	upg.text = "⬆  Upgrade Building   (Coming Soon)"
	upg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upg.disabled = true
	_style_action_btn(upg, Color(0.50, 0.48, 0.44))
	body.add_child(upg)


# ── Panel builder helpers ─────────────────────────────────────────────────────
func _make_building_panel(ui: CanvasLayer, accent: Color, title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	# Top-right corner, below top bar
	panel.anchor_left   = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_top    = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left   = -358
	panel.offset_right  = -8
	panel.offset_top    = 62
	panel.offset_bottom = 310
	panel.visible = false

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.07, 0.05, 0.12, 0.97)
	ps.border_color = accent
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.content_margin_left = 0; ps.content_margin_right = 0
	ps.content_margin_top  = 0; ps.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", ps)
	ui.add_child(panel)

	var outer := VBoxContainer.new()
	outer.layout_direction = Control.LAYOUT_DIRECTION_LTR
	outer.add_theme_constant_override("separation", 0)
	panel.add_child(outer)

	# Title bar
	var tbar := ColorRect.new()
	tbar.color = accent.darkened(0.45)
	tbar.custom_minimum_size = Vector2(0, 40)
	outer.add_child(tbar)

	var trow := HBoxContainer.new()
	trow.layout_direction = Control.LAYOUT_DIRECTION_LTR
	trow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tbar.add_child(trow)

	var tlbl := Label.new()
	tlbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	tlbl.text = "  " + title
	tlbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tlbl.add_theme_font_size_override("font_size", 15)
	tlbl.add_theme_color_override("font_color", accent.lightened(0.55))
	trow.add_child(tlbl)

	var close_x := Button.new()
	close_x.layout_direction = Control.LAYOUT_DIRECTION_LTR
	close_x.text = "✕"
	close_x.flat = true
	close_x.custom_minimum_size = Vector2(40, 40)
	close_x.add_theme_font_size_override("font_size", 16)
	close_x.add_theme_color_override("font_color", accent.lightened(0.40))
	close_x.pressed.connect(func(): panel.visible = false)
	trow.add_child(close_x)

	return panel


func _panel_body(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 0)
	panel.get_child(0).add_child(margin)   # outer VBox

	var body := VBoxContainer.new()
	body.layout_direction = Control.LAYOUT_DIRECTION_LTR
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)
	return body


func _count_row(body: VBoxContainer, label_text: String, value_color: Color) -> Label:
	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	body.add_child(row)

	var lbl := Label.new()
	lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	lbl.text = label_text + ":"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.72, 0.70, 0.66))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var val := Label.new()
	val.layout_direction = Control.LAYOUT_DIRECTION_LTR
	val.text_direction = Control.TEXT_DIRECTION_LTR
	val.text = "0 / 5"
	val.add_theme_font_size_override("font_size", 16)
	val.add_theme_color_override("font_color", value_color)
	row.add_child(val)
	return val


func _panel_sep(body: VBoxContainer, accent: Color):
	var sep := ColorRect.new()
	sep.color = accent.darkened(0.40)
	sep.color.a = 0.45
	sep.custom_minimum_size = Vector2(0, 1)
	body.add_child(sep)


func _style_action_btn(btn: Button, accent: Color):
	btn.add_theme_font_size_override("font_size", 13)
	var s := StyleBoxFlat.new()
	s.bg_color = accent.darkened(0.45)
	s.border_color = accent
	s.set_border_width_all(1)
	s.set_corner_radius_all(5)
	s.content_margin_left = 10; s.content_margin_right = 10
	s.content_margin_top = 7;   s.content_margin_bottom = 7
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = accent.darkened(0.20)
	btn.add_theme_stylebox_override("hover", h)
	var d := s.duplicate() as StyleBoxFlat
	d.bg_color = Color(0.12, 0.10, 0.18)
	d.border_color = accent.darkened(0.40)
	btn.add_theme_stylebox_override("disabled", d)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.43, 0.40))


func _build_preacher_shelter_panel(ui: CanvasLayer):
	preacher_shelter_panel = _make_building_panel(ui, Color(0.30, 0.75, 0.72), "Preacher Shelter")
	var body := _panel_body(preacher_shelter_panel)

	shelter_preacher_label = _count_row(body, "Preachers", Color(0.30, 0.82, 0.75))

	_panel_sep(body, Color(0.30, 0.75, 0.72))

	# ── Go button ──
	spread_go_btn = Button.new()
	spread_go_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	spread_go_btn.text = "✉  Spread the Faith   (2 hr)"
	spread_go_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_btn(spread_go_btn, Color(0.30, 0.75, 0.72))
	spread_go_btn.pressed.connect(_on_spread_pressed)
	body.add_child(spread_go_btn)

	# ── Selector row (hidden until Go tapped) ──
	spread_selector_row = HBoxContainer.new()
	spread_selector_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	spread_selector_row.visible = false
	body.add_child(spread_selector_row)

	var minus_btn := Button.new()
	minus_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	minus_btn.text = "−"
	minus_btn.custom_minimum_size = Vector2(30, 0)
	minus_btn.pressed.connect(func():
		spread_selector_count = max(1, spread_selector_count - 1)
		_update_spread_selector_label())
	spread_selector_row.add_child(minus_btn)

	spread_selector_label = Label.new()
	spread_selector_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	spread_selector_label.text_direction = Control.TEXT_DIRECTION_LTR
	spread_selector_label.text = "1 preacher"
	spread_selector_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spread_selector_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spread_selector_label.add_theme_font_size_override("font_size", 13)
	spread_selector_row.add_child(spread_selector_label)

	var plus_btn := Button.new()
	plus_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(30, 0)
	plus_btn.pressed.connect(func():
		spread_selector_count = min(preachers_in_shelter, spread_selector_count + 1)
		_update_spread_selector_label())
	spread_selector_row.add_child(plus_btn)

	var confirm_btn := Button.new()
	confirm_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	confirm_btn.text = "Send →"
	_style_action_btn(confirm_btn, Color(0.30, 0.75, 0.72))
	confirm_btn.pressed.connect(_on_spread_confirm_pressed)
	spread_selector_row.add_child(confirm_btn)

	# ── Progress area (hidden until mission started) ──
	spread_progress_container = VBoxContainer.new()
	spread_progress_container.layout_direction = Control.LAYOUT_DIRECTION_LTR
	spread_progress_container.visible = false
	body.add_child(spread_progress_container)

	spread_label = Label.new()
	spread_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	spread_label.text = "Spreading the faith..."
	spread_label.add_theme_font_size_override("font_size", 12)
	spread_label.add_theme_color_override("font_color", Color(0.30, 0.90, 0.80))
	spread_progress_container.add_child(spread_label)

	# Progress bar background + fill
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.10, 0.08, 0.16)
	bar_bg.custom_minimum_size = Vector2(0, 8)
	spread_progress_container.add_child(bar_bg)

	spread_bar = ColorRect.new()
	spread_bar.color = Color(0.30, 0.82, 0.75)
	spread_bar.anchor_top    = 0.0
	spread_bar.anchor_bottom = 1.0
	spread_bar.anchor_left   = 0.0
	spread_bar.anchor_right  = 0.0
	bar_bg.add_child(spread_bar)

	spread_rush_btn = Button.new()
	spread_rush_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	spread_rush_btn.text = "⚡ Rush  (1 Faith = -10 min)"
	spread_rush_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_btn(spread_rush_btn, Color(0.72, 0.55, 1.00))
	spread_rush_btn.pressed.connect(_on_spread_rush_pressed)
	spread_progress_container.add_child(spread_rush_btn)

	_panel_sep(body, Color(0.30, 0.75, 0.72))

	var upg := Button.new()
	upg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	upg.text = "⬆  Upgrade Building   (Coming Soon)"
	upg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upg.disabled = true
	_style_action_btn(upg, Color(0.50, 0.48, 0.44))
	body.add_child(upg)

	# ── Mission result popup (CanvasLayer level) ──
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	ui.add_child(overlay)
	spread_result_popup = overlay

	var result_panel := PanelContainer.new()
	result_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	var rps := StyleBoxFlat.new()
	rps.bg_color     = Color(0.08, 0.06, 0.14)
	rps.border_color = Color(0.30, 0.80, 0.75)
	rps.set_border_width_all(2)
	rps.set_corner_radius_all(12)
	rps.content_margin_left = 28; rps.content_margin_right  = 28
	rps.content_margin_top  = 22; rps.content_margin_bottom = 22
	result_panel.add_theme_stylebox_override("panel", rps)
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.offset_left = -220; result_panel.offset_right  = 220
	result_panel.offset_top  = -110; result_panel.offset_bottom = 110
	overlay.add_child(result_panel)

	var vb := VBoxContainer.new()
	vb.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	result_panel.add_child(vb)

	var title := Label.new()
	title.layout_direction = Control.LAYOUT_DIRECTION_LTR
	title.text = "✉  Mission Complete!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.30, 0.90, 0.80))
	vb.add_child(title)

	spread_result_label = Label.new()
	spread_result_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	spread_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spread_result_label.add_theme_font_size_override("font_size", 14)
	spread_result_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.98))
	vb.add_child(spread_result_label)

	var ok_btn := Button.new()
	ok_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	ok_btn.text = "Praise be!"
	ok_btn.pressed.connect(func(): overlay.visible = false)
	_style_action_btn(ok_btn, Color(0.30, 0.75, 0.72))
	vb.add_child(ok_btn)


func _build_shelter_panel(ui: CanvasLayer):
	shelter_panel = _make_building_panel(ui, Color(0.85, 0.55, 0.18), "Humble Shelter")
	var body := _panel_body(shelter_panel)

	shelter_believer_label = _count_row(body, "Believers", Color(0.92, 0.75, 0.38))

	_panel_sep(body, Color(0.85, 0.55, 0.18))

	# Tutorial hint — shown only during TAP_GO_PRAY step
	pray_tutorial_arrow = Label.new()
	pray_tutorial_arrow.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pray_tutorial_arrow.text = "↓  Tap Go Pray!"
	pray_tutorial_arrow.add_theme_font_size_override("font_size", 14)
	pray_tutorial_arrow.add_theme_color_override("font_color", Color(1.0, 0.18, 0.18))
	pray_tutorial_arrow.visible = false
	body.add_child(pray_tutorial_arrow)

	# Go Pray button
	pray_go_btn = Button.new()
	pray_go_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pray_go_btn.text = "🙏  Go Pray  (30 min)"
	pray_go_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pray_go_btn.pressed.connect(_on_go_pray_pressed)
	_style_action_btn(pray_go_btn, Color(0.55, 0.35, 0.82))
	body.add_child(pray_go_btn)

	# Selector row (hidden initially)
	pray_selector_row = HBoxContainer.new()
	pray_selector_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pray_selector_row.add_theme_constant_override("separation", 4)
	pray_selector_row.visible = false
	body.add_child(pray_selector_row)

	var minus_btn := Button.new()
	minus_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	minus_btn.text = "−"
	minus_btn.custom_minimum_size = Vector2(30, 0)
	minus_btn.pressed.connect(func():
		prayer_selector_count = max(1, prayer_selector_count - 1)
		_update_pray_selector_label()
	)
	_style_action_btn(minus_btn, Color(0.55, 0.35, 0.82))
	pray_selector_row.add_child(minus_btn)

	pray_selector_label = Label.new()
	pray_selector_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pray_selector_label.text_direction = Control.TEXT_DIRECTION_LTR
	pray_selector_label.text = "1 believer"
	pray_selector_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pray_selector_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pray_selector_label.add_theme_font_size_override("font_size", 13)
	pray_selector_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.82))
	pray_selector_row.add_child(pray_selector_label)

	var plus_btn := Button.new()
	plus_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(30, 0)
	plus_btn.pressed.connect(func():
		prayer_selector_count = min(believers_count, prayer_selector_count + 1)
		_update_pray_selector_label()
	)
	_style_action_btn(plus_btn, Color(0.55, 0.35, 0.82))
	pray_selector_row.add_child(plus_btn)

	var confirm_btn := Button.new()
	confirm_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	confirm_btn.text = "Send to Pray"
	confirm_btn.pressed.connect(_on_pray_confirm_pressed)
	_style_action_btn(confirm_btn, Color(0.55, 0.35, 0.82))
	pray_selector_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_on_pray_cancel_pressed)
	_style_action_btn(cancel_btn, Color(0.50, 0.48, 0.44))
	pray_selector_row.add_child(cancel_btn)

	# Progress container (hidden initially)
	pray_progress_container = VBoxContainer.new()
	pray_progress_container.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pray_progress_container.add_theme_constant_override("separation", 6)
	pray_progress_container.visible = false
	body.add_child(pray_progress_container)

	pray_status_label = Label.new()
	pray_status_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pray_status_label.text = "Praying: 1 believer — 30:00"
	pray_status_label.add_theme_font_size_override("font_size", 13)
	pray_status_label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.82))
	pray_progress_container.add_child(pray_status_label)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.10, 0.08, 0.18)
	bar_bg.custom_minimum_size = Vector2(0, 8)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pray_progress_container.add_child(bar_bg)
	pray_bar = ColorRect.new()
	pray_bar.color = Color(0.55, 0.35, 0.82)
	pray_bar.anchor_top = 0.0; pray_bar.anchor_bottom = 1.0
	pray_bar.anchor_left = 0.0; pray_bar.anchor_right = 0.0
	bar_bg.add_child(pray_bar)

	pray_rush_btn = Button.new()
	pray_rush_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pray_rush_btn.text = "⚡ -10m"
	pray_rush_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pray_rush_btn.pressed.connect(_on_pray_rush_pressed)
	_style_action_btn(pray_rush_btn, Color(0.85, 0.65, 0.10))
	pray_progress_container.add_child(pray_rush_btn)

	_panel_sep(body, Color(0.85, 0.55, 0.18))

	var upg := Button.new()
	upg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	upg.text = "⬆  Upgrade Building   (Coming Soon)"
	upg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upg.disabled = true
	_style_action_btn(upg, Color(0.50, 0.48, 0.44))
	body.add_child(upg)


func _build_extra_shelter_panel(ui: CanvasLayer):
	extra_shelter_panel = _make_building_panel(ui, Color(0.85, 0.55, 0.18), "Believer Shelter")
	var body := _panel_body(extra_shelter_panel)

	extra_shelter_label = _count_row(body, "Believers", Color(0.92, 0.75, 0.38))

	_panel_sep(body, Color(0.85, 0.55, 0.18))

	# Go Pray button
	extra_pray_go_btn = Button.new()
	extra_pray_go_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	extra_pray_go_btn.text = "🙏  Go Pray  (30 min)"
	extra_pray_go_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extra_pray_go_btn.pressed.connect(_on_extra_go_pray_pressed)
	_style_action_btn(extra_pray_go_btn, Color(0.55, 0.35, 0.82))
	body.add_child(extra_pray_go_btn)

	# Selector row
	extra_pray_selector_row = HBoxContainer.new()
	extra_pray_selector_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	extra_pray_selector_row.add_theme_constant_override("separation", 4)
	extra_pray_selector_row.visible = false
	body.add_child(extra_pray_selector_row)

	var minus_btn := Button.new()
	minus_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	minus_btn.text = "−"
	minus_btn.custom_minimum_size = Vector2(30, 0)
	minus_btn.pressed.connect(func():
		extra_pray_selector_count = max(1, extra_pray_selector_count - 1)
		_update_extra_pray_selector_label()
	)
	_style_action_btn(minus_btn, Color(0.55, 0.35, 0.82))
	extra_pray_selector_row.add_child(minus_btn)

	extra_pray_selector_label = Label.new()
	extra_pray_selector_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	extra_pray_selector_label.text_direction = Control.TEXT_DIRECTION_LTR
	extra_pray_selector_label.text = "1 believer"
	extra_pray_selector_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extra_pray_selector_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	extra_pray_selector_label.add_theme_font_size_override("font_size", 13)
	extra_pray_selector_row.add_child(extra_pray_selector_label)

	var plus_btn := Button.new()
	plus_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(30, 0)
	plus_btn.pressed.connect(func():
		var in_shelter: int = clamp(believers_count - current_extra_shelter_idx * 5, 0, 5)
		var temple_slots: int = 5 - _praying_count()
		extra_pray_selector_count = min(extra_pray_selector_count + 1, mini(in_shelter, temple_slots))
		_update_extra_pray_selector_label()
	)
	_style_action_btn(plus_btn, Color(0.55, 0.35, 0.82))
	extra_pray_selector_row.add_child(plus_btn)

	var confirm_btn := Button.new()
	confirm_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	confirm_btn.text = "Send to Pray"
	confirm_btn.pressed.connect(_on_extra_pray_confirm_pressed)
	_style_action_btn(confirm_btn, Color(0.55, 0.35, 0.82))
	extra_pray_selector_row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func():
		extra_pray_selector_row.visible = false
		extra_pray_go_btn.visible = true
	)
	_style_action_btn(cancel_btn, Color(0.50, 0.48, 0.44))
	extra_pray_selector_row.add_child(cancel_btn)

	# Progress container (shown during active session from this shelter)
	extra_pray_progress_container = VBoxContainer.new()
	extra_pray_progress_container.layout_direction = Control.LAYOUT_DIRECTION_LTR
	extra_pray_progress_container.add_theme_constant_override("separation", 4)
	extra_pray_progress_container.visible = false
	body.add_child(extra_pray_progress_container)

	var prog_lbl := Label.new()
	prog_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	prog_lbl.text_direction = Control.TEXT_DIRECTION_LTR
	prog_lbl.text = "Praying..."
	prog_lbl.add_theme_font_size_override("font_size", 13)
	prog_lbl.add_theme_color_override("font_color", Color(0.88, 0.86, 0.82))
	extra_pray_progress_container.add_child(prog_lbl)

	_panel_sep(body, Color(0.85, 0.55, 0.18))

	var upg := Button.new()
	upg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	upg.text = "⬆  Upgrade Building   (Coming Soon)"
	upg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upg.disabled = true
	_style_action_btn(upg, Color(0.50, 0.48, 0.44))
	body.add_child(upg)


func _refresh_extra_shelter_panel():
	var filled: int = clamp(believers_count - current_extra_shelter_idx * 5, 0, 5)
	extra_shelter_label.text = "%d / 5" % filled
	# Restore correct pray button / progress state for this shelter
	var has_sess := _has_session(current_extra_shelter_idx)
	extra_pray_go_btn.visible = not has_sess
	extra_pray_go_btn.disabled = filled <= 0 or temple == null or _praying_count() >= 5
	extra_pray_selector_row.visible = false
	extra_pray_progress_container.visible = has_sess
	if has_sess:
		_update_extra_prayer_ui()

func _on_extra_go_pray_pressed():
	var in_shelter: int = clamp(believers_count - current_extra_shelter_idx * 5, 0, 5)
	if _has_session(current_extra_shelter_idx) or in_shelter <= 0 or temple == null or _praying_count() >= 5:
		return
	var temple_slots: int = 5 - _praying_count()
	extra_pray_selector_count = mini(1, mini(in_shelter, temple_slots))
	_update_extra_pray_selector_label()
	extra_pray_go_btn.visible = false
	extra_pray_selector_row.visible = true

func _update_extra_pray_selector_label():
	var s := "s" if extra_pray_selector_count > 1 else ""
	extra_pray_selector_label.text = "%d believer%s" % [extra_pray_selector_count, s]

func _on_extra_pray_confirm_pressed():
	var shelter_pos: Vector2
	if current_extra_shelter_idx - 1 < extra_shelter_buildings.size():
		shelter_pos = extra_shelter_buildings[current_extra_shelter_idx - 1].position
	else:
		return
	_start_prayer_session(current_extra_shelter_idx, shelter_pos, extra_pray_selector_count,
		extra_pray_selector_row, extra_pray_progress_container, extra_pray_go_btn)


func _praying_count() -> int:
	var total := 0
	for s in prayer_sessions:
		total += s.count
	return total

func _has_session(shelter_idx: int) -> bool:
	for s in prayer_sessions:
		if s.shelter_idx == shelter_idx:
			return true
	return false

func _on_go_pray_pressed():
	var available_in_shelter := mini(believers_count, 5)
	if _has_session(0) or available_in_shelter <= 0 or temple == null or _praying_count() >= 5:
		return
	prayer_selector_count = mini(1, available_in_shelter)
	_update_pray_selector_label()
	pray_go_btn.visible = false
	pray_selector_row.visible = true
	if tut_step == TutStep.TAP_GO_PRAY:
		tut_step = TutStep.CHOOSE_BELIEVERS
		tut_popup_dismissed = true
		_update_tutorial()


func _on_pray_cancel_pressed():
	pray_selector_row.visible = false
	pray_go_btn.visible = true


func _on_pray_confirm_pressed():
	_start_prayer_session(0, SHELTER_POS, prayer_selector_count,
		pray_selector_row, pray_progress_container, pray_go_btn)
	if tut_step == TutStep.CHOOSE_BELIEVERS:
		tut_step = TutStep.COMPLETE
		tut_popup_dismissed = false
		_update_tutorial()

func _start_prayer_session(shelter_idx: int, home_pos: Vector2, wanted: int,
		selector_row: HBoxContainer, progress_container: VBoxContainer, go_btn: Button):
	if temple == null or wanted <= 0 or _praying_count() + wanted > 5:
		return
	# Walk believers to temple via road network
	# Pick believers closest to the sending shelter so the right ones visually walk away
	var sorted_believers := believers.duplicate()
	sorted_believers.sort_custom(func(a, b): return a.position.distance_to(home_pos) < b.position.distance_to(home_pos))
	var nodes: Array = []
	var sent := 0
	var shelter_door: Vector2 = SHELTER_POS + Vector2(0, 40)
	for b in sorted_believers:
		if sent >= wanted:
			break
		believers.erase(b)
		nodes.append(b)
		var spread_x := (sent - (wanted - 1) * 0.5) * 18.0
		var target := temple.position + Vector2(spread_x, 48)
		if shelter_idx == 0:
			# Main shelter → temple (single L-corner)
			var door: Vector2 = home_pos + Vector2(0, 40)
			var corner := _road_corner(door, target)
			if corner.distance_to(target) > 4.0 and corner.distance_to(door) > 4.0:
				b.walk_to(corner)
				b.reached_forced_target.connect(func(): b.walk_to(target), CONNECT_ONE_SHOT)
			else:
				b.walk_to(target)
		else:
			# Extra shelter → main shelter door → temple (two legs via existing roads)
			var extra_door: Vector2 = home_pos + Vector2(0, 48)
			var c1 := _road_corner(extra_door, shelter_door)
			var c2 := _road_corner(shelter_door, target)
			# Chain: extra_door (→ c1) → shelter_door (→ c2) → target
			var _target := target
			if c1.distance_to(shelter_door) > 4.0 and c1.distance_to(extra_door) > 4.0:
				b.walk_to(c1)
				b.reached_forced_target.connect(func():
					b.walk_to(shelter_door)
					b.reached_forced_target.connect(func():
						if c2.distance_to(_target) > 4.0 and c2.distance_to(shelter_door) > 4.0:
							b.walk_to(c2)
							b.reached_forced_target.connect(func(): b.walk_to(_target), CONNECT_ONE_SHOT)
						else:
							b.walk_to(_target)
					, CONNECT_ONE_SHOT)
				, CONNECT_ONE_SHOT)
			else:
				b.walk_to(shelter_door)
				b.reached_forced_target.connect(func():
					if c2.distance_to(_target) > 4.0 and c2.distance_to(shelter_door) > 4.0:
						b.walk_to(c2)
						b.reached_forced_target.connect(func(): b.walk_to(_target), CONNECT_ONE_SHOT)
					else:
						b.walk_to(_target)
				, CONNECT_ONE_SHOT)
		sent += 1
	# Hide after walk time — use full path length for extra shelters
	var temple_center := temple.position + Vector2(0, 48)
	var path_dist: float
	if shelter_idx == 0:
		var door_pos: Vector2 = home_pos + Vector2(0, 40)
		var rc := _road_corner(door_pos, temple_center)
		path_dist = door_pos.distance_to(rc) + rc.distance_to(temple_center)
	else:
		var extra_door: Vector2 = home_pos + Vector2(0, 48)
		var rc2 := _road_corner(shelter_door, temple_center)
		path_dist = extra_door.distance_to(shelter_door) + shelter_door.distance_to(rc2) + rc2.distance_to(temple_center)
	var walk_time := path_dist / 35.0 + 2.0
	var nodes_ref := nodes
	get_tree().create_timer(walk_time).timeout.connect(func():
		for b in nodes_ref:
			if is_instance_valid(b):
				b.visible = false
				b.park()
	)
	# Build a session row in the temple panel
	var row := _make_prayer_session_row(wanted)
	temple_prayer_row.add_child(row)
	temple_prayer_row.visible = true
	# Create session dict
	var sess := {
		"count": wanted, "timer": PRAYER_TIME, "accumulator": 0.0,
		"nodes": nodes, "home_pos": home_pos, "shelter_idx": shelter_idx,
		"row": row, "bar": row.get_node("bar_bg/bar")
	}
	prayer_sessions.append(sess)
	# Update calling shelter's UI
	if selector_row:
		selector_row.visible = false
	if go_btn:
		go_btn.visible = false
	if progress_container:
		progress_container.visible = true
	if shelter_idx == 0:
		_update_prayer_ui()
	else:
		_update_extra_prayer_ui()
	_refresh_temple_panel()

func _make_prayer_session_row(count: int) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vb.add_theme_constant_override("separation", 3)
	vb.name = "session_row"
	var s_plural := "s" if count > 1 else ""
	var lbl := Label.new()
	lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	lbl.text_direction = Control.TEXT_DIRECTION_LTR
	lbl.text = "%d believer%s praying  (+%d faith/min)" % [count, s_plural, count]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.72, 1.00))
	vb.add_child(lbl)
	var bar_bg := ColorRect.new()
	bar_bg.name = "bar_bg"
	bar_bg.color = Color(0.10, 0.08, 0.18)
	bar_bg.custom_minimum_size = Vector2(0, 8)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(bar_bg)
	var bar := ColorRect.new()
	bar.name = "bar"
	bar.color = Color(0.72, 0.55, 1.00)
	bar.anchor_top    = 0.0
	bar.anchor_bottom = 1.0
	bar.anchor_left   = 0.0
	bar.anchor_right  = 0.0
	bar_bg.add_child(bar)
	return vb


func _on_pray_rush_pressed():
	if faith < 1:
		return
	faith -= 1
	# Rush the main shelter's session
	for i in range(prayer_sessions.size()):
		var sess: Dictionary = prayer_sessions[i]
		if sess.shelter_idx == 0:
			sess.timer = max(0.0, sess.timer - 600.0)
			if sess.timer <= 0.0:
				_complete_prayer_session(i)
			else:
				_update_prayer_ui()
			return


func _update_prayer_ui():
	for s in prayer_sessions:
		if s.shelter_idx == 0:
			var mins := int(s.timer) / 60
			var secs := int(s.timer) % 60
			var s_plural := "s" if s.count > 1 else ""
			pray_status_label.text = "Praying: %d believer%s — %d:%02d  (+%d faith/min)" % [
				s.count, s_plural, mins, secs, s.count]
			pray_bar.anchor_right = 1.0 - (s.timer / PRAYER_TIME)
			pray_rush_btn.disabled = faith < 1
			return
	_reset_prayer_ui()


func _update_extra_prayer_ui():
	if extra_pray_progress_container == null:
		return
	for s in prayer_sessions:
		if s.shelter_idx == current_extra_shelter_idx:
			var mins := int(s.timer) / 60
			var secs := int(s.timer) % 60
			(extra_pray_progress_container.get_child(0) as Label).text = \
				"Praying: %d — %d:%02d  (+%d faith/min)" % [s.count, mins, secs, s.count]
			return


func _complete_prayer_session(idx: int):
	var sess: Dictionary = prayer_sessions[idx]
	prayer_sessions.remove_at(idx)
	# Return believers to their home shelter via road network
	var sdoor: Vector2 = SHELTER_POS + Vector2(0, 40)
	for b in sess.nodes:
		if not is_instance_valid(b):
			continue
		b.position = temple.position + Vector2(randf_range(-15, 15), 40)
		b.visible = true
		believers.append(b)
		var home_offset: Vector2 = Vector2(randf_range(-30, 30), randf_range(-15, 15))
		var dest: Vector2 = sess.home_pos + home_offset
		if sess.shelter_idx == 0:
			_walk_via_road(b, sdoor, dest, func(): b.start_wandering(dest))
		else:
			# temple → main shelter door → extra shelter
			var temple_exit: Vector2 = temple.position + Vector2(0, 48)
			_walk_via_road(b, temple_exit, sdoor, func():
				_walk_via_road(b, sdoor, dest, func(): b.start_wandering(dest))
			)
	# Remove this session's temple row
	if is_instance_valid(sess.row):
		sess.row.queue_free()
	if prayer_sessions.size() == 0:
		temple_prayer_row.visible = false
	_refresh_temple_panel()
	# Reset the correct shelter's UI
	if sess.shelter_idx == 0:
		_reset_prayer_ui()
	else:
		_reset_extra_prayer_ui()


func _reset_prayer_ui():
	pray_progress_container.visible = false
	pray_selector_row.visible = false
	pray_go_btn.visible = true
	pray_go_btn.disabled = believers_count <= 0 or temple == null or _praying_count() >= 5
	shelter_believer_label.text = "%d / 5" % mini(believers_count, 5)


func _reset_extra_prayer_ui():
	if extra_pray_progress_container == null:
		return
	extra_pray_progress_container.visible = false
	if extra_pray_selector_row:
		extra_pray_selector_row.visible = false
	if extra_pray_go_btn:
		extra_pray_go_btn.visible = true
		var in_shelter: int = clamp(believers_count - current_extra_shelter_idx * 5, 0, 5)
		extra_pray_go_btn.disabled = in_shelter <= 0 or temple == null or _praying_count() >= 5


func _update_pray_selector_label():
	pray_selector_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pray_selector_label.text_direction = Control.TEXT_DIRECTION_LTR
	var s := "s" if prayer_selector_count > 1 else ""
	pray_selector_label.text = "%d believer%s" % [prayer_selector_count, s]


func _build_temple_panel(ui: CanvasLayer):
	temple_panel = _make_building_panel(ui, Color(0.72, 0.55, 1.00), "Small Temple")
	var body := _panel_body(temple_panel)

	temple_praying_label = _count_row(body, "Believers praying", Color(0.85, 0.72, 1.00))

	# Dynamic session rows — one sub-VBox added per active prayer session
	temple_prayer_row = VBoxContainer.new()
	temple_prayer_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	temple_prayer_row.add_theme_constant_override("separation", 6)
	temple_prayer_row.visible = false
	body.add_child(temple_prayer_row)

	_panel_sep(body, Color(0.72, 0.55, 1.00))

	var info_lbl := Label.new()
	info_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	info_lbl.text = "Send believers to pray\nfrom the Shelter panel."
	info_lbl.add_theme_font_size_override("font_size", 12)
	info_lbl.add_theme_color_override("font_color", Color(0.65, 0.63, 0.60))
	body.add_child(info_lbl)

	_panel_sep(body, Color(0.72, 0.55, 1.00))

	var upg := Button.new()
	upg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	upg.text = "⬆  Upgrade Building   (Coming Soon)"
	upg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upg.disabled = true
	_style_action_btn(upg, Color(0.50, 0.48, 0.44))
	body.add_child(upg)


func _build_garrison_panel(ui: CanvasLayer):
	garrison_panel = _make_building_panel(ui, Color(0.75, 0.22, 0.14), "Garrison")
	var body := _panel_body(garrison_panel)

	garrison_soldier_label = _count_row(body, "Soldiers housed", Color(0.90, 0.55, 0.18))

	_panel_sep(body, Color(0.75, 0.22, 0.14))

	# ── Go on a Crusade button ──
	crusade_go_btn = Button.new()
	crusade_go_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_go_btn.text = "⚔  Go on a Crusade   (2 hr)"
	crusade_go_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_btn(crusade_go_btn, Color(0.75, 0.22, 0.14))
	crusade_go_btn.pressed.connect(_on_crusade_pressed)
	body.add_child(crusade_go_btn)

	# ── Selector row (hidden until button tapped) ──
	crusade_selector_row = HBoxContainer.new()
	crusade_selector_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_selector_row.add_theme_constant_override("separation", 6)
	crusade_selector_row.visible = false
	body.add_child(crusade_selector_row)

	var minus_btn := Button.new()
	minus_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	minus_btn.text = "−"
	minus_btn.custom_minimum_size = Vector2(32, 0)
	minus_btn.pressed.connect(func():
		crusade_selector_count = max(1, crusade_selector_count - 1)
		_update_crusade_selector_label())
	crusade_selector_row.add_child(minus_btn)

	crusade_selector_label = Label.new()
	crusade_selector_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_selector_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crusade_selector_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crusade_selector_label.add_theme_font_size_override("font_size", 13)
	crusade_selector_row.add_child(crusade_selector_label)

	var plus_btn := Button.new()
	plus_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(32, 0)
	plus_btn.pressed.connect(func():
		crusade_selector_count = min(soldiers_in_garrison, crusade_selector_count + 1)
		_update_crusade_selector_label())
	crusade_selector_row.add_child(plus_btn)

	var send_btn := Button.new()
	send_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	send_btn.text = "March →"
	_style_action_btn(send_btn, Color(0.75, 0.22, 0.14))
	send_btn.pressed.connect(_on_crusade_confirm_pressed)
	crusade_selector_row.add_child(send_btn)

	# ── Bring Marcus toggle (hidden until he's available) ──
	crusade_bring_marcus_btn = Button.new()
	crusade_bring_marcus_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_bring_marcus_btn.text = "⚔ Bring Marcus as Leader"
	crusade_bring_marcus_btn.toggle_mode = true
	crusade_bring_marcus_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crusade_bring_marcus_btn.visible = false
	_style_action_btn(crusade_bring_marcus_btn, Color(0.80, 0.55, 0.10))
	crusade_selector_row.get_parent().add_child(crusade_bring_marcus_btn)   # sibling of selector_row, inside body

	# ── Progress area (hidden until mission started) ──
	crusade_progress_container = VBoxContainer.new()
	crusade_progress_container.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_progress_container.add_theme_constant_override("separation", 6)
	crusade_progress_container.visible = false
	body.add_child(crusade_progress_container)

	crusade_timer_label = Label.new()
	crusade_timer_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crusade_timer_label.add_theme_font_size_override("font_size", 13)
	crusade_timer_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.98))
	crusade_progress_container.add_child(crusade_timer_label)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.18, 0.08, 0.08)
	bar_bg.custom_minimum_size = Vector2(0, 12)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crusade_progress_container.add_child(bar_bg)

	crusade_bar = ColorRect.new()
	crusade_bar.color = Color(0.85, 0.25, 0.10)
	crusade_bar.anchor_top    = 0.0
	crusade_bar.anchor_bottom = 1.0
	crusade_bar.anchor_left   = 0.0
	crusade_bar.anchor_right  = 0.0
	bar_bg.add_child(crusade_bar)

	crusade_rush_btn = Button.new()
	crusade_rush_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_rush_btn.text = "⚡ Rush  (1 Faith = -10 min)"
	crusade_rush_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_btn(crusade_rush_btn, Color(0.72, 0.55, 1.00))
	crusade_rush_btn.pressed.connect(_on_crusade_rush_pressed)
	crusade_progress_container.add_child(crusade_rush_btn)

	_panel_sep(body, Color(0.75, 0.22, 0.14))

	var upg := Button.new()
	upg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	upg.text = "⬆  Upgrade Building   (Coming Soon)"
	upg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upg.disabled = true
	_style_action_btn(upg, Color(0.50, 0.48, 0.44))
	body.add_child(upg)


func _build_tutorial_panel(ui: CanvasLayer):
	# Full-screen overlay — blocks input while popup is showing
	tutorial_overlay = ColorRect.new()
	tutorial_overlay.layout_direction = Control.LAYOUT_DIRECTION_LTR
	tutorial_overlay.anchor_left   = 0.0
	tutorial_overlay.anchor_right  = 1.0
	tutorial_overlay.anchor_top    = 0.0
	tutorial_overlay.anchor_bottom = 1.0
	tutorial_overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_overlay.visible = false
	ui.add_child(tutorial_overlay)

	# Centered popup card (DragonVale style)
	tutorial_popup = PanelContainer.new()
	tutorial_popup.layout_direction = Control.LAYOUT_DIRECTION_LTR
	tutorial_popup.anchor_left   = 0.5
	tutorial_popup.anchor_right  = 0.5
	tutorial_popup.anchor_top    = 0.5
	tutorial_popup.anchor_bottom = 0.5
	tutorial_popup.offset_left   = -235
	tutorial_popup.offset_right  = 235
	tutorial_popup.offset_top    = -115
	tutorial_popup.offset_bottom = 115
	var _popup_style := StyleBoxFlat.new()
	_popup_style.bg_color = Color(0.08, 0.06, 0.16, 0.97)
	_popup_style.border_color = Color(0.85, 0.68, 0.15)
	_popup_style.set_border_width_all(3)
	_popup_style.set_corner_radius_all(12)
	_popup_style.content_margin_left   = 14
	_popup_style.content_margin_right  = 14
	_popup_style.content_margin_top    = 12
	_popup_style.content_margin_bottom = 12
	tutorial_popup.add_theme_stylebox_override("panel", _popup_style)
	tutorial_popup.visible = false
	ui.add_child(tutorial_popup)

	var _hbox := HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 14)
	tutorial_popup.add_child(_hbox)

	# Leader portrait on the left
	var _portrait := TextureRect.new()
	_portrait.custom_minimum_size = Vector2(100, 150)
	_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var _portrait_path: String
	match GameData.selected_leader:
		0: _portrait_path = "res://High Priest.png"
		1: _portrait_path = "res://Prophet of Wealth.png"
		2: _portrait_path = "res://Holy General.png"
		_: _portrait_path = "res://High Priest.png"
	_portrait.texture = load(_portrait_path)
	_hbox.add_child(_portrait)

	# Right side: leader name + speech text + OK button
	var _vbox := VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 8)
	_hbox.add_child(_vbox)

	var _name_lbl := Label.new()
	_name_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_name_lbl.text = GameData.leader_name
	_name_lbl.add_theme_font_size_override("font_size", 17)
	_name_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.25))
	_vbox.add_child(_name_lbl)

	tutorial_popup_text = Label.new()
	tutorial_popup_text.layout_direction = Control.LAYOUT_DIRECTION_LTR
	tutorial_popup_text.text = ""
	tutorial_popup_text.add_theme_font_size_override("font_size", 14)
	tutorial_popup_text.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	tutorial_popup_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_popup_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vbox.add_child(tutorial_popup_text)

	var _btn_row := HBoxContainer.new()
	_btn_row.alignment = BoxContainer.ALIGNMENT_END
	_vbox.add_child(_btn_row)

	var _ok_btn := Button.new()
	_ok_btn.text = "OK"
	_ok_btn.custom_minimum_size = Vector2(80, 36)
	_ok_btn.pressed.connect(_on_tutorial_popup_ok)
	_btn_row.add_child(_ok_btn)

	# ── Arrow hints (shown after popup is dismissed) ──────────────────────────

	# Floating badge that tracks the Humble Shelter on the map (TAP_SHELTER step)
	shelter_arrow = PanelContainer.new()
	shelter_arrow.layout_direction = Control.LAYOUT_DIRECTION_LTR
	shelter_arrow.anchor_left   = 0.0
	shelter_arrow.anchor_right  = 0.0
	shelter_arrow.anchor_top    = 0.0
	shelter_arrow.anchor_bottom = 0.0
	shelter_arrow.offset_left   = 0
	shelter_arrow.offset_right  = 180
	shelter_arrow.offset_top    = 0
	shelter_arrow.offset_bottom = 36
	var _sa_style := StyleBoxFlat.new()
	_sa_style.bg_color = Color(0.05, 0.04, 0.10, 0.88)
	_sa_style.border_color = Color(0.95, 0.15, 0.15)
	_sa_style.set_border_width_all(2)
	_sa_style.set_corner_radius_all(7)
	_sa_style.content_margin_left  = 10
	_sa_style.content_margin_right = 10
	_sa_style.content_margin_top   = 5
	_sa_style.content_margin_bottom = 5
	shelter_arrow.add_theme_stylebox_override("panel", _sa_style)
	shelter_arrow.visible = false
	ui.add_child(shelter_arrow)

	shelter_arrow_label = Label.new()
	shelter_arrow_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	shelter_arrow_label.text = "↓  Tap Shelter"
	shelter_arrow_label.add_theme_font_size_override("font_size", 17)
	shelter_arrow_label.add_theme_color_override("font_color", Color(0.95, 0.15, 0.15))
	shelter_arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shelter_arrow.add_child(shelter_arrow_label)

	# "Tap Rush →" label on the LEFT side of the Rush button row, pointing right
	rush_tutorial_arrow = Label.new()
	rush_tutorial_arrow.layout_direction = Control.LAYOUT_DIRECTION_LTR
	rush_tutorial_arrow.text = "Tap Rush →"
	rush_tutorial_arrow.add_theme_font_size_override("font_size", 14)
	rush_tutorial_arrow.add_theme_color_override("font_color", Color(1.0, 0.30, 0.30))
	rush_tutorial_arrow.anchor_left   = 0.0
	rush_tutorial_arrow.anchor_right  = 0.0
	rush_tutorial_arrow.anchor_top    = 1.0
	rush_tutorial_arrow.anchor_bottom = 1.0
	rush_tutorial_arrow.offset_left   = 16
	rush_tutorial_arrow.offset_right  = 160
	rush_tutorial_arrow.offset_top    = -82
	rush_tutorial_arrow.offset_bottom = -60
	rush_tutorial_arrow.visible = false
	ui.add_child(rush_tutorial_arrow)

	# Floating badge below the Wheel of Faith chip (WHEEL_HINT step)
	wheel_tutorial_arrow = PanelContainer.new()
	wheel_tutorial_arrow.layout_direction = Control.LAYOUT_DIRECTION_LTR
	wheel_tutorial_arrow.anchor_left   = 0.0
	wheel_tutorial_arrow.anchor_right  = 0.0
	wheel_tutorial_arrow.anchor_top    = 0.0
	wheel_tutorial_arrow.anchor_bottom = 0.0
	wheel_tutorial_arrow.offset_top    = 58
	wheel_tutorial_arrow.offset_bottom = 94
	var _wa_style := StyleBoxFlat.new()
	_wa_style.bg_color = Color(0.05, 0.04, 0.10, 0.90)
	_wa_style.border_color = Color(0.95, 0.15, 0.15)
	_wa_style.set_border_width_all(2)
	_wa_style.set_corner_radius_all(7)
	_wa_style.content_margin_left   = 8
	_wa_style.content_margin_right  = 8
	_wa_style.content_margin_top    = 4
	_wa_style.content_margin_bottom = 4
	wheel_tutorial_arrow.add_theme_stylebox_override("panel", _wa_style)
	wheel_tutorial_arrow.visible = false
	var _wa_lbl := Label.new()
	_wa_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_wa_lbl.text = "↑  Tap to Spin!"
	_wa_lbl.add_theme_font_size_override("font_size", 14)
	_wa_lbl.add_theme_color_override("font_color", Color(0.95, 0.15, 0.15))
	wheel_tutorial_arrow.add_child(_wa_lbl)
	ui.add_child(wheel_tutorial_arrow)


func _build_construction_panel(ui: CanvasLayer):
	construction_panel = PanelContainer.new()
	construction_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	construction_panel.anchor_left   = 0.0
	construction_panel.anchor_right  = 1.0
	construction_panel.anchor_top    = 1.0
	construction_panel.anchor_bottom = 1.0
	construction_panel.offset_left   = 8
	construction_panel.offset_right  = -8
	construction_panel.offset_top    = -118
	construction_panel.offset_bottom = -60
	construction_panel.visible = false
	ui.add_child(construction_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	construction_panel.add_child(vbox)

	# Title row: name + time
	construction_label = Label.new()
	construction_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	construction_label.text = "Small Temple — 5:00"
	construction_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(construction_label)

	# Progress bar (bg + fill)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.15, 0.12, 0.20)
	bar_bg.custom_minimum_size = Vector2(0, 10)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(bar_bg)

	construction_bar = ColorRect.new()
	construction_bar.color = Color(0.30, 0.75, 0.35)
	construction_bar.anchor_top    = 0.0
	construction_bar.anchor_bottom = 1.0
	construction_bar.anchor_left   = 0.0
	construction_bar.anchor_right  = 0.0   # grows as construction progresses
	bar_bg.add_child(construction_bar)

	# Rush button
	rush_button = Button.new()
	rush_button.layout_direction = Control.LAYOUT_DIRECTION_LTR
	rush_button.text = "⚡  Rush!  (1 Faith Point)"
	rush_button.add_theme_font_size_override("font_size", 14)
	rush_button.pressed.connect(_on_rush_pressed)
	vbox.add_child(rush_button)


func _update_construction_ui():
	var mins := int(active_construction_timer) / 60
	var secs := int(active_construction_timer) % 60
	var bname: String
	match active_construction_type:
		"temple":           bname = "Small Temple"
		"hall_of_devoted":  bname = "Hall of the Devoted"
		"preacher_shelter": bname = "Preacher Shelter"
		"armory":           bname = "Barracks"
		"garrison":         bname = "Garrison"
		"shelter":          bname = "Believer Shelter"
		_:                  bname = "Building"
	construction_label.text = "%s — %d:%02d remaining" % [bname, mins, secs]
	rush_button.disabled = faith < 1
	rush_button.text = "⚡  Rush!  (1 Faith Point)" if faith >= 1 else "⚡  Rush!  (need Faith)"
	var progress := 1.0 - (active_construction_timer / active_construction_max)
	construction_bar.anchor_right = progress

	# Pulse rush button during RUSH_PROMPT tutorial step
	if tut_step == TutStep.RUSH_PROMPT and faith >= 1 and tut_popup_dismissed:
		rush_pulse += get_process_delta_time() * 3.0
		var t := (sin(rush_pulse) + 1.0) * 0.5
		rush_button.modulate = Color(1.0, lerp(0.65, 1.0, t), lerp(0.20, 0.65, t))
	else:
		rush_button.modulate = Color.WHITE
		rush_pulse = 0.0


func _update_conversion_ui():
	var mins := int(conversion_timer) / 60
	var secs := int(conversion_timer) % 60
	conversion_label.text = "Converting — %d:%02d remaining" % [mins, secs]
	convert_btn.disabled = true
	convert_btn.text = "Converting… (%d:%02d)" % [mins, secs]
	var progress := 1.0 - (conversion_timer / CONVERSION_TIME)
	conversion_bar.anchor_right = progress
	conversion_rush_btn.visible = true
	conversion_rush_btn.disabled = faith < 1
	conversion_rush_btn.text = "⚡ -10m" if faith >= 1 else "⚡ need Faith"


# ── Tutorial logic ────────────────────────────────────────────────────────────
func _update_tutorial():
	var popup_showing: bool = !tut_popup_dismissed and tut_step != TutStep.DONE

	if tutorial_overlay:
		tutorial_overlay.visible = popup_showing
	if tutorial_popup:
		tutorial_popup.visible = popup_showing
		if popup_showing and tutorial_popup_text:
			tutorial_popup_text.text = _tut_speech(tut_step)

	# Arrows only appear after the popup for that step is dismissed
	if rush_tutorial_arrow:
		rush_tutorial_arrow.visible = tut_popup_dismissed and tut_step == TutStep.RUSH_PROMPT
	if shelter_arrow:
		shelter_arrow.visible = tut_popup_dismissed and tut_step == TutStep.TAP_SHELTER
	if pray_tutorial_arrow:
		pray_tutorial_arrow.visible = tut_popup_dismissed and tut_step == TutStep.TAP_GO_PRAY
	if wheel_tutorial_arrow:
		wheel_tutorial_arrow.visible = tut_popup_dismissed and tut_step == TutStep.WHEEL_HINT
		if tut_popup_dismissed and tut_step == TutStep.WHEEL_HINT and wheel_chip_node != null:
			var chip_pos := wheel_chip_node.global_position
			wheel_tutorial_arrow.offset_left  = chip_pos.x
			wheel_tutorial_arrow.offset_right = chip_pos.x + wheel_chip_node.size.x + 20
	if temple_build_indicator:
		temple_build_indicator.visible = tut_popup_dismissed and tut_step == TutStep.BUILD_TEMPLE


func _on_tutorial_popup_ok():
	match tut_step:
		TutStep.INTRO:
			tut_step = TutStep.BUILD_TEMPLE
			tut_popup_dismissed = false
		TutStep.TEMPLE_COMPLETE:
			tut_step = TutStep.TAP_SHELTER
			tut_popup_dismissed = false
		TutStep.COMPLETE:
			tut_step = TutStep.WHEEL_HINT
			tut_popup_dismissed = false
		_:
			tut_popup_dismissed = true
	_update_tutorial()


func _tut_speech(step: int) -> String:
	var n: String = GameData.leader_name
	match step:
		TutStep.INTRO:
			return "Greetings, my lord! I am %s, your faithful guide.\n\nFive believers have pledged their lives to your cause. Together, we shall build an empire worthy of the gods!" % n
		TutStep.BUILD_TEMPLE:
			return "Your people are restless — they need a place to worship.\n\nBuild a Temple and they will pray, earning you Faith Points. Open the Build menu to begin!"
		TutStep.PLACE_TEMPLE:
			return "Choose the perfect spot!\n\nTap anywhere on the map to place the Temple."
		TutStep.RUSH_PROMPT:
			return "Patience is a virtue — but Faith is power!\n\nEach Faith Point shaves 10 minutes off construction. Give that Rush button a tap!"
		TutStep.TEMPLE_COMPLETE:
			return "Magnificent! The Temple rises in your name.\n\nYour believers can now gather within its walls and pray."
		TutStep.TAP_SHELTER:
			return "Time to put your people to work!\n\nTap the Humble Shelter to send your believers to pray at the Temple."
		TutStep.TAP_GO_PRAY:
			return "Tap the Go Pray button, choose how many believers to send, then hit Send to Pray.\n\nThey will return after 30 minutes with faith in their hearts."
		TutStep.CHOOSE_BELIEVERS:
			return ""
		TutStep.COMPLETE:
			return "You've done it, my lord! Faith fuels everything — rush builds, unlock upgrades, and grow your empire.\n\nThe divine path lies open before you."
		TutStep.WHEEL_HINT:
			return "One final gift before you go!\n\nThe Grand Priestess has prepared a divine miracle. Tap the Spin chip to claim your first blessing."
		_:
			return ""


func _pulse_build_button(delta: float):
	if tut_step == TutStep.BUILD_TEMPLE and tut_popup_dismissed:
		highlight_pulse += delta * 3.0
		var t := (sin(highlight_pulse) + 1.0) * 0.5
		build_button.modulate = Color(1.0, lerp(0.55, 1.0, t), lerp(0.15, 0.55, t))
		# Pulse the rush arrow between bright red and soft red
		if rush_tutorial_arrow and rush_tutorial_arrow.visible:
			var t2 := (sin(highlight_pulse) + 1.0) * 0.5
			rush_tutorial_arrow.add_theme_color_override("font_color",
				Color(1.0, lerp(0.20, 0.45, t2), lerp(0.20, 0.45, t2)))
		# Pulse the temple indicator arrow between bright red and dim red
		if temple_build_indicator and temple_build_indicator.visible:
			var arrow_color := Color(1.0, lerp(0.15, 0.35, t), lerp(0.15, 0.35, t), lerp(0.6, 1.0, t))
			temple_build_indicator.add_theme_color_override("font_color", arrow_color)
	elif (tut_step == TutStep.TAP_SHELTER or tut_step == TutStep.TAP_GO_PRAY) and tut_popup_dismissed:
		highlight_pulse += delta * 3.0
		# Pulse the shelter / pray arrows
		if shelter_arrow_label and shelter_arrow and shelter_arrow.visible:
			var t := (sin(highlight_pulse) + 1.0) * 0.5
			shelter_arrow_label.add_theme_color_override("font_color",
				Color(1.0, lerp(0.10, 0.40, t), lerp(0.10, 0.40, t)))
		if pray_tutorial_arrow and pray_tutorial_arrow.visible:
			var t := (sin(highlight_pulse) + 1.0) * 0.5
			pray_tutorial_arrow.add_theme_color_override("font_color",
				Color(1.0, lerp(0.20, 0.50, t), lerp(0.20, 0.50, t)))
		if wheel_tutorial_arrow and wheel_tutorial_arrow.visible:
			var t2 := (sin(highlight_pulse) + 1.0) * 0.5
			var lbl2 := wheel_tutorial_arrow.get_child(0) as Label
			if lbl2:
				lbl2.add_theme_color_override("font_color",
					Color(1.0, lerp(0.15, 0.45, t2), lerp(0.15, 0.45, t2)))
	else:
		build_button.modulate = Color.WHITE
		highlight_pulse = 0.0


# ── Build actions ─────────────────────────────────────────────────────────────
func _on_build_pressed():
	if placing_building:
		_cancel_placement()
		return
	build_menu.visible = not build_menu.visible


func _on_build_shelter():
	_try_start_placement("shelter", 40)

func _on_build_temple():
	if temple != null:
		return
	_try_start_placement("temple", 30)

func _on_build_hall():
	if hall_of_devoted != null:
		return
	_try_start_placement("hall_of_devoted", 70)

func _on_build_preacher_shelter():
	if preacher_shelter_building != null:
		return
	_try_start_placement("preacher_shelter", 50)

func _on_build_armory():
	if armory != null:
		return
	_try_start_placement("armory", 80)

func _on_build_garrison():
	if garrison != null:
		return
	_try_start_placement("garrison", 60)

func _on_build_generals_quarters():
	if generals_quarters != null:
		return
	if not marcus_obtained:
		return
	_try_start_placement("generals_quarters", 100)


func _try_start_placement(type: String, cost: int):
	if active_construction_timer > 0.0:
		tutorial_label.text = "Finish the current construction first!"
		get_tree().create_timer(2.0).timeout.connect(_update_tutorial)
		return
	if gold < cost:
		tutorial_label.text = "Not enough gold! You need %d gold." % cost
		get_tree().create_timer(2.0).timeout.connect(_update_tutorial)
		return
	gold -= cost
	placing_cost = cost
	build_menu.visible = false
	_start_placement(type)


# ── Placement mode ────────────────────────────────────────────────────────────
func _start_placement(type: String):
	placing_building = true
	placing_type = type
	ghost_node = Area2D.new()
	ghost_node.set_script(load("res://building.gd"))
	ghost_node.building_type    = type
	ghost_node.building_label   = ""
	ghost_node.is_interactive   = false
	ghost_node.modulate         = Color(0.60, 1.0, 0.60, 0.55)
	ghost_node.position         = get_viewport().get_mouse_position()
	world.add_child(ghost_node)

	if type == "temple" and tut_step == TutStep.BUILD_TEMPLE:
		tut_step = TutStep.PLACE_TEMPLE
		tut_popup_dismissed = false
		if temple_build_indicator:
			temple_build_indicator.visible = false
		_update_tutorial()


func _cancel_placement():
	placing_building = false
	if ghost_node:
		ghost_node.queue_free()
		ghost_node = null
	gold += placing_cost   # refund
	if placing_type == "temple" and tut_step == TutStep.PLACE_TEMPLE:
		tut_step = TutStep.BUILD_TEMPLE
		tut_popup_dismissed = false
		_update_tutorial()
	placing_type = ""
	placing_cost = 0


func _place_building(pos: Vector2):
	var type := placing_type
	placing_building = false
	placing_type = ""
	placing_cost = 0
	if ghost_node:
		ghost_node.queue_free()
		ghost_node = null

	var label: String
	var max_time: float
	match type:
		"temple":           label = "Small Temple";        max_time = CONSTRUCTION_TIME
		"hall_of_devoted":  label = "Hall of the Devoted"; max_time = HALL_CONSTRUCTION_TIME
		"preacher_shelter": label = "Preacher Shelter";    max_time = PREACHER_SHELTER_TIME
		"shelter":          label = "Believer Shelter";    max_time = SHELTER_UPGRADE_TIME
		"armory":           label = "Barracks";            max_time = ARMORY_CONSTRUCTION_TIME
		"garrison":         label = "Garrison";            max_time = GARRISON_CONSTRUCTION_TIME

	var b := _make_building(type, pos, label, false)
	b.set_meta("under_construction", true)
	b.queue_redraw()

	match type:
		"temple":             temple                    = b
		"hall_of_devoted":    hall_of_devoted           = b
		"preacher_shelter":   preacher_shelter_building = b
		"armory":             armory                    = b
		"garrison":           garrison                  = b
		"shelter":            pass   # multiple allowed, tracked by believer_shelter_count

	blocked_zones.append({"pos": pos, "radius": 85.0})

	active_construction_node  = b
	active_construction_type  = type
	active_construction_max   = max_time
	active_construction_timer = max_time
	construction_panel.visible = true
	_update_construction_ui()

	if type == "temple" and tut_step == TutStep.PLACE_TEMPLE:
		tut_step = TutStep.RUSH_PROMPT
		tut_popup_dismissed = false
		_update_tutorial()


func _complete_construction():
	var type := active_construction_type
	var b    := active_construction_node
	active_construction_timer = 0.0
	active_construction_node  = null
	active_construction_type  = ""
	construction_panel.visible = false

	b.is_interactive = true
	b.remove_meta("under_construction")
	b.queue_redraw()

	match type:
		"temple":
			temple = b
			b.tapped.connect(_on_temple_tapped)
			_draw_road(SHELTER_POS + Vector2(0, 40), b.position + Vector2(0, 48))
			if tut_step == TutStep.RUSH_PROMPT:
				tut_step = TutStep.TEMPLE_COMPLETE
				tut_popup_dismissed = false
				_update_tutorial()
		"hall_of_devoted":
			b.tapped.connect(_on_hall_tapped)
			_draw_road(SHELTER_POS + Vector2(0, 40), b.position + Vector2(0, 20))
			_reset_conversion_ui()
		"preacher_shelter":
			preacher_shelter_built = true
			b.tapped.connect(_on_preacher_shelter_tapped)
			_draw_road(hall_of_devoted.position + Vector2(0, 20), b.position + Vector2(0, 48))
			# If a preacher was waiting at the hall, send them over now
			if preacher_waiting_at_hall and converting_node != null:
				preacher_waiting_at_hall = false
				_walk_via_road(converting_node, hall_of_devoted.position + Vector2(0, 20), preacher_shelter_building.position + Vector2(randf_range(-15, 15), 48), _on_preacher_arrived_at_shelter)
		"armory":
			armory_built = true
			b.tapped.connect(_on_armory_tapped)
			_draw_road(SHELTER_POS + Vector2(0, 40), b.position + Vector2(0, 20))
			_reset_training_ui()
		"garrison":
			garrison_built = true
			b.tapped.connect(_on_garrison_tapped)
			_draw_road(armory.position + Vector2(0, 20), b.position + Vector2(0, 48))
			# If a soldier was waiting at the barracks, send them over now
			if soldier_waiting_at_armory and training_node != null:
				soldier_waiting_at_armory = false
				_walk_via_road(training_node, armory.position + Vector2(0, 20), garrison.position + Vector2(randf_range(-15, 15), 48), _on_soldier_arrived_at_garrison)
		"generals_quarters":
			generals_quarters_built = true
			generals_quarters = b
			b.tapped.connect(_on_generals_quarters_tapped)
			_draw_road(garrison.position + Vector2(0, 48), b.position + Vector2(0, 48))
			# Spawn Marcus wandering around his new quarters
			var marcus_script := load("res://marcus_character.gd")
			marcus_character_node = marcus_script.new()
			world.add_child(marcus_character_node)
			marcus_character_node.setup(b.position + Vector2(0, 20))
		"shelter":
			believer_shelter_count += 1
			believer_capacity = believer_shelter_count * 5
			_draw_road(SHELTER_POS + Vector2(0, 40), b.position + Vector2(0, 48))
			var shelter_ref := b
			extra_shelter_buildings.append(b)
			b.tapped.connect(func():
				shelter_panel.visible = false
				conversion_panel.visible = false
				training_panel.visible = false
				preacher_shelter_panel.visible = false
				garrison_panel.visible = false
				current_extra_shelter_idx = extra_shelter_buildings.find(shelter_ref) + 1
				_refresh_extra_shelter_panel()
				extra_shelter_panel.visible = true
			)


func _on_rush_pressed():
	if faith < 1:
		return
	faith -= 1
	active_construction_timer = max(0.0, active_construction_timer - 600.0)   # -10 min
	if active_construction_timer <= 0.0:
		_complete_construction()
	else:
		_update_construction_ui()


func _on_temple_tapped():
	conversion_panel.visible = false
	training_panel.visible = false
	preacher_shelter_panel.visible = false
	garrison_panel.visible = false
	shelter_panel.visible = false
	if extra_shelter_panel:
		extra_shelter_panel.visible = false
	temple_panel.visible = not temple_panel.visible
	if temple_panel.visible:
		_refresh_temple_panel()


func _refresh_temple_panel():
	var total: int = 0
	for s in prayer_sessions:
		total += s.count
	temple_praying_label.text = "%d / 5" % total
	temple_prayer_row.visible = prayer_sessions.size() > 0


func _on_hall_tapped():
	training_panel.visible = false
	preacher_shelter_panel.visible = false
	garrison_panel.visible = false
	shelter_panel.visible = false
	if extra_shelter_panel:
		extra_shelter_panel.visible = false
	conversion_panel.visible = not conversion_panel.visible
	if conversion_panel.visible:
		_reset_conversion_ui()


func _on_convert_pressed():
	# Block if already converting or a preacher is still waiting/walking
	if converting or converting_node != null or believers_count <= 1:
		return
	# Pick a believer node to physically walk to the hall
	var chosen: CharacterBody2D = null
	for b in believers:
		chosen = b
		break
	if chosen == null:
		return
	believers.erase(chosen)
	converting_node = chosen
	converting = true
	conversion_timer = CONVERSION_TIME
	# Walk to hall entrance via road
	_walk_via_road(chosen, SHELTER_POS + Vector2(0, 40), hall_of_devoted.position + Vector2(0, 20), _on_believer_arrived_at_hall)
	_update_conversion_ui()


func _on_believer_arrived_at_hall():
	# Believer enters the building — hide them
	if converting_node:
		converting_node.visible = false
		converting_node.park()


func _on_conversion_rush_pressed():
	if faith < 1:
		return
	faith -= 1
	conversion_timer = max(0.0, conversion_timer - 600.0)   # -10 minutes
	if conversion_timer <= 0.0:
		_complete_conversion()
	else:
		_update_conversion_ui()


func _complete_conversion():
	converting = false
	believers_count -= 1
	preachers_count += 1
	# Convert the node visually
	if converting_node:
		converting_node.is_preacher = true
		converting_node.queue_redraw()
		preachers.append(converting_node)
		if preacher_shelter_built and preacher_shelter_building != null:
			# Shelter already exists — send preacher there via road
			converting_node.visible = true
			converting_node.needs_shelter = false
			_walk_via_road(converting_node, hall_of_devoted.position + Vector2(0, 20), preacher_shelter_building.position + Vector2(randf_range(-15, 15), 48), _on_preacher_arrived_at_shelter)
		else:
			# No shelter yet — stand at hall door and wait
			preacher_waiting_at_hall = true
			converting_node.visible = true
			converting_node.position = hall_of_devoted.position + Vector2(0, 30)
			converting_node.needs_shelter = true
			converting_node.park()
			converting_node.queue_redraw()
	_reset_conversion_ui()


func _on_preacher_arrived_at_shelter():
	if converting_node:
		preachers_in_shelter += 1
		preacher_waiting_at_hall = false
		converting_node.needs_shelter = false
		converting_node.start_wandering(
			preacher_shelter_building.position + Vector2(randf_range(-35, 35), randf_range(-18, 18)))
		converting_node = null
	_reset_conversion_ui()


func _on_spread_pressed():
	if spreading or preachers_in_shelter <= 0:
		return
	spread_selector_count = min(1, preachers_in_shelter)
	_update_spread_selector_label()
	spread_go_btn.visible = false
	spread_selector_row.visible = true


func _update_spread_selector_label():
	spread_selector_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	spread_selector_label.text_direction = Control.TEXT_DIRECTION_LTR
	var s := "s" if spread_selector_count > 1 else ""
	spread_selector_label.text = "%d preacher%s" % [spread_selector_count, s]


func _on_spread_confirm_pressed():
	if spreading or spread_selector_count <= 0 or preachers_in_shelter < spread_selector_count:
		return
	spreading = true
	spread_sent = spread_selector_count
	spread_timer = SPREAD_TIME
	spread_selector_row.visible = false
	spread_progress_container.visible = true

	# Hide the sent preachers from their shelter
	var hidden := 0
	for p in preachers.duplicate():
		if hidden >= spread_sent:
			break
		spreading_nodes.append(p)
		p.visible = false
		hidden += 1
	preachers_in_shelter -= spread_sent
	_refresh_preacher_label()
	_update_spread_ui()


func _update_spread_ui():
	if not spreading:
		return
	var mins := int(spread_timer) / 60
	var secs := int(spread_timer) % 60
	var s := "s" if spread_sent > 1 else ""
	spread_label.text = "%d preacher%s spreading the faith — %d:%02d remaining" % [spread_sent, s, mins, secs]
	var progress := 1.0 - (spread_timer / SPREAD_TIME)
	spread_bar.anchor_right = progress
	spread_rush_btn.disabled = faith < 1


func _on_spread_rush_pressed():
	if faith < 1:
		return
	faith -= 1
	spread_timer = max(0.0, spread_timer - 600.0)
	if spread_timer <= 0.0:
		_complete_spread()
	else:
		_update_spread_ui()
	_refresh_resource_labels()


func _complete_spread():
	spreading = false
	spread_progress_container.visible = false
	spread_go_btn.visible = true

	# Simulate how many believers each preacher brings
	var brought := 0
	for i in range(spread_sent):
		var roll := randf()
		if roll < 0.20:
			brought += 0       # 20% — nobody this time
		elif roll < 0.60:
			brought += 1       # 40% — 1 convert
		elif roll < 0.90:
			brought += 2       # 30% — 2 converts
		else:
			brought += 3       # 10% — inspired crowd

	# Cap by available shelter capacity
	var available := believer_shelter_count * 5 - believers_count
	var actually_joined := mini(brought, available)
	believers_count += actually_joined
	_refresh_resource_labels()

	# Return preachers to shelter
	preachers_in_shelter += spread_sent
	_refresh_preacher_label()
	for p in spreading_nodes:
		if is_instance_valid(p) and preacher_shelter_building != null:
			p.visible = true
			_walk_via_road(p, hall_of_devoted.position + Vector2(0, 20),
				preacher_shelter_building.position + Vector2(randf_range(-15, 15), 48),
				func(): pass)
	spreading_nodes.clear()

	# Build result message
	var result := ""
	if actually_joined <= 0 and brought <= 0:
		result = "The crowd was unmoved this time...\nYour preachers return to rest."
	elif actually_joined < brought:
		result = "%d soul%s wished to join, but your shelters\nare full! Build more to welcome them.\n%d joined anyway." % [
			brought, "s" if brought > 1 else "",
			actually_joined]
	else:
		var s := "s" if actually_joined > 1 else ""
		result = "%d new soul%s have joined your faith!\nThey make their way to your shelter." % [actually_joined, s]
	spread_result_label.text = result
	spread_result_popup.visible = true

	# Spawn the new believers at the correct shelter based on slot index
	if actually_joined > 0:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var start_count: int = believers_count - actually_joined
		for i in range(actually_joined):
			var b: CharacterBody2D = load("res://believer.tscn").instantiate()
			var shelter_idx: int = (start_count + i) / 5
			var spawn_pos: Vector2
			if shelter_idx == 0:
				spawn_pos = SHELTER_POS
			elif shelter_idx - 1 < extra_shelter_buildings.size():
				spawn_pos = extra_shelter_buildings[shelter_idx - 1].position
			else:
				spawn_pos = SHELTER_POS
			var offset := Vector2(rng.randf_range(-38, 38), rng.randf_range(-18, 18))
			world.add_child(b)
			b.setup(spawn_pos + offset, believers.size())
			believers.append(b)


func _refresh_preacher_label():
	var total: int = preachers_in_shelter + (spread_sent if spreading else 0)
	shelter_preacher_label.text = "%d / 5" % total


func _reset_conversion_ui():
	if preacher_waiting_at_hall:
		conversion_label.text = "⚠  Preacher waiting — build Preacher Shelter!"
		convert_btn.disabled = true
		convert_btn.text = "Preacher needs a home first"
	else:
		conversion_label.text = "Ready to convert"
		convert_btn.disabled = believers_count <= 1 or converting_node != null
		convert_btn.text = "Convert Believer  (1 hr)"
	conversion_bar.anchor_right = 0.0
	conversion_rush_btn.visible = false


# ── Armory / soldier training ─────────────────────────────────────────────────
func _on_armory_tapped():
	conversion_panel.visible = false
	preacher_shelter_panel.visible = false
	garrison_panel.visible = false
	shelter_panel.visible = false
	if extra_shelter_panel:
		extra_shelter_panel.visible = false
	training_panel.visible = not training_panel.visible
	if training_panel.visible:
		_reset_training_ui()

func _on_garrison_tapped():
	conversion_panel.visible = false
	training_panel.visible = false
	preacher_shelter_panel.visible = false
	shelter_panel.visible = false
	if extra_shelter_panel:
		extra_shelter_panel.visible = false
	garrison_panel.visible = not garrison_panel.visible
	if garrison_panel.visible:
		garrison_soldier_label.text = "%d / 5" % soldiers_in_garrison

func _on_generals_quarters_tapped():
	_show_building_info(generals_quarters, "General's Quarters\nMarcus the Iron Fist rests here\nbetween crusades.")

func _on_soldier_arrived_at_garrison():
	if training_node:
		soldiers_in_garrison += 1
		soldier_waiting_at_armory = false
		training_node.needs_shelter = false
		training_node.start_wandering(
			garrison.position + Vector2(randf_range(-35, 35), randf_range(-18, 18)))
		training_node = null
	_reset_training_ui()

func _on_train_pressed():
	if training or training_node != null or believers_count <= 1:
		return
	var chosen: CharacterBody2D = null
	for b in believers:
		chosen = b
		break
	if chosen == null:
		return
	believers.erase(chosen)
	training_node = chosen
	training = true
	training_timer = TRAINING_TIME
	_walk_via_road(chosen, SHELTER_POS + Vector2(0, 40), armory.position + Vector2(0, 20), _on_believer_arrived_at_armory)
	_update_training_ui()

func _on_believer_arrived_at_armory():
	if training_node:
		training_node.visible = false
		training_node.park()

func _on_training_rush_pressed():
	if faith < 1:
		return
	faith -= 1
	training_timer = max(0.0, training_timer - 600.0)
	if training_timer <= 0.0:
		_complete_training()
	else:
		_update_training_ui()

func _complete_training():
	training = false
	believers_count -= 1
	soldiers_count += 1
	if training_node:
		training_node.is_soldier = true
		training_node.queue_redraw()
		soldiers.append(training_node)
		if garrison_built and garrison != null:
			training_node.visible = true
			_walk_via_road(training_node, armory.position + Vector2(0, 20), garrison.position + Vector2(randf_range(-15, 15), 48), _on_soldier_arrived_at_garrison)
		else:
			# No garrison yet — stand at barracks door and wait
			soldier_waiting_at_armory = true
			training_node.visible = true
			training_node.position = armory.position + Vector2(0, 30)
			training_node.needs_shelter = true
			training_node.park()
			training_node.queue_redraw()
	_reset_training_ui()

func _update_training_ui():
	var mins := int(training_timer) / 60
	var secs := int(training_timer) % 60
	training_label.text = "Training — %d:%02d remaining" % [mins, secs]
	train_btn.disabled = true
	train_btn.text = "Training… (%d:%02d)" % [mins, secs]
	var progress := 1.0 - (training_timer / TRAINING_TIME)
	training_bar.anchor_right = progress
	training_rush_btn.visible = true
	training_rush_btn.disabled = faith < 1
	training_rush_btn.text = "⚡ -10m" if faith >= 1 else "⚡ need Faith"

func _reset_training_ui():
	if soldier_waiting_at_armory:
		training_label.text = "⚠  Soldier waiting — build a Garrison!"
		train_btn.disabled = true
		train_btn.text = "Soldier needs a home first"
	else:
		training_label.text = "Ready to train"
		train_btn.disabled = believers_count <= 1 or training_node != null
		train_btn.text = "Train Soldier  (30 min)"
	training_bar.anchor_right = 0.0
	training_rush_btn.visible = false


# ── Placement input + map panning ────────────────────────────────────────────
# Use _input (not _unhandled_input) so Control nodes eating mouse events don't block us
func _input(event: InputEvent):
	# Map panning: right-click drag (when not placing)
	if event is InputEventMouseMotion and is_panning:
		camera.position = pan_start_cam - (event.position - pan_start_mouse)
		get_viewport().set_input_as_handled()
		return

	var mb := event as InputEventMouseButton
	if mb == null:
		return

	if mb.button_index == MOUSE_BUTTON_RIGHT:
		if mb.pressed:
			if placing_building:
				get_viewport().set_input_as_handled()
				_cancel_placement()
			else:
				is_panning = true
				pan_start_mouse = mb.position
				pan_start_cam = camera.position
		else:
			is_panning = false
		return

	if not placing_building:
		return
	if not mb.pressed:
		return

	var vp_size := get_viewport().get_visible_rect().size
	var screen_pos: Vector2 = mb.position

	# Ignore clicks on the top UI bar or the bottom tutorial/construction strip
	if screen_pos.y < 58 or screen_pos.y > vp_size.y - 60:
		return

	if mb.button_index == MOUSE_BUTTON_LEFT:
		var pos := get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
		if _can_place_here(pos):
			get_viewport().set_input_as_handled()
			_place_building(pos)
		else:
			# Warn the player, then restore after 2 seconds
			tutorial_label.text = "Can't build there! Too close to a tree or building."
			get_tree().create_timer(2.0).timeout.connect(_update_tutorial)


func _can_place_here(pos: Vector2) -> bool:
	for zone in blocked_zones:
		if pos.distance_to(zone["pos"]) < zone["radius"]:
			return false
	return true


func _on_wheel_chip_input(event: InputEvent):
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if tut_step == TutStep.WHEEL_HINT:
		tut_step = TutStep.DONE
		_update_tutorial()
	if wheel_popup != null:
		wheel_popup.visible = true


func _build_wheel_popup(ui: CanvasLayer):
	# Dark overlay
	var overlay := ColorRect.new()
	overlay.color    = Color(0, 0, 0, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(overlay)

	# Main panel
	var panel := PanelContainer.new()
	panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color       = Color(0.08, 0.05, 0.15)
	pstyle.border_color   = Color(0.80, 0.62, 0.10)
	pstyle.set_border_width_all(3)
	pstyle.set_corner_radius_all(16)
	pstyle.content_margin_left   = 18
	pstyle.content_margin_right  = 18
	pstyle.content_margin_top    = 16
	pstyle.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", pstyle)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -420
	panel.offset_right  =  420
	panel.offset_top    = -300
	panel.offset_bottom =  300
	overlay.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)

	# ── Left: Grand Priestess ──
	var left := VBoxContainer.new()
	left.layout_direction = Control.LAYOUT_DIRECTION_LTR
	left.custom_minimum_size = Vector2(200, 0)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(left)

	var priestess_img := TextureRect.new()
	priestess_img.texture = load("res://grand_priestess.jpg")
	priestess_img.custom_minimum_size = Vector2(200, 360)
	priestess_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	priestess_img.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	left.add_child(priestess_img)

	var quote_lbl := Label.new()
	quote_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	quote_lbl.text = "\"The divine favours\nthe faithful...\""
	quote_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_lbl.add_theme_font_size_override("font_size", 11)
	quote_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.90))
	left.add_child(quote_lbl)

	# ── Right: Wheel + button ──
	var right := VBoxContainer.new()
	right.layout_direction = Control.LAYOUT_DIRECTION_LTR
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 12)
	hbox.add_child(right)

	var title_lbl := Label.new()
	title_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	title_lbl.text = "✦  Wheel of Faith  ✦"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.28))
	right.add_child(title_lbl)

	# Wheel container with pointer
	var wheel_area := Control.new()
	wheel_area.custom_minimum_size = Vector2(380, 390)
	right.add_child(wheel_area)

	# The spinning wheel node
	wheel_spinner = Node2D.new()
	var ws := _WheelSpinner.new()
	wheel_spinner.add_child(ws)
	wheel_spinner.position = Vector2(190, 205)
	wheel_area.add_child(wheel_spinner)

	# Pointer triangle at top of wheel
	var pointer := _PointerDrawer.new()
	pointer.position = Vector2(190, 38)
	wheel_area.add_child(pointer)

	# Result panel (hidden until spin completes)
	wheel_result_panel = PanelContainer.new()
	wheel_result_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	var rpstyle := StyleBoxFlat.new()
	rpstyle.bg_color     = Color(0.12, 0.08, 0.22)
	rpstyle.border_color = Color(0.80, 0.62, 0.10)
	rpstyle.set_border_width_all(2)
	rpstyle.set_corner_radius_all(8)
	wheel_result_panel.add_theme_stylebox_override("panel", rpstyle)
	wheel_result_panel.visible = false
	right.add_child(wheel_result_panel)

	wheel_result_label = Label.new()
	wheel_result_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	wheel_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wheel_result_label.add_theme_font_size_override("font_size", 15)
	wheel_result_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.30))
	wheel_result_panel.add_child(wheel_result_label)

	# Spin button
	wheel_spin_btn = Button.new()
	wheel_spin_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	wheel_spin_btn.text = "✦  Spin the Wheel  ✦"
	wheel_spin_btn.add_theme_font_size_override("font_size", 15)
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color     = Color(0.65, 0.45, 0.05)
	bstyle.border_color = Color(0.95, 0.80, 0.15)
	bstyle.set_border_width_all(2)
	bstyle.set_corner_radius_all(8)
	bstyle.content_margin_top    = 8
	bstyle.content_margin_bottom = 8
	wheel_spin_btn.add_theme_stylebox_override("normal", bstyle)
	wheel_spin_btn.add_theme_color_override("font_color", Color(0.98, 0.92, 0.40))
	wheel_spin_btn.pressed.connect(_on_spin_pressed)
	right.add_child(wheel_spin_btn)

	# Close button
	var close_btn := Button.new()
	close_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_color_override("font_color", Color(0.70, 0.65, 0.80))
	close_btn.pressed.connect(func(): overlay.visible = false)
	right.add_child(close_btn)

	overlay.visible = false
	wheel_popup = overlay


func _on_spin_pressed():
	if wheel_spinning or not wheel_available:
		return
	wheel_spinning = true
	wheel_available = false
	wheel_daily_timer = 0.0
	if wheel_chip_node != null:
		wheel_chip_node.visible = false
	wheel_spin_btn.disabled = true
	wheel_result_panel.visible = false

	# First spin always lands on +100 Gold (segment 2), after that random
	var target_seg: int
	if is_first_spin:
		target_seg = 2
		is_first_spin = false
	else:
		target_seg = randi() % WHEEL_SEGMENTS.size()

	# Calculate target rotation: spin 5 full turns + land exactly on segment center
	var seg_angle: float = (TAU / WHEEL_SEGMENTS.size())
	# Segment 0 starts at -PI/2 (top). To land segment target_seg at top (pointer):
	var landing_angle: float = -float(target_seg) * seg_angle - seg_angle * 0.5
	var total_rotation: float = TAU * 5.0 + landing_angle - fmod(wheel_spinner.rotation, TAU)

	var tween := create_tween()
	tween.tween_property(wheel_spinner, "rotation", wheel_spinner.rotation + total_rotation, 3.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _complete_spin(target_seg))


func _complete_spin(seg_index: int):
	wheel_spinning = false
	var seg: Dictionary = WHEEL_SEGMENTS[seg_index]
	match seg["type"]:
		"gold":
			gold += int(seg["amount"])
		"faith":
			faith += int(seg["amount"])
		"bad":
			gold = max(0, gold + int(seg["amount"]))
	_refresh_resource_labels()

	var result_text: String
	match seg["type"]:
		"gold":  result_text = "✦ +%d Gold flows into your treasury!" % int(seg["amount"])
		"faith": result_text = "✦ +%d Faith bestowed by the heavens!" % int(seg["amount"])
		"bad":   result_text = "⚠ Dark Omen! %d Gold was taken..." % abs(int(seg["amount"]))
		"card":  result_text = "✦ Aldric the Prophet answers your call!\n(Leader cards — coming soon)"
		_:       result_text = "✦ The gods have spoken!"

	wheel_result_label.text = result_text
	wheel_result_panel.visible = true


# ── Resource display ──────────────────────────────────────────────────────────
func _refresh_resource_labels():
	gold_label.text      = "Gold  %d"   % gold
	faith_label.text     = "Faith  %d"  % faith
	var total_people := believers_count + preachers_count + soldiers_count
	believers_label.text = "People  %d" % total_people
	# Keep people popup fresh while it's open
	if people_panel != null and people_panel.visible:
		_refresh_people_panel()


# ── Inner draw helpers (no separate files needed) ─────────────────────────────
class _TreeDrawer extends Node2D:
	var size_scale: float = 1.0   # varied per tree instance
	var green:      Color  = Color(0.22, 0.62, 0.12)
	var green2:     Color  = Color(0.32, 0.76, 0.20)

	func _draw():
		var s := size_scale
		var OUTLINE := Color(0.08, 0.04, 0.01)
		var TRUNK   := Color(0.50, 0.28, 0.10)
		var TRUNK_D := Color(0.36, 0.18, 0.06)
		var STONE   := Color(0.68, 0.62, 0.50)
		var STONE_D := Color(0.54, 0.48, 0.38)

		# ── Stone base ──────────────────────────────────────
		# Outline
		draw_colored_polygon(_ellipse_pts(Vector2(0, 8*s), 26*s, 8*s, 8), OUTLINE)
		# Stone platform
		draw_colored_polygon(_ellipse_pts(Vector2(0, 8*s), 23*s, 8*s, 8), STONE)
		# Stone tile lines
		for i in range(4):
			var a := i * PI / 4
			draw_line(
				Vector2(0, 8*s),
				Vector2(cos(a)*22*s, 8*s + sin(a)*7*s),
				STONE_D, 1.0)
		draw_colored_polygon(_ellipse_pts(Vector2(0, 8*s), 5*s, 4*s, 6), STONE_D)

		# ── Trunk ────────────────────────────────────────────
		# Flared base outline
		draw_colored_polygon(PackedVector2Array([
			Vector2(-14*s, 8*s), Vector2(14*s, 8*s),
			Vector2(8*s, -18*s), Vector2(-8*s, -18*s)
		]), OUTLINE)
		# Trunk fill (trapezoid — wide base, narrow top)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-12*s, 7*s), Vector2(12*s, 7*s),
			Vector2(6*s, -17*s), Vector2(-6*s, -17*s)
		]), TRUNK)
		# Trunk shadow stripe
		draw_colored_polygon(PackedVector2Array([
			Vector2(4*s, 7*s), Vector2(10*s, 7*s),
			Vector2(4*s, -17*s), Vector2(2*s, -17*s)
		]), TRUNK_D)
		# Root flares
		draw_colored_polygon(PackedVector2Array([
			Vector2(-12*s,7*s), Vector2(-20*s,10*s), Vector2(-14*s,2*s)
		]), TRUNK)
		draw_colored_polygon(PackedVector2Array([
			Vector2(12*s,7*s), Vector2(20*s,10*s), Vector2(14*s,2*s)
		]), TRUNK)
		draw_polyline(PackedVector2Array([
			Vector2(-12*s,7*s), Vector2(-20*s,10*s), Vector2(-14*s,2*s)
		]), OUTLINE, 1.2)
		draw_polyline(PackedVector2Array([
			Vector2(12*s,7*s), Vector2(20*s,10*s), Vector2(14*s,2*s)
		]), OUTLINE, 1.2)

		# ── Crown — 5 overlapping circles for scalloped edges ──
		# Draw all outlines first (slightly larger, dark)
		var blobs := [
			[Vector2(-18*s, -30*s), 20*s],   # left
			[Vector2( 18*s, -30*s), 20*s],   # right
			[Vector2(-10*s, -44*s), 22*s],   # upper-left
			[Vector2( 10*s, -44*s), 22*s],   # upper-right
			[Vector2(  0*s, -54*s), 22*s],   # top center
		]
		for b in blobs:
			draw_colored_polygon(_circle_pts(b[0], b[1]+3, 14), OUTLINE)
		# Fill with base green
		for b in blobs:
			draw_colored_polygon(_circle_pts(b[0], b[1], 14), green)
		# Top blob brighter (sunlit top)
		draw_colored_polygon(_circle_pts(Vector2(0, -54*s), 20*s, 14), green2)
		draw_colored_polygon(_circle_pts(Vector2(-8*s, -58*s), 12*s, 12), green2.lightened(0.15))
		# Small shine spot
		draw_colored_polygon(_circle_pts(Vector2(-10*s, -62*s), 5*s, 8),
			Color(1.0, 1.0, 1.0, 0.30))

	func _circle_pts(center: Vector2, r: float, n: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in range(n):
			var a = i * TAU / n
			pts.append(center + Vector2(cos(a) * r, sin(a) * r))
		return pts

	func _ellipse_pts(center: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in range(n):
			var a = i * TAU / n
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		return pts


class _PathDrawer extends Node2D:
	const DIRT    = Color(0.72, 0.56, 0.34)
	const DIRT2   = Color(0.62, 0.48, 0.28)
	const OUTLINE = Color(0.10, 0.05, 0.02)

	func _draw():
		# Soft shadow under path
		draw_rect(Rect2(-163, -18, 326, 48), Color(0,0,0,0.12))
		draw_rect(Rect2(-18, -118, 46, 204), Color(0,0,0,0.12))

		# Dirt path — horizontal
		draw_rect(Rect2(-162, -20, 324, 42), OUTLINE)
		draw_rect(Rect2(-160, -18, 320, 38), DIRT)
		# Dirt texture lines
		for i in range(6):
			draw_line(Vector2(-150+i*52, -16), Vector2(-130+i*52, 16), DIRT2, 1.5)

		# Dirt path — vertical
		draw_rect(Rect2(-20, -120, 42, 202), OUTLINE)
		draw_rect(Rect2(-18, -118, 38, 198), DIRT)
		for i in range(5):
			draw_line(Vector2(-16, -108+i*40), Vector2(16, -88+i*40), DIRT2, 1.5)


class _RoadSegment extends Node2D:
	const DIRT    = Color(0.72, 0.56, 0.34)
	const DIRT2   = Color(0.62, 0.48, 0.28)
	const OUTLINE = Color(0.10, 0.05, 0.02)
	const WIDTH   = 38.0
	var from_pos: Vector2
	var to_pos: Vector2

	func _draw_segment(a: Vector2, b: Vector2):
		if a.distance_to(b) < 1.0:
			return
		var dir: Vector2  = (b - a).normalized()
		var perp: Vector2 = Vector2(-dir.y, dir.x)
		draw_line(a, b, OUTLINE, WIDTH + 4)
		draw_line(a, b, DIRT, WIDTH)
		var n: int = int(a.distance_to(b) / 22.0)
		for i in range(1, n + 1):
			var c: Vector2 = a + dir * (float(i) * 22.0)
			draw_line(c - perp * (WIDTH * 0.4), c + perp * (WIDTH * 0.4), DIRT2, 1.5)

	func _draw():
		# Choose corner direction: go along the longer axis first for a natural path
		var dx: float = abs(to_pos.x - from_pos.x)
		var dy: float = abs(to_pos.y - from_pos.y)
		var corner: Vector2 = Vector2(from_pos.x, to_pos.y) if dy >= dx else Vector2(to_pos.x, from_pos.y)
		_draw_segment(from_pos, corner)
		_draw_segment(corner, to_pos)
		# Fill the corner junction so there's no gap
		draw_rect(Rect2(corner - Vector2(WIDTH / 2 + 2, WIDTH / 2 + 2), Vector2(WIDTH + 4, WIDTH + 4)), OUTLINE)
		draw_rect(Rect2(corner - Vector2(WIDTH / 2, WIDTH / 2), Vector2(WIDTH, WIDTH)), DIRT)


class _GrassPatch extends Node2D:
	var rx: float  = 40.0
	var ry: float  = 24.0
	var col: Color = Color(0.45, 0.78, 0.30, 0.55)

	func _draw():
		var pts := PackedVector2Array()
		for i in range(16):
			var a = i * TAU / 16
			pts.append(Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, col)


class _WheelSpinner extends Node2D:
	const TWO_PI := PI * 2.0
	const SEG_COLORS := [
		Color(0.88, 0.62, 0.08), Color(0.28, 0.14, 0.72),
		Color(0.82, 0.38, 0.04), Color(0.16, 0.08, 0.28),
		Color(0.50, 0.14, 0.86), Color(0.06, 0.38, 0.60),
		Color(0.95, 0.78, 0.00), Color(0.68, 0.22, 0.85),
	]
	const SEG_LABELS := [
		"+50 Gold", "+20 Faith", "+100 Gold", "Dark Omen",
		"+50 Faith", "Aldric", "+200 Gold", "+100 Faith",
	]
	const RADIUS := 155.0
	const N      := 8
	const STEPS  := 32

	func _draw():
		var font:      Font  = ThemeDB.fallback_font
		var seg_angle: float = TWO_PI / float(N)

		# ── Drop shadow ──────────────────────────────────────────────────────
		draw_circle(Vector2(5, 5), RADIUS + 14, Color(0, 0, 0, 0.35))

		# ── Outer decorative ring ─────────────────────────────────────────────
		draw_circle(Vector2.ZERO, RADIUS + 12, Color(0.92, 0.74, 0.12))
		draw_circle(Vector2.ZERO, RADIUS +  7, Color(0.55, 0.36, 0.04))
		draw_circle(Vector2.ZERO, RADIUS +  4, Color(0.80, 0.60, 0.08))

		# ── Coloured segments ─────────────────────────────────────────────────
		for i in range(N):
			var a_start: float = float(i) * seg_angle - PI * 0.5
			var a_end:   float = a_start + seg_angle

			var pts := PackedVector2Array()
			pts.append(Vector2.ZERO)
			for s in range(STEPS + 1):
				var a: float = a_start + (a_end - a_start) * float(s) / float(STEPS)
				pts.append(Vector2(cos(a), sin(a)) * RADIUS)
			draw_colored_polygon(pts, SEG_COLORS[i])

			# Lighter arc highlight along outer edge
			var arc_pts := PackedVector2Array()
			for s in range(STEPS + 1):
				var a: float = a_start + (a_end - a_start) * float(s) / float(STEPS)
				arc_pts.append(Vector2(cos(a), sin(a)) * (RADIUS - 2.0))
			draw_polyline(arc_pts, SEG_COLORS[i].lightened(0.35), 4.0)

		# ── Gold divider lines between segments ───────────────────────────────
		for i in range(N):
			var a: float = float(i) * seg_angle - PI * 0.5
			draw_line(Vector2.ZERO,
				Vector2(cos(a), sin(a)) * (RADIUS + 4),
				Color(0.85, 0.65, 0.08), 2.5)

		# ── Rotated labels ────────────────────────────────────────────────────
		for i in range(N):
			var mid_angle: float = float(i) * seg_angle - PI * 0.5 + seg_angle * 0.5
			# Rotate context to align text along segment direction
			draw_set_transform(Vector2.ZERO, mid_angle, Vector2.ONE)
			var txt: String = SEG_LABELS[i]
			var font_size:  int = 12
			# Shadow
			draw_string(font, Vector2(RADIUS * 0.38, 5), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.6))
			# Main text
			draw_string(font, Vector2(RADIUS * 0.38, 4), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.97, 0.85))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# ── Hub ───────────────────────────────────────────────────────────────
		draw_circle(Vector2.ZERO, 26, Color(0.92, 0.74, 0.12))
		draw_circle(Vector2.ZERO, 20, Color(0.18, 0.10, 0.30))
		draw_circle(Vector2.ZERO, 12, Color(0.88, 0.70, 0.10))
		draw_circle(Vector2.ZERO,  6, Color(0.98, 0.92, 0.55))


class _PointerDrawer extends Node2D:
	func _draw():
		# Shadow
		draw_colored_polygon(PackedVector2Array([
			Vector2(-13, -5), Vector2(13, -5), Vector2(2, 30)
		]), Color(0, 0, 0, 0.35))
		# Body
		draw_colored_polygon(PackedVector2Array([
			Vector2(-12, -8), Vector2(12, -8), Vector2(0, 28)
		]), Color(0.95, 0.18, 0.12))
		# Highlight
		draw_colored_polygon(PackedVector2Array([
			Vector2(-5, -7), Vector2(2, -7), Vector2(-3, 10)
		]), Color(1.0, 0.55, 0.50, 0.55))
		# Outline
		draw_polyline(PackedVector2Array([
			Vector2(-12, -8), Vector2(12, -8), Vector2(0, 28), Vector2(-12, -8)
		]), Color(0.55, 0.05, 0.02), 1.5)


class _PriestessDrawer extends Node2D:
	func _draw():
		# Aura glow
		for r in [80, 65, 50]:
			draw_circle(Vector2(0, -90), float(r), Color(0.55, 0.35, 0.80, 0.06))

		# Throne back
		draw_rect(Rect2(-52, -155, 104, 180), Color(0.18, 0.12, 0.28))
		draw_rect(Rect2(-46, -148, 92, 168), Color(0.25, 0.16, 0.38))
		# Throne armrests
		draw_rect(Rect2(-58, -60, 20, 12), Color(0.30, 0.20, 0.45))
		draw_rect(Rect2( 38, -60, 20, 12), Color(0.30, 0.20, 0.45))

		# Robe (long white flowing)
		var robe_pts := PackedVector2Array([
			Vector2(-38, -20), Vector2(38, -20),
			Vector2(52, 130),  Vector2(-52, 130)
		])
		draw_colored_polygon(robe_pts, Color(0.88, 0.86, 0.92))
		# Robe shading fold lines
		for x in [-12.0, 0.0, 12.0]:
			draw_line(Vector2(x, -10), Vector2(x + 8, 125), Color(0.72, 0.70, 0.80, 0.50), 1.5)

		# Body / torso
		draw_rect(Rect2(-22, -90, 44, 72), Color(0.82, 0.80, 0.88))
		# Collar / neckline detail
		draw_rect(Rect2(-18, -90, 36, 8), Color(0.65, 0.55, 0.78))

		# Arms
		draw_rect(Rect2(-42, -78, 20, 50), Color(0.80, 0.78, 0.86))
		draw_rect(Rect2( 22, -78, 20, 50), Color(0.80, 0.78, 0.86))
		# Hands resting on armrests
		draw_circle(Vector2(-35, -28), 8, Color(0.85, 0.72, 0.62))
		draw_circle(Vector2( 35, -28), 8, Color(0.85, 0.72, 0.62))

		# Head
		draw_circle(Vector2(0, -112), 28, Color(0.88, 0.76, 0.66))

		# Hair (long white/silver)
		var hair_l := PackedVector2Array([
			Vector2(-12, -138), Vector2(-28, -112),
			Vector2(-32, -60), Vector2(-22, -18)
		])
		draw_polyline(hair_l, Color(0.90, 0.90, 0.95), 10)
		var hair_r := PackedVector2Array([
			Vector2(12, -138), Vector2(28, -112),
			Vector2(32, -60), Vector2(22, -18)
		])
		draw_polyline(hair_r, Color(0.90, 0.90, 0.95), 10)

		# Crown base
		draw_rect(Rect2(-22, -148, 44, 12), Color(0.80, 0.62, 0.10))
		# Crown spikes
		for cx in [-14.0, 0.0, 14.0]:
			var spike := PackedVector2Array([
				Vector2(cx - 6, -148), Vector2(cx + 6, -148), Vector2(cx, -168)
			])
			draw_colored_polygon(spike, Color(0.90, 0.72, 0.12))

		# Crescent moon on crown
		draw_circle(Vector2(0, -178), 10, Color(0.92, 0.88, 0.60))
		draw_circle(Vector2(5, -176),  8, Color(0.18, 0.12, 0.28))

		# Eyes
		draw_circle(Vector2(-10, -114), 4, Color(0.15, 0.10, 0.22))
		draw_circle(Vector2( 10, -114), 4, Color(0.15, 0.10, 0.22))
		draw_circle(Vector2(-9,  -115), 2, Color(0.85, 0.75, 0.95))
		draw_circle(Vector2( 11, -115), 2, Color(0.85, 0.75, 0.95))

		# Mystical orb in right hand
		draw_circle(Vector2(35, -42), 12, Color(0.45, 0.25, 0.80, 0.70))
		draw_circle(Vector2(35, -42),  8, Color(0.65, 0.45, 0.95))
		draw_circle(Vector2(32, -45),  3, Color(0.90, 0.85, 1.00, 0.80))

		# Stars floating around
		for sp in [Vector2(-65, -130), Vector2(68, -100), Vector2(-70, -60), Vector2(72, -150)]:
			draw_circle(sp, 3, Color(0.95, 0.90, 0.55, 0.85))
			draw_circle(sp, 1, Color(1.0, 1.0, 0.9))

# ── Crusade functions ─────────────────────────────────────────────────────────

func _on_crusade_pressed():
	if crusading or soldiers_in_garrison <= 0:
		return
	crusade_selector_count = mini(1, soldiers_in_garrison)
	_update_crusade_selector_label()
	crusade_go_btn.visible = false
	crusade_selector_row.visible = true
	# Show Marcus toggle only when he's available and at his quarters
	if crusade_bring_marcus_btn != null:
		crusade_bring_marcus_btn.visible = generals_quarters_built and marcus_obtained and not marcus_leading_crusade
		crusade_bring_marcus_btn.button_pressed = false


func _update_crusade_selector_label():
	var s := "s" if crusade_selector_count != 1 else ""
	crusade_selector_label.text = "%d soldier%s" % [crusade_selector_count, s]


func _on_crusade_confirm_pressed():
	if crusading or crusade_selector_count <= 0 or soldiers_in_garrison < crusade_selector_count:
		return
	crusading = true
	crusade_sent = crusade_selector_count
	soldiers_in_garrison -= crusade_sent
	garrison_soldier_label.text = "%d / 5" % soldiers_in_garrison

	# Hide soldiers visually during crusade
	var hidden: int = 0
	for sol in soldiers:
		if hidden >= crusade_sent:
			break
		if is_instance_valid(sol):
			sol.visible = false
			crusading_nodes.append(sol)
			hidden += 1

	# If Marcus is toggled as leader, hide him from his quarters
	marcus_leading_crusade = crusade_bring_marcus_btn != null and crusade_bring_marcus_btn.button_pressed
	if marcus_leading_crusade and is_instance_valid(marcus_character_node):
		marcus_character_node.visible = false
		marcus_character_node.park()

	crusade_timer = CRUSADE_TIME
	crusade_selector_row.visible = false
	if crusade_bring_marcus_btn != null:
		crusade_bring_marcus_btn.visible = false
	crusade_progress_container.visible = true
	_update_crusade_ui()


func _update_crusade_ui():
	var mins: int = int(crusade_timer / 60.0)
	var secs: int = int(crusade_timer) % 60
	crusade_timer_label.text = "Crusading... %d:%02d remaining" % [mins, secs]
	var fill: float = 1.0 - (crusade_timer / CRUSADE_TIME)
	crusade_bar.anchor_right = fill
	if crusade_rush_btn != null:
		crusade_rush_btn.disabled = faith < 1


func _on_crusade_rush_pressed():
	if faith < 1:
		return
	faith -= 1
	crusade_timer = max(0.0, crusade_timer - 600.0)
	if crusade_timer <= 0.0:
		_complete_crusade()
	else:
		_update_crusade_ui()
	_refresh_resource_labels()


func _complete_crusade():
	crusading = false
	crusade_progress_container.visible = false
	crusade_go_btn.visible = true

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Marcus bonus: lower death rate + better boxes
	var death_rate := 0.05 if marcus_leading_crusade else 0.15

	# Soldier casualties
	var survivors: int = 0
	for i in range(crusade_sent):
		if rng.randf() > death_rate:
			survivors += 1
	var fallen: int = crusade_sent - survivors
	soldiers_in_garrison += survivors

	# Return surviving soldiers visually
	var returned: int = 0
	for sol in crusading_nodes:
		if is_instance_valid(sol):
			if returned < survivors:
				sol.visible = true
				if garrison != null:
					sol.start_wandering(garrison.position + Vector2(rng.randf_range(-35, 35), rng.randf_range(-18, 18)))
				returned += 1
	crusading_nodes.clear()
	garrison_soldier_label.text = "%d / 5" % soldiers_in_garrison

	# Roll one treasure box per soldier sent
	var boxes: Array = []
	var total_gold: int = 0
	var total_faith: int = 0
	var got_marcus: bool = false

	for i in range(crusade_sent):
		var box: Dictionary = _roll_box(rng)
		# Marcus leadership bonus: upgrade each box one rarity tier
		if marcus_leading_crusade:
			box = _upgrade_box_rarity(box, rng)
		boxes.append(box)
		total_gold  += box.gold
		total_faith += box.faith
		if not marcus_obtained and (true or rng.randf() < box.hero_chance):  # DEBUG: always drop on first crusade
			got_marcus = true

	if got_marcus:
		marcus_obtained = true

	# Return Marcus to his quarters
	if marcus_leading_crusade:
		marcus_leading_crusade = false
		if is_instance_valid(marcus_character_node) and generals_quarters != null:
			marcus_character_node.visible = true
			marcus_character_node.start_wandering(generals_quarters.position + Vector2(0, 20))

	# Store results for phase 2 (opened after player taps chests)
	crusade_pending = {
		"fallen": fallen,
		"gold": total_gold,
		"faith": total_faith,
		"got_marcus": got_marcus,
		"boxes": boxes
	}

	# Populate chest boxes in phase 1
	for child in crusade_chests_row.get_children():
		child.queue_free()
	crusade_chest_images.clear()
	var display_boxes: Array = boxes
	for box_data in display_boxes:
		_add_chest_box(crusade_chests_row, box_data.rarity)

	# Soldier info label
	if fallen > 0:
		var sf := "s" if fallen != 1 else ""
		crusade_result_label.text = "%d soldier%s fell in battle." % [fallen, sf]
	else:
		crusade_result_label.text = "All soldiers returned safely!"

	crusade_result_title.text = "The Crusade Returns!" if not marcus_leading_crusade else "Marcus Leads a Victory!"
	crusade_phase1.visible = true
	crusade_phase2.visible = false
	crusade_result_popup.visible = true


func _roll_box(rng: RandomNumberGenerator) -> Dictionary:
	var roll: float = rng.randf()
	var rarity: String
	if roll < 0.01:
		rarity = "Legendary"
	elif roll < 0.07:
		rarity = "Epic"
	elif roll < 0.20:
		rarity = "Rare"
	elif roll < 0.45:
		rarity = "Uncommon"
	else:
		rarity = "Common"

	var gold_reward: int
	var faith_reward: int
	var hero_chance: float

	match rarity:
		"Common":
			gold_reward  = rng.randi_range(50,  100)
			faith_reward = rng.randi_range(5,   10)
			hero_chance  = 0.02
		"Uncommon":
			gold_reward  = rng.randi_range(100, 200)
			faith_reward = rng.randi_range(10,  20)
			hero_chance  = 0.05
		"Rare":
			gold_reward  = rng.randi_range(200, 400)
			faith_reward = rng.randi_range(20,  40)
			hero_chance  = 0.10
		"Epic":
			gold_reward  = rng.randi_range(400, 800)
			faith_reward = rng.randi_range(40,  80)
			hero_chance  = 0.20
		"Legendary":
			gold_reward  = rng.randi_range(800, 1500)
			faith_reward = rng.randi_range(80,  150)
			hero_chance  = 0.50
		_:
			gold_reward  = 50
			faith_reward = 5
			hero_chance  = 0.02

	return {"rarity": rarity, "gold": gold_reward, "faith": faith_reward, "hero_chance": hero_chance}


func _upgrade_box_rarity(box: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	# Marcus leadership bonus: upgrade rarity one tier, boost rewards accordingly
	const TIERS := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	var idx: int = TIERS.find(box.rarity)
	if idx < 0 or idx >= TIERS.size() - 1:
		return box   # already Legendary, no change
	var new_rarity: String = TIERS[idx + 1]
	# Re-roll rewards at the higher tier
	var upgraded: Dictionary = _roll_box(rng)
	upgraded["rarity"] = new_rarity
	# Keep at least the original gold/faith as a floor
	upgraded["gold"]  = maxi(upgraded.gold,  box.gold)
	upgraded["faith"] = maxi(upgraded.faith, box.faith)
	return upgraded


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Common":    return Color(0.55, 0.55, 0.55)
		"Uncommon":  return Color(0.20, 0.75, 0.20)
		"Rare":      return Color(0.25, 0.50, 1.00)
		"Epic":      return Color(0.65, 0.20, 0.90)
		"Legendary": return Color(0.95, 0.65, 0.05)
	return Color(0.55, 0.55, 0.55)


func _add_chest_box(row: HBoxContainer, rarity: String):
	var col := _rarity_color(rarity)

	var inner := VBoxContainer.new()
	inner.layout_direction = Control.LAYOUT_DIRECTION_LTR
	inner.add_theme_constant_override("separation", 4)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(inner)

	# Chest image
	var chest_tex: Texture2D = load("res://Treasure box.png")
	var img := TextureRect.new()
	img.layout_direction = Control.LAYOUT_DIRECTION_LTR
	img.texture = chest_tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.custom_minimum_size = Vector2(220, 220)
	img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	img.modulate = col.lightened(0.15) if rarity != "Common" else Color.WHITE
	inner.add_child(img)
	crusade_chest_images.append(img)

	var rar_lbl := Label.new()
	rar_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	rar_lbl.text = rarity
	rar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rar_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rar_lbl.add_theme_font_size_override("font_size", 14)
	rar_lbl.add_theme_color_override("font_color", col)
	inner.add_child(rar_lbl)


func _on_open_chests_pressed():
	var open_tex: Texture2D = load("res://Open Treasure Box.png")
	var total: int = crusade_chest_images.size()

	# Animate each chest opening one by one with a small bounce
	for i in total:
		var img: TextureRect = crusade_chest_images[i]
		var delay: float = i * 0.18
		# Scale up (bounce) then swap to open texture
		var tw: Tween = create_tween()
		tw.tween_interval(delay)
		tw.tween_property(img, "scale", Vector2(1.25, 1.25), 0.10)
		tw.tween_callback(func():
			img.texture = open_tex
			img.modulate = Color.WHITE
		)
		tw.tween_property(img, "scale", Vector2(1.0, 1.0), 0.12)

	# After all chests have animated, switch to Phase 2
	var switch_delay: float = total * 0.18 + 0.45
	var sw: Tween = create_tween()
	sw.tween_interval(switch_delay)
	sw.tween_callback(func():
		var p: Dictionary = crusade_pending
		var g: int = p.get("gold", 0)
		var f: int = p.get("faith", 0)
		var got_marcus: bool = p.get("got_marcus", false)

		gold  += g
		faith += f
		_refresh_resource_labels()

		crusade_rewards_label.text = "+%d Gold     +%d Faith" % [g, f]
		crusade_marcus_container.visible = got_marcus

		crusade_phase1.visible = false
		crusade_phase2.visible = true

		# Unlock General's Quarters in build menu and show Hero Deck chip
		if marcus_obtained:
			if generals_quarters_build_row != null:
				generals_quarters_build_row.visible = true
			if generals_quarters_sep != null:
				generals_quarters_sep.visible = true
			if hero_deck_chip != null:
				hero_deck_chip.visible = true
	)


func _on_crusade_dismiss_pressed():
	crusade_result_popup.visible = false


# ── Crusade result popup ───────────────────────────────────────────────────────

func _build_crusade_result_popup(ui: CanvasLayer):
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.70)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	ui.add_child(overlay)
	crusade_result_popup = overlay

	# CenterContainer auto-centers panel on screen regardless of content size
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	panel.custom_minimum_size = Vector2(360, 0)   # fixed width, height follows content
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.05, 0.05)
	ps.border_color = Color(0.75, 0.22, 0.14)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.content_margin_left   = 20
	ps.content_margin_right  = 20
	ps.content_margin_top    = 16
	ps.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	# Title
	crusade_result_title = Label.new()
	crusade_result_title.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crusade_result_title.add_theme_font_size_override("font_size", 18)
	crusade_result_title.add_theme_color_override("font_color", Color(0.95, 0.55, 0.15))
	vb.add_child(crusade_result_title)

	# Soldier info (shared between phases)
	crusade_result_label = Label.new()
	crusade_result_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crusade_result_label.add_theme_font_size_override("font_size", 13)
	crusade_result_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.98))
	vb.add_child(crusade_result_label)

	# ── PHASE 1: closed chests ────────────────────────────────────────────────
	crusade_phase1 = VBoxContainer.new()
	crusade_phase1.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_phase1.add_theme_constant_override("separation", 10)
	vb.add_child(crusade_phase1)

	var tap_lbl := Label.new()
	tap_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	tap_lbl.text = "Your crusade brought back treasures!"
	tap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_lbl.add_theme_font_size_override("font_size", 13)
	tap_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.65))
	crusade_phase1.add_child(tap_lbl)

	var scroll := ScrollContainer.new()
	scroll.layout_direction = Control.LAYOUT_DIRECTION_LTR
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crusade_phase1.add_child(scroll)

	crusade_chests_row = HBoxContainer.new()
	crusade_chests_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_chests_row.add_theme_constant_override("separation", 16)
	crusade_chests_row.alignment = BoxContainer.ALIGNMENT_CENTER
	crusade_chests_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(crusade_chests_row)

	var open_btn := Button.new()
	open_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	open_btn.text = "Open Chests!"
	open_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_btn(open_btn, Color(0.75, 0.55, 0.05))
	open_btn.pressed.connect(_on_open_chests_pressed)
	crusade_phase1.add_child(open_btn)

	# ── PHASE 2: rewards + Marcus card ───────────────────────────────────────
	crusade_phase2 = VBoxContainer.new()
	crusade_phase2.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_phase2.add_theme_constant_override("separation", 10)
	crusade_phase2.visible = false
	vb.add_child(crusade_phase2)

	crusade_rewards_label = Label.new()
	crusade_rewards_label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crusade_rewards_label.add_theme_font_size_override("font_size", 16)
	crusade_rewards_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	crusade_phase2.add_child(crusade_rewards_label)

	# Marcus card reveal (hidden until he drops)
	crusade_marcus_container = VBoxContainer.new()
	crusade_marcus_container.layout_direction = Control.LAYOUT_DIRECTION_LTR
	crusade_marcus_container.add_theme_constant_override("separation", 8)
	crusade_marcus_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crusade_marcus_container.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	crusade_marcus_container.visible = false
	crusade_phase2.add_child(crusade_marcus_container)

	var hero_lbl := Label.new()
	hero_lbl.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hero_lbl.text = "NEW HERO OBTAINED!"
	hero_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_lbl.add_theme_font_size_override("font_size", 15)
	hero_lbl.add_theme_color_override("font_color", Color(0.98, 0.88, 0.20))
	crusade_marcus_container.add_child(hero_lbl)

	var marcus_tex: Texture2D = load("res://Marcus.png")
	if marcus_tex != null:
		# EXPAND_IGNORE_SIZE + SIZE_SHRINK_CENTER = locked to custom_minimum_size, never expands
		var card_img := TextureRect.new()
		card_img.layout_direction  = Control.LAYOUT_DIRECTION_LTR
		card_img.texture           = marcus_tex
		card_img.expand_mode       = TextureRect.EXPAND_IGNORE_SIZE
		card_img.stretch_mode      = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_img.custom_minimum_size   = Vector2(180, 240)
		card_img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_img.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		crusade_marcus_container.add_child(card_img)

	var dismiss_btn := Button.new()
	dismiss_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	dismiss_btn.text = "For Glory!"
	dismiss_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_btn(dismiss_btn, Color(0.75, 0.22, 0.14))
	dismiss_btn.pressed.connect(_on_crusade_dismiss_pressed)
	crusade_phase2.add_child(dismiss_btn)
	crusade_dismiss_btn = dismiss_btn


# ── Hero Deck panel ────────────────────────────────────────────────────────────

func _build_hero_deck_panel(ui: CanvasLayer):
	hero_deck_panel = PanelContainer.new()
	hero_deck_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hero_deck_panel.anchor_left   = 0.0
	hero_deck_panel.anchor_right  = 0.0
	hero_deck_panel.anchor_top    = 0.0
	hero_deck_panel.anchor_bottom = 0.0
	hero_deck_panel.offset_left   = 8
	hero_deck_panel.offset_right  = 370
	hero_deck_panel.offset_top    = 62
	hero_deck_panel.offset_bottom = 560
	hero_deck_panel.visible       = false
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.07, 0.05, 0.10, 0.97)
	pstyle.border_color = Color(0.80, 0.55, 0.10)
	pstyle.set_border_width_all(2)
	pstyle.set_corner_radius_all(8)
	pstyle.content_margin_left   = 12
	pstyle.content_margin_right  = 12
	pstyle.content_margin_top    = 10
	pstyle.content_margin_bottom = 10
	hero_deck_panel.add_theme_stylebox_override("panel", pstyle)
	ui.add_child(hero_deck_panel)

	var vb := VBoxContainer.new()
	vb.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vb.add_theme_constant_override("separation", 10)
	hero_deck_panel.add_child(vb)

	var title_row := HBoxContainer.new()
	title_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vb.add_child(title_row)

	var title := Label.new()
	title.layout_direction = Control.LAYOUT_DIRECTION_LTR
	title.text = "Hero Deck"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.98, 0.88, 0.30))
	title_row.add_child(title)

	var close := Button.new()
	close.layout_direction = Control.LAYOUT_DIRECTION_LTR
	close.text = "X"
	close.custom_minimum_size = Vector2(36, 36)
	close.add_theme_font_size_override("font_size", 16)
	close.pressed.connect(func(): hero_deck_panel.visible = false)
	title_row.add_child(close)

	var marcus_tex: Texture2D = load("res://Marcus.png")
	if marcus_tex != null:
		var card_img := TextureRect.new()
		card_img.layout_direction      = Control.LAYOUT_DIRECTION_LTR
		card_img.texture               = marcus_tex
		card_img.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
		card_img.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_img.custom_minimum_size   = Vector2(200, 268)
		card_img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_img.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		vb.add_child(card_img)

	var marcus_desc := Label.new()
	marcus_desc.layout_direction = Control.LAYOUT_DIRECTION_LTR
	marcus_desc.text = "Military General  |  Common\nBoosts crusade success in battle."
	marcus_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marcus_desc.add_theme_font_size_override("font_size", 12)
	marcus_desc.add_theme_color_override("font_color", Color(0.75, 0.70, 0.65))
	vb.add_child(marcus_desc)


func _on_hero_deck_chip_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		hero_deck_panel.visible = not hero_deck_panel.visible
