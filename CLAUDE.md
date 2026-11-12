# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Proyecto: El Nido en la Niebla

Aventura/puzles en **primera persona 3D** (Godot). Alcance actual: vertical slice
«Turno de noche» (~15–30 min según el jugador, a medir en playtest) para enseñar y conseguir financiación.

- **Fuente de verdad del slice:** `design/slice/slice-v0.3.md` (prevalece sobre cualquier GDD general).
- **Puzles y referencia para el equipo externo:** `biblia/` (raíz). En mecánicas de puzle, `biblia/04-puzles.md` prevalece sobre el slice y sobre los GDD `puzle-*.md` y `caja-y-compartimentos.md` (usuario, 2026-11-12).
- **Plan técnico:** `docs/PLAN-TECNICO.md` · **Mapa de carpetas:** `README.md`.
- **Idioma:** documentación y diseño en español; código, identificadores y ADRs en inglés
  (los IDs del documento —`VO_G_12A`, `caja_c1`, `EV_PUZZLE_SOLVED_*`— se conservan tal cual).
- **Rama:** trabajo en `main` por el momento.
- **Fin de fase:** siempre que se termine una fase de trabajo (un GDD, una revisión, un
  ADR, un hito) se mergea directamente en `main` y se hace push, sin abrir PR. Decisión
  del usuario (2026-11-08): no hace falta volver a pedirlo en cada fase.

## Modo de trabajo por lotes (decisión del usuario, 2026-11-09)

Sustituye al ciclo Pregunta→Opciones→Decisión→Borrador→Aprobación *por documento*.

- **Lotes por tipo:** una sesión de diseño redacta 4–5 GDDs de la misma capa; otra
  sesión revisa todos (un subagente por GDD, sin el contexto del autor, en paralelo).
  `/review-all-gdds` al cerrar una capa.
- **Decisiones por defecto:** se decide con la recomendación propia y se registra en
  una sección «Decisiones tomadas» del GDD (alternativa descartada + motivo). Solo se
  pregunta lo que cambie pilares, tono o alcance del slice, o contradiga
  `design/slice/slice-v0.3.md`.
- **Sin permiso por archivo:** se escribe sin preguntar «May I write…?»; la
  aprobación es una sola, al final del lote, sobre un resumen de una página por sistema.
- **Git:** un commit por GDD, push al final del lote (ver Fin de fase).
- **Paralelismo:** GDDs independientes con subagentes a la vez; los que se tocan, en serie.
- **Calidad intacta:** las 8 secciones (o las de `modes.workflow`), revisión
  independiente y consistencia con el índice y el registro de entidades.
- `project.yaml`: `modes.automation: autonomous`.

## Technology Stack

- **Engine**: Godot 4.7
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

<!-- ENGINE-REFERENCE-IMPORT: the line below is engine-specific. /setup-engine
     rewrites it to @docs/engine-reference/<engine>/VERSION.md for the chosen
     engine, so a Unity or Unreal project stops loading the Godot reference every
     session. It defaults to Godot (the template's example engine); skills that
     need the pinned version read docs/engine-reference/<engine>/VERSION.md on
     demand regardless of this import. -->
@docs/engine-reference/godot/VERSION.md


## Technical Preferences

`project.yaml` at the repo root is the primary config store — engine, specialists,
naming, platform, performance, modes. Skills resolve it via `resolve_config`
(see `.claude/docs/config-resolution.md`).

`.claude/docs/technical-preferences.md` is the **legacy fallback**, read on demand
when a key is absent from `project.yaml`. It is not imported here: before
`/setup-engine` runs it is almost entirely `[TO BE CONFIGURED]` placeholders, and
after it runs `project.yaml` holds the real values.

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
  (exempt: `active.md` appends, agent memory, a subagent's new file at the path
  its orchestrating skill named; see `.claude/rules/agent-memory.md`)
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction
- A skipped or dismissed question is not an answer: act on nothing, re-ask in
  plain text and wait
- Started outside this file's folder? Warn first: hooks, deny rules and the
  ask-first mode load only when Claude Code starts here

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

Read `.claude/docs/context-management.md` on demand — it is a reference, not
session context. Two of its conventions are load-bearing and cited by name
elsewhere in the repo, so they are restated here rather than lost:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or
  `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.** A script
  that scores or judges will eventually contradict a mode or override it cannot
  see. (Cited by `artifact-check.sh` and `adr-dep-graph.sh`.)
