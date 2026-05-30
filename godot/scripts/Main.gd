extends Control

const DATA_PATH := "res://data/game_data.json"
const SAVE_PATH := "user://campaign_save.json"

var data := {}
var campaign := {}
var selected_faction := "bsaa"
var selected_mission := 0
var units := []
var turn_side := "hero"
var selected_unit := -1
var current_mode := "move"
var round_number := 1
var acted_units := {}
var cover_tiles := ["4,1", "7,1", "2,3", "5,4", "8,4", "9,6", "3,7"]
var battle_over := false

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
	round_number = 1
	turn_side = "hero"
	selected_unit = 0
	current_mode = "move"
	acted_units = {}
	battle_over = false
	units = build_units()
	log_label.clear()
	render_battle()
	add_log("Mision iniciada: %s" % data.missions[selected_mission].name)
	add_log("Selecciona una unidad, mueve o ataca.")
	play_sfx("res://assets/audio/turn.wav")

func build_units() -> Array:
	return [
		{"id": "h1", "name": "Chris", "side": "hero", "x": 1, "y": 1, "hp": 12, "max_hp": 12, "move": 4, "damage": 3, "range": 4, "sprite": "soldier.svg"},
		{"id": "h2", "name": "Jill", "side": "hero", "x": 1, "y": 3, "hp": 10, "max_hp": 10, "move": 5, "damage": 3, "range": 4, "sprite": "agent.svg"},
		{"id": "h3", "name": "Leon", "side": "hero", "x": 1, "y": 5, "hp": 10, "max_hp": 10, "move": 4, "damage": 4, "range": 5, "sprite": "agent.svg"},
		{"id": "e1", "name": "Zombie", "side": "enemy", "x": 10, "y": 1, "hp": 7, "max_hp": 7, "move": 3, "damage": 2, "range": 1, "sprite": "zombie.svg"},
		{"id": "e2", "name": "Cerberus", "side": "enemy", "x": 9, "y": 3, "hp": 6, "max_hp": 6, "move": 5, "damage": 2, "range": 1, "sprite": "cerberus.svg"},
		{"id": "e3", "name": "Licker", "side": "enemy", "x": 10, "y": 5, "hp": 12, "max_hp": 12, "move": 4, "damage": 3, "range": 1, "sprite": "licker.svg"},
		{"id": "e4", "name": "Tyrant", "side": "enemy", "x": 11, "y": 7, "hp": 18, "max_hp": 18, "move": 2, "damage": 4, "range": 1, "sprite": "tyrant.svg"}
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
			var tile := Button.new()
			tile.modulate = get_tile_color(x, y)
			tile.size = Vector2(44, 24)
			tile.custom_minimum_size = Vector2(44, 24)
			tile.position = iso_pos(x, y)
			tile.text = ""
			tile.pressed.connect(func(tx := x, ty := y):
				handle_tile(tx, ty)
			)
			battle_grid.add_child(tile)
	for index in range(units.size()):
		var unit = units[index]
		var sprite := Sprite2D.new()
		sprite.texture = load("res://assets/sprites/%s" % unit.sprite)
		sprite.position = iso_pos(unit.x, unit.y) + Vector2(22, -26)
		sprite.scale = Vector2(0.85, 0.85)
		if index == selected_unit:
			sprite.modulate = Color(1.3, 1.3, 0.75, 1.0)
		battle_grid.add_child(sprite)
	render_unit_panel()

func iso_pos(x: int, y: int) -> Vector2:
	return Vector2((x - y) * 38 + 420, (x + y) * 20 + 80)

func render_unit_panel() -> void:
	for child in unit_panel.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "Combate terminado" if battle_over else "Ronda %s | Turno: %s | Modo: %s" % [round_number, turn_side, current_mode]
	unit_panel.add_child(title)
	var move_button := Button.new()
	move_button.text = "Mover"
	move_button.disabled = battle_over
	move_button.pressed.connect(func():
		current_mode = "move"
		render_battle()
		play_sfx("res://assets/audio/ui.wav")
	)
	unit_panel.add_child(move_button)
	var attack_button := Button.new()
	attack_button.text = "Atacar"
	attack_button.disabled = battle_over
	attack_button.pressed.connect(func():
		current_mode = "attack"
		render_battle()
		play_sfx("res://assets/audio/ui.wav")
	)
	unit_panel.add_child(attack_button)
	var wait_button := Button.new()
	wait_button.text = "Esperar"
	wait_button.disabled = battle_over
	wait_button.pressed.connect(wait_selected_unit)
	unit_panel.add_child(wait_button)
	var end_button := Button.new()
	end_button.text = "Terminar turno"
	end_button.disabled = battle_over
	end_button.pressed.connect(start_enemy_turn)
	unit_panel.add_child(end_button)
	for i in range(units.size()):
		var unit = units[i]
		var button := Button.new()
		button.text = "%s | %s/%s HP | %s%s" % [
			unit.name,
			unit.hp,
			unit.max_hp,
			unit.side,
			" | listo" if not acted_units.has(unit.id) else " | sin accion"
		]
		button.disabled = battle_over or unit.side != "hero" or turn_side != "hero"
		button.pressed.connect(func(index := i):
			selected_unit = index
			render_battle()
			play_sfx("res://assets/audio/ui.wav")
		)
		unit_panel.add_child(button)

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

func try_move_selected(x: int, y: int) -> void:
	var unit = units[selected_unit]
	if distance_xy(unit.x, unit.y, x, y) > unit.move:
		return
	if unit_at(x, y) >= 0 or cover_tiles.has("%s,%s" % [x, y]):
		return
	unit.x = x
	unit.y = y
	acted_units[unit.id] = true
	add_log("%s avanza." % unit.name)
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
	if distance_xy(attacker.x, attacker.y, target.x, target.y) > attacker.range:
		return
	target.hp -= attacker.damage
	acted_units[attacker.id] = true
	add_log("%s ataca a %s por %s." % [attacker.name, target.name, attacker.damage])
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
	acted_units[unit.id] = true
	add_log("%s espera." % unit.name)
	select_next_ready_hero()
	render_battle()

func select_next_ready_hero() -> void:
	for i in range(units.size()):
		if units[i].side == "hero" and not acted_units.has(units[i].id):
			selected_unit = i
			return
	start_enemy_turn()

func start_enemy_turn() -> void:
	if battle_over or turn_side == "enemy":
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
	select_next_ready_hero()
	add_log("Turno de heroes.")
	play_sfx("res://assets/audio/turn.wav")
	render_battle()

func step_enemy_toward(enemy_index: int, target_index: int) -> void:
	var enemy = units[enemy_index]
	var target = units[target_index]
	var best_x = enemy.x
	var best_y = enemy.y
	var best_score := 999
	var candidates = [[enemy.x + 1, enemy.y], [enemy.x - 1, enemy.y], [enemy.x, enemy.y + 1], [enemy.x, enemy.y - 1]]
	for candidate in candidates:
		var x = candidate[0]
		var y = candidate[1]
		if x < 0 or y < 0 or x >= 12 or y >= 9:
			continue
		if unit_at(x, y) >= 0 or cover_tiles.has("%s,%s" % [x, y]):
			continue
		var score = distance_xy(x, y, target.x, target.y)
		if score < best_score:
			best_score = score
			best_x = x
			best_y = y
	enemy.x = best_x
	enemy.y = best_y
	add_log("%s se acerca." % enemy.name)
	play_sfx("res://assets/audio/step.wav")

func check_result() -> bool:
	var heroes := units.filter(func(unit): return unit.side == "hero")
	var enemies := units.filter(func(unit): return unit.side == "enemy")
	if enemies.is_empty():
		add_log("Victoria. Zona despejada.")
		play_sfx("res://assets/audio/victory.wav")
		battle_over = true
		return true
	if heroes.is_empty():
		add_log("Derrota. El brote domina la zona.")
		play_sfx("res://assets/audio/defeat.wav")
		battle_over = true
		return true
	return false

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
