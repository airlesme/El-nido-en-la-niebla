# M1 cola de diseño, lote C (entrada, ajustes, arquitectura, registro) · 2026-11-11

Fuente: `docs/architecture/adr-reconciliation-2026-11-10.md` § 2 y Open Items de ADR-0006 / ADR-0007.
Ninguno contradice `design/slice/slice-v0.3.md` (el slice no menciona estos puntos).

| Cambio | Fichero | Estado | Línea / nota |
|---|---|---|---|
| G15 «tecla imprimible» → conjunto que consume el campo de texto | `design/gdd/entrada-y-controles.md` | aplicado | reglas 17 y 20 (l. 95, 98), AC-17 (l. 482); D37 |
| G16 / H28 consultar `bindings_revision()` | `design/gdd/entrada-y-controles.md` (lado 1) | aplicado en 1 | regla 24 (l. 117), OQ 19 cerrada (l. 545); D38. **Pendiente en el GDD 24 (prompt), de otro agente** |
| G19 `escala_texto_ui` cerrada (18 claves) | `design/gdd/ajustes-persistentes.md`, `design/registry/entities.yaml` | aplicado | regla 1 (l. 45), OQ 15 (l. 391), registro `escala_texto_ui` (l. 3486); D-6.11 |
| G21 sin aviso si el modo aplicado no cambia | `design/gdd/ajustes-persistentes.md` | aplicado | Edge Cases (l. 212), AC-13 (l. 341); D-6.12 |
| G21 adoptar `.tmp` huérfano si falta el principal | `design/gdd/ajustes-persistentes.md` | aplicado | Edge Cases (l. 192), AC-15b (l. 348); D-6.12 |
| A3 Data Flow 5: 4 abre `sin control` tras «iniciada» | `docs/architecture/architecture.md` | ya aplicado | l. 435: «4 abre `sin control`(4, D_carga) en 1 (SYNC, justo tras emitir «iniciada»; ADR-0003 D6)» |
| A4 liberar el título no es «descarga» | `docs/architecture/architecture.md` | ya aplicado | l. 224-225 |
| A6 QQ-14 nivel L y nivel B | `docs/architecture/architecture.md` | ya aplicado | l. 896: «Resuelta por ADR-0005 D3.2 (nivel L en `planta` y nivel B en arranque)» |
| A8 ruta `assets/data/state/flags.json` | `design/gdd/reviews/cross-review-r9-esquema-v2.md` | aplicado | l. 6 |
| A8 nota sobre `tr()` | `docs/engine-reference/godot/modules/ui.md` | aplicado | sección «Localization-Ready UI» y «Common Mistakes» |
| G18 suelo de 24 px (QQ-10) | — | no tocado | [U] decisión del usuario |
