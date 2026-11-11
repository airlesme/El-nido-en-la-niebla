# Story 007: Correos (registro único, orden explícito, etiquetas) y fichas

> **Epic**: Contenido narrativo y datos validados
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S (≈ 0,5 días, confianza BAJA)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/base-de-contenido-narrativo.md` § Detailed Design › Core Rules, reglas 11–13 (un dato, un registro; orden explícito; etiquetas)
**Requirement**: `TR-content-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Data schema validation and content catalog (D6 `get_mail`, `get_mail_order`, `get_task`)
**ADR Decision Summary**: Día, hora, remitente, asunto y etiquetas de cada correo viven en un único registro; el orden de presentación es una lista explícita en datos; `ContentDB` no expone búsqueda (la hace 19).
**ADR Version**: 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: ninguna.

**Control Manifest Rules (this layer)**:
- Required: F-R53 (arrays de registros con `id`), F-R58
- Forbidden: búsqueda en `ContentDB`
- Guardrail: —

---

## Acceptance Criteria

*From GDD `design/gdd/base-de-contenido-narrativo.md`:*

- [ ] **AC-11 (parte L)**: el correo 2 tiene lunes 09:14 en un único registro (`day`, `sent_min`); la impresión `I-01` es de 19 (fuera).
- [ ] **AC-12**: la lista de presentación es la de los datos: numerados 3, 1, 4, 2; completa 3, X1, 1, 4, X2, 2; ordenados por (día, hora) dan el orden del GDD.
- [ ] **AC-12b**: `MAIL_X1`/`MAIL_X2` tienen remitente, asunto y cuerpo no vacíos; X1 lunes 10:30, X2 martes 14:00.
- [ ] **AC-13**: los correos 1–4 incluyen la etiqueta «transición»; los dos de ruido no; no hay método de búsqueda público.

---

## Implementation Notes

- Firmas (ADR-0005): `get_mail(id) -> ContentMail` (`{found, ref, sender, subject, body, day, sent_min, tags}`), `get_mail_order() -> Array[StringName]`, `get_task(id) -> ContentTask`.
- Fichas T1–T4: solo el getter y su esquema; sus datos son de M2 (caja fuera de M1). AC-12b «ninguno nombra a un personaje» es revisión humana del texto (009).

---

## Out of Scope

- Búsqueda «transición» e impresión `I-01` (ordenador-e-impresora).

---

## Files

- `src/narrative/content_db.gd`, `src/narrative/content_mail.gd`, `src/narrative/content_task.gd`
- `tests/unit/content/mails_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content/mails_test.gd` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/contenido-y-datos/story-004-content-db-load-and-lifecycle.md`
- Unlocks: `production/epics/contenido-y-datos/story-009-m1-narrative-data.md`
