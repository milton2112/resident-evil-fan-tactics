# Migracion a motor

## Recomendacion

Para este proyecto conviene migrar a Godot antes que Unity si quieren avanzar rapido:

- Godot es liviano.
- Exporta facil a web y escritorio.
- El sistema 2D/isometrico es suficiente para este juego.
- No obliga a manejar un pipeline 3D pesado desde el primer dia.

## Estructura sugerida en Godot

- `MainMenu.tscn`: titulo, tutorial, continuar.
- `CampaignMap.tscn`: mapa de misiones, tienda y progreso.
- `BattleScene.tscn`: tablero tactico.
- `Unit.gd`: vida, movimiento, ataques, estados.
- `Tile.gd`: cobertura, puerta, obstaculo, spawn.
- `AIController.gd`: prioridades enemigas.
- `CampaignSave.gd`: guardado local.
- `AudioManager.gd`: musica, FX y volumen.

## Migracion por etapas

1. Replicar el tablero y movimiento.
2. Importar sprites y sonidos desde `assets/`.
3. Migrar unidades, armas y B.O.W.s.
4. Migrar misiones y progreso.
5. Rehacer UI nativa.
6. Exportar a web para compartir.

## Unity

Unity conviene si luego quieren 3D real, modelos animados, camaras complejas o publicar en muchas plataformas. Para el estado actual, seria mas trabajo inicial.
