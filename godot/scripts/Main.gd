extends Control

const DATA_PATH := "res://data/game_data.json"
const SAVE_PATH := "user://campaign_save.json"

var data := {}
var campaign := {}
var selected_faction := "bsaa"
var selected_mission := 0
var units := []

@onready var title_screen: Control = %TitleScreen
@onready var start_screen: Control = %StartScreen
@onready var battle_screen: Control = %BattleScreen
@onready var faction_list: VBoxContainer = %FactionList
@onready var mission_list: VBoxContainer = %MissionList
@onready var campaign_stats: Label = %CampaignStats
@onready var mission_title: Label = %MissionTitle
@onready var battle_grid: Node2D = %BattleGrid
@onready var unit_panel: VBoxContainer = %UnitPanel
@onready var log_label: RichTextLabel = %LogLabel
@onready var music: AudioStreamPlayer = %Music
@onready var sfx: AudioStreamPlayer = %Sfx

func _ready() -> void:
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

func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file else {}
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func show_title() -> void:
	title_screen.visible = true
	start_screen.visible = false
	battle_screen.visible = false

func show_menu() -> void:
	title_screen.visible = false
	start_screen.visible = true
	battle_screen.visible = false
	render_missions()

func start_battle() -> void:
	title_screen.visible = false
	start_screen.visible = false
	battle_screen.visible = true
	units = build_units()
	render_battle()
	add_log("Mision iniciada: %s" % data.missions[selected_mission].name)
	play_sfx("res://assets/audio/turn.wav")

func build_units() -> Array:
	return [
		{"name": "Chris", "side": "hero", "x": 1, "y": 1, "hp": 12, "sprite": "soldier.svg"},
		{"name": "Jill", "side": "hero", "x": 1, "y": 3, "hp": 10, "sprite": "agent.svg"},
		{"name": "Leon", "side": "hero", "x": 1, "y": 5, "hp": 10, "sprite": "agent.svg"},
		{"name": "Zombie", "side": "enemy", "x": 10, "y": 1, "hp": 7, "sprite": "zombie.svg"},
		{"name": "Cerberus", "side": "enemy", "x": 9, "y": 3, "hp": 6, "sprite": "cerberus.svg"},
		{"name": "Licker", "side": "enemy", "x": 10, "y": 5, "hp": 12, "sprite": "licker.svg"},
		{"name": "Tyrant", "side": "enemy", "x": 11, "y": 7, "hp": 18, "sprite": "tyrant.svg"}
	]

func render_factions() -> void:
	for child in faction_list.get_children():
		child.queue_free()
	for faction_id in data.factions.keys():
		var button := Button.new()
		button.text = data.factions[faction_id].name
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
	campaign_stats.text = "%s | Victorias: %s | Creditos: $%s | Investigacion: %s" % [
		data.factions[selected_faction].name,
		progress.wins,
		progress.credits,
		progress.research
	]
	for i in range(data.missions.size()):
		var mission = data.missions[i]
		var button := Button.new()
		button.text = "%s. %s" % [i + 1, mission.name]
		button.disabled = i > progress.unlockedMission
		button.pressed.connect(func(index := i):
			selected_mission = index
			mission_title.text = data.missions[selected_mission].briefing
			play_sfx("res://assets/audio/ui.wav")
		)
		mission_list.add_child(button)
	mission_title.text = data.missions[selected_mission].briefing

func get_progress(faction_id: String) -> Dictionary:
	if not campaign.has(faction_id):
		campaign[faction_id] = {"wins": 0, "credits": 0, "research": 0, "unlockedMission": 0}
	return campaign[faction_id]

func render_battle() -> void:
	for child in battle_grid.get_children():
		child.queue_free()
	for y in range(9):
		for x in range(12):
			var tile := ColorRect.new()
			tile.color = Color(0.12, 0.18, 0.18, 1.0) if (x + y) % 2 == 0 else Color(0.09, 0.14, 0.14, 1.0)
			tile.size = Vector2(44, 24)
			tile.position = iso_pos(x, y)
			battle_grid.add_child(tile)
	for unit in units:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/sprites/%s" % unit.sprite)
		sprite.position = iso_pos(unit.x, unit.y) + Vector2(22, -26)
		sprite.scale = Vector2(0.85, 0.85)
		battle_grid.add_child(sprite)
	render_unit_panel()

func iso_pos(x: int, y: int) -> Vector2:
	return Vector2((x - y) * 38 + 420, (x + y) * 20 + 80)

func render_unit_panel() -> void:
	for child in unit_panel.get_children():
		child.queue_free()
	for unit in units:
		var label := Label.new()
		label.text = "%s | %s HP | %s" % [unit.name, unit.hp, unit.side]
		unit_panel.add_child(label)

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
