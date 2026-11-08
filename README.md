# El Nido en la Niebla

Juego de puzles y misterio en **primera persona 3D**, hecho con **Godot 4**.
Vertical slice actual: **«Turno de noche»** (25–30 min, un piso de oficinas, seis puzles, una llamada y un final con variaciones).

> Objetivo inmediato: tener un slice jugable y con calidad final en lo que se muestra, para enseñarlo y conseguir financiación.

## Documentos clave

| Documento | Qué es |
|---|---|
| [`design/slice/slice-v0.3.md`](design/slice/slice-v0.3.md) | **Fuente de verdad del slice** (v0.3 + anexos A–D). |
| [`design/slice/README.md`](design/slice/README.md) | Índice del documento: dónde vive cada cosa en el repo, decisiones abiertas e incoherencias detectadas. |
| [`docs/PLAN-TECNICO.md`](docs/PLAN-TECNICO.md) | Plan de acción técnico: motor, arquitectura, hitos y primeros pasos. |
| [`CLAUDE.md`](CLAUDE.md) | Configuración del «game studio» de agentes (Claude Code Game Studios). |

## Estructura del repo

```
CLAUDE.md, project.yaml     Config del estudio de agentes (project.yaml = fuente de verdad)
.claude/                    49 agentes, 74 skills, hooks y reglas (Claude Code Game Studios)

design/                     Diseño (no tocar a mano lo de slice/ sin versionar)
  slice/                    Documento del slice (fuente de verdad) + índice
  gdd/                      GDDs por sistema (/design-system, /map-systems)
  narrative/                Guion, línea temporal, lore
  levels/                   Planos y blocking de los espacios (Anexo A)
  art/                      Art bible, paleta, referencias
  audio/                    Dirección de audio, lista de VO/SFX
  registry/                 Registro de entidades (lo gestiona el estudio)

src/                        Código GDScript (raíz de código de Godot)
  core/                     Autoloads: EventBus, GameState, SaveSystem, Settings
  player/                   Cámara/movimiento en 1.ª persona, manos
  interaction/              Raycast, prompt contextual, inspección de objetos
  puzzles/                  PuzzleBase + los 6 puzles
  world/                    Puertas, lectores de tarjeta, triggers de zona, luces
  narrative/                Escenas 1–8, director de eventos, llamada
  ui/                       HUD, ordenador, menú de pausa, pistas, subtítulos
  audio/                    AudioDirector, megafonía, ambientes
  systems/                  Inventario (bolsillo visual), pistas, accesibilidad

scenes/                     Escenas .tscn (levels/, props/, puzzles/, ui/)
assets/                     art/, audio/, shaders/ y data/ (JSON: líneas, flags, puzles)
tests/                      unit/, integration/, playtest/
tools/                      Scripts de build, export y pipeline de assets
prototypes/                 Prototipos desechables (fuera de src/)
docs/                       architecture/, decisions/ (ADRs), engine-reference/ (API Godot pinneada)
production/                 sprints/, milestones/, playtests/ (+ session-state local)
studio-tests/               QA de las propias skills (no del juego)
```

La raíz del proyecto Godot es la raíz del repo (`project.godot` se creará aquí con `/setup-engine`).

## Cómo trabajar con el estudio de agentes

Abre Claude Code en la raíz del repo (para que carguen hooks y reglas) y sigue el orden del
[plan técnico](docs/PLAN-TECNICO.md#6-primeros-pasos-con-las-skills). Resumen:

```
/start  →  /setup-engine godot 4.7  →  /art-bible  →  /map-systems  →  /create-architecture  →  /create-epics  →  /create-stories
        →  /sprint-plan  →  /dev-story ↔ /story-done
```

El estudio colabora, no ejecuta solo: cada agente pregunta antes de escribir. Detalle en
[`docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`](docs/COLLABORATIVE-DESIGN-PRINCIPLE.md) y
[`docs/WORKFLOW-GUIDE.md`](docs/WORKFLOW-GUIDE.md).

## Créditos y licencias

El estudio de agentes proviene de
[Claude Code Game Studios](https://github.com/donchitos/claude-code-game-studios) (MIT).
Su README y licencia originales están en [`docs/vendor/ccgs/`](docs/vendor/ccgs/). Para actualizar el
framework, consulta [`UPGRADING.md`](UPGRADING.md).

El contenido del juego (diseño, guion, arte, código propio) es propiedad del autor; licencia por definir.
Registro de herramientas de IA usadas por asset: pendiente (ver sección 18 del slice).
