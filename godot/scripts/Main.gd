extends Control

const DATA_PATH := "res://data/game_data.json"
const SAVE_PATH := "user://campaign_save.json"
const UNIT_VIEW := preload("res://scenes/UnitView.tscn")
const PROP_VIEW := preload("res://scenes/PropView.tscn")
const EFFECT_BURST := preload("res://scenes/EffectBurst.tscn")
const TILE_W := 60.0
const TILE_H := 32.0
const BOARD_W := 15
const BOARD_H := 11
const ISO_ORIGIN := Vector2(420, 70)
const COLORS := {
	"bg": Color("#070909"),
	"bg_2": Color("#101412"),
	"panel": Color("#121716"),
	"panel_2": Color("#1a2120"),
	"panel_deep": Color("#090d0c"),
	"line": Color("#3d4743"),
	"line_hot": Color("#7c241f"),
	"text": Color("#e7eadf"),
	"muted": Color("#9aa39a"),
	"hero": Color("#74c7ec"),
	"enemy": Color("#d94b3f"),
	"accent": Color("#d4d7a0"),
	"warning": Color("#b52a23"),
	"bio": Color("#78b96d"),
	"tile": Color("#222d2a"),
	"tile_alt": Color("#263230"),
	"cover": Color("#48533c")
}

var data := {}
var campaign := {}
var selected_faction := "bsaa"
var selected_mission := 0
var units := []
var turn_side := "hero"
var selected_unit := -1
var current_mode := "move"
var selected_weapon := "pistol"
var round_number := 1
var acted_units := {}
var cover_tiles := ["4,1", "7,1", "2,3", "5,4", "8,4", "9,6", "3,7"]
var obstacle_tiles := {}
var door_tiles := {}
var wall_tiles := {}
var active_map := {}
var battle_over := false
var battle_result := ""
var reward_claimed := false
var mission_turn_limit := 10
var objective_activated := false
var objective_tiles := {}

@onready var title_screen: Control = %TitleScreen
@onready var start_screen: Control = %StartScreen
@onready var battle_screen: Control = %BattleScreen
@onready var battle_area: Panel = get_node("BattleScreen/BattleArea")
@onready var side_panel: VBoxContainer = get_node("BattleScreen/Side")
@onready var faction_list: VBoxContainer = %FactionList
@onready var mission_list: VBoxContainer = %MissionList
@onready var campaign_stats: Label = %CampaignStats
@onready var mission_title: Label = %MissionTitle
@onready var battle_preview: Panel = get_node("StartScreen/BattlePreview")
@onready var battle_grid: Node2D = %BattleGrid
@onready var unit_panel: VBoxContainer = %UnitPanel
@onready var log_label: RichTextLabel = %LogLabel
@onready var music: AudioStreamPlayer = %Music
@onready var sfx: AudioStreamPlayer = %Sfx

func _ready() -> void:
	apply_visual_theme()
	data = load_json(DATA_PATH)
	campaign = load_json(SAVE_PATH)
	if campaign.is_empty():
		campaign = {}
	music.stream = load("res://assets/audio/music-ambient.wav")
	music.volume_db = -18
	music.play()
	render_factions()
	render_missions()
	show_title()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, COLORS.bg)
	for y in range(0, int(size.y), 4):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.018), 1.0)
	draw_rect(Rect2(0, 0, 10, size.y), Color(COLORS.warning, 0.34))
	draw_rect(Rect2(size.x - 10, 0, 10, size.y), Color(COLORS.warning, 0.18))
	draw_line(Vector2(24, 22), Vector2(size.x - 24, 22), Color(COLORS.line_hot, 0.42), 2.0)
	draw_line(Vector2(24, size.y - 22), Vector2(size.x - 24, size.y - 22), Color(COLORS.line, 0.35), 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_M:
				current_mode = "move"
				render_battle()
			KEY_A:
				current_mode = "attack"
				selected_weapon = "pistol"
				render_battle()
			KEY_G:
				current_mode = "grenade"
				selected_weapon = "grenade"
				render_battle()
			KEY_H:
				current_mode = "heal"
				selected_weapon = "medkit"
				render_battle()
			KEY_O:
				enable_overwatch()
			KEY_SPACE:
				if battle_screen.visible:
					start_enemy_turn()
			KEY_ESCAPE:
				if battle_screen.visible:
					show_menu()

func apply_visual_theme() -> void:
	add_theme_color_override("font_color", COLORS.text)
	var root_style := make_panel_style(COLORS.bg, COLORS.line, 0)
	add_theme_stylebox_override("panel", root_style)
	title_screen.add_theme_constant_override("separation", 16)
	title_screen.alignment = BoxContainer.ALIGNMENT_CENTER
	start_screen.add_theme_constant_override("separation", 14)
	battle_screen.add_theme_constant_override("separation", 12)
	battle_area.add_theme_stylebox_override("panel", make_panel_style(Color(0.03, 0.045, 0.043, 0.98), Color(COLORS.line_hot, 0.55), 0))
	battle_preview.add_theme_stylebox_override("panel", make_panel_style(Color(0.025, 0.035, 0.034, 0.98), Color(COLORS.line_hot, 0.5), 0))
	side_panel.custom_minimum_size = Vector2(360, 0)
	unit_panel.add_theme_constant_override("separation", 6)
	log_label.add_theme_stylebox_override("normal", make_panel_style(Color(0.025, 0.03, 0.03, 0.94), Color(COLORS.line, 0.8), 2))
	log_label.add_theme_color_override("default_color", COLORS.muted)
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	get_node("TitleScreen/Title").add_theme_font_size_override("font_size", 52)
	get_node("TitleScreen/Title").add_theme_color_override("font_color", COLORS.warning)
	get_node("TitleScreen/Subtitle").add_theme_color_override("font_color", COLORS.muted)
	get_node("TitleScreen/Subtitle").add_theme_font_size_override("font_size", 18)
	get_node("TitleScreen/Continue").text = "ENTRAR AL INCIDENTE"
	get_node("StartScreen/Left/Start").text = "EMPEZAR MISION"
	style_tree(self)
	queue_redraw()

func style_tree(node: Node) -> void:
	if node is Label:
		node.add_theme_color_override("font_color", COLORS.text)
		node.add_theme_font_size_override("font_size", 15)
	if node is Button:
		style_button(node)
	if node is Panel:
		node.add_theme_stylebox_override("panel", make_panel_style(COLORS.panel, Color(COLORS.line, 0.65), 0))
	for child in node.get_children():
		style_tree(child)

func style_button(button: Button, primary := false) -> void:
	var normal := COLORS.warning if primary else COLORS.panel_2
	var border := COLORS.accent if primary else COLORS.line
	button.add_theme_stylebox_override("normal", make_panel_style(normal, border, 1))
	button.add_theme_stylebox_override("hover", make_panel_style(normal.lightened(0.12), COLORS.accent, 1))
	button.add_theme_stylebox_override("pressed", make_panel_style(normal.darkened(0.16), COLORS.line_hot, 1))
	button.add_theme_stylebox_override("disabled", make_panel_style(Color("#151817"), Color("#252b29"), 1))
	button.add_theme_color_override("font_color", COLORS.text)
	button.add_theme_color_override("font_disabled_color", Color(COLORS.muted, 0.52))
	button.add_theme_font_size_override("font_size", 14)
	button.custom_minimum_size = Vector2(0, 36)

func make_panel_style(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file else {}
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func save_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))

func show_title() -> void:
	title_screen.visible = true
	start_screen.visible = false
	battle_screen.visible = false

func show_menu() -> void:
	title_screen.visible = false
	start_screen.visible = true
	battle_screen.visible = false
	render_missions()
	render_menu_preview()

func start_battle() -> void:
	title_screen.visible = false
	start_screen.visible = false
	battle_screen.visible = true
	round_number = 1
	turn_side = "hero"
	selected_unit = 0
	current_mode = "move"
	selected_weapon = "pistol"
	acted_units = {}
	battle_over = false
	battle_result = ""
	reward_claimed = false
	objective_activated = false
	active_map = data.missions[selected_mission].get("map", {})
	mission_turn_limit = int(data.missions[selected_mission].get("turnLimit", 10))
	cover_tiles = active_map.get("cover", [])
	obstacle_tiles = array_to_lookup(active_map.get("obstacles", []))
	door_tiles = array_to_lookup(active_map.get("doors", []))
	wall_tiles = array_to_lookup(active_map.get("walls", []))
	objective_tiles = array_to_lookup(active_map.get("objectives", []))
	units = build_units()
	log_label.clear()
	render_battle()
	add_log("Mision iniciada: %s" % data.missions[selected_mission].name)
	add_log("Selecciona una unidad, mueve o ataca.")
	play_sfx("res://assets/audio/turn.wav")

func build_units() -> Array:
	var heroes = active_map.get("heroes", [
		{"id": "h1", "name": "Chris", "x": 1, "y": 1, "hp": 12, "move": 4, "damage": 3, "range": 4, "art": "chris.png", "role": "assault"},
		{"id": "h2", "name": "Jill", "x": 1, "y": 3, "hp": 10, "move": 5, "damage": 3, "range": 4, "art": "jill.png", "role": "scout"},
		{"id": "h3", "name": "Leon", "x": 1, "y": 5, "hp": 10, "move": 4, "damage": 4, "range": 5, "art": "leon.png", "role": "marksman"}
	])
	var enemies = active_map.get("enemies", [
		{"id": "e1", "name": "Zombie", "x": 10, "y": 1, "hp": 7, "move": 3, "damage": 2, "range": 1, "art": "zombie.png", "role": "slow"},
		{"id": "e2", "name": "Cerberus", "x": 9, "y": 3, "hp": 6, "move": 5, "damage": 2, "range": 1, "art": "cerberus.png", "role": "runner"},
		{"id": "e3", "name": "Licker", "x": 10, "y": 5, "hp": 12, "move": 4, "damage": 3, "range": 1, "art": "licker.png", "role": "ambusher"},
		{"id": "e4", "name": "Tyrant", "x": 11, "y": 7, "hp": 18, "move": 2, "damage": 4, "range": 1, "art": "tyrant.png", "role": "boss"}
	])
	var built := []
	for hero in heroes:
		built.append(make_unit(hero, "hero"))
	for enemy in enemies:
		built.append(make_unit(enemy, "enemy"))
	return built

func make_unit(raw: Dictionary, side: String) -> Dictionary:
	var hp := int(raw.get("hp", 10))
	return {
		"id": raw.get("id", "%s-%s-%s" % [side, raw.get("x", 0), raw.get("y", 0)]),
		"name": raw.get("name", "Unidad"),
		"side": side,
		"x": int(raw.get("x", 0)),
		"y": int(raw.get("y", 0)),
		"hp": hp,
		"max_hp": hp,
		"move": int(raw.get("move", 4)),
		"damage": int(raw.get("damage", 3)),
		"range": int(raw.get("range", 4)),
		"art": raw.get("art", "chris.png"),
		"role": raw.get("role", "unit"),
		"ap": 2,
		"max_ap": 2,
		"ammo": make_loadout(raw, side),
		"status": []
	}

func make_loadout(raw: Dictionary, side: String) -> Dictionary:
	if side != "hero":
		return {}
	var defaults := {
		"pistol": int(data.weapons.pistol.get("ammo", 12)),
		"shotgun": int(data.weapons.shotgun.get("ammo", 6)),
		"rifle": int(data.weapons.rifle.get("ammo", 8)),
		"grenade": int(data.weapons.grenade.get("ammo", 1)),
		"medkit": int(data.weapons.medkit.get("ammo", 1))
	}
	var loadout = raw.get("loadout", {})
	if typeof(loadout) == TYPE_DICTIONARY:
		for key in loadout.keys():
			defaults[key] = int(loadout[key])
	defaults.pistol = int(raw.get("pistolAmmo", defaults.pistol))
	defaults.shotgun = int(raw.get("shotgunAmmo", defaults.shotgun))
	defaults.rifle = int(raw.get("rifleAmmo", defaults.rifle))
	defaults.grenade = int(raw.get("grenades", defaults.grenade))
	defaults.medkit = int(raw.get("medkits", defaults.medkit))
	return defaults

func array_to_lookup(items: Array) -> Dictionary:
	var lookup := {}
	for item in items:
		lookup[item] = true
	return lookup

func render_factions() -> void:
	for child in faction_list.get_children():
		child.queue_free()
	for faction_id in data.factions.keys():
		var button := Button.new()
		button.text = "[ %s ]" % str(data.factions[faction_id].name).to_upper()
		style_button(button, faction_id == selected_faction)
		button.pressed.connect(func():
			selected_faction = faction_id
			render_missions()
			play_sfx("res://assets/audio/ui.wav")
		)
		faction_list.add_child(button)

func render_missions() -> void:
	for child in mission_list.get_children():
		child.queue_free()
	var progress := get_progress(selected_faction)
	campaign_stats.text = "ARCHIVO DE CAMPANA\n%s  //  VICTORIAS %s  //  CREDITOS $%s  //  INVESTIGACION %s" % [
		str(data.factions[selected_faction].name).to_upper(),
		progress.wins,
		progress.credits,
		progress.research
	]
	for i in range(data.missions.size()):
		var mission = data.missions[i]
		var button := Button.new()
		button.text = "%02d  %s" % [i + 1, str(mission.name).to_upper()]
		button.disabled = i > progress.unlockedMission
		style_button(button, i == selected_mission)
		button.pressed.connect(func(index := i):
			selected_mission = index
			mission_title.text = data.missions[selected_mission].briefing
			render_missions()
			render_menu_preview()
			play_sfx("res://assets/audio/ui.wav")
		)
		mission_list.add_child(button)
	mission_title.text = "%s\n%s" % [str(data.missions[selected_mission].name).to_upper(), data.missions[selected_mission].briefing]

func render_menu_preview() -> void:
	for child in battle_preview.get_children():
		child.queue_free()
	var mission = data.missions[selected_mission]
	var map = mission.get("map", {})
	var header := Label.new()
	header.position = Vector2(28, 24)
	header.size = Vector2(520, 34)
	header.text = "EXPEDIENTE: %s" % str(mission.name).to_upper()
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", COLORS.warning)
	battle_preview.add_child(header)
	var briefing := Label.new()
	briefing.position = Vector2(28, 66)
	briefing.size = Vector2(560, 90)
	briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing.text = "%s\nOBJETIVO: %s\nZONA: %s" % [mission.briefing, objective_text(mission.get("objective", "eliminate")), str(map.get("theme", "unknown")).to_upper()]
	briefing.add_theme_color_override("font_color", COLORS.text)
	battle_preview.add_child(briefing)
	var grid_origin := Vector2(270, 205)
	var preview_w := int(map.get("width", BOARD_W))
	var preview_h := int(map.get("height", BOARD_H))
	var preview_walls: Array = map.get("walls", [])
	var preview_cover: Array = map.get("cover", [])
	var preview_doors: Array = map.get("doors", [])
	var preview_objectives: Array = map.get("objectives", [])
	for y in range(preview_h):
		for x in range(preview_w):
			var key := "%s,%s" % [x, y]
			var tile := Polygon2D.new()
			var p := grid_origin + Vector2((x - y) * 18.0, (x + y) * 9.0)
			tile.position = p
			tile.polygon = PackedVector2Array([Vector2(0, -8), Vector2(16, 0), Vector2(0, 8), Vector2(-16, 0)])
			tile.color = Color("#222c29") if (x + y) % 2 == 0 else Color("#1a2220")
			if preview_cover.has(key):
				tile.color = Color("#4a503b")
			if preview_walls.has(key):
				tile.color = Color("#4b2623")
			if preview_doors.has(key):
				tile.color = Color("#876f42")
			if preview_objectives.has(key):
				tile.color = Color("#77b7bd")
			tile.z_index = y * preview_w + x
			battle_preview.add_child(tile)
	var red_line := ColorRect.new()
	red_line.position = Vector2(28, 160)
	red_line.size = Vector2(560, 2)
	red_line.color = Color(COLORS.line_hot, 0.9)
	battle_preview.add_child(red_line)
	var stamp := Label.new()
	stamp.position = Vector2(28, 428)
	stamp.size = Vector2(560, 60)
	stamp.text = "BIOHAZARD RESPONSE // NO COMERCIAL FAN BUILD"
	stamp.add_theme_font_size_override("font_size", 16)
	stamp.add_theme_color_override("font_color", Color(COLORS.accent, 0.8))
	battle_preview.add_child(stamp)

func get_progress(faction_id: String) -> Dictionary:
	if not campaign.has(faction_id):
		campaign[faction_id] = {"wins": 0, "credits": 0, "research": 0, "unlockedMission": 0}
	return campaign[faction_id]

func render_battle() -> void:
	for child in battle_grid.get_children():
		child.queue_free()
	draw_scene_backdrop()
	for y in range(BOARD_H):
		for x in range(BOARD_W):
			draw_tile(x, y)
	draw_board_hit_layer()
	for index in range(units.size()):
		var unit = units[index]
		draw_unit(unit, index)
	render_unit_panel()

func iso_pos(x: int, y: int) -> Vector2:
	return Vector2((x - y) * (TILE_W / 2.0), (x + y) * (TILE_H / 2.0)) + ISO_ORIGIN

func draw_scene_backdrop() -> void:
	var backdrop := Polygon2D.new()
	backdrop.polygon = PackedVector2Array([
		Vector2(92, 34), Vector2(762, 10), Vector2(910, 312), Vector2(690, 548), Vector2(116, 506), Vector2(0, 220)
	])
	backdrop.color = Color(0.055, 0.075, 0.075, 0.96)
	backdrop.z_index = -30
	battle_grid.add_child(backdrop)
	for i in range(9):
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(88 + i * 78, 58), Vector2(18 + i * 78, 500)])
		line.width = 1.0
		line.default_color = Color(1, 1, 1, 0.035)
		line.z_index = -29
		battle_grid.add_child(line)
	for i in range(7):
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(28, 88 + i * 70), Vector2(872, 42 + i * 70)])
		line.width = 1.0
		line.default_color = Color(1, 1, 1, 0.03)
		line.z_index = -29
		battle_grid.add_child(line)

func draw_tile(x: int, y: int) -> void:
	var holder := Node2D.new()
	holder.position = iso_pos(x, y)
	holder.z_index = y * 10 + x
	battle_grid.add_child(holder)
	var shadow := Polygon2D.new()
	shadow.position = Vector2(0, 9)
	shadow.polygon = diamond_points(TILE_W, TILE_H)
	shadow.color = Color(0, 0, 0, 0.28)
	holder.add_child(shadow)
	var tile_sprite := Sprite2D.new()
	tile_sprite.texture = load(tile_art_path(x, y))
	tile_sprite.scale = Vector2(0.5, 0.5)
	holder.add_child(tile_sprite)
	draw_theme_floor_details(holder, x, y)
	var highlight := Line2D.new()
	highlight.points = PackedVector2Array([Vector2(0, -TILE_H / 2.0), Vector2(TILE_W / 2.0, 0), Vector2(0, TILE_H / 2.0), Vector2(-TILE_W / 2.0, 0), Vector2(0, -TILE_H / 2.0)])
	highlight.width = 1.4
	highlight.default_color = Color(1, 1, 1, 0.12)
	holder.add_child(highlight)
	if wall_tiles.has("%s,%s" % [x, y]):
		draw_wall_prop(holder, x, y)
		return
	if cover_tiles.has("%s,%s" % [x, y]):
		draw_cover_prop(holder)
	if obstacle_tiles.has("%s,%s" % [x, y]):
		draw_obstacle_prop(holder)
	if door_tiles.has("%s,%s" % [x, y]):
		draw_door_prop(holder)
	if objective_tiles.has("%s,%s" % [x, y]):
		draw_objective_marker(holder)

func draw_board_hit_layer() -> void:
	var hit_layer := Control.new()
	hit_layer.position = Vector2(0, 0)
	hit_layer.size = Vector2(900, 600)
	hit_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	hit_layer.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var tile := screen_to_tile(event.position)
			if tile.x >= 0:
				handle_tile(int(tile.x), int(tile.y))
	)
	hit_layer.z_index = 50
	battle_grid.add_child(hit_layer)

func screen_to_tile(pos: Vector2) -> Vector2:
	var best := Vector2(-1, -1)
	var best_dist := 999999.0
	for y in range(BOARD_H):
		for x in range(BOARD_W):
			var d := pos.distance_squared_to(iso_pos(x, y))
			if d < best_dist:
				best_dist = d
				best = Vector2(x, y)
	if best_dist <= 1250.0:
		return best
	return Vector2(-1, -1)

func tile_art_path(x: int, y: int) -> String:
	var key := "%s,%s" % [x, y]
	if cover_tiles.has(key):
		return "res://assets/painted/tiles/cover_tile.png"
	if selected_unit >= 0 and selected_unit < units.size() and units[selected_unit].side == "hero":
		var unit = units[selected_unit]
		var d := distance_xy(unit.x, unit.y, x, y)
		if current_mode == "move" and d <= unit.move:
			return "res://assets/painted/tiles/move_tile.png"
		if current_mode == "attack" and d <= selected_attack_range(unit):
			return "res://assets/painted/tiles/attack_tile.png"
		if current_mode == "activate" and d <= 1:
			return "res://assets/painted/tiles/move_tile.png"
	var theme := str(active_map.get("theme", "lab"))
	if theme == "street":
		if x < 3 or x > 11:
			return "res://assets/painted/tiles/floor_mansion.png"
		return "res://assets/painted/tiles/floor_street.png"
	if theme == "village":
		return "res://assets/painted/tiles/floor_mansion.png"
	return "res://assets/painted/tiles/floor_lab.png" if (x + y) % 2 == 0 else "res://assets/painted/tiles/floor_lab_alt.png"

func draw_theme_floor_details(holder: Node2D, x: int, y: int) -> void:
	var theme := str(active_map.get("theme", "lab"))
	if theme == "street":
		if y == 5 or y == 6:
			draw_floor_line(holder, Color("#d0bf67"), 2.0, Vector2(-18, -7), Vector2(18, 7))
		if (x + y) % 7 == 0:
			draw_floor_stain(holder, Color("#6e1612"), Vector2(4, -2))
		if x < 3 or x > 11:
			draw_floor_line(holder, Color("#4a3a2c"), 1.5, Vector2(-24, 0), Vector2(24, 0))
	elif theme == "village":
		if x <= 5 and y <= 5:
			draw_floor_line(holder, Color("#6b472c"), 1.5, Vector2(-28, -3), Vector2(24, 10))
			draw_floor_line(holder, Color("#2a1b12"), 1.0, Vector2(-18, 8), Vector2(28, -6))
		else:
			draw_floor_stain(holder, Color("#26351f"), Vector2(-4, 1))
	else:
		if (x == 7 or x == 8) and y > 1 and y < 9:
			for offset in [-18, -6, 6, 18]:
				draw_floor_line(holder, Color("#6e7c7a"), 1.0, Vector2(offset, -8), Vector2(offset + 12, 8))
		if y == 2 or y == 8:
			draw_floor_line(holder, Color("#c1a83f"), 2.0, Vector2(-20, 8), Vector2(4, -6))
			draw_floor_line(holder, Color("#c1a83f"), 2.0, Vector2(4, 8), Vector2(28, -6))

func draw_floor_line(holder: Node2D, color: Color, width: float, from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.width = width
	line.default_color = Color(color, 0.82)
	line.z_index = 2
	holder.add_child(line)

func draw_floor_stain(holder: Node2D, color: Color, offset: Vector2) -> void:
	var stain := Polygon2D.new()
	stain.position = offset
	stain.polygon = PackedVector2Array([Vector2(-10, -2), Vector2(-2, -6), Vector2(12, -3), Vector2(10, 4), Vector2(-5, 6)])
	stain.color = Color(color, 0.72)
	stain.z_index = 2
	holder.add_child(stain)

func diamond_points(width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -height / 2.0), Vector2(width / 2.0, 0), Vector2(0, height / 2.0), Vector2(-width / 2.0, 0)])

func draw_cover_prop(holder: Node2D) -> void:
	var prop = PROP_VIEW.instantiate()
	prop.position = Vector2(0, -20)
	prop.scale = Vector2(0.62, 0.62)
	prop.z_index = 5
	holder.add_child(prop)
	prop.setup("res://assets/painted/props/cover_crate.png")

func draw_wall_prop(holder: Node2D, x: int, y: int) -> void:
	var theme := str(active_map.get("theme", "lab"))
	var wall := Polygon2D.new()
	wall.position = Vector2(0, -22)
	wall.polygon = PackedVector2Array([
		Vector2(-35, 0), Vector2(0, -18), Vector2(35, 0), Vector2(35, -42), Vector2(0, -60), Vector2(-35, -42)
	])
	wall.color = wall_color_for_theme(theme, x, y)
	wall.z_index = 8
	holder.add_child(wall)
	var top := Polygon2D.new()
	top.position = Vector2(0, -82)
	top.polygon = PackedVector2Array([Vector2(-35, 40), Vector2(0, 22), Vector2(35, 40), Vector2(0, 58)])
	top.color = wall.color.lightened(0.18)
	top.z_index = 9
	holder.add_child(top)
	var edge := Line2D.new()
	edge.points = PackedVector2Array([Vector2(-35, -22), Vector2(0, -40), Vector2(35, -22)])
	edge.width = 2.0
	edge.default_color = Color(COLORS.line_hot, 0.7)
	edge.z_index = 10
	holder.add_child(edge)

func wall_color_for_theme(theme: String, x: int, y: int) -> Color:
	if theme == "street":
		return Color("#2f3331") if (x + y) % 2 == 0 else Color("#242928")
	if theme == "village":
		return Color("#453224") if (x + y) % 2 == 0 else Color("#2e251e")
	return Color("#374044") if (x + y) % 2 == 0 else Color("#273034")

func draw_obstacle_prop(holder: Node2D) -> void:
	var prop = PROP_VIEW.instantiate()
	prop.position = Vector2(0, -26)
	prop.scale = Vector2(0.55, 0.55)
	prop.z_index = 6
	holder.add_child(prop)
	prop.setup("res://assets/painted/props/lab_tank.png")

func draw_door_prop(holder: Node2D) -> void:
	var prop = PROP_VIEW.instantiate()
	prop.position = Vector2(0, -34)
	prop.scale = Vector2(0.5, 0.5)
	prop.z_index = 7
	holder.add_child(prop)
	prop.setup("res://assets/painted/props/metal_door.png")

func draw_objective_marker(holder: Node2D) -> void:
	var marker := Polygon2D.new()
	marker.position = Vector2(0, -18)
	marker.polygon = PackedVector2Array([Vector2(0, -18), Vector2(18, -4), Vector2(10, 18), Vector2(-10, 18), Vector2(-18, -4)])
	marker.color = Color("#86e6ff") if not objective_activated else Color("#bfd66f")
	marker.z_index = 12
	holder.add_child(marker)
	var core := ColorRect.new()
	core.position = Vector2(-5, -24)
	core.size = Vector2(10, 16)
	core.color = Color("#f3fbff")
	core.z_index = 13
	holder.add_child(core)

func draw_unit(unit: Dictionary, index: int) -> void:
	var holder := Node2D.new()
	holder.position = iso_pos(unit.x, unit.y) + Vector2(0, -24)
	holder.z_index = 500 + unit.y * 10 + unit.x
	battle_grid.add_child(holder)
	var accent: Color = COLORS.hero if unit.side == "hero" else COLORS.enemy
	var unit_view = UNIT_VIEW.instantiate()
	holder.add_child(unit_view)
	unit_view.setup(unit)
	unit_view.set_selected(index == selected_unit)
	unit_view.get_node("HpBar").color = accent
	draw_status_badges(holder, unit)
	var name_label := Label.new()
	name_label.text = unit.name
	name_label.position = Vector2(-40, 49)
	name_label.size = Vector2(80, 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", COLORS.text)
	holder.add_child(name_label)
	if index == selected_unit:
		var selection := Line2D.new()
		selection.points = PackedVector2Array([Vector2(0, -54), Vector2(34, -28), Vector2(24, 18), Vector2(-24, 18), Vector2(-34, -28), Vector2(0, -54)])
		selection.width = 3
		selection.default_color = COLORS.accent
		selection.z_index = -1
		holder.add_child(selection)

func draw_status_badges(holder: Node2D, unit: Dictionary) -> void:
	var badges := []
	if unit.status.has("overwatch"):
		badges.append(["OW", COLORS.accent])
	if unit.status.has("bleeding"):
		badges.append(["BL", COLORS.warning])
	if unit.status.has("poisoned"):
		badges.append(["PX", COLORS.bio])
	if unit.ap <= 0 and unit.side == "hero":
		badges.append(["AP", COLORS.muted])
	for i in range(badges.size()):
		var badge = badges[i]
		var box := ColorRect.new()
		box.position = Vector2(-38 + i * 27, -82)
		box.size = Vector2(24, 14)
		box.color = Color(badge[1], 0.86)
		box.z_index = 20
		holder.add_child(box)
		var text := Label.new()
		text.text = badge[0]
		text.position = box.position + Vector2(1, -2)
		text.size = box.size
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.add_theme_font_size_override("font_size", 9)
		text.add_theme_color_override("font_color", COLORS.bg)
		text.z_index = 21
		holder.add_child(text)

func unit_body_points(unit: Dictionary) -> PackedVector2Array:
	if unit.sprite == "cerberus.svg" or unit.sprite == "licker.svg":
		return PackedVector2Array([Vector2(-28, 4), Vector2(-8, -20), Vector2(28, -12), Vector2(32, 10), Vector2(12, 24), Vector2(-24, 20)])
	if unit.sprite == "tyrant.svg":
		return PackedVector2Array([Vector2(-24, -18), Vector2(0, -36), Vector2(28, -18), Vector2(24, 24), Vector2(0, 40), Vector2(-24, 24)])
	return PackedVector2Array([Vector2(-18, -18), Vector2(0, -30), Vector2(18, -18), Vector2(22, 18), Vector2(0, 34), Vector2(-22, 18)])

func render_unit_panel() -> void:
	for child in unit_panel.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "COMBATE TERMINADO" if battle_over else "RONDA %s/%s  //  TURNO %s  //  %s" % [round_number, mission_turn_limit, str(turn_side).to_upper(), str(current_mode).to_upper()]
	title.add_theme_color_override("font_color", COLORS.accent)
	title.add_theme_font_size_override("font_size", 16)
	unit_panel.add_child(title)
	if battle_over:
		render_result_panel()
		return
	render_objective_panel()
	render_selected_unit_panel()
	var move_button := Button.new()
	move_button.text = "MOVER"
	move_button.disabled = battle_over
	style_button(move_button, current_mode == "move")
	move_button.pressed.connect(func():
		current_mode = "move"
		render_battle()
		play_sfx("res://assets/audio/ui.wav")
	)
	unit_panel.add_child(move_button)
	var attack_button := Button.new()
	attack_button.text = "ATACAR"
	attack_button.disabled = battle_over
	style_button(attack_button, current_mode == "attack")
	attack_button.pressed.connect(func():
		current_mode = "attack"
		render_battle()
		play_sfx("res://assets/audio/ui.wav")
	)
	unit_panel.add_child(attack_button)
	render_weapon_buttons()
	var wait_button := Button.new()
	wait_button.text = "ESPERAR"
	wait_button.disabled = battle_over
	style_button(wait_button)
	wait_button.pressed.connect(wait_selected_unit)
	unit_panel.add_child(wait_button)
	var end_button := Button.new()
	end_button.text = "TERMINAR TURNO"
	end_button.disabled = battle_over
	style_button(end_button, true)
	end_button.pressed.connect(start_enemy_turn)
	unit_panel.add_child(end_button)
	var overwatch_button := Button.new()
	overwatch_button.text = "OVERWATCH"
	overwatch_button.disabled = battle_over
	style_button(overwatch_button)
	overwatch_button.pressed.connect(enable_overwatch)
	unit_panel.add_child(overwatch_button)
	for i in range(units.size()):
		var unit = units[i]
		var button := Button.new()
		button.text = "%s | %s/%s HP | AP %s | %s%s" % [
			unit.name,
			unit.hp,
			unit.max_hp,
			unit.ap,
			unit.side,
			" | LISTO" if not acted_units.has(unit.id) else " | SIN ACCION"
		]
		button.disabled = battle_over or unit.side != "hero" or turn_side != "hero"
		style_button(button, i == selected_unit)
		button.pressed.connect(func(index := i):
			selected_unit = index
			render_battle()
			play_sfx("res://assets/audio/ui.wav")
		)
		unit_panel.add_child(button)

func render_objective_panel() -> void:
	var mission = data.missions[selected_mission]
	var enemies_left := units.filter(func(unit): return unit.side == "enemy").size()
	var heroes_left := units.filter(func(unit): return unit.side == "hero").size()
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "OBJETIVO\n%s\n%s\nHEROES %s  //  INFECTADOS %s" % [
		objective_text(mission.get("objective", "eliminate")),
		mission.get("briefing", ""),
		heroes_left,
		enemies_left
	]
	label.add_theme_color_override("font_color", COLORS.muted)
	unit_panel.add_child(label)

func render_selected_unit_panel() -> void:
	if selected_unit < 0 or selected_unit >= units.size():
		return
	var unit = units[selected_unit]
	var status_text := "Normal" if unit.status.is_empty() else ", ".join(unit.status)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "%s  [%s]\nHP %s/%s  //  AP %s/%s  //  %s\nMUNICION  P:%s  E:%s  R:%s  G:%s  B:%s" % [
		str(unit.name).to_upper(),
		str(unit.role).to_upper(),
		unit.hp,
		unit.max_hp,
		unit.ap,
		unit.max_ap,
		str(status_text).to_upper(),
		ammo_count(unit, "pistol"),
		ammo_count(unit, "shotgun"),
		ammo_count(unit, "rifle"),
		ammo_count(unit, "grenade"),
		ammo_count(unit, "medkit")
	]
	label.add_theme_color_override("font_color", COLORS.text)
	unit_panel.add_child(label)

func render_weapon_buttons() -> void:
	for weapon_id in ["pistol", "shotgun", "rifle", "grenade"]:
		var weapon = data.weapons[weapon_id]
		var button := Button.new()
		var shots_left := selected_unit_ammo(weapon_id)
		var hit_text := "100%" if weapon_id == "grenade" else "%s%%" % selected_weapon_accuracy(weapon_id)
		button.text = "%s x%s  |  D%s R%s  |  %s" % [str(weapon.name).to_upper(), shots_left, weapon.damage, weapon.range, hit_text]
		button.disabled = selected_unit < 0 or shots_left <= 0 or turn_side != "hero"
		style_button(button, current_mode in ["attack", "grenade"] and selected_weapon == weapon_id)
		button.pressed.connect(func(id: String = weapon_id):
			selected_weapon = id
			current_mode = "grenade" if id == "grenade" else "attack"
			render_battle()
			play_sfx("res://assets/audio/ui.wav")
		)
		unit_panel.add_child(button)
	var medkit = data.weapons.medkit
	var heal_button := Button.new()
	heal_button.text = "%s x%s  |  +%s" % [str(medkit.name).to_upper(), selected_unit_ammo("medkit"), medkit.heal]
	heal_button.disabled = selected_unit < 0 or selected_unit_ammo("medkit") <= 0 or turn_side != "hero"
	style_button(heal_button, current_mode == "heal")
	heal_button.pressed.connect(func():
		current_mode = "heal"
		selected_weapon = "medkit"
		render_battle()
		play_sfx("res://assets/audio/ui.wav")
	)
	unit_panel.add_child(heal_button)
	if data.missions[selected_mission].get("objective", "eliminate") == "activate":
		var objective_button := Button.new()
		objective_button.text = "ACTIVAR OBJETIVO" if not objective_activated else "OBJETIVO ACTIVADO"
		objective_button.disabled = selected_unit < 0 or objective_activated or not selected_unit_near_objective()
		style_button(objective_button, current_mode == "activate")
		objective_button.pressed.connect(activate_objective)
		unit_panel.add_child(objective_button)

func selected_weapon_accuracy(weapon_id: String) -> int:
	if not data.weapons.has(weapon_id):
		return 0
	var base := int(data.weapons[weapon_id].get("accuracy", 80))
	if selected_unit < 0 or selected_unit >= units.size():
		return base
	var target := best_visible_enemy_for_unit(units[selected_unit], int(data.weapons[weapon_id].get("range", 4)))
	if target < 0:
		return base
	return clamp(base - cover_penalty(units[target].x, units[target].y), 15, 100)

func best_visible_enemy_for_unit(unit: Dictionary, attack_range: int) -> int:
	var best := -1
	var best_hp := 9999
	for i in range(units.size()):
		if units[i].side == unit.side:
			continue
		if distance_xy(unit.x, unit.y, units[i].x, units[i].y) > attack_range:
			continue
		if not has_line_of_sight(unit.x, unit.y, units[i].x, units[i].y):
			continue
		if int(units[i].hp) < best_hp:
			best = i
			best_hp = int(units[i].hp)
	return best

func objective_text(objective: String) -> String:
	match objective:
		"activate":
			return "Activar la consola y eliminar hostiles." if not objective_activated else "Consola activada. Elimina los hostiles."
		"boss":
			return "Neutralizar al enemigo pesado."
		"survive":
			return "Sobrevivir hasta evacuar."
		_:
			return "Eliminar todos los enemigos."

func render_result_panel() -> void:
	var mission = data.missions[selected_mission]
	var summary := Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if battle_result == "victory":
		summary.text = "VICTORIA EN %s\nRECOMPENSA: $%s / INVESTIGACION %s" % [str(mission.name).to_upper(), mission.rewardCredits, mission.rewardResearch]
	else:
		summary.text = "DERROTA EN %s\nReagrupa al escuadron y vuelve a intentarlo." % str(mission.name).to_upper()
	unit_panel.add_child(summary)
	var retry_button := Button.new()
	retry_button.text = "REINTENTAR"
	style_button(retry_button)
	retry_button.pressed.connect(start_battle)
	unit_panel.add_child(retry_button)
	var menu_button := Button.new()
	menu_button.text = "VOLVER AL MENU"
	style_button(menu_button)
	menu_button.pressed.connect(show_menu)
	unit_panel.add_child(menu_button)
	if battle_result == "victory" and selected_mission < data.missions.size() - 1:
		var next_button := Button.new()
		next_button.text = "SIGUIENTE MISION"
		style_button(next_button, true)
		next_button.pressed.connect(func():
			selected_mission += 1
			start_battle()
		)
		unit_panel.add_child(next_button)

func get_tile_color(x: int, y: int) -> Color:
	var key := "%s,%s" % [x, y]
	if cover_tiles.has(key):
		return Color(0.35, 0.42, 0.24, 1.0)
	if selected_unit >= 0 and selected_unit < units.size() and units[selected_unit].side == "hero":
		var unit = units[selected_unit]
		var d := distance_xy(unit.x, unit.y, x, y)
		if current_mode == "move" and d <= unit.move:
			return Color(0.25, 0.55, 0.7, 1.0)
		if current_mode == "attack" and d <= unit.range:
			return Color(0.65, 0.25, 0.18, 1.0)
	return Color(0.12, 0.18, 0.18, 1.0) if (x + y) % 2 == 0 else Color(0.09, 0.14, 0.14, 1.0)

func handle_tile(x: int, y: int) -> void:
	if battle_over or turn_side != "hero" or selected_unit < 0 or selected_unit >= units.size():
		return
	var clicked := unit_at(x, y)
	if clicked >= 0 and units[clicked].side == "hero":
		selected_unit = clicked
		render_battle()
		return
	var unit = units[selected_unit]
	if acted_units.has(unit.id):
		return
	if current_mode == "move":
		try_move_selected(x, y)
	elif current_mode == "attack" and clicked >= 0:
		try_attack(selected_unit, clicked)
	elif current_mode == "grenade" and clicked >= 0:
		try_grenade(selected_unit, clicked)
	elif current_mode == "heal" and clicked >= 0:
		try_heal(selected_unit, clicked)
	elif current_mode == "activate":
		activate_objective()

func try_move_selected(x: int, y: int) -> void:
	var unit = units[selected_unit]
	var path := find_path(Vector2i(unit.x, unit.y), Vector2i(x, y), unit.move)
	if path.is_empty():
		return
	if is_blocked(x, y):
		return
	unit.x = x
	unit.y = y
	unit.ap -= 1
	mark_if_spent(unit)
	add_log("%s avanza." % unit.name)
	spawn_float_text(unit.x, unit.y, "-1 AP", COLORS.muted)
	play_sfx("res://assets/audio/step.wav")
	select_next_ready_hero()
	render_battle()

func try_attack(attacker_index: int, target_index: int) -> void:
	if attacker_index < 0 or target_index < 0:
		return
	var attacker = units[attacker_index]
	var target = units[target_index]
	if attacker.side == target.side:
		return
	var weapon = data.weapons.get(selected_weapon, data.weapons.pistol) if attacker.side == "hero" else {}
	var attack_range = int(weapon.get("range", attacker.range))
	if distance_xy(attacker.x, attacker.y, target.x, target.y) > attack_range:
		if attacker.side == "hero":
			add_log("Objetivo fuera de rango para %s." % data.weapons[selected_weapon].name)
		return
	if not has_line_of_sight(attacker.x, attacker.y, target.x, target.y):
		if attacker.side == "hero":
			add_log("Linea de vision bloqueada.")
		return
	if attacker.side == "hero" and not consume_ammo(attacker, selected_weapon):
		add_log("%s no tiene municion para %s." % [attacker.name, data.weapons[selected_weapon].name])
		play_sfx("res://assets/audio/ui.wav")
		render_battle()
		return
	var hit_chance: int = clamp(int(weapon.get("accuracy", 80)) - cover_penalty(target.x, target.y), 15, 100)
	var roll := randi_range(1, 100)
	if roll > hit_chance:
		attacker.ap -= 1
		mark_if_spent(attacker)
		add_log("%s falla contra %s." % [attacker.name, target.name])
		play_sfx("res://assets/audio/shot.wav")
		if attacker.side == "hero":
			select_next_ready_hero()
		render_battle()
		return
	var damage: int = int(weapon.get("damage", attacker.damage))
	if randi_range(1, 100) <= int(weapon.get("crit", 10)):
		damage += 2
		add_log("Critico.")
	target.hp -= damage
	if attacker.side == "enemy" and attacker.role == "spitter" and not target.status.has("poisoned"):
		target.status.append("poisoned")
		add_log("%s queda envenenado." % target.name)
	attacker.ap -= 1
	mark_if_spent(attacker)
	spawn_effect(target.x, target.y, "hit")
	spawn_float_text(target.x, target.y, "-%s" % damage, COLORS.warning if attacker.side == "hero" else COLORS.enemy)
	add_log("%s ataca a %s por %s." % [attacker.name, target.name, damage])
	play_sfx("res://assets/audio/shot.wav" if attacker.side == "hero" else "res://assets/audio/bite.wav")
	if target.hp <= 0:
		add_log("%s cae." % target.name)
		units.remove_at(target_index)
		if selected_unit >= units.size():
			selected_unit = units.size() - 1
	if check_result():
		render_battle()
		return
	if attacker.side == "hero":
		select_next_ready_hero()
	render_battle()

func wait_selected_unit() -> void:
	if battle_over or selected_unit < 0 or selected_unit >= units.size():
		return
	var unit = units[selected_unit]
	if unit.side != "hero":
		return
	unit.ap = 0
	mark_if_spent(unit)
	add_log("%s espera." % unit.name)
	select_next_ready_hero()
	render_battle()

func enable_overwatch() -> void:
	if battle_over or selected_unit < 0 or selected_unit >= units.size():
		return
	var unit = units[selected_unit]
	if unit.side != "hero" or unit.ap <= 0:
		return
	unit.status.append("overwatch")
	unit.ap = 0
	mark_if_spent(unit)
	add_log("%s cubre la zona." % unit.name)
	select_next_ready_hero()
	render_battle()

func try_grenade(attacker_index: int, target_index: int) -> void:
	var attacker = units[attacker_index]
	var target = units[target_index]
	if attacker.side == target.side or attacker.ap <= 0:
		return
	if distance_xy(attacker.x, attacker.y, target.x, target.y) > 4:
		return
	if not consume_ammo(attacker, "grenade"):
		add_log("%s no tiene granadas." % attacker.name)
		play_sfx("res://assets/audio/ui.wav")
		render_battle()
		return
	for i in range(units.size() - 1, -1, -1):
		if units[i].side != attacker.side and distance_xy(units[i].x, units[i].y, target.x, target.y) <= 1:
			units[i].hp -= 4
			spawn_float_text(units[i].x, units[i].y, "-4", COLORS.warning)
			if not units[i].status.has("bleeding"):
				units[i].status.append("bleeding")
			if units[i].hp <= 0:
				add_log("%s cae por la explosion." % units[i].name)
				units.remove_at(i)
	attacker.ap = 0
	mark_if_spent(attacker)
	spawn_effect(target.x, target.y, "explosion")
	add_log("%s lanza una granada." % attacker.name)
	play_sfx("res://assets/audio/special.wav")
	if check_result():
		render_battle()
		return
	select_next_ready_hero()
	render_battle()

func try_heal(healer_index: int, target_index: int) -> void:
	var healer = units[healer_index]
	var target = units[target_index]
	if healer.side != target.side or healer.ap <= 0:
		return
	if distance_xy(healer.x, healer.y, target.x, target.y) > 1:
		return
	if not consume_ammo(healer, "medkit"):
		add_log("%s no tiene botiquines." % healer.name)
		play_sfx("res://assets/audio/ui.wav")
		render_battle()
		return
	target.hp = min(target.max_hp, target.hp + 5)
	target.status.erase("bleeding")
	target.status.erase("poisoned")
	spawn_float_text(target.x, target.y, "+5", COLORS.bio)
	healer.ap -= 1
	mark_if_spent(healer)
	add_log("%s cura a %s." % [healer.name, target.name])
	play_sfx("res://assets/audio/ui.wav")
	select_next_ready_hero()
	render_battle()

func select_next_ready_hero() -> void:
	for i in range(units.size()):
		if units[i].side == "hero" and units[i].ap > 0 and not acted_units.has(units[i].id):
			selected_unit = i
			return
	start_enemy_turn()

func start_enemy_turn() -> void:
	if battle_over or turn_side == "enemy":
		return
	apply_status_damage("enemy")
	if check_result():
		render_battle()
		return
	turn_side = "enemy"
	render_battle()
	await get_tree().create_timer(0.45).timeout
	run_enemy_turn()

func run_enemy_turn() -> void:
	for enemy_index in range(units.size() - 1, -1, -1):
		if enemy_index >= units.size() or units[enemy_index].side != "enemy":
			continue
		var target_index := nearest_hero(enemy_index)
		if target_index < 0:
			continue
		if distance_units(enemy_index, target_index) <= units[enemy_index].range:
			try_attack(enemy_index, target_index)
		else:
			step_enemy_toward(enemy_index, target_index)
	if check_result():
		render_battle()
		return
	turn_side = "hero"
	round_number += 1
	acted_units = {}
	for unit in units:
		unit.ap = unit.max_ap
		unit.status.erase("overwatch")
	apply_status_damage("hero")
	if check_result():
		render_battle()
		return
	if round_number > mission_turn_limit:
		add_log("Derrota. Se agoto la ventana de extraccion.")
		play_sfx("res://assets/audio/defeat.wav")
		battle_over = true
		battle_result = "defeat"
		render_battle()
		return
	select_next_ready_hero()
	add_log("Turno de heroes.")
	play_sfx("res://assets/audio/turn.wav")
	render_battle()

func step_enemy_toward(enemy_index: int, target_index: int) -> void:
	var enemy = units[enemy_index]
	var target = units[target_index]
	var best_x = enemy.x
	var best_y = enemy.y
	var best_score := 9999
	var candidates = [[enemy.x + 1, enemy.y], [enemy.x - 1, enemy.y], [enemy.x, enemy.y + 1], [enemy.x, enemy.y - 1]]
	for candidate in candidates:
		var x = candidate[0]
		var y = candidate[1]
		if x < 0 or y < 0 or x >= BOARD_W or y >= BOARD_H:
			continue
		if is_blocked(x, y):
			continue
		var score = enemy_move_score(enemy, target, x, y)
		if score < best_score:
			best_score = score
			best_x = x
			best_y = y
	enemy.x = best_x
	enemy.y = best_y
	add_log("%s se acerca." % enemy.name)
	spawn_float_text(enemy.x, enemy.y, str(enemy.role).to_upper(), COLORS.enemy)
	play_sfx("res://assets/audio/step.wav")
	trigger_overwatch(enemy_index)

func enemy_move_score(enemy: Dictionary, target: Dictionary, x: int, y: int) -> int:
	var distance := distance_xy(x, y, target.x, target.y)
	var score := distance * 10
	if enemy.role == "runner":
		score = distance * 6
	if enemy.role == "spitter":
		var ideal_range := 3
		score = abs(distance - ideal_range) * 12
		if cover_tiles.has("%s,%s" % [x, y]):
			score -= 8
	if enemy.role == "boss":
		score = distance * 8
		if cover_tiles.has("%s,%s" % [x, y]):
			score += 6
	if enemy.role == "ambusher" and cover_tiles.has("%s,%s" % [x, y]):
		score -= 10
	return score

func check_result() -> bool:
	var heroes := units.filter(func(unit): return unit.side == "hero")
	var enemies := units.filter(func(unit): return unit.side == "enemy")
	var mission_objective = data.missions[selected_mission].get("objective", "eliminate")
	var boss_alive = enemies.any(func(unit): return unit.role == "boss")
	var objective_done = mission_objective != "activate" or objective_activated
	var boss_done = mission_objective != "boss" or not boss_alive
	if enemies.is_empty() and objective_done:
		add_log("Victoria. Zona despejada.")
		play_sfx("res://assets/audio/victory.wav")
		battle_over = true
		battle_result = "victory"
		claim_mission_rewards()
		return true
	if mission_objective == "boss" and boss_done:
		add_log("Victoria. Zona despejada.")
		play_sfx("res://assets/audio/victory.wav")
		battle_over = true
		battle_result = "victory"
		claim_mission_rewards()
		return true
	if heroes.is_empty():
		add_log("Derrota. El brote domina la zona.")
		play_sfx("res://assets/audio/defeat.wav")
		battle_over = true
		battle_result = "defeat"
		return true
	return false

func claim_mission_rewards() -> void:
	if reward_claimed:
		return
	reward_claimed = true
	var progress := get_progress(selected_faction)
	var mission = data.missions[selected_mission]
	progress.wins += 1
	progress.credits += int(mission.get("rewardCredits", 0))
	progress.research += int(mission.get("rewardResearch", 0))
	progress.unlockedMission = max(int(progress.unlockedMission), min(selected_mission + 1, data.missions.size() - 1))
	save_json(SAVE_PATH, campaign)

func unit_at(x: int, y: int) -> int:
	for i in range(units.size()):
		if units[i].x == x and units[i].y == y:
			return i
	return -1

func nearest_hero(enemy_index: int) -> int:
	var best := -1
	var best_score := 999
	var enemy = units[enemy_index]
	for i in range(units.size()):
		if units[i].side != "hero":
			continue
		var score = units[i].hp + distance_xy(enemy.x, enemy.y, units[i].x, units[i].y) * 2
		if score < best_score:
			best = i
			best_score = score
	return best

func distance_units(a: int, b: int) -> int:
	return distance_xy(units[a].x, units[a].y, units[b].x, units[b].y)

func distance_xy(ax: int, ay: int, bx: int, by: int) -> int:
	return abs(ax - bx) + abs(ay - by)

func mark_if_spent(unit: Dictionary) -> void:
	if unit.ap <= 0:
		acted_units[unit.id] = true

func selected_attack_range(unit: Dictionary) -> int:
	if selected_weapon in data.weapons:
		return int(data.weapons[selected_weapon].get("range", unit.range))
	return int(unit.range)

func selected_unit_ammo(kind: String) -> int:
	if selected_unit < 0 or selected_unit >= units.size():
		return 0
	return ammo_count(units[selected_unit], kind)

func ammo_count(unit: Dictionary, kind: String) -> int:
	if not unit.has("ammo") or typeof(unit.ammo) != TYPE_DICTIONARY:
		return 0
	return int(unit.ammo.get(kind, 0))

func consume_ammo(unit: Dictionary, kind: String) -> bool:
	if unit.side != "hero":
		return true
	if ammo_count(unit, kind) <= 0:
		return false
	unit.ammo[kind] = ammo_count(unit, kind) - 1
	return true

func selected_unit_near_objective() -> bool:
	if selected_unit < 0 or selected_unit >= units.size():
		return false
	var unit = units[selected_unit]
	for key in objective_tiles.keys():
		var parts = str(key).split(",")
		if parts.size() == 2 and distance_xy(unit.x, unit.y, int(parts[0]), int(parts[1])) <= 1:
			return true
	return false

func activate_objective() -> void:
	if battle_over or selected_unit < 0 or selected_unit >= units.size():
		return
	var unit = units[selected_unit]
	if unit.side != "hero" or unit.ap <= 0 or objective_activated or not selected_unit_near_objective():
		return
	objective_activated = true
	unit.ap -= 1
	mark_if_spent(unit)
	add_log("%s activa la consola." % unit.name)
	play_sfx("res://assets/audio/ui.wav")
	if check_result():
		render_battle()
		return
	select_next_ready_hero()
	render_battle()

func apply_status_damage(side: String) -> void:
	for i in range(units.size() - 1, -1, -1):
		if units[i].side != side:
			continue
		var damage := 0
		if units[i].status.has("bleeding"):
			damage += 1
		if units[i].status.has("poisoned"):
			damage += 1
		if damage <= 0:
			continue
		units[i].hp -= damage
		add_log("%s sufre %s por estados." % [units[i].name, damage])
		spawn_effect(units[i].x, units[i].y, "hit")
		if units[i].hp <= 0:
			add_log("%s cae por sus heridas." % units[i].name)
			units.remove_at(i)

func is_blocked(x: int, y: int) -> bool:
	return unit_at(x, y) >= 0 or obstacle_tiles.has("%s,%s" % [x, y]) or wall_tiles.has("%s,%s" % [x, y])

func cover_penalty(x: int, y: int) -> int:
	return 25 if cover_tiles.has("%s,%s" % [x, y]) else 0

func has_line_of_sight(ax: int, ay: int, bx: int, by: int) -> bool:
	var steps = max(abs(ax - bx), abs(ay - by))
	if steps <= 1:
		return true
	for step in range(1, steps):
		var t := float(step) / float(steps)
		var x := roundi(lerp(float(ax), float(bx), t))
		var y := roundi(lerp(float(ay), float(by), t))
		if obstacle_tiles.has("%s,%s" % [x, y]) or wall_tiles.has("%s,%s" % [x, y]):
			return false
	return true

func find_path(start: Vector2i, goal: Vector2i, max_steps: int) -> Array:
	if goal.x < 0 or goal.y < 0 or goal.x >= BOARD_W or goal.y >= BOARD_H:
		return []
	var frontier := [start]
	var came_from := {start: start}
	var cost := {start: 0}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal:
			break
		for next in [Vector2i(current.x + 1, current.y), Vector2i(current.x - 1, current.y), Vector2i(current.x, current.y + 1), Vector2i(current.x, current.y - 1)]:
			if next.x < 0 or next.y < 0 or next.x >= BOARD_W or next.y >= BOARD_H:
				continue
			if is_blocked(next.x, next.y) and next != goal:
				continue
			var new_cost := int(cost[current]) + 1
			if new_cost > max_steps:
				continue
			if not cost.has(next) or new_cost < int(cost[next]):
				cost[next] = new_cost
				came_from[next] = current
				frontier.append(next)
	if not came_from.has(goal):
		return []
	var path := [goal]
	var current := goal
	while current != start:
		current = came_from[current]
		path.push_front(current)
	return path

func trigger_overwatch(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= units.size():
		return
	var enemy = units[enemy_index]
	for hero in units:
		if hero.side == "hero" and hero.status.has("overwatch") and distance_xy(hero.x, hero.y, enemy.x, enemy.y) <= hero.range:
			enemy.hp -= 2
			hero.status.erase("overwatch")
			add_log("%s dispara en overwatch." % hero.name)
			play_sfx("res://assets/audio/shot.wav")
			if enemy.hp <= 0:
				add_log("%s cae." % enemy.name)
				units.erase(enemy)
			return

func spawn_effect(x: int, y: int, _kind: String) -> void:
	var effect = EFFECT_BURST.instantiate()
	effect.position = iso_pos(x, y) + Vector2(0, -18)
	effect.z_index = 900
	battle_grid.add_child(effect)
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector2(1.7, 1.7), 0.18)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.24)
	tween.tween_callback(effect.queue_free)

func spawn_float_text(x: int, y: int, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = iso_pos(x, y) + Vector2(-24, -76)
	label.size = Vector2(64, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.z_index = 980
	battle_grid.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -26), 0.45)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.45)
	tween.tween_callback(label.queue_free)

func add_log(text: String) -> void:
	log_label.append_text(text + "\n")

func play_sfx(path: String) -> void:
	sfx.stream = load(path)
	sfx.volume_db = -8
	sfx.play()

func _on_continue_pressed() -> void:
	show_menu()

func _on_start_pressed() -> void:
	start_battle()
