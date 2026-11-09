# Revisión independiente del lote Feature 1 — resumen

**Fecha:** 2026-11-09 · **Alcance:** GDDs 8, 10, 19, 20, 21 (borradores) · **Revisores:** uno por GDD, sin el contexto del autor, solo Grep y Read.
**Veredicto de los cinco: NEEDS REVISION.** Ningún GDD es MAJOR REVISION: el diseño base se sostiene; los bloqueantes son de contrato entre borradores escritos en paralelo.
Informes completos (con citas exactas y NO LEÍDO): [8](control-de-acceso-review.md) · [10](caja-y-compartimentos-review.md) · [19](ordenador-correo-impresora-review.md) · [20](documentos-y-bolsillo-review.md) · [21](director-de-escenas-review.md).

## Bloqueantes por GDD

| GDD | Bloqueante | Resumen |
|---|---|---|
| **8** | B1 | El cajón `A05` (única fuente de `tarjeta_B/D`) no tiene dueño en 8, aunque 7 lo asigna a 8 y 20 dice que 8 llama a `otorgar("A05")`: sin él, las puertas B y D son inalcanzables. |
| **8** | B2 | 20 R16 dice que 8 llama a `sostener_item`/`guardar_item` alrededor de `HAND_CARD_SWIPE` (dependencia dura 8→20); 8 dice «Nada». |
| **8** | B3 | 8 y 21 se reclaman la respuesta de `C08` (ascensor): 8 con cooldown de 8 s y aviso «ascensor llamado»; 21 con 10 s y su propio temporizador. Dos emisores de `MEGA_03`, dos temporizadores de 2,0 s. |
| **10** | B1 | Edge Case 9 y regla 6 suponen P5 resuelto con el jugador lejos y `pendiente_revelacion` limpiado al cargar; 9 (reglas 17, 18, 19, 8.1) dice lo contrario: la secuencia solo corre con la vista abierta. No figura en «Cambios requeridos». |
| **19** | B1 | Usa `entregar_item('I-01')`; 20 define `otorgar_sesion("I-01")`. Marca a 20 y 21 como «sin GDD» y ya existen. |
| **19** | B2 | Nadie es dueño de mostrar el contenido de `I-01` (20 lo declara no releíble; 9 no define de dónde sale el papel de `C05`). |
| **19** | B3 | La contradicción del slice B.1 frente a las pistas 2/3 (pie «Ordena por hora de envío» y hora) se resuelve de facto sin decisión; debe ser pregunta abierta de alcance. |
| **20** | B1 | Dice que 8 «no tiene GDD» y que llamará a `otorgar("A05")`, `sostener_item`, `guardar_item`: 8 existe y no define ninguna. Nadie es dueño de la interacción de `A05`. Además 8 propone que 7 pase `tarjeta_item` a `HAND_CARD_SWIPE`, lo que choca con 20 R16. |
| **20** | B2 | Cita «7, E2-1», regla inexistente (la correcta es la 27b). |
| **21** | B1 | Choque con 8 por `C08` (ver 8-B3); además `C08` queda `EN_USO` sin reintento si 4 rechaza `recepcion`. |
| **21** | B2 | La regla 7 trata voz de Vera y megafonía como un solo canal: `MEGA_01` (6,0 s) se aplazaría a ~9,5 s, contra la tabla de `ESC1_LLEGADA`, el ejemplo de F1 y AC-21-05. |

## Decisiones propuestas para cerrar los contratos cruzados (aún no aplicadas)

1. **`C08` (ascensor):** lo posee 8 (lector, activación, `MEGA_03` con su cooldown de 8 s, aviso «ascensor llamado»). 21 escucha ese aviso y ejecuta solo el trayecto; retira su propia gestión de `C08` y su cooldown. Si 4 rechaza `recepcion`, 8 vuelve a `LISTO` y se puede reintentar.
2. **`A05`:** lo posee 8 y es la única fuente de `tarjeta_B/D`; 8 llama a `otorgar("A05")` de 20. 8 añade a 20 como dependencia dura.
3. **Gesto de tarjeta:** 8 pide a 20 `sostener_item`/`guardar_item` alrededor de `HAND_CARD_SWIPE`; 7 no pasa `tarjeta_item`.
4. **`I-01` (contenido del papel del P1):** lo posee 19 (la hoja impresa); 20 solo guarda `has_item`; 9 recibe las referencias del papel de 19, no de 20. 19 corrige `otorgar_sesion`.
5. **P5 en 10:** 10 se alinea con 9: la secuencia solo corre con la vista abierta y `pendiente_revelacion` permanece verdadero al cargar; se retira la rama de «resuelto con el jugador lejos».
6. **Voz de la escena 1:** voz de Vera y megafonía son canales independientes en 21; la megafonía no espera a la voz.
7. **Slice B.1 (19):** pregunta abierta de alcance (pie y hora siempre visibles frente a solo con las pistas 2 y 3), con B.1 como valor provisional.

## Avisos relevantes (resto en los informes)
- Los valores inventados deben llevar † (tiempos de 10 y 21, umbrales de playtest de 10, `repaso_*` de 20).
- 7 debe cambiar la fila de `C08` (`habilitado_si: llamada_completada` contradice el slice §13.3) y la cadena de `D01a`–`D01c` frente a `D01d`.
- 6 debe listar a 19 como consumidor de `reducir_movimiento`.
- NOT SOURCEABLE: comportamiento de la pausa con animaciones en Godot 4.7 (10).
- Sin leer o comprobar en parte: ver «NO LEÍDO» de cada informe (varios no leyeron `game-concept.md`, el registro ni algunos GDDs vecinos enteros).
