# Game Concept: El Nido en la Niebla

*Created: 2026-11-08*
*Status: Draft — derivado del slice v0.3 (`design/slice/slice-v0.3.md`); pendiente de revisión del autor*

> **Origen de este documento.** No se ha inventado nada: cada sección sale del slice v0.3 (que prevalece sobre cualquier otro documento). Lo que el slice no dice figura como **«Pendiente»** y no se rellena por inferencia.

---

## Elevator Pitch

> Es una aventura de puzles en primera persona donde, en el turno de noche de una oficina bajo la lluvia, reconstruyes con correos, memorandos y objetos qué se firmó a tu nombre, y decides qué responder a quien lo hizo.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Aventura narrativa de puzles en primera persona (misterio íntimo, sin combate) |
| **Platform** | PC (Windows y Linux), teclado/ratón y mando |
| **Target Audience** | Pendiente (ver «Target Player Profile») |
| **Player Count** | Un jugador |
| **Session Length** | Slice: 25–30 minutos |
| **Monetization** | Pendiente. Objetivo inmediato: enseñar el slice para conseguir financiación |
| **Estimated Scope** | Slice: ~6–7 semanas (ver `docs/PLAN-TECNICO.md`). Versión completa: pendiente (el slice sirve para medirlo, objetivo 6 del §2) |
| **Comparable Titles** | Pendiente de confirmar por el autor |

---

## Core Fantasy

Eres Vera, una líder recién trasladada que se queda a trabajar de noche y descubre que alguien actuó en su nombre. La promesa emocional no es ganar, sino **entender sin que nadie te lo confirme**: reconstruir una verdad incompleta a partir de papeles que se contradicen, y elegir qué hacer con ella. Afecto y daño pueden coexistir; el juego no te dice qué sentir.

---

## Unique Hook

«Es como una aventura de investigación en oficina, **y además** cada puzle responde a una pregunta de la historia o te obliga a una elección, y esas elecciones se ven reflejadas después (la carta que escribes cambia la primera frase de la llamada; tu respuesta cambia la última línea de Vera).»

Un solo puñado de decisiones, pocas pero visibles. No hay moral binaria, ni barra de relación, ni castigo.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** | 3 | Luz, reflejos, lluvia y silencio expresan la emoción (§4, §14, `design/art/art-bible.md`) |
| **Fantasy** | 4 | Ser Vera en primera persona; manos visibles |
| **Narrative** | 1 | Cronología reconstruida con documentos; ambigüedad deliberada (§9) |
| **Challenge** | 5 | Seis puzles deducibles con información del juego; nunca bloquean (§10) |
| **Fellowship** | N/A | Un jugador; la relación con El Guardián es narrativa, no social |
| **Discovery** | 2 | Buscar información → resolver puzle → descubrir historia (§2) |
| **Expression** | 6 | Solo a través de pocas elecciones: carta y respuesta de la llamada |
| **Submission** | N/A | La tensión es central; hay silencios largos pero no es un juego de relajación |

*(El orden es una propuesta derivada del slice: confirmarlo con el autor.)*

### Key Dynamics (Emergent player behaviors)
- El jugador **elige qué mirar** y reconstruye la línea temporal por su cuenta (pilar «Autonomía como progresión»).
- Compara fuentes que se contradicen (formulario, correos, memorando) y forma su propia hipótesis.
- Se detiene a escuchar: hay silencio parcial en los puzles para que se oigan las pistas.
- Comenta la ambigüedad («¿firmó ella o no?»), que es lo que se quiere medir en el playtest.

### Core Mechanics (Systems we build)
1. **Búsqueda y lectura de documentos** (ordenador, impresora, formulario, correos).
2. **Puzles de estado sin castigo** (cronología, lámparas/reflejo, encaje, tablero de tareas, espejo, decisión).
3. **Progresión por banderas** (puertas, tarjetas, caja con compartimentos encadenados).
4. **Elecciones con reflejo posterior** (carta A/B/C → llamada; respuesta A–D → final).
5. **Atmósfera reactiva** (luces, reflejos, sonido espacial, megafonía) como lenguaje narrativo.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Decide qué mirar, aceptar y responder; ninguna opción es «la correcta» en el puzle 6 ni en la llamada | Core |
| **Competence** | Cada puzle es deducible con información del juego y tiene hasta tres niveles de pista (dos en el P6) | Supporting |
| **Relatedness** | Vínculo ambiguo con El Guardián a través de voz y documentos; nunca aparece en pantalla | Core |

### Player Type Appeal (Bartle Taxonomy)
- [ ] **Achievers** — no es el foco
- [x] **Explorers** — buscan, comparan documentos, reconstruyen la historia
- [ ] **Socializers** — no aplica
- [ ] **Killers/Competitors** — no aplica

### Flow State Design
- **Onboarding curve**: ordenador → impresión → primer puzle (cronología) → primera puerta; cada paso enseña un verbo (buscar, leer, colocar).
- **Difficulty scaling**: los seis puzles tienen funciones distintas; ninguno requiere más de dos minutos (§22).
- **Feedback clarity**: cada acción tiene feedback visual y sonoro, correcta o no (§16).
- **Recovery from failure**: inmediata y sin penalización; no hay muerte ni game over (pilar 4).

---

## Core Loop

### Moment-to-Moment (30 seconds)
Caminar a velocidad de paseo, mirar, interactuar con un único botón contextual, girar objetos en la mano y leer con pulsación prolongada.

### Short-Term (5-15 minutes)
Buscar información → resolver un puzle → descubrir una pieza de historia. Cada puzle abre una puerta, un compartimento o una escena.

### Session-Level (30-120 minutes)
En el slice, una sesión completa son 25–30 min: de la llegada (23:40) a la recepción (03:40–04:10) con un final que deja abierta la pregunta «¿quién firmó?». Pendiente: estructura de sesión en la versión completa.

### Long-Term Progression
Pendiente. El slice no define progresión de largo plazo; la versión completa (más plantas, ciudad exterior) queda fuera del alcance actual.

### Retention Hooks
- **Curiosity**: la pregunta abierta del final («Continuará»).
- **Investment**: la elección de la carta y la respuesta de la llamada.
- **Social / Mastery**: no aplica.

---

## Game Pillars

Ver el documento completo: `design/gdd/game-pillars.md`.

1. **Ambivalencia sin moral binaria** — sin medidor de bueno/malo.
2. **El espacio expresa la emoción** — luz, reflejos y sonido sin explicarlo.
3. **Autonomía como progresión** — avanzar es decidir qué mirar, aceptar y responder.
4. **Tensión sin castigo** — sustos = sonido, luz y silencio; nunca bloquean.
5. **Información incompleta** — ninguna pista confirma intenciones.

### Anti-Pillars (What This Game Is NOT)
- **NOT un juego de combate o persecución**: se sustituye por tensión de sonido y luz; un enemigo obligaría a castigar.
- **NOT un juego con medidores de moral/relación/cordura**: contradice «sin moral binaria» (§16).
- **NOT una explicación**: ni los personajes ni la UI confirman intenciones; si lo hicieran, desaparece la ambigüedad.

---

## Inspiration and References

Pendiente de confirmar por el autor. El slice no cita juegos de referencia.

**Non-game inspirations**: pendiente. El tono declarado es «misterio nocturno, íntimo y melancólico, con humor seco de Vera como mecanismo de defensa».

---

## Target Player Profile

Pendiente. El slice no define público objetivo. Sí define lo que **no** debe provocar (advertencias de contenido, §17): estrés laboral, aislamiento, decepción afectiva, llanto contenido y dinámicas de control y desigualdad en una relación de trabajo. Sin violencia gráfica, sin autolesiones.

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.7 · GDScript (decidido; ver `docs/PLAN-TECNICO.md`) |
| **Key Technical Challenges** | Atmósfera con low poly (luz, shaders); memorando en espejo (P2); espejo de la diferencia (P5); voz convertida del Guardián |
| **Art Style** | 3D low poly con texturas generadas; luz cálida en Sala B y fría en el resto (§15) |
| **Art Pipeline Complexity** | Media: modelos simples + texturas/arte generado por IA; lista P0 cerrada |
| **Audio Needs** | Moderadas: drone, lluvia por capas, voces, SFX de puzle, megafonía |
| **Networking** | Ninguno |
| **Content Volume** | Slice: 4 espacios + recepción, 6 puzles, 1 llamada, 26 líneas de guion con ID (§12) |
| **Procedural Systems** | Ninguno |

---

## Risks and Open Questions

### Design Risks
- Los puzles se perciben como tediosos (§22).
- La ambigüedad se confunde con incoherencia.
- El tema toca experiencias personales reconocibles.

### Technical Risks
- Los assets low poly no transmiten atmósfera sin iluminación y shaders trabajados.
- La voz convertida suena artificial.

### Market Risks
Pendiente (el slice no analiza mercado).

### Scope Risks
- Alcance mayor del previsto; la lista de assets P0 está cerrada y los P1 solo si sobra tiempo.
- La reducción de espacios podría empobrecer el slice (D-13).
- Licencias de IA por asset (§18).

### Open Questions
Decisiones del slice aún abiertas: D-04 (nombre de Vera), D-06 (clasificación), D-07 (nombre del Guardián), D-08 (voz de Vera), D-13 (número de espacios). Resueltas en esta sesión: D-05 (Godot), D-10 (claves de traducción desde ya), D-14, D-15 y D-16 (cadena c1→c3→c4, c2 libre).

---

## MVP Definition

**Core hypothesis**: el bucle **buscar información → resolver puzle → descubrir historia** funciona como juego, mantiene la tensión sin castigo y las decisiones del jugador tienen efectos visibles (§2).

**Required for MVP**:
1. Cuatro espacios (despacho de Vera, Archivo, Sala de Reuniones, Despacho del Guardián) más Recepción.
2. Seis puzles, cada uno con una función narrativa.
3. Una llamada con variantes de carta y respuestas, y un final con variaciones.

**Explicitly NOT in MVP**:
- Ciudad exterior o más plantas; combate o enemigos; gestión de tareas completa; guardado manual; localización a otros idiomas; despacho de Dirección como sala.

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | Slice de un piso | Seis puzles, llamada, final | Pendiente (estimación gruesa 6–7 semanas) |
| **Vertical Slice** | Mismo que el MVP, con calidad final en lo que se muestra | Playtest con cinco personas | Pendiente |
| **Alpha** | Pendiente | Pendiente | Pendiente |
| **Full Vision** | Pendiente | Pendiente | Pendiente |

*(En este proyecto MVP y Vertical Slice coinciden en contenido: el slice es el objetivo. Los tiers superiores quedan sin definir hasta el gate de preproducción.)*

---

## Next Steps

- [ ] Aprobación del autor (y `creative-director` si se activa review)
- [x] Motor configurado (`/setup-engine`)
- [ ] `/map-systems` para descomponer el slice en sistemas
- [ ] `/design-system` por cada sistema
- [ ] `/vertical-slice` / `/playtest-report` tras el prototipo
