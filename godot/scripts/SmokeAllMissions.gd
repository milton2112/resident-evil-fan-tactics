extends SceneTree

func _initialize() -> void:
	var packed := load("res://scenes/Main.tscn")
	if packed == null:
		push_error("No se pudo cargar Main.tscn")
		quit(1)
		return
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	if main.data.is_empty() or not main.data.has("missions"):
		push_error("No se cargaron datos de misiones")
		quit(1)
		return
	for index in range(main.data.missions.size()):
		main.selected_mission = index
		main.start_battle()
		await process_frame
		if not main.battle_screen.visible:
			push_error("La mision %s no muestra combate" % index)
			quit(1)
			return
		if main.units.is_empty():
			push_error("La mision %s arranca sin unidades" % index)
			quit(1)
			return
		if main.battle_grid.get_child_count() == 0:
			push_error("La mision %s no renderiza tablero" % index)
			quit(1)
			return
	print("SmokeAllMissions OK: %s misiones arrancan y renderizan." % main.data.missions.size())
	quit()
