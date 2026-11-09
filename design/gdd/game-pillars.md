# Game Pillars: El Nido en la Niebla

## Document Status
- **Version**: 0.1 (derivado del slice v0.3 §4)
- **Last Updated**: 2026-11-08
- **Approved By**: pendiente (autor)
- **Status**: Draft

> Los cinco pilares y su redacción base vienen del slice (§4). Las tablas por departamento, los tests de diseño, el orden de prioridad y las anti-pilares son **propuestas** derivadas de ese mismo documento; el autor debe validarlas.

---

## Core Fantasy

> Eres Vera, y descubres —sin que nadie te lo confirme— que alguien actuó en tu nombre. Reconstruyes la verdad a partir de papeles que se contradicen y decides qué hacer con ella.

---

## Target MDA Aesthetics

| Rank | Aesthetic | How Our Game Delivers It |
| ---- | ---- | ---- |
| 1 | Narrative | Reconstrucción de una cronología con ambigüedad deliberada |
| 2 | Discovery | Buscar, leer, comparar documentos y objetos |
| 3 | Sensation | Luz, reflejos, lluvia, silencio como lenguaje |
| 4 | Fantasy | Primera persona, manos visibles |
| 5 | Challenge | Puzles deducibles, siempre sin castigo |
| N/A | Fellowship, Submission | Un jugador; la tensión es central |

---

## The Pillars

### Pillar 1: Ambivalencia sin moral binaria

**One-Sentence Definition**: Ninguna decisión ni documento clasifica a nadie como bueno o malo; afecto y daño coexisten.

**Target Aesthetics Served**: Narrative, Fantasy.

**Design Test**: Si dudamos entre un indicador de «relación» y dejar que la carta y la llamada cambien el texto, elegimos lo segundo (no hay medidores, §16).

| Department | This Pillar Says... | Example |
| ---- | ---- | ---- |
| **Game Design** | Ninguna opción es incorrecta | Puzle 6: tres botones, sin respuesta mala |
| **Art** | No se codifica «bueno/malo» con color | Paleta fría para toda la oficina; sin rojo/verde moral |
| **Audio** | La voz del Guardián no suena ni amable ni amenazante | Voz convertida con timbre distinto al de Vera |
| **Narrative** | El Guardián no es villano ni héroe | Sus líneas nunca explican por qué pasó algo |
| **Engineering** | Ningún flag representa «moralidad» | `carta_variante` y `respuesta_llamada` solo cambian líneas |

#### Serving This Pillar
- Las cuatro respuestas de la llamada tienen peso emocional distinto, no de «bien/mal».
- La nota «No te quites la carga. Yo tampoco».

#### Violating This Pillar
- Un medidor, logro o final «bueno/malo».
- Una línea que confirme la intención del Guardián.

---

### Pillar 2: El espacio expresa la emoción

**One-Sentence Definition**: La tensión y la emoción se comunican con luz, reflejos y sonido, sin que un personaje las explique.

**Target Aesthetics Served**: Sensation, Narrative.

**Design Test**: Si dudamos entre una línea que diga «Vera está nerviosa» y un parpadeo con silencio, elegimos el parpadeo.

| Department | This Pillar Says... | Example |
| ---- | ---- | ---- |
| **Game Design** | Los avisos son sensoriales, no mecánicos | Escena 4: el reflejo llega tarde y vuelve al girar la cabeza |
| **Art** | La luz manda sobre el modelado | Luz cálida en Sala B, fría en el resto (art bible) |
| **Audio** | Silencios largos son parte del diseño | Lluvia más intensa en Archivo y pasillo |
| **Narrative** | El subtexto vive en el decorado | Abrigo mojado, taza fría, libro de visitas |
| **Engineering** | Iluminación y shaders son prioridad | Prueba de atmósfera de 30 s antes de modelar el resto |

#### Serving This Pillar
- Apagón completo seguido de sillas rodando y tecleo sin imagen.
- Lluvia que se atenúa dentro de las salas cerradas.

#### Violating This Pillar
- Monólogos que expliquen el estado emocional de Vera.
- Un indicador de estrés en la interfaz.

---

### Pillar 3: Autonomía como progresión

**One-Sentence Definition**: Avanzar es decidir qué mirar, qué aceptar y qué responder, no ejecutar un guion.

**Target Aesthetics Served**: Discovery, Fantasy.

**Design Test**: Si dudamos entre una cinemática que muestre el hallazgo y obligar al jugador a encontrarlo, elegimos que lo encuentre.

| Department | This Pillar Says... | Example |
| ---- | ---- | ---- |
| **Game Design** | El jugador elige qué leer y en qué orden (dentro de las dependencias) | Sala B antes o después de D |
| **Art** | Lo importante se descubre al acercarse | Halo en el cristal solo al acercar la cámara (P2, nivel 3) |
| **Audio** | La voz no guía al jugador | `VO_V_*` comenta, no instruye |
| **Narrative** | La cronología la reconstruye el jugador | Puzle 1: ordenar correos |
| **Engineering** | Estado en banderas, no en cinemáticas lineales | `GameState` con flags de Anexo D.2 |

#### Serving This Pillar
- Puzle 4: la ficha «Carta a Dirección» obliga a decidir si Vera habla por otra persona.
- Pistas opcionales de hasta tres niveles (dos en el puzle 6).

#### Violating This Pillar
- Tutoriales que dicen la solución.
- Escenas que resuelven el puzle por el jugador.

---

### Pillar 4: Tensión sin castigo

**One-Sentence Definition**: Los sustos son sonido, luz y silencio; nunca bloquean la historia ni penalizan.

**Target Aesthetics Served**: Sensation, Narrative.

**Design Test**: Si dudamos entre un enemigo que persiga al jugador y un sonido que se acerque pero nunca llegue, elegimos el sonido.

| Department | This Pillar Says... | Example |
| ---- | ---- | ---- |
| **Game Design** | Ningún fallo es terminal | «Si falla»: vibración y reinicio, sin penalización |
| **Art** | El susto es visual y reversible | El reflejo vuelve a la normalidad al girar la cabeza |
| **Audio** | Opción de reducir sobresaltos | Regulación independiente de voces/efectos/música |
| **Narrative** | Las presencias no se acercan a distancia de reacción | Sillas, tecleo y pasos, sin voz |
| **Engineering** | Sin softlocks; guardado automático en hitos | Casos límite §13.3 |

#### Serving This Pillar
- El llanto contenido se representa como algo que el juego espera.
- Sin temporizador en el tablero de tareas.

#### Violating This Pillar
- Muerte, game over o penalización.
- Un temporizador que decida por el jugador.

---

### Pillar 5: Información incompleta

**One-Sentence Definition**: Los hechos observables son fijos y fiables; las intenciones nunca se confirman.

**Target Aesthetics Served**: Narrative, Discovery.

**Design Test**: Si dudamos entre un documento que aclare quién firmó y uno que lo deje abierto, elegimos el abierto.

| Department | This Pillar Says... | Example |
| ---- | ---- | ---- |
| **Game Design** | Los puzles responden preguntas de hechos, no de intención | P1 reconstruye fechas y horas |
| **Art** | Detalles que sugieren sin afirmar | La V del libro de visitas «cerrada hacia dentro» |
| **Audio** | Las líneas del Guardián pueden contradecir documentos | `VO_G_07` |
| **Narrative** | Contradicción deliberada y comprobable | Formulario firmado antes de pedir confirmación |
| **Engineering** | Los datos narrativos viven en archivos, no en código | `lines.json`, documentos como recursos |

#### Serving This Pillar
- Memorando: «aprobado a petición de la interesada» con «ratificación pendiente».
- Final abierto («Continuará»).

#### Violating This Pillar
- Un epílogo que resuelva quién firmó.
- Hechos que cambian según el jugador (fechas, correos).

---

## Anti-Pillars (What This Game Is NOT)

- **NOT un juego de combate o persecución**: contradiría «Tensión sin castigo» y obligaría a penalizar.
- **NOT un juego con medidores de moral, relación o cordura**: contradiría «Ambivalencia sin moral binaria».
- **NOT una historia explicada**: si los personajes confirman intenciones, desaparece «Información incompleta».

---

## Pillar Conflict Resolution

| Priority | Pillar | Rationale |
| ---- | ---- | ---- |
| 1 | Tensión sin castigo | Es una regla dura (sin softlock ni game over) y afecta a accesibilidad |
| 2 | Información incompleta | Protege el hook narrativo del slice |
| 3 | Autonomía como progresión | Define cómo se juega |
| 4 | El espacio expresa la emoción | Es el medio; cede ante los tres anteriores |
| 5 | Ambivalencia sin moral binaria | Se respeta casi siempre por diseño de contenido |

*(Orden propuesto: el slice no lo define; confirmar con el autor.)*

**Resolution Process**: identificar los pilares en tensión → aplicar el orden → servir parcialmente al inferior si es posible → documentar la decisión → escalar a `creative-director` si es irreconciliable.

---

## Player Motivation Alignment

| Need | Which Pillar Serves It | How |
| ---- | ---- | ---- |
| **Autonomy** | Autonomía como progresión | Elegir qué mirar, aceptar y responder |
| **Competence** | Tensión sin castigo | Puzles deducibles, pistas de hasta tres niveles (dos en el P6), fallo recuperable |
| **Relatedness** | Ambivalencia sin moral binaria | Vínculo ambiguo con El Guardián |

---

## Emotional Arc

| Phase | Duration | Target Emotion | Pillar(s) Driving It | Mechanics Delivering It |
| ---- | ---- | ---- | ---- | ---- |
| Opening | 0–5 min | Soledad y curiosidad | 2 | Escena 1: lluvia, ventilador, mensaje que desaparece |
| Rising | 5–20 min | Inquietud e inquisición | 3, 5 | Archivo, pasillo (escena 4), Sala B, despacho del Guardián |
| Climax | 20–27 min | Intimidad y tensión | 1, 4 | Caja (puzles 3–6), apagón y llamada |
| Resolution | 27–30 min | Duda y reflexión | 5, 1 | Recepción, libro de visitas, «La V no me convence» |
| Hook | Fin | Curiosidad | 5 | «Continuará» |

### Long-Term Emotional Progression
Pendiente (fuera del alcance del slice).

---

## Reference Games

Pendiente de confirmar por el autor.

**Non-game inspirations**: pendiente. Tono declarado: misterio nocturno, íntimo y melancólico, con humor seco.

---

## Pillar Validation Checklist

- [x] **Count**: 5 pilares
- [x] **Falsifiable**: cada uno prohíbe algo concreto
- [x] **Constraining**: eliminan medidores, enemigos, explicaciones y cinemáticas resolutivas
- [x] **Cross-departmental**: tabla por departamento en cada pilar
- [x] **Design-tested**: un test por pilar
- [x] **Anti-pillars defined**: 3
- [ ] **Priority-ranked**: propuesto, sin confirmar
- [x] **MDA-aligned**
- [x] **SDT coverage**
- [ ] **Memorable**: cinco es el máximo; revisar con el equipo
- [x] **Core fantasy served**

---

*Documento creativo base. Vive en `design/gdd/game-pillars.md`. Revisar tras el primer playtest.*
