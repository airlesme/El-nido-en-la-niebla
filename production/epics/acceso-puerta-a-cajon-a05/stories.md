# Historias — Acceso: puerta A y cajón A05 (sistema 8, alcance M1)

> **Generado**: 2026-11-11 por `/create-stories` (modo `autonomous`, `review_mode: lean`)
> **Manifest Version**: 2026-11-11b · **Workflow**: standard · **Granularidad**: balanced
> **ADRs**: ADR-0001 Accepted · ADR-0002 Accepted · ADR-0005 Accepted · ADR-0009 Accepted · ADR-0011 Accepted · ADR-0012 Accepted · ADR-0004 **Proposed** (solo AC fuera de M1)
> **QL-STORY-READY**: omitido — modo Lean
> **Estimaciones**: días de una persona, confianza **BAJA** (sin historial de sprints).

| ID | Título | Tipo | Est. (días) | Depende de | Estado |
|----|--------|------|-------------|------------|--------|
| 001 | `access.json`: esquema completo, datos M1 (A, A05) y política de fallo | Logic | 1 (0,5–1,5) | épico contenido-y-datos | Ready |
| 002 | Estados derivados y configuración al arrancar (puerta A, A05) | Logic | 1 (0,5–1,5) | 001; épico estado-y-bus | Ready |
| 003 | Puerta A: `ABRIÉNDOSE` → `ABIERTA`, «puerta abierta» y curva 1,2 s | Logic | 1 (0,5–1,5) | 002 | Ready |
| 004 | Puerta A en escena: hoja, colisión con Jolt y paso del jugador | Integration | 1 (0,5–2) | 003; épicos jugador-primera-persona, carga-de-planta | Ready |
| 005 | Cajón `A05`: manejador, `HAND_DRAWER` o tope 3 s → `otorgar("A05")` | Integration | 1 (0,5–1,5) | 002; bolsillo 003; interacción 007 | Ready |
| 006 | Invariantes no-softlock M1 (P1 → A → A05) con capturas | Integration | 0,5 (0,5–1) | 004, 005; épico puzles-marco-y-p1 | Ready |

**Total Ready**: 6 historias · 5,5 días esperados (rango 3–9) · 0 Blocked.

## Decisión registrada (modo autónomo)

- **`access.json` en M1 lleva el esquema completo** (`doors[]`, `readers[]`, `drawers[]`, `elevator`) con datos solo de
  la puerta A y del cajón A05; `readers[]` vacío, puertas B/D ausentes y `elevator` con sus valores por defecto
  (2,0 / 8 / 20,0 s). **Alternativa descartada:** un esquema recortado a A/A05, porque obligaría a migrar esquema y
  CI al entrar las salas B/D (ADR-0005 D9, IDs estables) y la validación lector→tarjeta de TR-access-002 se perdería.

## Diferido / bloqueado por ADR

| Qué | TR / AC | Bloqueado por | Salida |
|-----|---------|---------------|--------|
| Guardado al abrir la puerta A (`door_opened:A` → causa de guardado) y AC-14 de GDD 8; reanudación desde guardado real | — (AC-14, AC-02 en su parte de carga) | **ADR-0004** (Proposed) | recorte 4 del hito (M2); en M1 «nace según hechos» se prueba con restore de 3 |

## Fuera del alcance de M1 (no por ADR)

- Puertas B y D con lectores `C06`/`C07`/`D06` y gesto de tarjeta: TR-access-010, -011, -017; AC-04, -05, -06, -08 (B/D), -15, -17, -21.
- Ascensor `C08` y `MEGA_03`: TR-access-013, -014, -015; AC-09, -10, -11, -18, -20.
- AC-16 completo (B, D, `C08`): en M1 solo el tramo P1 → A → A05 (story 006).
- TR-access-002 (mapa lector→tarjeta) entra solo como validación de datos en 001, con `readers[]` vacío en M1 y un fixture de prueba completo.
