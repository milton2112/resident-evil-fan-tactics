# Zona Cero Tactica

Prototipo fan no comercial de tactica por turnos y survival horror, hecho en Godot 4.6.

## Jugar

### Opcion 1: Godot

1. Abrir Godot 4.6 o superior.
2. Elegir `Import`.
3. Seleccionar `godot/project.godot`.
4. Presionar `F5`.

### Opcion 2: Builds

Las builds se generan en `godot/dist` cuando estan instaladas las export templates de Godot:

- Web: `godot/dist/web/index.html`
- Windows: `godot/dist/windows/ZonaCeroTactica.exe`

## Estado actual

- Sprites recortados desde hoja visual de referencia.
- Mapas distintos por mision desde `godot/data/game_data.json`.
- Escenas reutilizables para unidad, tile, prop, puerta, obstaculo y efectos.
- Combate con movimiento por pathfinding, obstaculos, puertas, cobertura, linea de vision, AP, granadas, curacion, criticos, overwatch basico y roles enemigos.
- UI de menu, selector de faccion/mision, panel de unidad, log de combate y pantalla de titulo.
- Audio base para musica, UI, disparos, pasos, golpes y victoria/derrota.
- Presets de exportacion Web y Windows.

## Controles

- Click en una unidad para seleccionarla.
- `Mover`: click en una casilla valida.
- `Atacar`: click en un enemigo con linea de vision y rango.
- `Granada`: ataque de area.
- `Curar`: cura a una unidad aliada adyacente.
- `Overwatch`: guarda la accion y dispara si un enemigo se acerca.
- `Terminar turno`: pasa a la IA enemiga.

## Aviso legal

Este proyecto es un prototipo fan no comercial. No usa logos oficiales y debe mantenerse como obra original inspirada en survival horror tactico si se comparte publicamente.
