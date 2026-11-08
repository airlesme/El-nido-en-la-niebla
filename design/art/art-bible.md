# Art Bible: El Nido en la Niebla

> **Status**: Draft (secciones 1–9 redactadas y aprobadas por el usuario)
> **Owned By**: art-director
> **Last Updated**: 2026-11-08
> **Art Director Sign-Off (AD-ART-BIBLE)**: SKIPPED 2026-11-08 — lean mode

`/art-bible` writes these nine sections in this order and replaces each
section's `[To be designed]` line as that section is approved. A section still
holding its placeholder is incomplete; a later run fills only those.

## 1. Visual Identity Statement

**Regla visual:** *Que la luz diga lo que nadie dice.*

Cuando una decisión visual sea ambigua, elige la opción que exprese el estado emocional de la noche con luz, reflejo o sombra, y no con un objeto, un texto o un efecto añadido. La planta nueve es un espacio ordinario (mesas, carpetas, un ventilador, una taza fría). Lo que lo vuelve inquietante, íntimo o triste es cómo lo ilumina la noche, no lo que contiene.

Esta regla sale directamente del Pilar 2 y del tono del slice (misterio nocturno, íntimo y melancólico). La contención que pide es también la del humor seco de Vera: lo cotidiano (la taza fría, el peluche cúbico) hace la broma sin subrayarla.

### Principio 1 · La luz es el narrador
*Sirve al Pilar 2 (El espacio expresa la emoción).*

El estado de ánimo se lee en la temperatura y la estabilidad de la luz. La planta vive en luz fría (verde grisáceo, azul), y el ámbar es escaso a propósito: solo aparece en las lámparas y el halo de la Sala de Reuniones. Esa escasez le da peso. Cuando el jugador entra en ámbar, el color funciona como señal de intimidad y de verdad a medias, no de refugio. El memorando aparece justo ahí, así que la calidez no equivale a seguridad. Eso mantiene la ambivalencia del Pilar 1, porque ningún color significa «bueno» o «malo».

Los cambios de tensión (parpadeo en el pasillo, reflejo desfasado, apagón de las 02:30) se hacen con la iluminación y los reflejos que ya existen. Así el espacio «habla» sin explicar nada y sin UI que lo traduzca.

> **Test:** cuando dudes entre señalar tensión con un elemento nuevo (objeto, partícula, texto) o con un cambio de luz o reflejo sobre lo que ya está, elige el cambio de luz.

### Principio 2 · Insinuar, nunca mostrar
*Sirve al Pilar 4 (Tensión sin castigo) y al Pilar 5 (Información incompleta).*

Lo inquietante se presenta como rastro, no como presencia: el reflejo que llega un instante tarde, las sillas rodando por el pasillo, el abrigo mojado en el perchero del Guardián. No hay criaturas, siluetas persecutorias ni cambios bruscos de imagen. El susto es siempre un aviso que se disuelve cuando el jugador mira (el reflejo vuelve a la normalidad al girar la cabeza), de modo que la imagen nunca castiga ni bloquea.

El mismo criterio vale para las pistas. Los detalles visuales sugieren sin confirmar, como la «V» cerrada hacia dentro en el libro de visitas, que es una diferencia mínima y no una flecha. La imagen no resuelve lo que el guion deja abierto.

> **Test:** cuando dudes entre mostrar una figura o causa visible y mostrar solo su huella (reflejo, objeto movido, sombra, ausencia), elige la huella.

### Principio 3 · Mirar es elegir
*Sirve al Pilar 3 (Autonomía como progresión) y al principio de interfaz sin HUD.*

Avanzar es decidir qué mirar, así que la imagen guía con contraste y no con instrucciones. El low poly con texturas generadas (formas simples, superficies limpias) es la herramienta: el detalle y el contraste se concentran en lo que se puede examinar o resolver (papeles, fichas, la caja, el cristal), y el resto del entorno se mantiene sobrio y de baja lectura. El ojo llega a lo importante porque el resto es más callado, no porque una flecha o un brillo se lo imponga.

La interfaz sigue la misma lógica: sin barras, y con un único icono discreto de interacción. La oscuridad nunca debe volver ilegible un puzle. La atmósfera se consigue con temperatura y contraste, no ocultando lo que el jugador necesita leer.

> **Test:** cuando dudes entre añadir detalle o resaltar algo para que el jugador no se lo pierda y dejar que lo encuentre por contraste y composición, elige el contraste, salvo que la legibilidad de un puzle esté en juego. Ahí manda la legibilidad.

**Regla de desempate entre principios:** la legibilidad de un puzle gana siempre a la atmósfera (decisión del usuario al aprobar esta sección).

> **Pendiente técnico:** validar con el technical-artist el coste en Forward+ de reflejos, lluvia y cristal (shaders P0 de slice §15) antes de tratar el Principio 1 como regla dura.

## 2. Mood & Atmosphere

**Criterio de diferenciación:** cada estado cambia al menos dos de estos ejes: temperatura de color, contraste y comportamiento de la luz (estable, pulsante, desfasada, ausente). Ninguna tensión se resuelve con objetos nuevos (Sección 1, regla). Las temperaturas son orientativas y las afina el technical-artist.

### 2.1 Llegada (23:40)
- **Objetivo emocional:** cansancio doméstico con una grieta de inquietud. Todo es familiar y nada está del todo bien.
- **Luz:** ambiente azul noche con sesgo verde (~6000 K), contraste bajo. La fuente dominante es el monitor (~7000 K) sobre un fundido desde negro. El gris de la lluvia se cuela por la persiana.
- **Descriptores:** cansada, zumbante, mojada, familiar, estrecha.
- **Energía:** baja (2/10).
- **Elemento que lleva el ánimo:** el ventilador que vibra proyecta una sombra pulsante en la pared, y las rayas de lluvia cruzan el cristal. El mensaje «Este número ya no está disponible» es lo más brillante del encuadre, así que la pantalla es la única voz de la escena (Principio 1).

### 2.2 Trabajo y exploración (00:05–02:30)
Cubre Despacho de Vera, Archivo y Despacho del Guardián.
- **Objetivo emocional:** concentración solitaria con un punto de vigilancia. Es la sensación de ser la única persona despierta del edificio.
- **Luz:** fluorescente frío (5500–6500 K) con sesgo verde grisáceo. Contraste medio, con charcos de luz sobre lo examinable y sombra sobria en el resto (Principio 3).
- **Descriptores:** sobria, metódica, polvorienta, atenta, silenciosa.
- **Energía:** baja-media (3–4/10).
- **Elemento que lleva el ánimo:** el charco de luz fría sobre el panel, el escritorio o la caja marca qué se puede mirar.
- **Variantes por espacio:**
  - Archivo: más azul y más oscuro, con estanterías que cierran la sombra.
  - Despacho del Guardián: ~5200 K, algo más «seco» y menos verde. El abrigo mojado es una masa oscura colgada del perchero y la taza fría es un punto de luz plana. Ambos son rastro, no presencia (Principio 2).

### 2.3 Sala de Reuniones (puerta B)
- **Objetivo emocional:** calidez que inquieta. Es una invitación sin consuelo, una reunión a la que nadie ha venido.
- **Luz:** lámparas ámbar (~2700 K) en charcos definidos, contra un ventanal gris azulado (~7000 K). Es el contraste más alto y más cromático de la planta.
- **Descriptores:** cálida, expectante, vacía, ceremonial, zumbante.
- **Energía:** media y suspendida (4/10).
- **Elemento que lleva el ánimo:** el halo ámbar sobre la mesa con sillas vacías. En el cristal, el memorando se refleja en ámbar sobre la lluvia azul, y las dos temperaturas conviven en un mismo encuadre. Las lámparas tienen una micro-fluctuación de intensidad asociada al zumbido, así que la calidez nunca se asienta (Pilar 1).

### 2.4 Pasillo con tensión (00:40)
- **Objetivo emocional:** vigilancia contenida. Es la sensación de que alguien acaba de mirar.
- **Luz:** tubos frío-verdosos (~6500 K) en hileras. El parpadeo se organiza en secuencias legibles, no en estroboscopio. Contraste en bandas alternas de luz y sombra a lo largo de 24 m.
- **Descriptores:** alargado, rítmico, vítreo, helado, expectante.
- **Energía:** media-alta (6/10). Es el techo antes del apagón y nunca llega a susto.
- **Elemento que lleva el ánimo:** el reflejo de Vera en el patio de luces llega un instante tarde. Es la misma silueta, desplazada en tiempo y sin deformarse. Se normaliza al girar la cabeza (Principio 2).

### 2.5 Apagón y llamada (02:30)
- **Objetivo emocional:** vulnerabilidad e intimidad forzada. Se pasa de la alarma a la espera, y la llamada es un momento para escuchar, no para huir.
- **Luz:** sin fuente de techo. Negro azulado, no negro puro, con gris lluvia residual por la persiana. Las únicas fuentes son la pantalla del teléfono y el monitor en reposo (blanco frío). Contraste extremo pero local. No se añade piloto de emergencia: sería un objeto nuevo.
- **Descriptores:** cerrada, íntima, auditiva, suspendida, temblorosa.
- **Energía:** alta en el apagón (7–8/10) y baja y sostenida durante la llamada (3/10).
- **Elemento que lleva el ánimo:** la pantalla del teléfono, con su propia extensión, ilumina las manos de Vera desde abajo. Durante los 20 s de espera la luz no cambia. La luz quieta es la forma en que el juego espera sin presionar.

### 2.6 Recepción final (03:40–04:10)
- **Objetivo emocional:** lucidez agotada y duelo sin resolver. No es alivio (Pilar 1).
- **Luz:** la más neutra y limpia del slice (~5600 K), difusa y de baja saturación. Techo de 3,20 m, que da más aire que en cualquier otro espacio. Sin ámbar.
- **Descriptores:** despejada, hueca, nítida, quieta, fría.
- **Energía:** muy baja (1–2/10).
- **Elemento que lleva el ánimo:** al cesar la lluvia, los cristales pierden las rayas y los reflejos quedan fijos. Una luz puntual neutra cae sobre el libro de visitas y la V cerrada se lee bien.

### 2.7 Menús, pausa y ordenador
- **Objetivo emocional:** refugio funcional. El mundo se detiene y se puede leer sin prisa.
- **Luz:**
  - Pausa: el mundo queda atrás con velo azul noche y ligera desaturación.
  - Ordenador (diegético): pantalla blanco frío sobre azul noche, cuyo resplandor ilumina las manos de Vera.
  - Pantalla de inicio con advertencias: sobria, solo texto.
- **Descriptores:** neutra, serena, legible, plana, silenciosa.
- **Energía:** mínima (1/10).
- **Elemento que lleva el ánimo:** la ausencia de movimiento. La legibilidad prima sobre la atmósfera (Principio 3).

### Decisiones y pendientes de esta sección
- **Ventana de Vera:** la Escena 1 habla de «lluvia contra un cristal» y el Anexo A.1 dice que el despacho no tiene ventana. Se trata como persiana con tiras de luz, y las gotas se ven en el cristal del monitor o de una puerta. Reconciliar el texto del slice cuando se revise.
- **Fotosensibilidad:** el parpadeo del pasillo y el apagón necesitan un límite de destellos por segundo, y la opción «reducir sobresaltos» (slice §14) debe atenuarlos. Lo definen technical-artist y accessibility-specialist.
- **Recepción:** el slice no fija su color; se propone neutro y frío sin ámbar. Un destello cálido final sería una excepción a la regla del ámbar escaso, y la decidiría el creative-director.

## 3. Shape Language

### 3.1 Silueta: manos, presencia y objetos legibles
*(Principio 2 Insinuar, nunca mostrar · Pilares 4 y 5)*
- **Vera** existe en primera persona a través de las manos y en el reflejo. Las manos tienen forma simple y limpia, y funcionan como señal de agencia y como sujeto de la luz del monitor y del teléfono.
- El **reflejo** es una silueta oscura con proporciones idénticas a las de Vera. El desfase es temporal y nunca de forma. Una silueta deformada rompería «sin criaturas ni cambios bruscos».
- **El Guardián no tiene cuerpo.** Existe como rastro: abrigo, taza, silla, voz. Su silueta nunca se completa, porque una figura completa sería presencia.
- **Objetos clave:** cada pieza de puzle debe reconocerse en silueta a 3 m. Para eso se exagera ligeramente su proporción (≈10–15 %) y no se solapa con otros volúmenes.

### 3.2 Geometría del entorno
*(Principio 1 La luz es el narrador)*
- La planta es **rectilínea y repetitiva**: pasillo de 24 × 2,6 m, techo de 2,70 m, puertas idénticas, hileras de tubos. La repetición hace que cualquier desviación, como un parpadeo o un reflejo tardío, se lea de inmediato.
- Lo **curvo se reserva para la luz**. Los halos y los charcos ámbar son las únicas formas blandas del mundo. Así el ámbar se reconoce por su forma además de por su color.
- El **Despacho de Vera** admite pequeñas irregularidades (papeles, un cable) porque es el único espacio habitado. La **Recepción** abre el volumen (3,20 m) y es lo único que respira.

### 3.3 Gramática de forma de la interfaz
*(Principio 3 Mirar es elegir · Pilar 4)*
- **Ordenador diegético:** ventanas rectangulares de esquinas vivas y tipografía plana sobre azul noche. Es parte del mundo y obedece su geometría.
- **Icono de interacción (overlay):** un **anillo fino con punto central**, discreto y blanco frío. Se diferencia en forma de todo el mobiliario rectilíneo y no se confunde con el ámbar, porque no tiene color cálido ni halo.
- El overlay no usa sombras ni brillos, para que no se lea como una fuente de luz del mundo.
- **Feedback de puzle:** acierto = el elemento encaja y se asienta con un aumento de brillo. Error = un leve temblor frío, sin rojo. Es un feedback no punitivo (Pilar 4).

### 3.4 Formas protagonistas y de apoyo
*(Principio 3 · legibilidad por encima de atmósfera)*
- **Examinables:** bordes biselados que atrapan luz, más detalle de textura, mayor contraste de valor con su entorno y siempre dentro de un charco de luz.
- **Decorado:** sombreado plano y mate, valores cercanos al muro, sin textura distintiva. Se funde con el fondo.
- Los modelos gratuitos y los generados por IA deben pasar por esta regla (valor, densidad de textura y bisel) para integrarse en la misma familia.

### 3.5 Qué comunica el low poly
- Un mundo **recordado, no documentado**. La falta de detalle fino respalda la información incompleta (Pilar 5): hay huecos, y las lagunas importan.
- Los planos angulosos refuerzan la frialdad, y las texturas generadas, con su desgaste, aportan humanidad al papel y la madera.
- **Riesgo:** el low poly puede leerse «simpático» o «barato». Se contrarresta con iluminación sobria, un rango de valores restringido y sin contornos dibujados.

## 4. Color System

### 4.1 Paleta
| # | Nombre | Hex | Rol y significado |
|---|---|---|---|
| 1 | Verde humo | `#5E6B66` | Base de la planta: muros, mobiliario. El «normal» del edificio. |
| 2 | Azul noche | `#1C2A38` | Sombras, apagón, fondo de UI. Nunca negro puro dentro del juego. |
| 3 | Gris lluvia | `#8FA3B0` | Ventanas, lluvia, reflejos. Lo exterior y lo que devuelve la mirada. |
| 4 | Ámbar lámpara | `#E0A458` | Lámparas y halo de la Sala de Reuniones. Atención y memoria, no seguridad. |
| 5 | Blanco frío | `#DCE6E8` | Pantallas, teléfono, papel, texto de UI. Información y rastro eléctrico. |
| 6 | Madera apagada | `#6B5848` | Caja del Guardián y mobiliario. Material bajo luz fría, nunca emisivo. |
| 7 | Rojo óxido (reservado) | `#9B4A3F` | Acento diegético muy raro (por ejemplo un LED de grabación o un detalle del libro de visitas), nunca en UI y nunca como señal de error. |

### 4.2 Semántica
- **Ámbar:** es donde algo pide atención, y no donde estás a salvo. Siempre va acompañado de zumbido, fluctuación o vacío (sillas vacías). Un ámbar estable y silencioso sería el único consuelo del slice, y rompería el Pilar 1.
- **Azul frío:** es el estado base de la planta y de la noche. No significa peligro. El peligro es el cambio dentro del azul: un parpadeo, un reflejo tardío, un apagón.
- **Blanco frío:** es lo que dice algo, ya sea una pantalla, un papel o el teléfono. Es la luz de la información.
- **Rojo/aviso:** el juego **no avisa con rojo**. Avisa con desfase de luz (regla de la Sección 1), y la derrota no existe (Pilar 4). El rojo óxido es un acento diegético opcional y nunca una señal de error.
- **Por qué ámbar ≠ seguridad:** la Sala de Reuniones es el lugar donde se revela una verdad incómoda (memorando en el cristal), y su calidez es más cercana a la nostalgia que al refugio.

### 4.3 Temperatura de color por espacio
| Espacio | Temperatura | Carácter |
|---|---|---|
| Despacho de Vera | ~6000 K, sesgo verde | Plano, monitor como acento (7000 K) |
| Pasillo | ~6500 K, verde grisáceo | Hileras con flicker secuenciado |
| Archivo | ~7000 K, más azul y bajo | Sombras profundas entre estanterías |
| Sala de Reuniones | Lámparas 2700 K / ventanal 7000 K | Único espacio cálido, contraste máximo |
| Despacho del Guardián | ~5200 K, seco | Madera apagada, sin ámbar |
| Apagón | ~8000 K residual | Solo teléfono y monitor |
| Recepción | ~5600 K neutro | Más limpio, sin sesgo verde |

### 4.4 Paleta de UI y divergencia del mundo
- **UI:** texto en blanco frío `#DCE6E8` sobre paneles azul noche `#1C2A38` (≈85 % de opacidad). Secundario en gris lluvia `#8FA3B0`. Selección = más brillo + subrayado o corchete, no cambio de tono.
- **Divergencia:** el mundo tiene textura, degradados y luz. La UI es plana, de tonos fijos y sin ruido. **El ámbar no entra en la UI**, para que siga siendo una señal del mundo.
- **Contraste de texto:** objetivo ≥ 7:1 en cuerpo y ≥ 4,5:1 en grande.
- **El ordenador diegético** pertenece al mundo y comparte esta paleta de UI.

### 4.5 Daltonismo: pares de riesgo y respaldo
| Par | Riesgo | Respaldo obligatorio |
|---|---|---|
| Ámbar vs verde humo | Deuteranopia/protanopia: luminancias parecidas | Forma del halo (curva), brillo y zumbido de las lámparas |
| Rojo óxido vs verde humo | Clásico rojo/verde | No usar el rojo como señal. Si aparece, añadir forma o texto |
| Madera vs verde humo/ámbar | Valores cercanos | Bisel y contraste de valor en la caja |
| Gris lluvia vs azul noche | Tritanopia, poco | Diferencia de valor, no de tono |

**Reglas de puzle:**
- Ningún puzle puede depender solo del color. Las piezas de foto, las fichas de tarea, los tres botones de decisión y las lámparas se distinguen por forma, símbolo, posición, brillo o sonido.
- Las opciones de la llamada se distinguen por texto y posición.
- El icono de interacción debe tener una opción de mayor tamaño y contraste en el menú de accesibilidad.

> **A validar en pantalla:** la caja de madera del Guardián (`#6B5848`, iluminada en frío) frente a la regla «cálido solo en la Sala de Reuniones» del slice §15.

## 5. Character Design Direction

**Regla de partida:** en este juego el personaje no es un cuerpo, es una huella. Vera se ve en las manos y en un reflejo. Los demás existen como rastros que se reconocen por su material, su estado de tiempo o su movimiento, nunca por una figura. Esto aplica la Sección 1 (insinuar, nunca mostrar) y la Sección 3.1 (el Guardián no tiene cuerpo, el reflejo no se deforma).

### 5.1 Vera en primera persona: manos y mangas
- **Arquetipo:** una trabajadora de oficina al final de una jornada demasiado larga, recién trasladada. Lo comunican las mangas y la economía de gesto, no un rostro.
- **Manos:** formas simples y limpias, con dedos articulados lo justo para girar una lámpara, pasar una página, sostener el cubo o llevar el teléfono al oído. Van mate y sin bisel. Según la Sección 3.4, el detalle y el brillo son para lo examinable, y las manos no pueden competir con ello. Su función es ser el sujeto de la luz: se leen por contraste de valor frente al mobiliario verde humo, y la luz del monitor y del teléfono las ilumina.
- **Mangas:** manga larga hasta la muñeca, de punto fino, en un tono azul-gris desaturado de valor medio-bajo. Así la mano, más clara, se separa del escritorio por valor y no por tono (respaldo para daltonismo, Sección 4.5). No usa ámbar ni rojo óxido.
- **Objeto visible:** ninguno. Sin reloj, anillo, pulsera ni cordón con acreditación. En un juego de pistas, cualquier objeto llevado puesto se leería como pista, y la Sección 1 prohíbe añadir objetos para sugerir. Los ítems (tarjetas, formulario, impresión) aparecen en la mano al usarse y vuelven al «bolsillo visual» del slice (D.1), sin menú.
- **Piel y vestuario concreto:** el slice no los fija. La regla es que el tono de piel se resuelva por valor bajo luz fría y no por un matiz cálido, para que no se confunda con el ámbar. Pendiente de decisión de dirección.
- **Humedad:** la humedad es la firma del Guardián (5.3), así que Vera va seca. La lluvia se ve en el cristal, no en su ropa.
- **Pose y expresión:** realista y contenida. Los gestos son cortos, algo cansados y sin floritura. El humor seco de Vera (Sección 1) vive en los tiempos muertos, por ejemplo cuando el cubo se queda un segundo girando en la mano, y no en una expresión.

### 5.2 El reflejo de Vera
- **Forma:** una silueta oscura de cuerpo entero, con las proporciones de Vera. Incluye el contorno de las mangas para que se lea como «ella», pero no tiene rostro ni textura interna.
- **Comportamiento:** su pose es mimética. Repite lo que hizo Vera, con un retraso de 0,6 s durante 3 s en el patio de luces (slice A.3, T-PAS-2) y sin hacer nunca nada que Vera no haya hecho. Una pose independiente sería ya una criatura. Se normaliza al girar la cabeza (Sección 2.4).
- **Dónde aparece:** solo en superficies reflectantes ya existentes, como el patio de luces, los cristales y el marco interior del puzle 5. No añade objetos.
- **Regla de desempate:** la legibilidad del puzle gana a la atmósfera. El reflejo se suprime sobre el ventanal de la Sala de Reuniones mientras dura el puzle 2, para que no tape el memorando.
- **Lectura contra el entorno:** se lee porque la superficie tiene baja densidad de textura y bandas de luz alternas (ver 6.2). La silueta oscura contrasta con las bandas claras del pasillo.

### 5.3 Los ausentes: cuatro tipos de rastro
| Tipo | Quién | Cómo se ve | Señal que lo distingue |
|---|---|---|---|
| **Residuo** | El Guardián | Materia con un estado de tiempo: abrigo que gotea (2 gotas/s), taza fría, nombre tachado | Estático y singular. Siempre tiene humedad, temperatura o uso. Si se puede examinar, está en un charco de luz |
| **Movimiento** | Presencias (sillas, pasos, tecleo) | Un objeto que ya existía se mueve sin causa y termina en reposo | Transitorio, en la periferia, nunca examinable. No deja huella ni correlato visual: sin huellas, sin teclas que se hunden |
| **Archivo** | El Equipo anterior | Cartón, etiquetas, pegatinas, cajas de traslado, el margen de una foto | Material de oficina «de mudanza». Texto mínimo y plano |
| **Eco** | La propia Vera | El reflejo desfasado y su letra manuscrita (firma, formulario) | Imita siempre a Vera, nunca a otro |

**Test de un vistazo:**
- ¿Se mueve solo? Es Presencia.
- ¿Está mojado, frío o gastado? Es el Guardián.
- ¿Es cartón o etiqueta? Es el Equipo anterior.
- ¿Copia a Vera? Es eco.

**Voces sin cuerpo.** Megafonía, la voz del Guardián y la de Vera no tienen avatar, onda de audio ni retrato. En la llamada, la imagen es solo la pantalla del teléfono y las manos iluminadas desde abajo (Sección 2.5). La megafonía es un altavoz de techo inerte, sin luz propia. Si algo parpadea, es el edificio y no la voz.

### 5.4 Figuras que sí aparecen: la foto y el peluche
- **Figuras de foto** (D04 y piezas del puzle 3): son textura y no geometría. Su pose es **rígida**: foto de equipo corporativa, frontal y a la misma distancia entre personas. Esa rigidez es parte del relato, porque cuenta una formalidad que ya se perdió. La expresión es neutra y los rostros quedan sin resolver, con grano o semitono de papel impreso. Vera aparece **al margen**, parcialmente cortada por el borde del encuadre. Las caras generadas por IA se revisan una a una por artefactos y se degradan antes de entrar, porque un rostro deforme rompe la Sección 1.
- **Peluche cúbico:** un cubo de 12 cm con bisel suave. Es la única «cara amable» del juego, y su humor depende de no subrayarse. La pegatina del equipo antiguo es el único detalle, y solo es legible a distancia de mano.
- **Estilos descartados:** ninguna figura es expresiva ni exagerada. Todo lo humano es sobrio, y el espectro va de lo realista contenido (manos) a lo rígido (foto).

### 5.5 LOD a distancia de juego
La regla es que el detalle se reparte según la distancia y el tiempo de mirada, no según la importancia narrativa. Los números los fija la Sección 8.

| Elemento | Distancia típica | Tratamiento |
|---|---|---|
| Manos | 0,3–0,6 m, siempre en pantalla | Tier más alto de personaje, pero mate y sin competir. Un solo LOD |
| Reflejo | 3–12 m, segundos, sobre cristal | Tier mínimo: solo silueta, sin dedos ni rostro. La rugosidad del cristal justifica el bajo detalle |
| Figuras de foto | 0,4–0,6 m al inspeccionar, 3–5 m en la pared | Solo textura. De lejos son manchas de masa, de cerca grano |
| Peluche | 0,4 m en mano | Malla trivial. La textura y la pegatina llevan el detalle |

El slice es una escena continua y pequeña, así que no se prevén cambios de LOD visibles. Queda para el technical-artist el proxy de cuerpo entero que alimenta el reflejo y el campo de visión propio de las manos.

> **Pendiente:** el rojo óxido (Sección 4) queda sin asignar a ningún personaje; la tinta del Guardián es decisión narrativa del guion.

## 6. Environment Design Language

### 6.1 Estilo arquitectónico: una oficina que nadie diseñó
La planta nueve es **arquitectura de nadie**: paneles modulares, falso techo, luminarias empotradas, mobiliario laminado, persianas. No hay señas de un lugar real. Sirve a la ambigüedad del Pilar 1 porque la indiferencia institucional nunca se lee como hostilidad. Esa neutralidad es el comentario cultural del mundo: «traslado interno» y «reasignación» son procedimientos, no dramas.

El espacio se lee como **tres capas de tiempo** superpuestas:
1. El edificio base, utilitario y anónimo.
2. Una reforma intermedia («Procedimientos 2019», slice A.4).
3. La reorganización reciente, hecha con cartón, rótulos nuevos y mobiliario ajeno.

La jerarquía del diseño sigue al poder. La Sala de Reuniones es el único espacio con diseño (mesa de cristal, ventanal). La Recepción es neutra y abierta, la cara que da al exterior. Todo lo demás es funcional.

Esto es coherente con la Sección 3.2: las curvas se reservan para la luz. Los objetos redondos (taza, silla giratoria) se **facetan** en pocos lados para no leerse como formas blandas.

**Lámparas de escritorio (Despacho de Vera y Despacho del Guardián):** neutras-cálidas y desaturadas, sin llegar al ámbar, para conservar la escasez del ámbar de la Sala de Reuniones (Principio 1). Las temperaturas exactas del slice (A.2, A.5, A.6) se reconcilian con esta regla al revisar el anexo.

### 6.2 Filosofía de textura
**Decisión:** híbrido de *albedo estilizado + rugosidad narrativa*, sin PBR completo. Es la que mejor sirve a la Sección 1.

| Opción | A favor | En contra |
|---|---|---|
| Pintado plano | Muy coherente con el low poly | Sin respuesta a la luz, y la luz es el narrador |
| PBR completo | Material creíble | Las texturas de IA salen incoherentes y con luz horneada |
| **Híbrido (elegido)** | Albedo dentro de la paleta, con **rugosidad** como portadora de significado (cristal, abrigo mojado, papel) y normal solo en lo examinable | Exige disciplina de revisión |

Reglas para texturas generadas o procedimentales:
- **Albedo limpio:** sin sombras ni luz horneadas, y con matiz y valor recolocados dentro de la paleta de la Sección 4.
- **Texto siempre autoría propia.** La IA no escribe texto legible, así que rótulos, etiquetas y papeles se superponen como decales.
- **Sin rostros ni manos en texturas.** Excepto la foto, que se degrada como en 5.4.
- **Tres tiers de resolución:** Hero (examinable), Estándar y Fondo. Cada escalón supone aproximadamente el doble de densidad de texel respecto al siguiente. Las cifras concretas las fija la Sección 8.
- **Tiling:** trim sheets para muros, techo y suelo. La repetición del pasillo es deliberada (Sección 3.2), así que **no** se aleatoriza. La variación de desgaste crece hacia los espacios habitados.
- **Desgaste:** el polvo va en horizontales y la abrasión en puntos de contacto. Los **ghost marks** (rectángulos pálidos donde hubo algo, restos de cinta) cuentan la reorganización sin añadir objetos. Son una excepción de baja visibilidad a la Sección 3.4: apenas perceptibles a 3 m.
- **Lectura de siluetas:** los muros y el decorado se mantienen en baja frecuencia y valor cercano al muro (Sección 3.4), para que manos, reflejo y rastros se separen por valor.

### 6.3 Densidad de props por espacio
| Espacio | Densidad | Qué la dirige |
|---|---|---|
| Despacho de Vera | Media-alta, **concentrada** en el escritorio. El resto del cuarto queda vacío | Único espacio habitado (Sección 3.2). Una mesa a medio adoptar: objetos del equipo anterior sin colocar |
| Pasillo | Mínima, solo en muros. **Suelo despejado** | La repetición debe delatar cualquier desviación. El suelo libre deja leer el movimiento de las Presencias |
| Archivo | Alta en volumen, **baja en detalle distintivo** | Estanterías idénticas que cierran la sombra. Solo A03 y A05 destacan |
| Sala de Reuniones | Baja y simétrica | «Una reunión a la que nadie vino». La silla volcada (B07) es la única ruptura |
| Despacho del Guardián | Media, ordenada | Cada objeto responde a un gesto (colgado, dejado, abandonado). Sin acumulación |
| Recepción | La más baja | La luz y el aire (3,20 m) son el contenido. Libro, mostrador, ventanal, puerta cerrada |

### 6.4 Narración ambiental
Pautas, con el Pilar 5 (información incompleta) como límite:
1. **Cada espacio plantea una pregunta y no la responde.** El detalle indica que falta algo, no qué.
2. **Estado antes que objeto.** Lo húmedo, lo frío, lo tachado, lo a medio empaquetar.
3. **Huecos como pistas.** Sillas sin ocupar, el borde de una foto, la «tarjeta sin foto». Muestra la ausencia y no su causa.
4. **El desgaste cuenta lo que el texto calla.** Si un detalle puede contarse con textura, no se añade un objeto (Sección 1, principio 1).
5. **Texto solo cuando el puzle lo exige.** El resto es relleno plano y breve (por ejemplo, los rótulos de las cajas del Archivo).
6. **Sin flechas ni énfasis.** La «V» cerrada del libro de visitas debe ser una diferencia mínima y no una indicación.

### 6.5 Visible frente a callado, por espacio
Se distinguen dos grados de «examinable»: **crítico** (puzle) y **de relleno**. El de relleno lleva bisel pero menos contraste que el crítico, para no generar falsas pistas.

| Espacio | Debe verse (protagonista) | Debe quedar callado (apoyo) |
|---|---|---|
| Despacho de Vera | Monitor, teléfono (V02), caja de cartón (V04), peluche (V05), impresora al imprimir | Persiana, armario, silla decorativa, cajón con bolígrafo y grapas |
| Pasillo | Panel de cronología (C05), lectores de tarjeta (C06, C07), cartel de planta (C04) | Luminarias en estado normal, altavoz de megafonía, marcos de puertas. El ascensor (C08) es mudo hasta que cambia su luz |
| Archivo | Caja de traslado (A03), formulario (A04), cajón inferior (A05) | Estanterías, cajas de relleno (A02), papelera (A06) |
| Sala de Reuniones | Las tres lámparas, las marcas del suelo (B08), el ventanal con el memorando (B04), la nota (B05) | Sillas, reloj (B06), silla volcada (B07) |
| Despacho del Guardián | Caja de madera (D01), marco de foto (D04), abrigo (D02), taza (D03) | Estantería baja, cajón (D05), perchero, silla |
| Recepción | Libro de visitas (R01) en su luz puntual | Mostrador, puerta de salida cerrada, ventanal |

### Pendientes de esta sección
- **Orientación de las sillas:** el anexo A.2/A.6 las orienta de forma que ambas apuntan hacia fuera del escritorio. Si es intencionado, la silla del Guardián girada hacia la puerta sería un buen rastro de movimiento; si no, es un error del anexo.
- **Persiana de Vera:** el slice dice que «tapa la ventana» y a la vez que no hay ventana (ver Sección 2).
- **«Sillas rodando por el pasillo»:** tratadas como movimiento periférico visible; el slice §6 solo define su sonido. A confirmar.
- **Foto del puzle 3 y marco del puzle 5:** verificar que no muestran al Guardián de forma reconocible ni reflejan a Vera de un modo que contradiga la Sección 5.

## 7. UI/HUD Visual Direction

**Regla de la sección:** la interfaz es lo más callado del juego. Existe para leerse, no para mirarse. Cuando la legibilidad y la atmósfera choquen, gana la legibilidad (regla de desempate de la Sección 1). Esta sección sirve al Principio 3 (*Mirar es elegir*) y al Pilar 4 (*Tensión sin castigo*).

### 7.1 Reparto: diegético frente a overlay

| Capa | Elementos | Regla visual |
|---|---|---|
| **Diegético** (existe en el mundo, lo ilumina y lo ocluye) | Ordenador (buscador, lista y lectura de correos), teléfono (mensaje «¿Jugamos esta noche?», opciones, llamada), documentos impresos | Comparte la paleta de UI (4.4) y la gramática de esquinas vivas (3.3). Emite luz blanco frío sobre las manos de Vera. Sin degradados ni ruido en la interfaz del propio software. |
| **Overlay** (pantalla, sobre el mundo) | Icono de interacción, menú de pausa (con pistas), subtítulos, pantalla de controles, accesibilidad, pantalla de inicio con advertencias, prompts de mando/teclado | Plano, tonos fijos, sin sombras ni brillos (3.3), sin ámbar (4.4). |

**Lo que no existe:** barra de salud, de cordura o de relación, game over, contador de pistas usadas, indicador de objetivos, brújula y marcadores de misión (slice §16 y Pilares 4 y 5). El jugador nunca ve una cifra que mida su rendimiento. Tampoco hay indicador de guardado automático: la pausa lo indica con texto.

**Márgenes seguros:** 5 % por lado (96 × 54 px a 1920×1080). Subtítulos y prompts no salen de ahí.

**Modo de enfoque a pantalla completa.** Todo texto necesario para resolver un puzle (ordenador, impresiones, formulario, memorando, teléfono) se lee en una vista ampliada a pantalla completa, con el tamaño mínimo de la UI y zoom. Nunca se exige leer texto 3D a distancia de juego. La interfaz diegética se ve en el mundo, pero se lee en esa vista, y por eso la escala de texto de accesibilidad también la cubre.

### 7.2 Tipografía

**Personalidad:** sans humanista, neutra, de oficina y sin gracia decorativa. Debe sentirse como software corporativo cansado y no como diseño de juego. Nada de serifas ni tipos «de misterio». Necesita distinguir `I / l / 1` y `0 / O`, porque los correos llevan referencias y horas.

**Elegida:** **Atkinson Hyperlegible Next** (OFL) para todo el overlay. Máxima legibilidad, pensada para baja visión, y refuerza la regla de desempate. Para el ordenador diegético se puede evaluar IBM Plex Sans (+ Plex Mono) en una prueba dentro del motor, por la identidad de «software de oficina».
Antes de importarla a Godot hay que verificar la licencia y que el archivo concreto cubre `¿ ¡ « » ñ á é í ó ú ü` y `…`.

**Jerarquía a 1080p (escala UI 100 %):**

| Rol | Tamaño | Peso | Color |
|---|---|---|---|
| Título de pantalla (Pausa, Accesibilidad) | 44 px | Bold 700 | Blanco frío `#DCE6E8` |
| Encabezado de sección | 32 px | Medium 500 | Blanco frío |
| Cuerpo (pistas, correos, opciones) | 28 px | Regular 400 | Blanco frío |
| Secundario (metadatos, remitente, hora) | 24 px | Regular 400 | Gris lluvia `#8FA3B0` |
| Subtítulos | 34 px | Regular 400 | Blanco frío |

Reglas:
- Ningún texto necesario baja de 24 px. Con mando se recomienda ≥ 28 px en cuerpo y subtítulos (a validar en pantalla real, a distancia de TV).
- **Gris lluvia:** su contraste sobre azul noche es de ≈5,6:1, por debajo del 7:1 de la 4.4. Queda restringido a texto ≥ 24 px y a información no esencial (marcas de tiempo, etiquetas). Nunca va en subtítulos, opciones de la llamada ni pistas.
- La selección no cambia de peso (evita saltos de maquetación). Usa brillo más subrayado o corchete (4.4).
- Sin cursiva ni versalitas.
- Se usan las comillas angulares `« »` y los signos `¿ ¡` del castellano. Formato de hora de 24 h.
- Interlineado 1,35 en cuerpo y alineación a la izquierda, sin justificar.

### 7.3 Iconografía

**Estilo:** contorno (outline) monocromo, trazo de 2 px, esquinas en inglete (rectilíneo, coherente con 3.2), sin relleno, sin sombra y sin degradado. Color único: blanco frío `#DCE6E8`. El icono se usa solo cuando ahorra lectura. El menú es texto.

**Regla de exclusividad del círculo:** el círculo pertenece a la luz del mundo (halos) y al icono de interacción. Ningún otro icono de overlay flotante usa círculos. Así el anillo con punto no se confunde con nada.

**Icono de interacción (3.3):**
- Anillo fino con punto central, blanco frío, sin halo ni sombra.
- Estándar: anillo de 28 px, trazo de 2 px, punto de 4 px, opacidad 80 %.
- Solo aparece sobre un objeto interactuable. No hay punto de mira permanente.
- **Filo plano de 1 px en azul noche `#1C2A38`** alrededor del anillo, para que no se pierda sobre fondos claros (monitor, papel, ventanal). No es sombra ni brillo, y amplía la gramática de 3.3.
- Dos estados que se distinguen por forma y no por color: solo punto (nada que hacer aquí) y anillo con punto (interactuable).
- Para la pulsación prolongada, el anillo se rellena mientras se mantiene, y hay una alternativa de alternar en accesibilidad.
- Versión grande (accesibilidad, 4.5): anillo de 48 px, trazo de 3 px, punto de 8 px, opacidad 100 % y contorno de 2 px.
- **Etiqueta de acción** («Abrir», «Girar», «Examinar», «Leer»): desactivada por defecto, activable en accesibilidad. Muestra además el glifo del botón, que cambia según el último dispositivo usado.

**Pistas (tres niveles):** sin iconos. Se usa **corchete más numeral**, `[1]` `[2]` `[3]`, junto a una etiqueta textual. Esto reutiliza el corchete de selección (4.4) y no depende del color. Sin candados ni cerraduras (se confundirían con la cerradura de decisión del puzle 5). Todos los niveles son visibles y ninguno lleva marca de «usado».

**Prompts de mando y teclado:**
- Glifos en contorno, tecla como rectángulo de esquinas vivas y botón de mando como forma neutra con su letra o símbolo.
- Se muestran **en línea con el texto** (menús, pantalla de controles, opciones del teléfono) y nunca flotando junto al anillo.
- Cambian automáticamente según el último dispositivo de entrada y reflejan el remapeo.
- Tamaño igual a la altura de línea del texto que los acompaña.

### 7.4 Animación y sensación de la UI

Principio: **todo se disuelve, nada irrumpe.**

| Evento | Comportamiento |
|---|---|
| Aparece el icono de interacción | Fundido de opacidad, 250 ms, ease-out |
| Desaparece | Fundido, 150 ms |
| Pulsar interactuar | El anillo sube de 80 % a 100 % de opacidad durante 120 ms. Sin escala |
| Abrir la pausa | Velo azul noche con desaturación suave (2.7), fundido de 350 ms. El mundo queda quieto |
| Cambio de selección | Brillo más subrayado, 120 ms. Sin desplazamiento |
| Mostrar una pista | Fundido de 400 ms, sin máquina de escribir. **Persiste hasta que el jugador la cierra** y se puede releer desde la pausa |
| Resultados del buscador | Aparecen a los 0,4 s del slice (C.2), con fundido corto |

Prohibido en toda la UI:
- Rojo (el rojo óxido está reservado y nunca es UI).
- Escalado con rebote, temblores y destellos.
- Contadores regresivos visibles.
- Sonidos de error agudos asociados a la UI. El tratamiento sonoro lo decide el audio-director.

El error de puzle no pertenece a la UI. Es el feedback del mundo (3.3): temblor frío, sin rojo. Cada acierto o error lleva además sonido y un cambio visual que no dependa del movimiento (símbolo o cambio de estado), para que se perciba en escenas oscuras o con reducción de movimiento.

**Opción «Reducir movimiento»:** sustituye los fundidos por un fundido fijo de 100 ms y el temblor por un cambio estático.

### 7.5 Subtítulos

- **Posición:** centrados abajo, dentro del margen seguro. Si coinciden con las opciones de la llamada, los subtítulos van arriba y las opciones abajo.
- **Formato:** máximo 2 líneas y unos 37 caracteres por línea (referencia a verificar: UNE 153010).
- **Panel:** azul noche `#1C2A38` al 85 % por defecto. Opciones 100 % y «sin panel» (esta última con contorno de 2 px).
- **Texto:** blanco frío, 34 px.
- **Locutor:** etiqueta en texto, p. ej. `VERA:` o `GUARDIÁN:`, nunca por color (4.5). El Guardián solo es voz, así que la etiqueta es imprescindible.
- **Efectos sonoros relevantes:** entre corchetes y en gris lluvia, describiendo el sonido y no la emoción (p. ej. `[teléfono vibra]`). Lo exige slice §17: ningún texto indica cómo sentirse.
- **Aparición:** fundido de 150 ms. Desaparición: fundido de 250 ms.
- **Tiempo en pantalla:** mínimo 1 s y unos 15 caracteres por segundo.
- **Tamaños:** 100 / 125 / 150 / 200 %.

### 7.6 Reglas visuales de accesibilidad

| Opción | Efecto visual |
|---|---|
| **Escala de texto UI** | 100 / 125 / 150 %. Los paneles se reflowean y no se recortan. Cubre también la vista de enfoque (7.1) |
| **Escala de subtítulos** | Independiente (7.5) |
| **Alto contraste** | Paneles al 100 %. Secundario pasa a blanco frío. Corchetes y subrayados más gruesos (3 px). Sin transparencias |
| **Icono de interacción grande** | Variante de 7.3 (exigido por 4.5) |
| **Etiquetas de acción** | Activa el texto bajo el anillo |
| **Reducir movimiento** | 7.4 |
| **Reducir sobresaltos / destellos** | Atenúa parpadeo del pasillo y apagón (pendiente de 2.7) y limita todo destello a un tope duro de 2 ciclos por segundo, con pausas mínimas de 0,35 s (8.7). La UI ya no parpadea |

- **Daltonismo:** nada en la UI se distingue solo por color. Selección = brillo más forma; locutor = texto; nivel de pista = numeral.
- **Contraste:** el blanco frío sobre azul noche da ≈11,5:1, cumpliendo el objetivo de 7:1. Con el panel al 85 % sobre el fondo más claro del mundo baja hacia el límite (≈7,1:1), y los subtítulos admiten 100 %.
- **Opciones de la llamada durante el apagón:** el foco se marca con corchete, subrayado y posición, y no solo con brillo. Se limita la luminancia máxima del panel en esa escena, el foco inicial es determinista y la navegación vertical con mando. No hay temporizador: «No responder» es un botón.
- **Ordenador con mando:** teclado en pantalla o sugerencias de búsqueda seleccionables, navegación por foco y salida siempre con el mismo botón. Sin scanlines, bloom fuerte ni parpadeo.
- **Requisitos mínimos del documento de accesibilidad** (`design/accessibility-requirements.md`): todo el juego completable solo con teclado y ratón o solo con mando, con remapeo completo; subtítulos que cubren todas las líneas del §12, incluida la llamada; volúmenes de voces, efectos y música independientes; todo sonido de feedback con equivalente visual.

### 7.7 Pantalla de inicio y pausa (resumen)

- **Inicio con advertencias (slice §17):** solo texto sobre azul noche, sin animación. Fundido de entrada de 600 ms. Avanza solo cuando el jugador lo decide.
- **Pausa:** columna de texto a la izquierda y panel de contenido a la derecha. Entradas del slice §16: Pistas, Subtítulos, Controles, Accesibilidad. Sin confirmaciones alarmistas. Cualquier diálogo usa tono neutro y botón por defecto en la opción segura.

### Pendientes y cambios que obliga a hacer en el slice
- **Pista del puzle 2 (slice B.2):** el texto dura 2 s. Debe persistir hasta que el jugador lo cierre y poder releerse desde la pausa.
- **Puzle 1 con mando (slice C.2):** escribir «transición» exige teclado en pantalla o búsqueda sugerida.
- **Pausa (slice §16):** faltan volumen independiente (voces, efectos, música), «reducir sobresaltos» y salir del juego. Sugerencia: lo visual en Accesibilidad y un submenú propio de Sonido.
- **Gesto de cámara como pista de nivel 1 (slice §10):** debe tener alternativa equivalente en el menú, sin marcador visual.
- **Nombres de los niveles de pista:** el slice solo los numera. Decidir si se nombran; el contador de pistas usadas no se muestra en ningún caso.
- **Extensión de 3.3:** el filo de 1 px del icono queda aprobado aquí y amplía esa sección.
- **Evidencia:** las temporizaciones de fundido y los tamaños de texto se validan en pantalla (captura retenida en `production/qa/evidence/`), a 1080p y a distancia de TV.

## 8. Asset Standards

> Esta sección reúne la dirección de arte (lo que queremos) y los límites duros del motor (lo que podemos). Las cifras marcadas **[A]** son suposiciones del technical-artist: `project.yaml` no tiene bloques `performance` ni `platform` y el equipo de referencia está sin definir (slice §21). Cuando arte y motor difieren, se registran ambas posturas y la decisión tomada (8.9).

### 8.1 Formatos de archivo

| Tipo | Formato preferido | Notas |
|---|---|---|
| Modelos | **glTF 2.0 binario (`.glb`)**, uno por asset | Se acepta FBX solo si la fuente no exporta glTF. Metros, transformaciones aplicadas, sin escala negativa, origen en el centro de la base |
| Fuente de modelos | `.blend` en `assets/art/source/` | No se importa en el juego ni viaja en el build |
| Texturas | **PNG** sin pérdida, 8 bits, externas al `.glb` | No se importan JPG: su compresión se acumula con la de VRAM. Un JPG de origen puede servir de material de partida y se re-exporta a PNG tras limpiarlo |
| Mapas de datos (rugosidad, normal) | PNG lineal | Albedo en sRGB. Normal en convención OpenGL (Y+), tangent space |
| Decales de texto | PNG con alfa, autoría propia | La IA no escribe texto legible (6.2) |
| Materiales compartidos | `.tres` de Godot | No se confía en los materiales incrustados en el `.glb` |

### 8.2 Convención de nombres

**Regla base:** `snake_case`, minúsculas, sin acentos ni `ñ`, sin espacios, con **sustantivos en español**. Estructura: `[categoría]_[nombre]_[variante]_[tamaño].[ext]`.

**Por qué todo en minúsculas:** el export a Linux distingue mayúsculas y Windows no. Un `Caja.png` referenciado como `caja.png` funciona en el editor de Windows y se rompe en el build de Linux.

Categorías: `env_` (arquitectura y trim), `prop_` (objetos), `char_` (manos, peluche, proxy de reflejo), `tex_` (texturas sueltas), `decal_` (texto superpuesto), `mat_` (materiales), `vfx_`, `ui_`.

Ejemplos: `prop_caja_madera.glb`, `tex_caja_madera_albedo_1k.png`, `tex_caja_madera_rough_1k.png`, `decal_memorando_espejo_2k.png`, `mat_papel_ficha.tres`.

El sufijo de tamaño indica la resolución del mapa (`_2k`, `_1k`, `_512`), no el tier. El tier se registra en la ficha del asset (8.8).

**Relación con los IDs del slice:** `caja_c1`, `V02`, `B02`, `C05`, `D01a` **no son nombres de archivo**. Son **nombres de nodo** dentro de la escena y claves de datos, y se conservan tal cual, con sus mayúsculas. Un `prop_lampara_escritorio.glb` se instancia varias veces con sus IDs. Los IDs de voz (`VO_G_12A`) y de sonido (`SFX_UNLOCK`) conservan su forma en los datos. El nombre del archivo de audio lo decide el audio-director, avisado del riesgo de mayúsculas en Linux.

**Sufijos de Godot dentro del `.glb`:** los hints del importador (`-col`, `-convcolonly`, `-occ`) van en nombres de nodo, nunca en nombres de archivo. Son la única excepción a `snake_case`.

### 8.3 Tiers de textura

Los tiers de 6.2 se definen por **densidad de texel** (píxeles por metro), cada escalón el doble del siguiente, con un techo de resolución por mapa. **Decisión:** se adopta el estándar restringido (1K por defecto en Hero, 2K reservado), no el ideal de 2K en todo lo examinable.

| Tier | Densidad [A] | Techo por defecto | Mapas | Compresión | Qué entra |
|---|---|---|---|---|---|
| **Hero** | ~1024 px/m | **1K** (2K reservado, ver abajo) | Albedo, normal solo aquí, rugosidad por mapa o por parámetro | Albedo BC7 (calidad alta). Normal BC5 | Todo lo examinable (3.4): caja, panel del puzle 1, marco de foto, fichas, teléfono, peluche, manos |
| **Estándar** | ~512 px/m | **1K** | Albedo. Rugosidad por parámetro | BC1 (BC7 si hay degradados con banding) | Mobiliario cercano no examinable, puertas, ordenador, lámparas |
| **Fondo** | ~256 px/m | **512** (trims 1K) | Albedo | BC1 | Muros, techo, suelo (por trim sheet), props lejanos, ventana exterior |

- **2K reservado** para la máscara del memorando (2048×1024, R8 sin pérdida, ≈2,7 MB) y el atlas de la foto de las piezas del puzle 3, que se comparte con el marco de la pared y el del puzle 5. **Papeles legibles y foto nunca bajan de su resolución.**
- **Orden de sacrificio** si la VRAM aprieta: primero Estándar a 512; después Hero a 1K excepto papeles y foto; Fondo nunca por debajo de 256 px/m (el pasillo repetido delata el pixelado).
- **Trim sheets:** una por familia (muro, techo, suelo, mobiliario laminado) a 1K–2K. Es la mejor palanca para ahorrar memoria sin perder coherencia. La repetición del pasillo no se aleatoriza (6.2).
- **Presupuesto de VRAM de texturas [A]:** ≤256 MB. Reparto: Hero ≤80, Estándar ≤60, Fondo y trims ≤30, UI y decales ≤30, lightmaps ≤20 y margen 36. Recepción se carga de forma asíncrona durante la escena 7, con presupuesto ≤30 MB [A].
- **Mipmaps** activados en todo lo 3D y desactivados en UI. Anisotrópico 8x [A], por los suelos rasantes del pasillo.
- **Banding:** el slice es oscuro y de rango de valores restringido, y la compresión por bloques marca degradados en las sombras. Si aparece, es un defecto de arte y no «estilo»: se valora dithering o debanding.
- **Memorando:** se guarda legible en la textura y se espeja en el shader (`uv.x = 1 - uv.x`), para que el fuente sea revisable.
- **Compresión de proyecto:** solo S3TC/BPTC en PC. ETC2/ASTC desactivado.

### 8.4 LOD

- **Un solo LOD (LOD0)** en todo el slice: escena continua y pequeña, sin cambios visibles (5.5). La distancia se resuelve por densidad de texel y no por mallas alternativas.
- **Generación automática de LOD desactivada** en la importación: puede deformar las siluetas facetadas, y la silueta es el contrato visual de 3.1 y 3.2. Verificar su comportamiento por defecto en 4.7.
- Manos: un solo LOD, ≤45 huesos entre ambas, ≤4 pesos por vértice, sin blendshapes. El proxy de cuerpo entero del reflejo lo resuelve el technical-artist.

### 8.5 Política de materiales

- **Todo asset:** albedo + rugosidad. **Normal solo en Hero**: en el decorado delata el «mapeado barato».
- **Rugosidad como portadora de significado:** cristal, abrigo mojado y papel (6.2). Se importa vinculada a su normal (`roughness/src_normal`) para reducir el parpadeo especular.
- **Metalizado** casi siempre cero. **Emisión** solo en lámparas y pantalla del ordenador.
- **Un material por prop** como ideal, con material compartido para familias (papel, laminado, metal pintado). Ningún material nuevo entra por comodidad del autor.
- **Límites [A]:** ≤40 materiales únicos y ≤8 shaders únicos en el slice. Slots de material por malla: 1 por defecto, ≤2 en Hero.
- Cristal, lluvia y memorando al revés (slice §15) son shaders a medida (8.7).

### 8.6 Presupuestos de triángulos y de escena [A]

Se cuentan triangulados y tras la importación.

| Categoría | Objetivo / tope | Notas |
|---|---|---|
| Prop pequeño (papeles, carpetas, taza) | 50–300 / 500 | Sin sombra proyectada |
| Prop mediano (silla, mesa, escritorio, monitor, estantería) | 500–1.500 / 2.500 | 1 slot (2 si hay pantalla o cristal) |
| Examinable Hero (caja, marco de 6 huecos, panel, lámparas, teléfono, botones, fichas) | 1.500–4.000 / 6.000 | Bisel que atrape luz (3.4) |
| Puertas (A, B, D) | 800–1.500 / 2.000 | Cerradura incluida |
| Módulos de set | 4–50 por tramo; marco 150–500 | Pasillo completo ≤10k, sala completa ≤4k |
| Manos y mangas (par) | 1.500–2.500 / 3.000 | Un solo LOD |
| Proxy de reflejo | 400–800 / 1.000 | Sin iluminar; silueta sin dedos ni rostro |
| Escena | ≤300k triángulos en la peor vista (pasillo con puerta abierta) | `cast_shadow` desactivado en props pequeños |

- **Frame-time (TBD):** equipo de referencia sin definir. Asunción conservadora [A]: GPU de gama media de hacia 2018 (clase GTX 1060 / RX 580, 4 GB de VRAM), 4 núcleos, 8 GB de RAM, 1080p a 60 fps objetivo y suelo duro de 30. Si no se llega, `scaling_3d` al 75 % con FSR. Presupuesto de GPU de 12 ms sobre 16,6 ms. Los 60 fps y las ~1500 draw calls son provisionales en `technical-preferences.md`; objetivo interno de ≤500 draw calls en la vista normal [A].

### 8.7 Shaders P0, iluminación y fotosensibilidad

**Shaders P0** (presupuesto conjunto ≤2 ms de GPU [A], medido con tiempo de GPU o RenderDoc):

| Shader | Diseño recomendado | Presupuesto [A] |
|---|---|---|
| **Lluvia** (ventanales B, D y patio) | Exterior como carta con imagen (P1) y rayas por scroll de un ruido de flujo de 256². Sin `hint_screen_texture` (fuerza copia del backbuffer). Uniforme `rain_amount` (en Recepción baja a 0 y los reflejos quedan fijos). Partículas solo tras la ventana, con `VisibleOnScreenNotifier3D` | ≤4 fetches y ~60 ALU. ≤400 partículas en total. 1 draw por ventana |
| **Cristal con memorando** | Máscara espejada más 3 uniformes de haz (posición, radio, intensidad). Fresnel y sonda de reflexión. Uniforme `reflection_strength` para suprimir el reflejo durante el puzle 2 (5.2) | 2 fetches, 1 draw por superficie |
| **Marco reflectante del puzle 5** | Reflexión analítica: se intersecta el vector reflejado con un plano virtual que contiene la foto de la pared. El alineamiento sale de la geometría, sin viewport de espejo | 2 fetches, 1 draw, sin render target |
| **Parpadeo** | No es un shader: una secuencia de datos (`FlickerSequence`) mueve `light_energy` y el emisivo del tubo. Uniforme global `flicker_scale` para «reducir sobresaltos» | 0 draws nuevos. Tubos sin sombra |

**Iluminación en Forward+:**
- **Sin lightmaps al inicio.** Luces dinámicas más ambiente por sala, con `ReflectionProbe`. Un `LightmapGI` conserva el indirecto horneado y no sigue al parpadeo ni al apagón de las 02:30, y exige UV2, que los assets gratuitos y de IA no suelen traer. Solo se reconsidera, en modo Dynamic, si la prueba de escena de 30 s (slice §22) demuestra que falta rebote. «Sin luz horneada» se refiere a las **texturas**, no a la iluminación del motor.
- **Luces [A]:** ≤8 por vista y ≤2 con sombra por sala. Se prefieren spots a omnis. Sin luz direccional (es de noche). Pasillo: 6 tubos sin sombra. Despacho: lámpara con sombra para la sombra de las manos. Sala B: 3 spots de lámpara sin sombra, porque el haz sobre el cristal lo hace el shader. No depender de `AreaLight3D` (4.7, no verificado).
- **Culling:** `OccluderInstance3D` en los muros, con activación de luces por sala.
- **Reflejos de 5.2:** SSR no sirve (no refleja lo que está detrás de la cámara). Vera: proxy de silueta oscura con el retardo aplicado, espejado detrás del cristal. Ambiente: una `ReflectionProbe` por sala y 2–3 en el pasillo. Espejo planar con SubViewport solo como plan B, a media resolución.
- **Post:** evitar SSIL, SDFGI y VoxelGI. Antialiasing MSAA 2x–4x o SMAA 1x; evitar TAA (fantasmas sobre lluvia). El glow amplifica el parpadeo de los emisivos, así que cuenta para el límite de fotosensibilidad.

**Fotosensibilidad (decisión: tope duro de 2 por segundo):**
- Tope de **2 ciclos por segundo** con pausas mínimas de 0,35 s entre parpadeos, **siempre activo**, aunque la opción de accesibilidad esté apagada. El slice («3 veces, 0,15 s cada vez») no fija el intervalo y sin pausa podría llegar a ~3,3 Hz.
- Modo «reducir sobresaltos»: el parpadeo no baja del 40–50 % del nivel nominal [A] y las rampas son lentas. El apagón es una sola caída en ≥0,3 s [A], sin parpadeo de restauración.
- Validación con una herramienta de análisis de destellos, con captura retenida en `production/qa/evidence/`. Lo cierra el accessibility-specialist (2.7).

### 8.8 Importación, exportación y ficha de asset

1. Preset de importación **por tier**, guardado en el proyecto, para no depender de la memoria de quien importe.
2. Albedo en sRGB; rugosidad y normal en lineal.
3. Tangentes solo en mallas con normal. UV2 solo si se hornea. Texturas externas y nombres en `snake_case`.
4. **Shader Baker (4.5+)** en el export, para evitar tirones de compilación, más un calentamiento de los shaders P0 al cargar.
5. Las fuentes (`.blend`, PSD, PNG de origen) viven en `assets/art/source/` y se excluyen del export.
6. **Ficha mínima por asset:** tier (Hero/Estándar/Fondo), categoría, origen y espacio donde vive. Permite auditar la coherencia entre espacios sin abrir cada escena.

**Checklist de aceptación para modelos gratuitos y generados por IA.** Un asset de terceros o generado no entra en la escena hasta cumplir todo esto:
- **Geometría:** sin no-manifold, caras duplicadas ni vértices sueltos; normales coherentes; topología facetada y simple (6.1), con malla densa y «blanda» rehecha o descartada; sin partes ocultas; UVs sin solapes y con densidad acorde al tier; triángulos dentro del tope de su categoría (8.6).
- **Escala y pivote:** validado a escala real contra un objeto de referencia (puerta, silla); pivote en la base, sin escala ni rotación pendientes.
- **Conformidad visual (3.4, 4, 6.2):** albedo recolocado en la paleta; sin luz ni sombras horneadas en el albedo (se comprueba con una sola luz en el visor); decorado plano y mate; examinable con bisel y contraste; sin texto legible generado, sin rostros ni manos en textura; sin contornos dibujados. Revisado **en escena, con la iluminación del espacio**.
- **Uso permitido de la IA:** texturas albedo revisadas, el exterior P1 y referencia o kitbash. Las mallas de IA y gratuitas pasan por retopología hasta el tope de su categoría y se re-texturizan con la paleta.
- **Procedencia (para la declaración de IA, slice §18):** entrada creada en el registro **antes** de importar, con archivo e ID, origen (IA / gratuito / autoría propia), herramienta y versión, plan y licencia con fecha de comprobación, fuente o prompt, autor, modificación humana y si lo ve el jugador. Registro único en `assets/art/PROVENANCE.md`. Modificar un asset generado no lo convierte en autoría propia a efectos de la declaración; la decisión legal es del usuario.

### 8.9 Registro de tensiones y decisiones

| Preferencia de arte | Límite técnico | Decisión |
|---|---|---|
| Hero a 2K en todo lo examinable | VRAM (≤256 MB [A]) sin equipo de referencia | **Estándar restringido:** 1K por defecto, 2K reservado a memorando y atlas de foto; papeles y foto no bajan |
| Sin LOD, silueta facetada intacta | LOD automática del importador | LOD0 único, generación automática desactivada |
| Normal solo en Hero | Ninguna previsible | Aprobado |
| Compresión alta en texto y albedo Hero | Tamaño del paquete | Se mantiene en texto y Hero; estándar en el resto |
| Parpadeo expresivo del pasillo | Fotosensibilidad | Tope duro de 2 ciclos por segundo, siempre activo |
| Nombres de archivo | Idioma | Sustantivos en español, `snake_case`, minúsculas |

### Pendientes de esta sección
- **FOV de la cámara:** el slice fija 70°, pero `Camera3D.fov` es vertical por defecto (70° vertical son ~102° horizontales en 16:9). Decidir cuál es, porque cambia las densidades de texel y la sensación de espacio.
- **Equipo de referencia y backend de Windows** (D3D12, predeterminado desde 4.6, o Vulkan): sin ellos todas las cifras [A] son opinión. Perfilado temprano en cuanto haya equipo; decisión del technical-director.
- **Campo de visión de las manos:** corregir la proyección en el `vertex()` del shader de las manos, sin segunda cámara. Escribir `PROJECTION_MATRIX` en 4.7 está sin verificar.
- **Confirmar en 4.7:** comportamiento por defecto de las LOD automáticas, el frente del modelo en glTF (+Z), `AreaLight3D` y el aplicado de SSR a materiales transparentes.
- **Registro de procedencia:** crear `assets/art/PROVENANCE.md` antes de importar el primer asset de terceros o generado.

## 9. Reference Direction

**Cómo se eligieron.** Son cuatro referencias, y cada una responde a una pregunta distinta del Art Bible: dónde cae la luz (Hopper), cómo se lee un puzle con pocos valores (Obra Dinn), cómo es un edificio que nadie diseñó (Severance) y cómo se encuadra la ausencia (Höfer). Ninguna aporta personajes, criaturas ni HUD. Se toma de cada una una técnica concreta, nunca su estética general. Los hechos citados son los que se conocen con seguridad; lo que no, se marca con **[verificar]**.

### 9.1 Edward Hopper (pintura, años 30-50) · La luz como forma

- **Qué tomar:** la **mancha de luz de borde duro**. En sus interiores nocturnos la luz es una forma geométrica y legible (un rectángulo sobre una pared, un haz que cruza un suelo) contra un resto en sombra sobria. La fuente artificial es casi siempre la única cálida o la única brillante del cuadro. *Nighthawks* (1942) sirve de referencia para la **luz fluorescente verdosa** del interior frente a una calle oscura. *Office at Night* (1940) sirve para el **escritorio con lámpara como único foco** dentro de un espacio de trabajo.
- **Qué evitar o cambiar:**
  - No hay figuras. En Hopper la gente es el tema, aquí solo se toma la luz.
  - No se toma su calidez general. En sus cuadros lo cálido suele extenderse, y en el juego el ámbar es escaso y ≠ seguridad (4.2).
  - No se toma la pincelada ni la nostalgia de la América de mediados de siglo.
  - No se hacen recreaciones de composiciones suyas. Una captura que se lea como «un Hopper» es un fallo.
- **Soporta:** Sección 1 (Principio 1), 2.2 (charcos de luz sobre lo examinable), 2.3 (halo definido), 4.2 y 6.3.
- **Prueba de uso:** el charco de luz sobre el panel o la caja debe poder describirse como una forma («un trapecio de luz fría sobre el escritorio»), no como un brillo difuso.

### 9.2 *Return of the Obra Dinn* (Lucas Pope, 2018) · Legibilidad con un rango de valores mínimo

- **Qué tomar:** la **disciplina de valor**. Con un rango tonal extremadamente restringido (1 bit con dithering), todo lo que no es pista queda callado y la forma y la posición hacen el trabajo de guiar la mirada. Es la prueba de que un rango de valores restringido no resta legibilidad si el contraste se concentra en lo examinable. Aplicado al juego: papeles, fichas y la caja se separan por valor y bisel (Principio 3, 3.4), y el decorado se mantiene en baja frecuencia.
- **Qué evitar o cambiar:**
  - No se copia el 1 bit ni el dithering. La paleta es la de la Sección 4, con color.
  - No se usan contornos dibujados (3.5 los excluye).
  - No se representan escenas congeladas de muerte con figuras. Eso contradice «insinuar, nunca mostrar».
  - No se toma su estructura de juego, solo su disciplina visual.
- **Soporta:** Sección 1 (Principio 3 y desempate), 3.4, 3.5 («rango de valores restringido»), 6.2 (silueta por valor) y 7.6.
- **Prueba de uso:** en escala de grises y a baja resolución, el objeto examinable sigue siendo lo primero que se lee. Es la misma prueba que ya exige 4.5 para el daltonismo.

### 9.3 *Severance* (Apple TV+, 2022) · Arquitectura de institución

- **Qué tomar:** el **lenguaje de espacio institucional**. Pasillos largos y repetitivos, luz fluorescente uniforme y un entorno indiferente en el que lo inquietante nace de la ausencia de decisión estética. Es la referencia de «arquitectura de nadie» (6.1) y de la repetición deliberada del pasillo sin aleatorizar (3.2, 6.2). Tomar la idea de que **la neutralidad es el comentario**. Detalles concretos de color y materiales: **[verificar con fotogramas antes de fijarlos en un prompt]**.
- **Qué evitar o cambiar:**
  - No se toma el blanco clínico ni la simetría de gran angular. Nuestra planta es verde humo, azul y gris lluvia, sucia de reforma intermedia y con cartón de mudanza (tres capas de tiempo, 6.1).
  - No se toma el surrealismo cómico ni el tono de sátira.
  - No se toman logotipos, tipografía corporativa ni el vestuario.
  - Nuestro edificio no tiene marca ni ideología visible.
- **Soporta:** 6.1, 3.2, 2.4 (pasillo), 4.3 y 6.3.
- **Prueba de uso:** una captura de la planta nueve no debe delatar una empresa concreta. Si «parece Lumon», se ha copiado.

### 9.4 Candida Höfer (fotografía, interiores vacíos) · Encuadre de la ausencia

- **Qué tomar:** el **encuadre frontal y sereno de espacios sin gente**, con luz neutra y pareja. La ausencia es el sujeto y no se subraya con efectos. Es la referencia para la Recepción (2.6, ~5600 K, sin ámbar, reflejos fijos), para la Sala de Reuniones con sillas vacías y para «el edificio espera». Detalle de series o espacios concretos: **[verificar; no se especifican títulos]**.
- **Qué evitar o cambiar:**
  - No se toma su grandeza ni su arquitectura histórica (teatros, bibliotecas). Nuestros espacios son funcionales.
  - No se toma el equilibrio estático como regla. En juego la cámara es del jugador y manda su mirada, no el encuadre.
  - No se toma la nitidez fotográfica ni el detalle fino. El low poly es «recordado, no documentado» (3.5).
- **Soporta:** 2.6, 2.3, 5.3 (ausentes), 6.4 y 6.5.
- **Prueba de uso:** el estado de calma (Recepción, pausa) debe poder leerse como espacio vacío que ha dejado de ser amenazante sin cambiar objetos, solo la luz.

### 9.5 Por qué no se solapan

| Referencia | Aporta | Pregunta que responde | No aporta |
|---|---|---|---|
| Hopper | Forma de la luz | ¿Dónde cae y qué forma tiene? | Figuras, calidez extendida |
| Obra Dinn | Disciplina de valor | ¿Cómo se lee una pista con poco rango? | Contorno, 1 bit |
| Severance | Arquitectura | ¿Cómo es un edificio de nadie? | Blanco clínico, sátira |
| Höfer | Encuadre | ¿Cómo se compone la ausencia? | Grandeza, simetría obligatoria |

Se descartó *Kentucky Route Zero* (Cardboard Computer) por solaparse con Hopper en «la luz talla el espacio» y por su color saturado, que contradice el ámbar escaso.

### 9.6 Cómo usar esta sección

- **Artistas:** cada referencia es una **herramienta de revisión, no un moodboard**. Usa solo la columna «Qué tomar». Si una captura recuerda a una referencia en conjunto, es una señal de alarma.
- **Prompts de IA (texturas, exterior P1, kitbash):**
  - No nombres artistas, juegos ni películas en el prompt. Describe la técnica en términos propios (por ejemplo «mancha de luz fría de borde duro sobre pared verde grisácea, sin figuras»).
  - Nombrar obras puede arrastrar estilo ajeno y complica la declaración de procedencia (8.8).
  - Las referencias se guardan para la revisión humana, no para el prompt.
- **Revisión de escena:** antes de aprobar una captura, pasa estas tres pruebas.
  1. ¿La luz se puede describir como forma? (Hopper)
  2. ¿Se lee lo importante en escala de grises? (Obra Dinn)
  3. ¿Hay algo en la imagen que delate una marca o una época concreta? (Severance)
- **Jerarquía:** las referencias nunca anulan las reglas bloqueadas. Si una referencia sugiere ámbar estable, una figura o un contorno, gana el Art Bible. La legibilidad de un puzle gana siempre a la atmósfera.

### Pendientes de esta sección
- **Verificar con imágenes** antes de citarlos como guía concreta: colores y materiales de *Severance* y las series de Höfer.
- **Imágenes de referencia:** este documento no las incluye por derechos. Si se quiere un archivo de consulta interna, decidir dónde vive (fuera del repositorio o en `assets/art/source/`, excluido del export) y si cuenta para el registro de procedencia.
- **Quinta referencia** opcional para reflejos y lluvia sobre cristal: sin candidata verificable por ahora.
- **Sala de Reuniones:** *Severance* aporta al pasillo y poco a ese espacio, el único «con diseño» (6.1); el peso lo lleva Hopper.
