# 03 · Kit de mecánicas (del piloto «La Caja»)

El piloto es un objeto único que se resuelve con una cadena de seis piezas mecánicas. Aquí están desmontadas con los valores del código, para reutilizarlas tal cual. Los puzles de `04` solo combinan estas piezas.

**La cadena del piloto, para tenerla en la cabeza:**

```
Tapa lateral (pista) ─► Tambores (combinación) ─► Cajón (objeto) ─► Eje + manivela (accionar) ─► Pestillo (desbloqueo) ─► Revelación (final)
                                                                   Medallón: gira, no hace nada
```

Por qué funciona y hay que conservarlo:
- **Una sola idea por cara.** Cada cara del objeto tiene una cosa que hacer.
- **Todo responde.** Cada gesto da sonido y movimiento, acierte o no.
- **El bloqueo explica el bloqueo.** Lo que no se puede hacer todavía se resiste y dice dónde mirar («escucha el mecanismo de atrás»).
- **El objeto se gana en la mano.** El engranaje se ve brillar, se coge, vuela hacia la cámara y aparece en el hueco.
- **Sin interfaz de puzle.** No hay paneles 2D: todo ocurre sobre el objeto en 3D.

---

## M0 · Modo examen (cámara y navegación)

| Parámetro | Valor en el piloto | Notas para el juego |
|---|---|---|
| Vista general | Órbita alrededor del objeto. Arrastre: giro horizontal 0,0065 rad/px, vertical 0,005 rad/px; inclinación limitada a 0,1–1,3 rad. Inercia al soltar (amortiguación 0,93 / 0,90 por fotograma) | Con mando: stick derecho = órbita |
| Zoom | Rueda o pellizco, 0,6× a 1,5× | Opcional |
| Enfocar una cara | Tocar una cara la enfoca: la cámara viaja (suavizado exponencial, k = 1 − e^(−5·dt)) a una vista frontal de esa cara | Con mando: botón de acción sobre la cara apuntada |
| Navegación enfocada | Botones ◀ ▶ (cara anterior/siguiente en el orden frente → derecha → trasera → izquierda), ▲ Arriba (cara superior), ✕ Volver (vista general) | Con mando: LB/RB, Y, B |
| Regla clave | **Solo se manipula la cara enfocada.** En vista general, tocar algo enfoca su cara; no lo acciona | Evita accionar cosas por accidente al orbitar |
| Luz | Una luz puntual sigue a la cámara; sube de 5 a 9 al enfocar | Equivale a la linterna/lámpara de Vera |
| Aviso de contexto | 650 ms después de enfocar una cara, aparece un aviso que depende del estado de esa cara (ver M8) | — |

## M1 · Tapa con asa (pista oculta)

Una tapa abatible cubre una placa grabada. Se levanta arrastrando hacia arriba.

| Parámetro | Valor |
|---|---|
| Gesto | Arrastre vertical hacia arriba |
| Sensibilidad | 0,012 rad por píxel |
| Recorrido | 0 a 1,65 rad. Se queda donde se suelta (no vuelve sola) |
| Suavizado | 14 por segundo |
| Lectura | A partir de 1,0 rad la pista se considera vista: se dispara una sola vez el aviso de lectura (5,2 s) |
| Sonido | `creak` al empezar el arrastre |
| Estado guardado | `flapSeen` |

**Uso:** la pista vive en el propio objeto, pero escondida. El jugador aprende que mirar es una acción.

## M2 · Tambores (combinación)

Prismas hexagonales que giran sobre un eje horizontal común, cada uno con un símbolo por cara.

| Parámetro | Valor |
|---|---|
| Caras por tambor | 6 (paso de 60°) |
| Gesto | Arrastre vertical sobre el tambor |
| Sensibilidad | 30 px = un paso |
| Clic | `tick` cada vez que el tambor cruza un paso |
| Al soltar | Imán al paso más cercano; entonces se comprueba la combinación |
| Suavizado visual | 18 por segundo |
| Posición inicial | No resuelta y distinta en cada tambor (piloto: 4, 1, 3) |
| Al resolver | Tambores bloqueados. `chime`; a los 0,5 s `clunk`; a los 0,25 s `slide`; aviso; el cajón sale en 1,4 s |
| Fallo | No existe como evento. Una combinación mala simplemente no abre nada |

**Uso:** copiar o deducir un código a partir de una pista. La pista nunca está en la misma cara que los tambores.

## M3 · Cajón, objeto e inventario de un hueco

| Paso | Comportamiento |
|---|---|
| El objeto espera | Dentro del cajón, el objeto gira despacio (0,8 rad/s) y tiene un halo que late (opacidad 0,45 ± 0,25 a ~0,5 Hz) |
| Coger | Tocarlo: `pick`; vuela hacia la cámara en 0,7 s encogiéndose al 10 % y desaparece; aparece el **hueco de inventario** abajo a la izquierda con su icono, **ya seleccionado** |
| Inventario | **Un solo hueco.** Tocarlo alterna seleccionado / no seleccionado (`tick`). Seleccionado = borde iluminado |
| Destino | El sitio donde va el objeto muestra un **anillo de guía que late** solo mientras el objeto está seleccionado |
| Usar | Tocar el destino con el objeto seleccionado: el objeto aparece a 0,9 de distancia y entra en su sitio en 0,8 s; `clunk`; aviso; el hueco de inventario desaparece |
| Usar sin tenerlo | Aviso: «Aquí falta una pieza» |
| Usar sin seleccionarlo | Aviso: «Selecciona la pieza» |

**Uso:** llevar algo de una cara a otra. Une dos puzles del mismo objeto.

## M4 · Eje y manivela (accionar con progreso)

| Parámetro | Valor |
|---|---|
| Gesto | Arrastre circular alrededor del eje de la manivela (se calcula el ángulo del puntero sobre el plano de la cara) |
| Clic | `tick` cada 30° |
| Sin la pieza | Los engranajes giran en vacío. Tras media vuelta (180°), aviso una vez: falta una pieza en el eje |
| Con la pieza | Progreso = \|giro acumulado\| / 4π (es decir, **dos vueltas completas**, en cualquier sentido) |
| Indicador | 4 gemas que se encienden al 25, 50, 75 y 100 % (suavizado 8/s, giran más rápido encendidas) |
| Engranajes | Todos giran a la vez con la relación de dientes correcta (11, 15, 11, 9). Se ve el mecanismo trabajar |
| Al completar | `clunk`, `chime` a los 0,25 s, aviso, desbloqueo de otra cara. La manivela queda inmóvil |

**Uso:** un esfuerzo físico que se ve avanzar. Convierte «colocar» en «hacer funcionar».

## M5 · Pestillo bloqueado (desbloqueo con resistencia)

| Parámetro | Valor |
|---|---|
| Gesto | Arrastre horizontal sobre un carril |
| Recorrido | De −0,62 a +0,62 (unidades de escena) |
| Bloqueado | Avanza hasta un tope a 0,16 del inicio, `rattle` (como mucho cada 350 ms) y aviso que señala la causa. Al soltar vuelve al inicio |
| Indicador | Gema roja; pasa a verde al desbloquear |
| Desbloqueado | El carril mueve las dos tapas superiores proporcionalmente (hasta 1,85 rad cada una) |
| Disparo | Cuando la apertura supera el 55 %, empieza la revelación (M6) |

**Uso:** el jugador intenta antes de tiempo, el objeto se queja y le dice dónde mirar. Bloquear no es castigar.

## M6 · Revelación (final del objeto)

| Paso | Valor |
|---|---|
| Aparición | El objeto final crece desde 0 y sube 0,6 en 2,8 s; una luz interior sube de 0 a 7; `reveal` |
| Espera | Flota y gira despacio (0,9 rad/s, balanceo 0,03 a 1,6 Hz) |
| Final | Tocarlo: `chime`, la cámara va a la cara superior, el bloom sube en 2,5 s; a los 2,2 s, fundido a la pantalla de final |

**Uso:** cerrar el objeto con algo que se toca, no con un cartel.

## M7 · Medallón (giro libre)

| Parámetro | Valor |
|---|---|
| Gesto | Arrastre circular sobre el disco |
| Clic | `tick` cada 22,5° |
| Límites | Ninguno: gira libremente |
| Función en el piloto | **Ninguna.** Es un objeto de distracción |

**En este juego se le da función** (puzle 5). Es la pieza del piloto que no se aprovechaba.

## M8 · Avisos de contexto

Textos breves en cursiva, centrados abajo, con sombra. Duran 4,2 s por defecto (algunos 3,6–5,2 s). Un aviso nuevo sustituye al anterior.

| Disparador | Ejemplo en el piloto |
|---|---|
| Enfocar una cara (a los 650 ms), según su estado | «Tres tambores con símbolos. Desliza cada uno arriba o abajo.» |
| Primera vez que pasa algo | «Tres símbolos grabados. Léelos de izquierda a derecha.» |
| Intento bloqueado | «No cede. Algo lo mantiene cerrado… escucha el mecanismo de atrás.» |
| Consecuencia | «Algo ha cedido en la parte superior de la caja.» |

**En el juego** estos avisos son **pensamientos de Vera** (texto, sin voz), con su humor seco. Todos están en `05-textos.md` con ID. No sustituyen a las pistas del menú de pausa: son la capa cero de ayuda.

## Sonidos del kit

| ID del piloto | Cómo suena | ID propuesto en el juego | Usos |
|---|---|---|---|
| `tick` | Clic metálico corto | `SFX_KIT_TICK` | Pasos de tambor, manivela, medallón, inventario |
| `clunk` | Golpe grave de mecanismo | `SFX_KIT_CLUNK` | Algo encaja o cede |
| `rattle` | Traqueteo metálico | `SFX_KIT_RATTLE` | Intento bloqueado |
| `creak` | Crujido de bisagra | `SFX_KIT_CREAK` | Tapas |
| `slide` | Roce de madera | `SFX_KIT_SLIDE` | Cajones, cambio de cara |
| `chime` | Cuatro notas ascendentes | `SFX_KIT_CHIME` | Puzle resuelto |
| `pick` | Dos notas brillantes | `SFX_KIT_PICK` | Coger objeto |
| `reveal` | Barrido grave y acorde que sube | `SFX_KIT_REVEAL` | Revelación final |
| `drone` | Zumbido grave continuo | — | Ya existe: drone del edificio |

**Ajuste temático:** en el piloto, `chime` es un arpegio luminoso. En este juego no hay celebraciones: `SFX_KIT_CHIME` es un acorde menor y más corto (unos 0,6 s) **[NUEVO]**. La lluvia baja un 30 % durante 1,5 s después de cada `chime`: el espacio contiene la respiración.

## Lo que el piloto hace y el juego tiene que añadir

| Necesidad | Por qué | Solución mínima |
|---|---|---|
| Mando y teclado | El juego es para PC con mando | El cursor del modo examen se mueve con el stick; el arrastre es mantener A + stick. Teclado: ratón, igual que el piloto |
| Accesibilidad | Requisito del slice | Ver `04` §5 |
| Guardado | Automático por compartimento | Cada «resuelto» de `04` guarda |
| Pistas del menú de pausa | Requisito del slice (3 niveles; 2 en el puzle 6) | Ver cada puzle en `04` |
