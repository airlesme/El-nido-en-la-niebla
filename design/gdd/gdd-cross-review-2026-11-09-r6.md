# Cross-GDD Review Report (ronda 6 · verificación de las correcciones de la ronda 5)

**Fecha:** 2026-11-09 · **Veredicto: CONCERNS** (0 bloqueantes) · **Modo:** autonomous, workflow standard · **Focus:** since-last-review (14 GDDs, solo lo cambiado)
Informes anteriores: `gdd-cross-review-2026-11-09.md` (8 bloqueantes), `-r2` (2), `-r3` (2), `-r4` (CONCERNS), `-r5` (FAIL, 1: E4-1).

- **GDDs reviewed:** 14 of 14 present. Tres revisores independientes (Grep y Read): 1 (E4-1), 2 (W-1…W-9 y simetría de dependencias), 3 (F9, diseño y valores †). Cada uno escribió borrador a disco antes de terminar; ninguno agotó su límite de turnos.
- **Decisiones del usuario respetadas:** las de rondas anteriores y las 5 aprobadas el 2026-11-09 (`repasar_bolsillo`, `I-05`/`I-06a` releíbles, B.1 literal, `MEGA_03`, zonas `T-D-OUT`/`T-OFI-IN`; slice v0.4).

## Estado del bloqueante de r5

| Bloqueante | Estado | Evidencia |
|---|---|---|
| **E4-1** («Nueva partida» desde la pausa durante la escena 1: pila [menú, sin control(21), menú]) | **CERRADO** | Revisor 1 recorrió ocho formas de pila (Nueva partida/Continuar desde [menú]; escena 1 en curso con pausa; pausa durante otra escena dirigida; fallo de carga tras absorber; cierre durante la carga; «Volver al título» desde Recepción): 1 regla 6/AC-E13c, 4 regla 9 paso 3/regla 15/AC-21b y 21 reglas 1, 11b, 22/AC-21-23b y AC-21-29 pueden pasar a la vez; el `sin control` ajeno no puede caducar porque ya no existe y el tope `D_carga` + 2 s se abre sobre una pila limpia. Los avisos «sin control absorbido» y «descarga total solicitada» coinciden en 1, 3 (regla 10), 4 (regla 15), 21 y el registro. |
| W-1 (re-inspección tras fallo) | **CERRADO** | 5 reglas 17/18/24/29 y AC-18, 18d, 18g, 36b, 38c consistentes con 4 |
| W-9 (`BOX_OPEN_MAX`, `fov_step_deg`, †) | **CERRADO** | un solo dueño (10) |
| W-2 (`sostener` de 2 frente a 7) | **PARCIAL** | firma alineada; sigue abierto si la pieza del P3 es sostenible (7 solo admite `V05`) y AC-47 de 2 usa `derecha` donde 7 regla 13 manda `izquierda` |
| W-3/W-4/W-5/W-6/W-7 | **PARCIAL** | quedan los avisos de abajo |

---

## Consistency Issues

### Blocking
Ninguno.

### Warnings

⚠️ **R6-1 · Dureza y reciprocidad de dependencias (11 discrepancias).** 20 dice Indirecta con 4 y con 5, y estos dicen Dura y Blanda. 9 declara 20 como Blanda (:463) y como Indirecta (:477). 9 dice 21 Indirecta y 21 dice 9 «Sin dependencia». El índice trata 1, 5 y 21 como indirectas de 10 y 10 y 1 declaran otra dureza. El texto de 20 :216 sobre 1 está obsoleto. El índice no lista 10 en la fila 20 ni las dependencias duras de 1 en la fila 1; 8↔20 difiere en la dirección declarada. *(Revisor 2.)*
⚠️ **R6-2 · Restos de nombres y textos desfasados.** «repasar bolsillo» sin guion bajo en 18 (:134, :370), 3 (:330), 5 (:560, :583), 2 (:584) y el log de 20 (:355). `BOX_Cn_OPEN` sin marcar como sustituida en `systems-index.md:253` y `ajustes-persistentes.md:383`; 10 la usa como notación genérica y en :336 aún pide «actualizar»; `entities.yaml:519` dice «pendiente de actualizar 7» (ya hecho). *(Revisor 2.)*
⚠️ **R6-3 · W-2 restante.** AC-47 de 2 usa `derecha` y 7 regla 13 manda `izquierda`; 2:112 documenta `sostener(item_id, izquierda)` con dos argumentos frente a los tres de la firma; sigue abierto si la pieza del P3 es sostenible. *(Revisor 2.)*
⚠️ **R6-4 · Pila.** (a) `ESC8_CIERRE` abre su `sin control` sobre `exploración`: la pila real con pausa es [exploración, sin control(21), menú], que la tabla de 1 y 4 y los ACs no listan (el texto general la cubre). (b) 1 y 3 llaman `continuar` a la causa; 4 regla 7 define el motivo como `reanudar`. (c) 21 regla 1 borra su estado «al pasar a inactivo», pero la regla 11c, el Edge Case :174 y AC-21-23a dicen que lo borra al recibir «completada». (d) La fila E7-1 de Decisiones del 4 (:400) descarta lo mismo que hacen ahora las reglas 1 y 15. (e) Falta la fila «Nueva partida desde la pausa en la planta». (f) AC-E13c y AC-21-23b necesitan una carga forzada larga. (g) No queda claro si una descarga total pasa por el reinicio de pila. *(Revisor 1.)*
⚠️ **R6-5 · N4-2.** 9 AC-59 («un `atrás` durante `Saliendo` de `D01d` lo consume la vista») y 1 AC-E17 (`repasar_bolsillo` en transición bloqueante) pueden chocar si la pila ya es `exploración` durante `Saliendo`. *(Revisor 2.)*
⚠️ **R6-6 · Tiempo (F9 de 9).** Errata: «13,5 min» en F9, OQ10 y D9-61 son 10,5 + 0,8 + 2,0 = 13,3 (el 13,5 viene de r5). El mínimo de cargas (0,2 min = 12 s) queda por debajo de su fuente (11,7 + 12 s = 23,7 s). Las escenas de 21 no son «fijas»: `ESC8_CIERRE` usa topes (8 s por línea) y margen de 1 s, y el mínimo se sobreestima unos 0,3 min. *(Revisor 3.)*
⚠️ **R6-7 · Valores sin fuente ni †.** `t_mostrar_item_s` y `t_tapa_s` (20 :331–332); `card_read_delay_s`, `drawer_a05_open_s`, `door_open_angle_deg`, `elevator_deny_line_cooldown_s` y `elevator_in_use_timeout_s` (8 :329–334). *(Revisor 3.)*
⚠️ **R6-8 · AC-X5 (9).** Verificable solo a medias: faltan el método de cronometraje, los hitos de inicio y fin, las exclusiones y el umbral por componente; el slice §23 habla de 5 testers y AC-X5 de ≥ 6. *(Revisor 3.)*

---

## Game Design Issues (revisor 3)

### Blocking
Ninguno. Sin riesgo nuevo de pilar o anti-pilar. D-W1, D-W4 (sin mitigación; el slice :738 la confirma), D-W5, D-W8, D-W9, D-W10, D-W11 siguen vigentes; D-W6 cerrado.

### Warnings

⚠️ **R6-9 · El criterio de 25–30 min no está demostrado (decisión tuya pendiente).** Slice L6 y §19.1 y `game-concept.md` (L24, L110) afirman 25–30 min; F9 de 9 da mínimo 15,0, techo 33,2 min. La Open Question 10 ofrece (a) subir contenido/duración hasta 25–30, (b) bajar el techo, (c) corregir el criterio del slice al rango medido; no propone opción por defecto ni dice que el mínimo queda unos 10 min por debajo de 25. El slice §22 L495 («ningún puzle requiere más de dos minutos») choca con F7 (P1 2–4, P2 3–6, P4 2–4).
ℹ️ INFO: `EN_USO` de `C08` (20 s† sin pie, solo si falla 21 o 4) a vigilar.

---

## Cross-System Scenario Issues
Sin escenarios nuevos esta ronda. E4-1 y N-escenarios de r5 sin cambios salvo los avisos R6-4/R6-5. E6 (llamada) sigue sin recorrer: 22 sin GDD.

---

## GDDs Flagged for Revision

| GDD | Motivo | Tipo | Prioridad |
|---|---|---|---|
| marco-de-puzles.md (9) | R6-1, R6-6, R6-8, R6-5 | Consistency | Warning |
| documentos-y-bolsillo.md (20) | R6-1, R6-2, R6-7 | Consistency | Warning |
| entrada-y-controles.md (1) | R6-1, R6-4 | Consistency | Warning |
| escena-de-planta.md (4) | R6-4 | Consistency | Warning |
| director-de-escenas.md (21) | R6-1, R6-4 | Consistency | Warning |
| control-de-acceso.md (8) | R6-1, R6-7 | Consistency | Warning |
| jugador-en-primera-persona.md (2) | R6-3, R6-2 | Consistency | Warning |
| interaccion-e-inspeccion.md (7) | R6-3 | Consistency | Warning |
| caja-y-compartimentos.md (10) | R6-2 | Consistency | Warning |
| base-de-contenido-narrativo.md · estado-y-bus-de-eventos.md · guardado-y-carga.md · ajustes-persistentes.md | R6-2 | Consistency | Warning |
| systems-index.md · entities.yaml | R6-1, R6-2 | Consistency | Warning |

## Verdict: CONCERNS

Sin bloqueantes. Todos los bloqueantes de las seis revisiones están cerrados y verificados por un revisor distinto del autor. Los avisos son de redacción, simetría de dependencias, nombres y cobertura de ACs, salvo R6-9, que es una decisión de alcance del slice y no se resuelve editando GDDs.

### Required actions before architecture
1. Decidir el criterio de duración del slice (R6-9): subir contenido, bajar el techo o corregir el criterio al rango medido (lo decide el usuario; la recomendación de este informe es (c) provisional, corregir a «~15–30 min medidos» y medirlo con AC-X5).
2. Limpieza de R6-1…R6-8 (un lote corto, ~1 sesión).
3. Escribir el GDD 22 (llamada), de cuyo contrato dependen 8, 21, 9 y 5, antes de dar la capa Feature por cerrada.

---

## Cobertura (qué no se pudo revisar)
**NOT ASSESSED:** revisor 1 no leyó 5 (reglas 17 y 29 solo por grep), 7, y de 1 y 4 los apartados Dependencies y Tuning Knobs; revisor 2 no leyó las reglas 14 y 15 de 4, 7 regla 27b y D7-63, N1-1 y N5-1, las Dependencies de 3, 6 y 18 ni 19 completo; revisor 3 no leyó el Tuning de 10 y 19, las reglas completas de 21, el slice §11 y §13, ni `game-pillars.md`. Heredado: E6 (llamada) no recorrido; sin GDDs de 22, 23, 24, 25, 27, 28; NOT SOURCEABLE: `AnimationPlayer`/`SceneTree.paused`/`AudioStreamPlayer`/`Area3D`-Jolt.
