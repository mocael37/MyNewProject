extends Control

var selected_god := -1
var selected_leader := -1
var god_cards := []
var leader_cards := []
var begin_button: Button

const GODS = [
	{
		"name": "The Sun God",
		"icon": "☀",
		"desc": "God of light and warmth.\nRuler of the sky and all who bask beneath it."
	},
	{
		"name": "The Forest God",
		"icon": "🌿",
		"desc": "God of nature and growth.\nAncient spirit of the deep woods and wild places."
	},
	{
		"name": "The Sea God",
		"icon": "🌊",
		"desc": "God of storms and the unknown.\nMaster of tides, fate, and distant horizons."
	},
]

const LEADERS = [
	{
		"name": "High Priest",
		"desc": "+25% faith generation\nPreachers convert faster\nOccasional free miracle"
	},
	{
		"name": "Prophet of Wealth",
		"desc": "+25% gold generation\nBuildings cost less\nChance of rich pilgrim events"
	},
	{
		"name": "Holy General",
		"desc": "Stronger soldiers\nRaids more profitable\nCounter-raid immunity window"
	},
]

const COLOR_DEFAULT  = Color(0.18, 0.15, 0.25)
const COLOR_SELECTED = Color(0.75, 0.60, 0.10)
const COLOR_BG       = Color(0.08, 0.06, 0.12)
const COLOR_TITLE    = Color(0.95, 0.85, 0.40)


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_BG
	add_child(bg)

	# Single-screen layout — no scroll, everything fits in 648px
	var margin := MarginContainer.new()
	margin.layout_direction = Control.LAYOUT_DIRECTION_LTR
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_theme_constant_override("margin_left",   35)
	margin.add_theme_constant_override("margin_right",  35)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	# ── Title ──────────────────────────────────────────────
	var title := Label.new()
	title.text = "✨  Oh my GOD!  ✨"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Build your faith. Rule your people."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.62, 0.60, 0.65))
	vbox.add_child(subtitle)

	_add_separator(vbox)

	# ── God Selection ──────────────────────────────────────
	var god_header := Label.new()
	god_header.text = "Choose Your God"
	god_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	god_header.add_theme_font_size_override("font_size", 19)
	god_header.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(god_header)

	var god_row := HBoxContainer.new()
	god_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	god_row.alignment = BoxContainer.ALIGNMENT_CENTER
	god_row.add_theme_constant_override("separation", 18)
	vbox.add_child(god_row)

	for i in range(GODS.size()):
		god_row.add_child(_make_god_card(GODS[i], i))

	_add_separator(vbox)

	# ── Leader Selection ───────────────────────────────────
	var leader_header := Label.new()
	leader_header.text = "Choose Your Religious Leader"
	leader_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leader_header.add_theme_font_size_override("font_size", 19)
	leader_header.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(leader_header)

	var leader_row := HBoxContainer.new()
	leader_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	leader_row.alignment = BoxContainer.ALIGNMENT_CENTER
	leader_row.add_theme_constant_override("separation", 18)
	vbox.add_child(leader_row)

	for i in range(LEADERS.size()):
		leader_row.add_child(_make_leader_card(LEADERS[i], i))

	_add_separator(vbox)

	# ── Begin Button ───────────────────────────────────────
	begin_button = Button.new()
	begin_button.text = "Begin Your Reign"
	begin_button.custom_minimum_size = Vector2(240, 44)
	begin_button.add_theme_font_size_override("font_size", 19)
	begin_button.disabled = true
	begin_button.pressed.connect(_on_begin_pressed)

	var center := CenterContainer.new()
	center.add_child(begin_button)
	vbox.add_child(center)


# ── God card (unchanged layout, slightly larger) ──────────────────────────────
func _make_god_card(data: Dictionary, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 122)

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_DEFAULT
	style.corner_radius_top_left    = 10
	style.corner_radius_top_right   = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.28, 0.50)
	panel.add_theme_stylebox_override("panel", style)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	panel.add_child(inner)

	# Icon
	var icon_lbl := Label.new()
	icon_lbl.text = data["icon"]
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 30)
	inner.add_child(icon_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", COLOR_TITLE)
	inner.add_child(name_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
	inner.add_child(desc_lbl)

	# Spacer
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(sp)

	# Select button
	var btn := Button.new()
	btn.text = "Select"
	btn.pressed.connect(_on_card_selected.bind(index, "god", panel, style, btn))
	inner.add_child(btn)

	god_cards.append({"panel": panel, "style": style, "btn": btn})
	return panel


# ── Leader card (portrait + info layout) ──────────────────────────────────────
func _make_leader_card(data: Dictionary, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 248)

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_DEFAULT
	style.corner_radius_top_left    = 10
	style.corner_radius_top_right   = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.28, 0.50)
	panel.add_theme_stylebox_override("panel", style)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	panel.add_child(inner)

	# Portrait — clipped to 148px so it fits; shadow ellipse at y≈148 is trimmed
	var portrait: Control
	match index:
		0:
			portrait = _HighPriestPortrait.new()
		1:
			portrait = _ProphetPortrait.new()
		2:
			portrait = _HolyGeneralPortrait.new()
		_:
			portrait = Control.new()
			portrait.custom_minimum_size = Vector2(200, 148)
	portrait.clip_contents = true
	inner.add_child(portrait)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", COLOR_TITLE)
	inner.add_child(name_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	inner.add_child(desc_lbl)

	# Spacer
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(sp)

	# Select button
	var btn := Button.new()
	btn.text = "Select"
	btn.pressed.connect(_on_card_selected.bind(index, "leader", panel, style, btn))
	inner.add_child(btn)

	leader_cards.append({"panel": panel, "style": style, "btn": btn})
	return panel


func _on_card_selected(index: int, type: String, panel: PanelContainer, style: StyleBoxFlat, btn: Button):
	var list = god_cards if type == "god" else leader_cards

	# Reset all cards in this group
	for item in list:
		item["style"].bg_color = COLOR_DEFAULT
		item["style"].border_color = Color(0.35, 0.28, 0.50)
		item["btn"].text = "Select"

	# Highlight selected
	style.bg_color = COLOR_SELECTED
	style.border_color = Color(1.0, 0.85, 0.2)
	btn.text = "✓ Chosen"

	if type == "god":
		selected_god = index
	else:
		selected_leader = index

	_update_begin_button()


func _update_begin_button():
	begin_button.disabled = (selected_god == -1 or selected_leader == -1)
	if not begin_button.disabled:
		begin_button.text = "Begin Your Reign  →"


func _on_begin_pressed():
	GameData.selected_god  = selected_god
	GameData.selected_leader = selected_leader
	GameData.god_name      = GODS[selected_god]["name"]
	GameData.leader_name   = LEADERS[selected_leader]["name"]
	get_tree().change_scene_to_file("res://game.tscn")


func _add_separator(parent: VBoxContainer):
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.3, 0.25, 0.45))
	parent.add_child(sep)


# ═══════════════════════════════════════════════════════════════════════════════
# Portrait inner classes
# ═══════════════════════════════════════════════════════════════════════════════

class _HighPriestPortrait extends Control:
	func _init():
		custom_minimum_size = Vector2(200, 148)

	func _draw():
		var cx: float = size.x / 2.0

		# Colors
		var ROBE   := Color(0.88, 0.72, 0.12)
		var ROBE_D := Color(0.62, 0.48, 0.06)
		var SKIN   := Color(0.92, 0.78, 0.62)
		var BEARD  := Color(0.96, 0.94, 0.90)
		var STAFF_C := Color(0.55, 0.38, 0.12)
		var GLOW   := Color(0.98, 0.92, 0.35)
		var MITRE  := Color(0.90, 0.75, 0.14)
		var CROSS  := Color(0.98, 0.88, 0.40)
		var GEM    := Color(0.25, 0.70, 0.88)

		# Background — dark warm
		draw_rect(Rect2(0, 0, 200, 160), Color(0.12, 0.08, 0.04))
		# Subtle golden glow circle behind head
		for i in range(8):
			var r := 38.0 - i * 3.0
			var a := 0.04 - i * 0.004
			draw_circle(Vector2(cx, 32), r, Color(0.98, 0.88, 0.30, a))

		# 1. Ground shadow ellipse
		var shadow_pts := PackedVector2Array()
		for k in range(16):
			var a := k * TAU / 16
			shadow_pts.append(Vector2(cx + cos(a) * 28, 148 + sin(a) * 6))
		draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.35))

		# 2. Staff pole
		draw_rect(Rect2(cx - 22, 28, 5, 118), STAFF_C)
		draw_rect(Rect2(cx - 21, 29, 3, 116), STAFF_C.lightened(0.2))

		# 3. Staff top ornament
		draw_circle(Vector2(cx - 19, 28), 12, Color(0.98, 0.92, 0.35, 0.35))
		draw_circle(Vector2(cx - 19, 28), 8, GLOW)
		draw_rect(Rect2(cx - 20, 16, 3, 20), CROSS)
		draw_rect(Rect2(cx - 25, 22, 13, 3), CROSS)

		# 4. Long robe — outer darker trapezoid
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 28, 145), Vector2(cx + 28, 145),
			Vector2(cx + 18, 62),  Vector2(cx - 18, 62)
		]), ROBE_D)
		# inner lighter
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 26, 143), Vector2(cx + 26, 143),
			Vector2(cx + 16, 64),  Vector2(cx - 16, 64)
		]), ROBE)
		# center seam
		draw_rect(Rect2(cx - 2, 64, 4, 79), ROBE.lightened(0.15))

		# 5. Hem decorative band
		draw_rect(Rect2(cx - 28, 137, 56, 4), ROBE_D)
		draw_rect(Rect2(cx - 28, 135, 56, 2), GLOW.darkened(0.3))

		# 6. Body/chest
		draw_rect(Rect2(cx - 16, 62, 32, 24), ROBE)
		draw_rect(Rect2(cx - 2, 65, 4, 14), CROSS)
		draw_rect(Rect2(cx - 7, 70, 14, 4), CROSS)

		# 7. Belt
		draw_rect(Rect2(cx - 18, 84, 36, 6), ROBE_D)
		draw_circle(Vector2(cx, 87), 4, GEM)

		# 8. Wide sleeves
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 16, 65), Vector2(cx - 16, 82),
			Vector2(cx - 32, 88), Vector2(cx - 30, 70)
		]), ROBE.darkened(0.1))
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx + 16, 65), Vector2(cx + 16, 82),
			Vector2(cx + 32, 88), Vector2(cx + 30, 70)
		]), ROBE.darkened(0.1))

		# 9. Hands
		draw_rect(Rect2(cx - 36, 86, 8, 5), SKIN)
		draw_rect(Rect2(cx + 28, 86, 8, 5), SKIN)

		# 10. Neck
		draw_rect(Rect2(cx - 4, 56, 8, 8), SKIN)

		# 11. Face
		draw_rect(Rect2(cx - 11, 36, 22, 22), SKIN)
		# Eyes
		draw_rect(Rect2(cx - 8, 42, 3, 3), Color(0.15, 0.10, 0.08))
		draw_rect(Rect2(cx + 5, 42, 3, 3), Color(0.15, 0.10, 0.08))
		# Serene mouth
		draw_rect(Rect2(cx - 3, 53, 6, 2), Color(0.70, 0.50, 0.42))

		# 12. White beard
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 10, 50), Vector2(cx + 10, 50),
			Vector2(cx + 7, 62),  Vector2(cx - 7, 62)
		]), BEARD)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 7, 60), Vector2(cx + 7, 60),
			Vector2(cx + 4, 70), Vector2(cx - 4, 70)
		]), BEARD)

		# 13. Mitre hat base band
		draw_rect(Rect2(cx - 14, 34, 28, 6), MITRE.darkened(0.2))
		draw_rect(Rect2(cx - 13, 35, 26, 5), MITRE)

		# 14. Mitre body — two pointed lobes
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 13, 34), Vector2(cx - 1, 34),
			Vector2(cx - 3, 12),  Vector2(cx - 14, 18)
		]), MITRE)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx + 13, 34), Vector2(cx + 1, 34),
			Vector2(cx + 3, 12),  Vector2(cx + 14, 18)
		]), MITRE)

		# 15. Gold cross on mitre front
		draw_rect(Rect2(cx - 2, 13, 4, 20), CROSS)
		draw_rect(Rect2(cx - 6, 19, 12, 3), CROSS)

		# 16. Halo — 12 small circles in a ring
		for i in range(12):
			var a := i * TAU / 12
			var hx := cx + cos(a) * 18
			var hy := 32.0 + sin(a) * 18
			draw_circle(Vector2(hx, hy), 2, Color(0.96, 0.88, 0.30, 0.55))


class _ProphetPortrait extends Control:
	func _init():
		custom_minimum_size = Vector2(200, 148)

	func _draw():
		var cx: float = size.x / 2.0

		# Colors
		var COAT   := Color(0.38, 0.18, 0.62)
		var COAT_L := Color(0.50, 0.28, 0.78)
		var TRIM   := Color(0.88, 0.72, 0.12)
		var SKIN   := Color(0.82, 0.65, 0.48)
		var BEARD  := Color(0.62, 0.42, 0.22)
		var HAT    := Color(0.28, 0.12, 0.48)
		var COIN   := Color(0.95, 0.82, 0.12)
		var JEWEL  := Color(0.22, 0.75, 0.92)
		var SHIRT  := Color(0.88, 0.85, 0.80)

		# Background — dark purple
		draw_rect(Rect2(0, 0, 200, 160), Color(0.08, 0.05, 0.14))
		# Purple sparkle hints
		for i in range(6):
			var sx := 20.0 + i * 30.0
			var sy := 10.0 + (i % 3) * 20.0
			draw_circle(Vector2(sx, sy), 2, Color(0.65, 0.40, 0.95, 0.30))
			draw_circle(Vector2(sx + 15, sy + 30), 1.5, Color(0.80, 0.60, 1.0, 0.25))

		# 1. Ground shadow ellipse
		var shadow_pts := PackedVector2Array()
		for k in range(16):
			var a := k * TAU / 16
			shadow_pts.append(Vector2(cx + cos(a) * 26, 148 + sin(a) * 5))
		draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.28))

		# 2. Fine shoes
		draw_rect(Rect2(cx - 14, 138, 12, 7), Color(0.28, 0.18, 0.08))
		draw_rect(Rect2(cx + 2, 138, 12, 7), Color(0.28, 0.18, 0.08))

		# 3. Elegant pants (below coat)
		draw_rect(Rect2(cx - 12, 115, 10, 28), COAT)
		draw_rect(Rect2(cx + 2, 115, 10, 28), COAT)

		# 4. Long ornate coat (3/4 length)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 22, 143), Vector2(cx + 22, 143),
			Vector2(cx + 18, 52),  Vector2(cx - 18, 52)
		]), COAT)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 20, 141), Vector2(cx + 20, 141),
			Vector2(cx + 16, 54),  Vector2(cx - 16, 54)
		]), COAT_L)

		# 5. Gold trim on coat hem
		draw_rect(Rect2(cx - 22, 137, 44, 3), TRIM)
		draw_line(Vector2(cx - 22, 54), Vector2(cx - 22, 137), TRIM, 1.5)
		draw_line(Vector2(cx + 22, 54), Vector2(cx + 22, 137), TRIM, 1.5)

		# 6. Cream shirt visible at chest
		draw_rect(Rect2(cx - 8, 55, 16, 18), SHIRT)

		# 7. Coat lapels
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 8, 55), Vector2(cx - 16, 54),
			Vector2(cx - 18, 68), Vector2(cx - 8, 72)
		]), COAT_L)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx + 8, 55), Vector2(cx + 16, 54),
			Vector2(cx + 18, 68), Vector2(cx + 8, 72)
		]), COAT_L)

		# 8. Jeweled medallion
		draw_circle(Vector2(cx, 72), 8, TRIM.darkened(0.1))
		draw_circle(Vector2(cx, 72), 5, JEWEL)
		draw_circle(Vector2(cx, 72), 2, Color(1, 1, 1, 0.8))

		# 9. Gold chains
		draw_line(Vector2(cx - 8, 63), Vector2(cx + 8, 63), TRIM, 2)
		draw_line(Vector2(cx - 9, 67), Vector2(cx + 9, 67), TRIM, 1.5)

		# 10. Belt/sash
		draw_rect(Rect2(cx - 18, 88, 36, 5), TRIM.darkened(0.2))

		# 11. Sleeves
		draw_rect(Rect2(cx - 22, 54, 6, 34), COAT)
		draw_rect(Rect2(cx + 16, 54, 6, 34), COAT)
		# Gold cuffs
		draw_rect(Rect2(cx - 23, 82, 8, 4), TRIM)
		draw_rect(Rect2(cx + 15, 82, 8, 4), TRIM)

		# 12. Left hand holding gold coin
		draw_rect(Rect2(cx - 28, 84, 8, 6), SKIN)
		draw_circle(Vector2(cx - 32, 82), 5, COIN)
		draw_circle(Vector2(cx - 32, 82), 3, COIN.lightened(0.25))
		draw_circle(Vector2(cx - 32, 82), 1, Color(1, 1, 1, 0.5))

		# 13. Right hand
		draw_rect(Rect2(cx + 20, 84, 8, 6), SKIN)

		# 14. Neck
		draw_rect(Rect2(cx - 4, 48, 8, 8), SKIN)

		# 15. Face
		draw_rect(Rect2(cx - 11, 28, 22, 22), SKIN)
		# Dignified eyes (slightly narrower)
		draw_rect(Rect2(cx - 8, 34, 4, 2), Color(0.15, 0.10, 0.08))
		draw_rect(Rect2(cx + 4, 34, 4, 2), Color(0.15, 0.10, 0.08))
		# Neat beard
		draw_rect(Rect2(cx - 8, 43, 16, 10), BEARD)
		# Thin mustache
		draw_rect(Rect2(cx - 6, 41, 12, 2), BEARD.darkened(0.1))

		# 16. Large brimmed hat
		# Brim
		draw_rect(Rect2(cx - 20, 26, 40, 6), HAT)
		# Hat crown
		draw_rect(Rect2(cx - 12, 8, 24, 20), HAT)
		# Gold band
		draw_rect(Rect2(cx - 12, 24, 24, 4), TRIM)
		# Feather
		draw_line(Vector2(cx + 10, 12), Vector2(cx + 18, 2), Color(0.88, 0.82, 0.70), 3)
		draw_line(Vector2(cx + 12, 10), Vector2(cx + 16, 4), Color(0.95, 0.90, 0.80), 2)
		# Sparkle dots on hat
		draw_circle(Vector2(cx - 4, 16), 1.5, Color(0.95, 0.82, 0.12, 0.7))
		draw_circle(Vector2(cx + 4, 12), 1.5, Color(0.95, 0.82, 0.12, 0.6))
		draw_circle(Vector2(cx - 2, 20), 1, Color(0.95, 0.82, 0.12, 0.5))


class _HolyGeneralPortrait extends Control:
	func _init():
		custom_minimum_size = Vector2(200, 148)

	func _draw():
		var cx: float = size.x / 2.0

		# Colors
		var ARMOR   := Color(0.58, 0.60, 0.65)
		var ARMOR_D := Color(0.38, 0.40, 0.44)
		var ARMOR_L := Color(0.75, 0.78, 0.82)
		var CAPE    := Color(0.72, 0.12, 0.10)
		var GOLD    := Color(0.88, 0.72, 0.12)
		var SKIN    := Color(0.85, 0.68, 0.52)
		var LEATHER := Color(0.32, 0.22, 0.12)
		var SWORD   := Color(0.82, 0.85, 0.90)

		# Background — dark stone
		draw_rect(Rect2(0, 0, 200, 160), Color(0.08, 0.08, 0.10))
		# Red atmospheric tint at bottom
		draw_rect(Rect2(0, 100, 200, 60), Color(0.20, 0.04, 0.04, 0.30))

		# 1. Ground shadow ellipse
		var shadow_pts := PackedVector2Array()
		for k in range(16):
			var a := k * TAU / 16
			shadow_pts.append(Vector2(cx + cos(a) * 30, 148 + sin(a) * 7))
		draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.30))

		# 2. Red cape BEHIND body
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 8, 52), Vector2(cx + 8, 52),
			Vector2(cx + 28, 138), Vector2(cx - 28, 138)
		]), CAPE.darkened(0.3))
		# Cape highlight
		draw_line(Vector2(cx + 8, 52), Vector2(cx + 28, 138), CAPE.lightened(0.15), 2)

		# 3. Heavy armored boots
		draw_rect(Rect2(cx - 18, 128, 14, 17), ARMOR_D)
		draw_rect(Rect2(cx + 4, 128, 14, 17), ARMOR_D)
		draw_rect(Rect2(cx - 17, 128, 5, 4), ARMOR_L)
		draw_rect(Rect2(cx + 5, 128, 5, 4), ARMOR_L)

		# 4. Leg plate armor (greaves)
		draw_rect(Rect2(cx - 17, 100, 12, 30), ARMOR)
		draw_rect(Rect2(cx + 5, 100, 12, 30), ARMOR)
		draw_circle(Vector2(cx - 11, 108), 5, ARMOR_L)
		draw_circle(Vector2(cx + 11, 108), 5, ARMOR_L)

		# 5. Lower body/waist plate
		draw_rect(Rect2(cx - 18, 90, 36, 12), ARMOR.darkened(0.1))
		# Tassets (skirt plates hanging down)
		draw_rect(Rect2(cx - 16, 100, 8, 12), ARMOR_D)
		draw_rect(Rect2(cx + 8, 100, 8, 12), ARMOR_D)

		# 6. Broad chest plate
		draw_rect(Rect2(cx - 22, 52, 44, 40), ARMOR_D)
		draw_rect(Rect2(cx - 20, 54, 40, 38), ARMOR)
		# Chest emblem
		draw_rect(Rect2(cx - 3, 58, 6, 16), GOLD)
		draw_rect(Rect2(cx - 8, 64, 16, 4), GOLD)

		# 7. Pauldrons (shoulder armor)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 22, 52), Vector2(cx - 36, 50),
			Vector2(cx - 34, 64), Vector2(cx - 22, 66)
		]), ARMOR)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx + 22, 52), Vector2(cx + 36, 50),
			Vector2(cx + 34, 64), Vector2(cx + 22, 66)
		]), ARMOR)
		# Gold edges on pauldrons
		draw_line(Vector2(cx - 36, 50), Vector2(cx - 34, 64), GOLD, 2)
		draw_line(Vector2(cx + 36, 50), Vector2(cx + 34, 64), GOLD, 2)

		# 8. Left arm with shield
		draw_rect(Rect2(cx - 34, 64, 8, 30), ARMOR)
		# Shield
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 42, 60), Vector2(cx - 32, 60),
			Vector2(cx - 32, 96), Vector2(cx - 36, 104), Vector2(cx - 42, 96)
		]), ARMOR_D)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 40, 62), Vector2(cx - 34, 62),
			Vector2(cx - 34, 94), Vector2(cx - 37, 100), Vector2(cx - 40, 94)
		]), CAPE)
		draw_circle(Vector2(cx - 37, 78), 5, GOLD)

		# 9. Right arm with sword
		draw_rect(Rect2(cx + 26, 64, 8, 30), ARMOR)
		draw_rect(Rect2(cx + 24, 90, 10, 8), ARMOR_D)
		# Sword handle
		draw_rect(Rect2(cx + 29, 80, 4, 14), LEATHER)
		# Crossguard
		draw_rect(Rect2(cx + 24, 80, 14, 3), ARMOR_D)
		# Blade
		draw_rect(Rect2(cx + 30, 36, 3, 46), SWORD)
		# Blade highlight
		draw_rect(Rect2(cx + 30, 36, 1, 46), ARMOR_L)

		# 10. Neck gorget
		draw_rect(Rect2(cx - 6, 46, 12, 8), ARMOR)

		# 11. Helmet (imposing, mostly closed)
		draw_rect(Rect2(cx - 14, 22, 28, 26), ARMOR_D)
		draw_rect(Rect2(cx - 12, 24, 24, 24), ARMOR)
		draw_rect(Rect2(cx - 10, 32, 20, 14), ARMOR_D)
		# Narrow visor slit
		draw_rect(Rect2(cx - 8, 36, 16, 3), Color(0.05, 0.05, 0.05))
		# Tiny eye glints through visor
		draw_rect(Rect2(cx - 6, 37, 3, 1), Color(0.55, 0.42, 0.12, 0.80))
		draw_rect(Rect2(cx + 3, 37, 3, 1), Color(0.55, 0.42, 0.12, 0.80))

		# 12. Red plume on top of helmet
		draw_line(Vector2(cx, 22), Vector2(cx - 4, 6), CAPE, 4)
		draw_line(Vector2(cx - 4, 6), Vector2(cx - 8, 2), CAPE, 3)
		draw_line(Vector2(cx + 1, 20), Vector2(cx - 3, 8), CAPE.lightened(0.2), 2)
		draw_line(Vector2(cx - 1, 18), Vector2(cx - 5, 4), CAPE.darkened(0.1), 2)

		# 13. Gold trim on helmet visor
		draw_rect(Rect2(cx - 11, 32, 22, 2), GOLD)
		draw_rect(Rect2(cx - 11, 44, 22, 2), GOLD)

		# 14. Red cape flowing over shoulders (front layer)
		draw_line(Vector2(cx - 22, 52), Vector2(cx - 26, 70), CAPE, 3)
		draw_line(Vector2(cx + 22, 52), Vector2(cx + 26, 70), CAPE, 3)
