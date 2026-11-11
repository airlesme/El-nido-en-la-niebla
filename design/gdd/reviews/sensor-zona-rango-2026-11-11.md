# Corrección del rango del sensor de zona (2026-11-11)

Decisión del usuario: corregir el rango documentado en lugar de añadir la caja aritmética (Alternativa 5 del ADR-0003 descartada).
Medido en el spike S-0003-B (fila S-0003-B.1), Godot 4.7.2 + Jolt: Jolt reporta la entrada en el primer tick DESPUÉS de que la superficie cruza la cara.
Fórmula correcta: `X_activación = 9,0 − radio + (0, v·dt]`; con radio 0,05 y v·dt = 0,0267: (8,95; 8,977] (observado 8,95013–8,97653).

## Ficheros editados
- `design/gdd/jugador-en-primera-persona.md`: regla 4 (resumen, l.38), l.335 (nota a Escena de planta), knob `radio_sensor_zona` (l.358), D-24 (l.481), AC-09 (l.517, sigue PV, valor medido anotado), nueva fila D-46 en «Decisiones tomadas».
- `design/gdd/escena-de-planta.md`: regla 18(c) (l.78), fila `T-PAS-1` de «Decisiones tomadas» (l.386, con alternativa descartada y motivo), l.440 (historial de ronda 3 marcado como histórico y corregido). AC-05a/b no citan el rango: sin cambios.
- `docs/architecture/adr-0003-scene-loading-and-sin-control-handoff.md`: D8 (l.~224, nota «Resolved 2026-11-11»), R2 (l.~720), criterio de S-0003-B (l.~818), nuevo Open Item O8 «Resuelto 2026-11-11: rango corregido a (8,95; 8,977], Alternativa 5 descartada». Estado `Proposed` intacto. La tabla de resultados del spike (S-0003-B.1) queda como histórico.
- `docs/architecture/tr-baseline-provisional.md` y `docs/architecture/tr-registry.yaml`: TR-player-003.

## Sin cambios
- `design/registry/entities.yaml`: no contiene el rango.
- `design/gdd/reviews/*`, `gdd-cross-review-*`: registro histórico.
- `design/slice/slice-v0.3.md`: solo cita «X entre 9,0 y 10,0».

## Verificación
Grep de `8,923`/`8.923`: solo quedan menciones de «antes/histórico» (ADR-0003 l.228, 898 y spike; escena-de-planta l.386 y 440; jugador D-46) y las reviews. `8.923` con punto: ninguna.
YAML: no validado (el agente no dispone de Bash); la edición en `tr-registry.yaml` solo cambió texto dentro de una cadena entre comillas dobles, sin comillas nuevas. Ejecutar: `python -I -c "import yaml;yaml.safe_load(open(r'C:\dev\personal\el-nido\docs\architecture\tr-registry.yaml',encoding='utf-8'))"`.
