# Story 025: Escala de UI del prompt (F2) y suelo de texto de 24 px

> **Epic**: Interacción y prompt (mitad Prompt)
> **Status**: **Blocked** — GDD 24 contradice ADR-0007 D7 / ADR-0016 (ver «Pregunta abierta»)
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S — 1 día (0,5–1,5), confianza BAJA (depende de la resolución de la pregunta)
> **Manifest Version**: 2026-11-11b
> **Last Updated**: —

## Context

**GDD**: `design/gdd/prompt-de-interaccion.md` — § Formulas F2; § Detailed Rules › D regla 24 y E regla 30; D24-15; AC-24-14 (parte de píxeles físicos)
**Requirement**: `TR-prompt-018` (**parte**: escala `s`, redondeo y rango 720p–2160p; la parte de márgenes/ultraancho es de la 015) y `TR-prompt-015` (**parte**: «texto ≥ max(28·s, 24) px»)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (D7.2 «24 F2 → `s` es la del motor; 24 no multiplica nada», D7.3 «el suelo de 24 px es **lógico**, validado en datos»); ADR-0016 (D3 suelo en validación, G-4 «ningún script computa ventana/1080»)
**ADR Decision Summary**: todos los tamaños de UI son px lógicos a la base 1920×1080 y el stretch del motor aplica `s`; `ui_escala_min/max` son el **rango de resoluciones soportado**, no un clamp calculado; el suelo de 24 se impone al **validar datos** (tema y `text_sizes.json` < 24 = error de CI), no con un `max()` en ejecución. A 720p el texto de 24 lógicos mide 16 px reales.
**ADR Version**: ADR-0007 2026-11-10 · ADR-0016 2026-11-10

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: la fracción de escala (`fractional`) y el tamaño mínimo de ventana están en SP-2 de ADR-0007 (parcial/NEEDS_WINDOWED); `Window.get_final_transform().get_scale()` = `s` exacta (SP-1).

**Control Manifest Rules (this layer)**:
- Required: P-R04; F-R18.
- Forbidden: calcular `alto_ventana/1080` o escribir `content_scale_factor` (ADR-0016 G-4); `max()` de suelo en tiempo de ejecución (ADR-0007 D7.3).
- Guardrail: validación en carga/CI, coste cero por fotograma.

**Decisiones de usuario ya cerradas que la afectan**: **nº 5** (2026-11-12): subtítulos/texto a 720p **escalan con la ventana con un suelo legible definido en 26** (D26-22 cerrada); **nº 3**: `escala_texto_ui` se da por cerrada. Ninguna de las dos confirma explícitamente **QQ-10** (suelo de 24 px lógicos, «USER confirmation pending» en ADR-0007 D7.3; G18 en el hito M1) ni dice si el suelo de 26 es el de 24 lógicos o uno en px físicos.

---

## Pregunta abierta (motivo del bloqueo)

El GDD 24 (F2, R24, AC-24-14, TR-prompt-015/-018) define `s = clamp(altura/1080, 0,67, 2,0)`, redondeo a entero y «≥ 24 px **físicos**» (texto `max(28·s, 24)`). ADR-0007 D7 / ADR-0016 (Accepted) mandan px lógicos, sin factor de ventana y suelo de 24 **lógicos** en validación (16 px reales a 720p). Son incompatibles en 720p. ADR-0016 lo registra como C1/OI-5 («GDD 24 F2/TR-prompt-015/-018 siguen con el factor de ventana; reread por ADR-0007 D7, G18, QQ-10») pendiente de «GDD 24 próxima ronda». **No se resuelve aquí.**

`TODO(ui-owner)`: decidir (a) que el suelo de 24 px es lógico (ADR-0007) y enmendar F2/AC-24-14/TR-prompt-015/-018 en el GDD 24, o (b) que sea físico y enmendar ADR-0007 D7.3. Mientras tanto, 023 implementa el pie en px lógicos de `PromptConfig` y esta historia no entra en el Sprint 4.

---

## Acceptance Criteria

*Provisionales, a reescribir tras la decisión (opción a: ADR-0007 prevalece):*

- [ ] **AC-24-14 (píxeles)**: en 720p, 1080p y 2160p el texto del pie y la etiqueta miden lo que dice la regla que se confirme (lógico 28 → 19/28/56 reales con la opción a) y **ningún** tamaño de `prompt.json`, del tema ni de `text_sizes.json` es < 24 lógicos (error de validación, CI).
- [ ] `ui_escala_min/max` se usan solo como rango soportado (resoluciones 720p–2160p), sin calcular `s` en código; grep en CI: sin `/ 1080` ni `content_scale_factor` en `src/ui/prompt/`.
- [ ] Anillo y etiqueta no se escalan con `escala_texto_ui`; el pie lo hace solo si se confirma que existe (ver 023).

---

## Implementation Notes

- Si se elige la opción a, la historia se reduce a un test de validación de datos + CI y a la captura a tres resoluciones de 024.

---

## Out of Scope

- Márgenes 5 % y ultraancho: 015. Cambios en el GDD 24 o en ADR-0007: los hace su dueño, no esta historia.

---

## Files

- `tests/unit/prompt/text_floor_validation_test.gd`, `src/ui/prompt/prompt_config.gd` (validación; ya creado en 014)
- Evidencia: `production/qa/evidence/prompt-evidence.md` (ampliación)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/prompt/text_floor_validation_test.gd` — debe existir y pasar, tras reescribir los AC.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: resolución de la pregunta abierta (game-designer / user); 014, 015, 023
- Unlocks: cierre de TR-prompt-015 y TR-prompt-018 en su totalidad
