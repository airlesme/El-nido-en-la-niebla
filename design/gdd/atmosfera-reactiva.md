# Atmósfera reactiva: luces, apagón, reflejo retardado y lluvia (sistema 28)

> **Status**: Revisado (ronda de corrección 10) — pendiente de re-review
> **Author**: Technical Artist (lote autónomo)
> **Last Updated**: 2026-11-12 (decisiones del usuario: `reducir_sobresaltos` = luz fija y oscurecimiento gradual ≥ 2,0 s en el apagón; `reducir_movimiento` apaga balanceo de cámara y movimientos decorativos; DT-23)
> **Implements Pillar**: El espacio expresa la emoción (luces, reflejos y lluvia cambian con la tensión, sin UI que lo explique) · Tensión sin castigo (aviso visual, nunca ataque; límite duro de destellos y atenuación con `reducir_sobresaltos` y `reducir_movimiento`) · Información incompleta (el apagón y el reflejo tardío son la única señal; ningún texto los traduce). Los dos últimos nombres no se han contrastado con el documento de pilares (no localizado en `design/pillars/`): revisar el literal en el re-review.

## Summary

Atmósfera reactiva (28) es el ejecutor visual de la tensión. Recibe órdenes por el bus («efecto de escena pedido», emitido por el Director de escenas 21), hechos de Estado (3) y ajustes de Ajustes (6), y mueve cuatro cosas: **estados de luz por zona** (incluido el parpadeo de las luminarias `C03` y del tubo del Archivo), el **apagón** de la escena 7 con su restauración, el **reflejo retardado** del patio de luces `C02` (usa la pose con retardo del Jugador, 2) y la **lluvia visible** (partículas y gotas en las ventanas). No decide cuándo ocurre nada (lo decide 21), no escribe hechos, no suena (el sonido es de 23) y no conoce al shader de 29: funciona con materiales estándar de Godot y una versión provisional de los efectos, y 29 solo los mejora. Todos los números viven en `assets/data/atmosphere/atmosphere.json`.

> **Quick reference** — Layer: `Presentation` (categoría `UI/Visual`) · Priority: `Vertical Slice` · Dura: `2 Jugador` · Blandas: `3 Estado y bus` (sin 3 no recibe órdenes, la partida sigue), `6 Ajustes` (sin 6 asume `false`), `9/13` (avisos de resolución), `23` (comparte `LLUVIA_*`), `25` (pausa), `29` (opcional) · `21 Director de escenas`: solo por el bus, sin dependencia directa · Escribe hechos: nada · Escribe ajustes: nada

## Overview

**Qué hace.** Mantiene un estado atmosférico por escena y lo transforma cuando llega una orden. Cuatro familias de efecto, todas con nombre fijo en el bus:

| Efecto (bus) | Origen | Qué hace 28 |
|---|---|---|
| `LUCES_PARPADEO` (sobre `C03`) | 21, `ESC4_PASILLO_MEGA` (+2,0 s tras `T-PAS-1`) | Hasta 3 caídas de luz de 0,15 s en las luminarias del pasillo, con pausas de 0,35 s (regla 9; ritmo pendiente del usuario, OQ 8) |
| `REFLEJO_RETARDADO` (sobre `C02`) | 21, `ESC4_PASILLO_REFLEJO` (`T-PAS-2`) | El reflejo de Vera en el patio de luces llega 0,6 s tarde durante 3,0 s o hasta que el jugador gira la cabeza |
| `LUCES_APAGON` / `LUCES_RESTAURAR` | 21, `ESC7_APAGON` (`T-D-OUT`, t = 0,0) / `ESC7_RESTAURAR` (+2,0 s tras `llamada_completada`) | Fundido de `C03` a la luz de apagón en 0,4 s; vuelta en 2,0 s. La lámpara `V06` sigue encendida |
| `LLUVIA_REALCE`, `LLUVIA_CESA`, `LLUVIA_VUELVE` | 21 (`ESC3_FORMULARIO`, `ESC8_ASCENSOR`, `ESC7_RESTAURAR`; el cese en el apagón es la OQ 1 de 23) | La parte **visible** de la lluvia: densidad de gotas en cristales y partículas en los ventanales |

**Qué no hace.** No arbitra el audio de la lluvia (23 lo hace con los mismos nombres de efecto; 28 y 23 reciben la misma orden y se mantienen sincronizados por construcción, regla 20). No retarda ni entrega reflejo a las superficies de los puzles 2 y 5 (regla 13). No dibuja UI. No contiene lógica de partida: si se borra 28, la partida sigue siendo completable (pilar *Información incompleta* en su peor caso: el mundo no cambia, pero nada se bloquea).

**Presupuesto de un vistazo.** 60 fps en el hardware mínimo (`project.yaml`), 16,6 ms por fotograma; 28 gasta como máximo **1,0 ms de GPU** y **0,15 ms de CPU** de media (F8), con **≤ 8 luces dinámicas visibles** y **≤ 2 con sombra** por vista.

## Player Fantasy

La planta nueve no te grita nada; te hace dudar de lo que ves. Pasas bajo una luminaria que titubea justo cuando la megafonía habla a una sala vacía. En el cristal del patio, Vera te mira un instante después de que tú te hayas movido, y cuando vuelves la cabeza, ya está en su sitio, como si nunca hubiera ocurrido. Más tarde, al salir del despacho del Guardián, las luces se van del pasillo de golpe pero no del todo: la lámpara ámbar de Vera sigue ahí, pequeña, y sabes adónde ir. Cuando cuelga la llamada, la luz vuelve despacio y con ella la lluvia.

Es un aviso, no un ataque. El jugador siente «algo no está bien» y nunca «he fallado». Quien tiene fotosensibilidad o sensibilidad al movimiento recibe la misma historia con menos energía, no con menos significado.

## Detailed Rules

### A. Arquitectura y propiedad

1. **28 es un nodo de escena persistente (autoload) más componentes por escena.** El autoload `Atmosphere` (script `atmosphere_director.gd`) guarda el estado y escucha el bus; cada escena de planta (`despacho_vera`, `pasillo`, `archivo`, `sala_reuniones`, `despacho_guardian`, `recepcion`) trae un nodo `AtmosphereZone` (`atmosphere_zone.gd`) que registra sus luces, ventanas y el espejo. Razón: el estado (apagón, lluvia) cruza escenas; las luces y ventanas pertenecen a cada escena. Alternativa descartada en Decisiones tomadas (DT-1).
2. **28 no depende de 21 ni de 29.** 21 y 28 solo se hablan por el bus (21 GDD, regla 6). 28 funciona con `StandardMaterial3D`, `Light3D`, `GPUParticles3D` y un `ShaderMaterial` mínimo propio para la gota de cristal; 29 puede sustituir `rain_glass` vía recursos de datos (regla 24) sin cambiar este GDD. 29 no recibe nada de 28 para el cristal del puzle 2 (regla 13).
3. **28 no escribe hechos ni ajustes.** Solo lee. Su estado es **memoria volátil** derivada de hechos (regla 21), nunca fuente de verdad.
4. **Datos.** Valores de luces, tiempos y umbrales en `assets/data/atmosphere/atmosphere.json`, un perfil por zona (`zone_profiles`). Ningún valor numérico en script, salvo los límites de seguridad de la regla 9, que son además **constantes de código con prueba** (una errata de datos no puede romper el límite de destellos).

### B. Estados de luz por zona

5. **Estados.** Cada zona está en un estado de luz `LightState`: `NORMAL`, `FLICKER` (transitorio), `APAGON`, `RESTAURANDO`. El estado deseado es una función de los hechos y de la última orden (regla 21). Tabla de base (fuente: slice A.2–A.7, C.4–C.7; los valores numéricos de energía son †, los fija el art director):

   | Zona | `NORMAL` | Se ve afectada por |
   |---|---|---|
   | `despacho_vera` | Lámpara `V06` ámbar 2700 K (slice A.2), ventilador; `NORMAL` | Nunca se apaga. Con `APAGON` es la **luz de emergencia** (regla 8) |
   | `pasillo` | Seis luminarias `C03` (X = 3, 7, 11, 15, 19, 23) frías, azul noche | `LUCES_PARPADEO`, `LUCES_APAGON`, `LUCES_RESTAURAR` |
   | `archivo` (A) | Un tubo fluorescente con parpadeo irregular propio: **dos parpadeos cada 20 s** (ambiente, regla 10) | Ninguna orden de escena; solo el límite de la regla 9 y `reducir_sobresaltos` |
   | `sala_reuniones` (B) | Lámparas ámbar 2200 K en posición 2, fluorescentes apagados, luz fría de ventana | Ninguna orden. Las lámparas son del puzle 2 (28 no las mueve) |
   | `despacho_guardian` (D) | Lámparas de mesa y luz de ventana; foto del equipo | `LUCES_APAGON` (fundido de `C03` «en el pasillo y en D») |
   | `recepcion` | Fluorescentes fríos 6500 K (dos tubos), ventanal `R03` (X = 8,0) con lluvia | `LLUVIA_CESA`. **Un tubo parpadea una vez al entrar** (slice línea 681): lo ejecuta 28 en «escena lista», como un parpadeo de tubo (regla 10, `f_tubo`, por el limitador), sin orden de 21 |

6. **Una orden de luz se ejecuta en el fotograma en que se recibe y es idempotente.** Repetir `LUCES_APAGON` con el apagón ya aplicado no reinicia la rampa. Una orden desconocida se ignora con un `push_warning` (nunca bloquea).
7. **Interpolación.** Todo cambio de luz es un `Tween` sobre la **energía** (`light_energy`) de las luces afectadas con la curva de la regla 8 o 9; el color no cambia durante la transición (decisión de color: art director). El `Tween` se detiene con la pausa (regla 22; `Tween.set_pause_mode(TWEEN_PAUSE_STOP)` ‡).

### C. Apagón

8. **Apagón (`LUCES_APAGON`, slice C.7).** Se dispara por 21 al cruzar `T-D-OUT` con `caja_completa` (t = 0,0). 28:
   - lleva la energía de las seis `C03` y de las luces de `despacho_guardian` a `E_apagon` (fracción `f_apagon`, 0,0† de la nominal) en `d_apagon` = **0,4 s** (una sola caída monótona; sin parpadeo de entrada ni de restauración, art bible §8.7);
   - aplica un **suelo de ambiente** `ambiente_apagon` (0,06† de energía de ambiente) para que el estado nunca sea negro puro (art bible, paleta: azul noche `#1C2A38`, «nunca negro puro dentro del juego»);
   - conserva **`V06`** al 100 % y la luz de la pantalla del teléfono `V02`: son la luz de emergencia diegética. No se añade luz de emergencia nueva (señal de salida, etc.) sin decisión del art director (Open Questions 2);
   - **requisito:** las manos conservan su mínimo de luz en el apagón (regla 28 de 2). El mecanismo (máscara de luz, segunda cámara o shader de manos, spike A/B de D-28 de 2) lo decide 2/ADR; 28 no lo fija ‡;
   - activa `apagon_visible = true` en la memoria volátil de 28.
   Mientras dura, 28 **no hace nada más**: sillas y tecleo (t = 1,0–7,5 s) son sonido sin imagen (slice C.7); 28 no añade silueta, sombra ni movimiento (pilar 4 e *Información incompleta*).
9. **Parpadeo (`LUCES_PARPADEO`, slice C.4) y límite de destellos.** 21 pide hasta 3 caídas de 0,15 s sobre `C03`. 28 las ejecuta como una **secuencia de caídas separadas por una pausa mínima `pausa_min_s` = 0,35 s**: caída 0,15 s, pausa 0,35 s, caída 0,15 s, pausa 0,35 s, caída 0,15 s, duración total 1,15 s, frecuencia **2,0 ciclos/s ≤ 2,0 Hz** (`FLASH_MAX_HZ`; más estricta que el tope de 3/s de 30; F1). Cada caída de 0,15 s **incluye ambas rampas** (envolvente: caída 0,05 s, mantenido 0,00 s, recuperación 0,10 s) y lleva la energía de `C03` a `f_parpadeo` (0,40† de la nominal, nunca por debajo del suelo de la regla 11e). El periodo caída+pausa es 0,50 s. El límite es defensa en profundidad: 28 aplica un **limitador de destellos global** (regla 11) aunque 21 pida más. **El ritmo 3 × 0,15 s con pausas de 0,35 s cambia el contenido del slice (C.4, «0,15 s cada vez», ≈ 0,45 s): lo decide el usuario (OQ 8); este es el valor por defecto que respeta ≤ 3 Hz.**
   - **Combinación de ajustes (una sola regla; enmendada 2026-11-12, DT-23).** Con `reducir_sobresaltos` activo **no hay parpadeo: la luz de `C03` queda fija** (la orden `LUCES_PARPADEO` se ignora, sin caída ni atenuación; el slice C.4 enmendado en v0.4.4). Si solo `reducir_movimiento` está activo → **una sola atenuación** suave de 0,6 s (la pide 21, regla 23) hasta `f_parpadeo_red` (0,65†). Con ambas, manda `reducir_sobresaltos` (luz fija). Nunca se suman dos atenuaciones. *(Antes: con `reducir_sobresaltos`, una atenuación con rampas de 0,30 s.)*
10. **Parpadeo ambiente del Archivo.** El tubo hace dos parpadeos cada 20,0 s (slice A.4). Se generan con un temporizador propio con `pausa_min_s` entre parpadeos y un desfase determinista por semilla de la escena (`seed_archivo`, sin `randf()` sin semilla). Cada parpadeo: caída a `f_tubo` (0,40†) 0,08 s, recuperación 0,12 s (0,20 s en total, incluidas ambas rampas). No cuenta como susto: con `reducir_sobresaltos` baja a `f_tubo_red` 0,65† y rampas ×2.
11. **Limitador de destellos (global, no desactivable).** 28 mantiene un registro de los cambios de luminancia del conjunto de luces afectadas por el atmosférico. Un **destello** es el de la definición única de 30 (regla 24): un par de cambios opuestos de luminancia relativa de ≥ 10 % del rango completo sobre un área > 25 % del campo de visión (caída + recuperación = **un** destello = dos cruces), contado en ventana deslizante de 1 s. Reglas: (a) nunca más de **2 ciclos por segundo** (por debajo del límite de 3 Hz; art bible §8.7; el parpadeo por defecto está **exactamente** en 2,0, sin margen: AC-28-01 mide con tolerancia ±0,02 s y el limitador, no el dato, es el garante); (b) pausa mínima de **0,35 s** entre el final de una recuperación (la caída de 0,15 s ya la incluye) y el inicio de la siguiente caída; (c) nunca más de 3 destellos en una ventana de 1,0 s (WCAG 2.3.1) ni destellos con área saturada roja; (d) si una orden violaría (a)–(c), 28 **fusiona** las caídas sobrantes (las omite) y registra `push_warning`. (e) **suelo de profundidad `FLASH_DEPTH_FLOOR` = 0,40** de la energía nominal, en todo parpadeo (`C03`, tubos), con o sin `reducir_*`: el limitador sube cualquier `f_parpadeo`/`f_tubo` de datos inferior a 0,40 (art bible §8.7: «no baja del 40–50 %»; AC-28-23). **No** se aplica al apagón ni a su restauración (cambios monótonos, no destellos). El orden de prioridad es: apagón > parpadeo `C03` > tubo del Archivo/Recepción (el tubo se omite si coincide).
12. **Restauración (`LUCES_RESTAURAR`, 2,0 s).** A +2,0 s de `llamada_completada` (21, `ESC7_RESTAURAR`). Sube la energía de `C03` y de las luces de D de `E_apagon` a la nominal en `d_restaurar` = **2,0 s** con una rampa **monótona** (sin parpadeo de restauración, art bible §8.7). Con `reducir_sobresaltos`, `d_restaurar_red` = 2,0 s (ya es lenta; no cambia). El apagón termina; `apagon_visible = false`.

### D. Reflejo retardado

13. **Alcance y contrato de reflejo (quién posee qué).** El reflejo retardado es **solo** el del patio de luces `C02` (muro sur, X 12,0–20,0), que es **una superficie distinta** del cristal del puzle 2.
    - **28 posee** `C02` entera: el proxy de Vera, su material y la `ReflectionProbe` provisional de esa vista (`mirror_glass_material`, regla 24). 28 es el único que usa `pose_con_retardo`.
    - **28 posee TODO reflejo** (decisión de la ronda 9; 29 R12 ya lo dice así): el de `C02` (proxy retardado) **y** el que reciba el cristal `B04` del puzle 2, que **no** es retardado: es la `ReflectionProbe` de la Sala de Reuniones sin retardo, que 28 configura y cuya intensidad acata el tope `reflection_strength_max` (0,15†) que **publica 29**. 28 no usa `pose_con_retardo` en P2 ni P5 (haría ilegible la solución) y no entrega `reflection_tex` ni `SubViewport` a ningún material de 29.
    - **29 posee** el **shader y el material** `mat_glass_memo` (película, fragmentos, previa, halo; superficies de P2/P5): aporta el cristal que compone el reflejo de 28 por debajo del texto. 29 no dibuja ni decide el reflejo; 28 no toca la película, los fragmentos ni el halo.
    - Compatibilidad: sin 29, el cristal de P2 se ve con la sonda sin retardo; sin 28, 29 funciona con reflejo cero (regla 15 de 29). Un nodo solo recibe retardo si está en el grupo `reflejo_retardado`, y solo `C02` lo está. 28 sirve a los puzles con **luz** (regla 19), no con reflejo retardado.
14. **Cómo se retrasa.** `C02` no es un espejo en tiempo real. Es un cristal semitransparente (fresnel simple + `ReflectionProbe` ‡ de la sala) delante de una **habitación espejada** de geometría mínima: el proxy de cuerpo entero de Vera (low poly, ≤ 400 triángulos†, sin cara; silueta: art director, OQ 6) vive en ese espacio detrás del cristal. En cada `_process`, 28 pide `Jugador.pose_con_retardo(τ)` y coloca el proxy en la **posición reflejada** respecto al plano de `C02` y con el yaw reflejado (F2), con la fase de paso de la pose. Con `τ = 0` el proxy es el reflejo normal; con `τ = 0,6 s` va tarde. **El proxy no se espeja** (sin escala negativa ni cambio de orden de caras): la lateralidad de un maniquí sin cara es imperceptible (W-1, DT-13). Sin `SubViewport` ni cámara espejada: una malla (1 draw call), paralaje correcto. (Alternativa descartada: DT-3.) El cristal no refleja el resto del pasillo (coste de DT-3): comprobar en el editor que la lectura «espejo» se sostiene (OQ 6).
15. **Ciclo del efecto (`REFLEJO_RETARDADO`, retardo 0,6 s, 3,0 s).** `T-PAS-2` solo se activa si no ocurrió ya (21 regla 12). Estados: `OFF`, `ENTRANDO`, `ACTIVO`, `SALIENDO`.
    - `OFF`: por defecto el proxy sigue la pose con `τ = 0` (reflejo normal) siempre que `C02` está a la vista. Alternativa de bajo coste a decidir con el art director (OQ 6): proxy invisible en `OFF`, aparece con el fundido de `ENTRANDO`.
    - `ENTRANDO`: `τ` sube de 0 a `retardo_reflejo_s` (0,6 s, dato de la orden) en `t_entrada_reflejo` (0,5 s†) con curva suave (F3). Mientras `τ` sube, el proxy no «salta»: su posición se interpola desde el reflejo normal.
    - `ACTIVO`: `τ = 0,6 s` constante hasta fin de duración (3,0 s tras la orden) o hasta que se cumple la condición de giro (regla 16), lo que ocurra antes, con una duración mínima de `t_activo_min_s` (1,0 s†) para que se llegue a ver.
    - `SALIENDO`: `τ` baja a 0 en `t_salida_reflejo` (0,35 s†); el reflejo vuelve a la normalidad («el reflejo vuelve a la normalidad», slice escena 4).
    - El efecto ocurre **una vez** en la partida; no hay repetición ni «segunda oportunidad». Si el jugador no mira el cristal, no se pierde nada.
16. **Condición de giro.** El umbral lo fija 28 (el Jugador solo ofrece `giro_acumulado()`, GDD 2 regla 30). El efecto pasa a `SALIENDO` cuando `giro_acumulado() ≥ umbral_giro_deg` (45°† en `T_giro` = 0,5 s†) **y** el efecto lleva activo ≥ `t_activo_min_s`. Un giro del ratón por debajo del umbral (microcorrecciones) no cuenta; el giro con mando se mide en grados, no en sticks, por lo que es equivalente.
17. **Aparición gradual con `reducir_movimiento` (21 regla 23).** El retardo en sí no se elimina (es el contenido narrativo). Con `reducir_movimiento` verdadero: (a) `ENTRANDO` no interpola `τ` sino que hace un **fundido cruzado** de 0,5 s† entre el proxy con `τ = 0` y un segundo proxy con `τ = 0,6 s` (sin movimiento intermedio); (b) `SALIENDO` es otro fundido de 0,35 s†; (c) el cambio brusco de posición queda sustituido por la transparencia, y no hay temblor ni desenfoque de movimiento sobre el reflejo. El valor se lee **en cada disparo** (21 regla 23).

### E. Ajustes y accesibilidad

18. **Qué lee 28 de Ajustes (6).** Dos claves booleanas, por aviso de cambio y al arrancar: `reducir_sobresaltos` (comparte nombre con 23 y 15; en el índice y la art bible aparece como «reducir sobresaltos / destellos») y `reducir_movimiento` (clave que ya lee Entrada 4 y 21). Las lee del contenedor de 6 (lectura, nunca escritura) y se suscribe a «ajustes aplicados». No tiene ajustes propios (decisión DT-6). Efectos por clave:

    | Elemento | `reducir_sobresaltos` | `reducir_movimiento` |
    |---|---|---|
    | Parpadeo `C03` | **Luz fija, sin parpadeo** (DT-23) | Una atenuación suave de 0,6 s (la pide 21, 21 R23); con ambas, manda la luz fija (regla 9) |
    | Tubo del Archivo / Recepción | Parpadeos a 0,65† y rampas ×2 | — |
    | Apagón | **Oscurecimiento gradual** en `d_apagon_red` = **2,0 s†** (≥ 2,0 s, decisión del usuario 2026-11-12, DT-23; rampa monótona, sin escalón) y suelo `ambiente_apagon_red` 0,10†. *(Antes 0,8 s†)* | — (es un cambio de luz, no de movimiento) |
    | Restauración | Sin cambio (ya es monótona y de 2,0 s) | — |
    | Reflejo retardado | — | Fundido cruzado en vez de interpolación (regla 17) |
    | Lluvia visible | — | Gotas en cristal y partículas a velocidad ×0,5†; sin relámpagos (no hay en el slice) |
    | Movimientos decorativos y balanceo de cámara | — | **Apagados** (decisión del usuario 2026-11-12, DT-23; 30 R19): el balanceo de cámara lo apaga 2 al leer la clave; 28 apaga todo movimiento ambiental sin función de juego (deriva de partículas decorativas); lluvia y reflejo según las filas anteriores |
    | Cambio de luz de resolución (regla 19) | Pulso hasta +0,15† (en vez de +0,25†) | — |

    La separación no es arbitraria: `reducir_sobresaltos` atenúa lo que sobresalta (destellos, caída de luz); `reducir_movimiento` atenúa lo que se mueve (reflejo, lluvia). Ambas atenúan, nunca eliminan el aviso: el apagón y el reflejo siguen contando la historia.
19. **Avisos de resolución (luz).** 9 emite `EV_PUZZLE_SOLVED_<ID>` (el ID de puzle va en el nombre del aviso; ya lo declaran 9 y 3) y 3 los hechos derivados. 28 **no** pide a 9 un aviso `puzzle_solved {id}`: no existe. 28 consume, como **efecto de luz puramente cosmético** y nunca como condición de nada: (a) **P3 (encaje de la foto)**: pulso de luz del marco iluminado de 1,0 s (GDD 9/13, regla 17 de P3), pasando por el limitador de la regla 11; (b) **P2**: brillo suave del cristal acompañando `SFX_GLASS_HUM` (2,0 s), con 28 solo moviendo una `OmniLight3D` auxiliar de la sala, **sin** tocar la superficie del puzle; (c) **P5**: pulso de 1,0 s sobre la revelación (su forma exacta la fija el GDD del puzle 5; 28 solo ofrece el pulso, regla 13). Pulso: sube `pulso_resolucion` (+0,25† de energía) en 0,3 s y baja en 0,7 s, una sola vez (1 ciclo, sin repetición). Cualquier otro uso de luz por puzle es del puzle.
20. **Lluvia visible (partículas y ventanas).** Capa continua en toda la planta, «más intensa en el Archivo y en el pasillo; se atenúa dentro de las salas cerradas» (slice §14 y §15). Montaje técnico:
    - **Ventanales visibles:** `B` (muro norte, Z = 6,3, X 11,5–18,5), `D` (muro norte, Z = 5,3, X 20,0–24,0), `R03` (muro este, X = 8,0, Y 0,9–2,8); Vera no tiene ventana (la lluvia se oye a través de la persiana).
    - **Gotas en el cristal:** un `ShaderMaterial` mínimo (`rain_glass.gdshader`, `spatial`, transparente, blend mix) que pinta las gotas como **normal y brillo en el propio cristal** (textura de ruido de gotas, 2 capas). No desplaza el fondo ni usa `hint_screen_texture` (DT-11). Parámetros: `densidad`, `velocidad`, `brillo`.
    - **Partículas:** un `GPUParticles3D` por ventanal, volumen de emisión del tamaño del ventanal, ≤ 200† partículas por ventanal y ≤ 500† en total visibles; mallas de 2 triángulos; sin sombras; sin transparencia ordenada (`transparency` aditiva o alfa recortada).
    - **Estado.** La lluvia tiene un nivel `lluvia_nivel` (0–1) por zona: `base_zona` × factor de orden. `LLUVIA_REALCE` (8,0 s†, `ESC3_FORMULARIO`): ×1,3† con rampa de 1,0 s (comparte duración con 23, que sube +3 dB). `LLUVIA_CESA` (6,0 s, `ESC8_ASCENSOR`): a 0 en 6,0 s. `LLUVIA_VUELVE` (`ESC7_RESTAURAR`): a `base_zona` en 2,0 s†.
    - **Lluvia y apagón (OQ 1 de 23).** 23 define por defecto que la lluvia **se silencia** (−60 dB en 0,4 s) con `LUCES_APAGON` y que `LLUVIA_VUELVE` la devuelve. Para que imagen y sonido no se contradigan (una lluvia visible sin sonido sería un fallo), 28 aplica el **mismo comportamiento**: con `LUCES_APAGON` la lluvia visible baja a `lluvia_apagon` (0,0†) en `d_lluvia_apagon` = 0,4 s (el mismo dato de 23) y regresa con `LLUVIA_VUELVE` en 2,0 s. Es una sola decisión pendiente en dos GDDs (Open Questions 1); si el usuario elige «lluvia baja pero audible», 28 sube `lluvia_apagon` al mismo valor relativo; no cambia ninguna regla.
21. **Reanudar el estado atmosférico (guardado y carga).** 28 no se guarda y no se persiste. Tras «Continuar», el estado visible se recalcula a partir de los **hechos** y de las órdenes que 21 emite al reanudar:
    - `caja_completa` ∧ ¬`llamada_completada`: 21 aplica el **apagón reducido** (21 regla 14, DT-7) pidiendo `LUCES_APAGON` con **duración 0**: 28 salta a `APAGON` sin rampa y sin parpadeo, con la lluvia a `lluvia_apagon`. Sin sillas ni tecleo (efecto ya visto).
    - `llamada_completada`: la escena se carga en `NORMAL`; no se repite `LUCES_RESTAURAR`.
    - Cualquier otro caso: `NORMAL` con la lluvia a `base_zona`.
    - Un efecto transitorio (parpadeo, reflejo retardado, realce de lluvia) en curso **no se reanuda**: se descarta; el reflejo retardado ya ocurrido no se repite (21 regla 12).
    - Si 28 recibe un `LUCES_APAGON` con duración 0, **no** lo trata como destello (no hay caída visible).
22. **Pausa.** Con «pausa abierta» (25) y «pausa cerrada» (declarados en 3 regla 10), 28 congela los `Tween` y las partículas (`PROCESS_MODE_PAUSABLE` y pausa de `GPUParticles3D` ‡) y las reanuda sin saltos. El estado no cambia durante la pausa. Si la pausa se abre en mitad de una caída del parpadeo, esta se completa al reanudar con el resto de su duración.
23. **Versión provisional (sin 29).** Mientras 29 no exista, 28 usa: luces estándar (`OmniLight3D`/`SpotLight3D`, atenuación por defecto), `ReflectionProbe` por sala, un único `ShaderMaterial` de gota de cristal (regla 20) y partículas de 2 triángulos. No usa `LightmapGI` (art bible §9). Cuando exista 29, puede sustituir `rain_glass.gdshader` (`rain_glass_material`) por el suyo reemplazando el recurso indicado en `atmosphere.json`; 29 **no** sustituye materiales de `C02` ni toca `mat_glass_memo` por esta vía (regla 13). Las reglas, los tiempos y los límites de este GDD no cambian.
24. **Recursos sustituibles.** `atmosphere.json` guarda rutas a recursos de material por nombre (`rain_glass_material`, `mirror_glass_material`, `rain_particles_material`). 28 los carga con `load()` al entrar en la escena (carga síncrona pequeña, ≤ 1 MB en total) y cae a un material por defecto si falta uno, con `push_error`.

### F. Lo que ve el jugador, en orden (resumen de tiempos del slice)

25. **Línea temporal atmosférica del slice.**

    | Momento | Evento | Efecto en 28 |
    |---|---|---|
    | Escena 1 | Llegada, lluvia contra un cristal | `NORMAL`, lluvia a `base_zona` |
    | Escena 3, `formulario_leido` | `LLUVIA_REALCE` (8,0 s) | Lluvia ×1,3†, rampa 1,0 s, vuelta |
    | Escena 4, `T-PAS-1` + 2,0 s | `LUCES_PARPADEO` | Regla 9 |
    | Escena 4, `T-PAS-2` | `REFLEJO_RETARDADO` | Regla 15 |
    | Escena 7, `T-D-OUT` | `LUCES_APAGON` (0,4 s) | Regla 8, lluvia visible a 0 |
    | Escena 7, +2,0 s tras `llamada_completada` | `LUCES_RESTAURAR` (2,0 s) y `LLUVIA_VUELVE` | Regla 12 |
    | Escena 8, entrada | `LLUVIA_CESA` (6,0 s) durante el trayecto | Lluvia a 0 en 6,0 s |

## Formulas

**F1. Frecuencia de destellos y duración del parpadeo.**
`T_parpadeo = N·t_caida + (N−1)·pausa_min_s`, `f_destello = 1 / (t_caida + pausa_min_s)`.
| Variable | Rango | Valor |
|---|---|---|
| `N` | 1–3 | 3 (nominal), 1 con atenuación |
| `t_caida` | 0,08–0,30 s | 0,15 s |
| `pausa_min_s` | ≥ 0,35 s | 0,35 s |
Ejemplo: `T_parpadeo = 3·0,15 + 2·0,35 = 1,15 s`; `f_destello = 1/(0,15+0,35) = 2,0 Hz ≤ 2,0 Hz` (`FLASH_MAX_HZ`). Con rampas de 0,05 s/0,10 s dentro de la caída la frecuencia no cambia. Invariante: `f_destello ≤ 2,0 Hz` para cualquier dato de `atmosphere.json` (el limitador fuerza `pausa_min_s ≥ 0,35`).

**F2. Posición del proxy reflejado.** Plano de `C02`: punto `p0`, normal unitaria `n` (datos del nivel). Pose retardada `P(τ)` = `Jugador.pose_con_retardo(τ)`.
`p' = p − 2·((p − p0)·n)·n`; `f' = f − 2·(f·n)·n` (dirección de mirada reflejada); `yaw' = atan2(f'.x, f'.z)`.
Ejemplo: `n = (0,0,1)`, `p0 = (16, 0, −1,5)`, `p = (14, 0, 0,5)` ⇒ `(p−p0)·n = 2,0`, `p' = (14, 0, −3,5)`. El proxy **no** se espeja: solo se reflejan posición y yaw; no hay escala negativa, así que no se toca el orden de caras (no se norma `CULL_FRONT`; comportamiento de Godot 4.7 ante determinante negativo no verificado, OQ 4).

**F3. Retardo del reflejo.**
`τ(t) = retardo · s(clamp((t − t0)/t_entrada, 0, 1))` en `ENTRANDO`, `τ = retardo` en `ACTIVO`, `τ(t) = retardo · (1 − s(clamp((t − t1)/t_salida, 0, 1)))` en `SALIENDO`, con `s(x) = x²(3 − 2x)` (smoothstep).
| Variable | Rango | Valor |
|---|---|---|
| `retardo` | 0,2–1,0 s (≤ `T_hist` de 2 = 1,0 s) | 0,6 s (dato de la orden) |
| `t_entrada` | 0,2–1,0 s | 0,5 s† |
| `t_salida` | 0,2–1,0 s | 0,35 s† |
| `t_activo_min_s` | 0,5–3,0 s | 1,0 s† |
Ejemplo: a `t − t0 = 0,25 s`, `x = 0,5`, `s = 0,5`, `τ = 0,3 s`. Invariante: `retardo ≤ T_hist`; si no, 28 recorta a `T_hist` y avisa. Duración total del efecto: `3,0 s` (ENTRANDO + ACTIVO) más `t_salida`, salvo giro anticipado.
Ejemplo de condición de giro: yaw 30° en 0,5 s ⇒ no cumple; yaw 55° en 0,4 s ⇒ cumple; si lleva activo 0,8 s (< 1,0 s), espera hasta 1,0 s.

**F4. Caída de luz (apagón y parpadeo).** `E(t) = E_nom · lerp(1, f, s(clamp((t − t0)/d, 0, 1)))`.
| Variable | Rango | Valor |
|---|---|---|
| `E_nom` | por luz | Dato por zona (†, art director) |
| `f` (apagón) | 0,0–0,1 | 0,0† |
| `f` (parpadeo, tubos) | 0,40–0,70 (suelo 0,40, R11e) | 0,40† / 0,65† reducido |
| `d` (apagón) | 0,3–2,0 s (reducido ≥ 2,0 s) | 0,4 s / 2,0 s† reducido (DT-23) |
Ejemplo: apagón nominal a 0,2 s ⇒ `x = 0,5`, `s = 0,5`, `E = 0,5·E_nom`. Restauración: `E(t) = E_ap + (E_nom − E_ap)·x` lineal **monótona** (sin smoothstep con rebote), `d = 2,0 s`: a 1,0 s, `E = 0,5·E_nom` (para `E_ap = 0`). La luminancia percibida no es lineal con la energía; la curva perceptual la ajusta el art director sin cambiar F1.

**F5. Lluvia (nivel por zona).** `lluvia_nivel(zona, t) = base_zona · m_orden(t)`, con `m_orden` ∈ {realce 1,3†, apagón 0,0†, cese 0,0}; rampa lineal de duración `d_orden` entre valores. `densidad = lluvia_nivel · densidad_max`; `n_emitidas = round(lluvia_nivel · n_max_ventanal)`, `n_max_ventanal` 200†. **`base_zona` se deriva de la jerarquía de 23** (`perfil_dB`, director-de-audio.md línea 279: A 0, C 0, V −6, B −9, D −9, R −6): `base_zona = 10^(perfil_dB/20)` ⇒ Archivo 1,0, pasillo 1,0, despacho de Vera 0,5, recepción 0,5, B y D 0,35 (coherente con slice §14: más intensa en Archivo y pasillo). Una sola jerarquía para imagen y sonido; si 23 cambia, cambia 28. Ejemplo: Archivo 1,0 con realce ×1,3 ⇒ 1,3 recortado a 1,0 (`n = 200`); recepción 0,5 ⇒ 0,65, `n = 130`.

**F7. Rampas con `reducir_*`.** Con `reducir_sobresaltos`: `d_apagon_red` = 2,0 s (dato fijo, ≥ 2,0 s; DT-23, antes `2·d_apagon` = 0,8 s); el parpadeo de `C03` no existe (luz fija); `f_parpadeo_red` (0,65) solo se usa con `reducir_movimiento` sin `reducir_sobresaltos` (atenuación de 0,6 s). Suelo de seguridad: `FLASH_DEPTH_FLOOR` = 0,40 de la nominal en todo parpadeo (R11e).

**F8. Presupuesto de rendimiento (sobre 16,6 ms por fotograma a 60 fps).**
| Concepto | Techo | Se mide con |
|---|---|---|
| Luces dinámicas visibles (`OmniLight3D`/`SpotLight3D`) | ≤ 8 por vista, ≤ 2 con sombra | `RenderingServer` / monitor «Objects in frame» ‡ |
| Luces totales cargadas por escena | ≤ 14 (las no visibles se apagan por visibilidad) | Árbol de escena |
| Luces por escena y dueño | Pasillo: 6 `C03` (28), sin sombra. Vera: `V06` (28; con sombra) + pantalla `V02` (28). B: lámparas y haz de P2 (**P2**, `SpotLight3D`, hasta 1 sombra) + `OmniLight3D` auxiliar de la regla 19b (28). Archivo: 1 tubo (28). Las ≤ 2 sombras se reparten: `V06` y el haz de P2 nunca coinciden en vista; **28 posee el presupuesto total** y P2 cuenta dentro de él. `C02` es un cristal, **no** una luz | Prueba de 30 s (§22) |
| Partículas de lluvia visibles | ≤ 500† en total | `GPUParticles3D` |
| Overdraw de ventanales | ≤ 3 capas alfa por píxel | Visor de overdraw |
| Reflejo `C02` | 1 draw call, ≤ 400 triángulos†, 0 `SubViewport` | Profiler |
| GPU de 28 | ≤ 1,0 ms, **incluye** el coste de sus luces, partículas y cristales; excluye las luces de P2 | Profiler de GPU |
| CPU de 28 | ≤ 0,15 ms de media, ≤ 0,5 ms de pico | Monitor `process` |
| Memoria de texturas de 28 | ≤ 8 MB† (ruido de gota 512², gradientes) | Monitor de VRAM |
| Tiempo de fotograma total | ≤ 16,6 ms (60 fps), 99 % de fotogramas | Prueba de 30 s |

Si se supera: (1) baja `n_max_ventanal` por distancia: emisión `n·clamp(1 − (d − 6)/10, 0,25, 1)` desde 6 m; (2) reduce a 1 capa de gota; (3) apaga las luces con `visible = false` fuera del frustum (Godot ya las excluye, pero se desactivan los scripts); (4) las luces `C03` lejanas pasan a sin sombra y con `distance_fade`. Cada una de estas cuestiona un presupuesto distinto: las partículas cuestan overdraw, las luces cuestan fillrate del clúster de Forward+.

## Edge Cases

- **Si llega `LUCES_APAGON` con el parpadeo `C03` en curso:** el apagón tiene prioridad. 28 cancela el parpadeo y parte de la energía actual de las luces (sin saltar), con `d_apagon`. Se garantiza que no hay un destello extra.
- **Si llega `LUCES_PARPADEO` durante `APAGON`:** se ignora (no hay luz que parpadear). `ESC4_PASILLO_MEGA` exige ¬`caja_completa`, así que no debería ocurrir.
- **Si `LUCES_RESTAURAR` llega sin apagón previo** (p. ej. una orden suelta): 28 la ignora y registra un `push_warning`; las luces ya están al 100 %.
- **Si el jugador cierra el juego durante el apagón** (`caja_completa` ∧ ¬`llamada_completada`): al continuar, apagón reducido con duración 0 (regla 21, 21 regla 14). Con la llamada sonando o no. La lluvia visible queda en `lluvia_apagon`.
- **Si el jugador cierra durante `REFLEJO_RETARDADO`:** el efecto no se reanuda, y como ya ocurrió (21 regla 12) no se repite. El reflejo vuelve a `OFF`.
- **Si el jugador vuelve a pasar por `T-PAS-2`:** 21 no emite otra orden. Si por un error llegara un segundo `REFLEJO_RETARDADO` en `ACTIVO`, 28 lo ignora; en `OFF` tras haber ocurrido, también (guarda `reflejo_hecho` en memoria volátil, no persistente: 21 regla 12 es la guarda real).
- **Si el jugador no mira `C02` durante los 3,0 s:** el efecto ocurre igual (cuesta lo mismo) y se pierde. No bloquea nada.
- **Si el jugador se queda quieto frente a `C02`:** `pose_con_retardo(0,6)` devuelve la misma pose; el proxy está quieto y no se ve diferencia. El efecto es solo una señal con movimiento; no hay respuesta forzada. Documentado, no es un fallo.
- **Si el jugador gira justo al inicio (< `t_activo_min_s`):** el efecto espera hasta 1,0 s y sale (F3).
- **Si la pose retardada no está disponible** (menos de `τ` s de historial tras una carga): el Jugador devuelve la pose más antigua (GDD 2 F6). 28 espera 0,6 s de historial antes de aceptar `REFLEJO_RETARDADO`; si llega antes, usa `τ` efectivo menor sin error.
- **Si `retardo` > `T_hist`:** se recorta (F3).
- **Si el jugador cruza `T-D-OUT` con un destello activo** (por ejemplo el tubo del Archivo, lejano): sólo se aplica el limitador (regla 11).
- **Si `reducir_sobresaltos` cambia a mitad de un parpadeo o de un apagón:** el efecto en curso termina como se emitió; el siguiente lee el valor nuevo. La lluvia y el reflejo leen `reducir_movimiento` al próximo disparo; los cambios continuos (velocidad de lluvia) se aplican con rampa de 0,5 s.
- **Si el jugador pausa durante el apagón:** todo se congela (regla 22); la luz de emergencia permanece.
- **Si falta un material** (regla 24): se usa el material por defecto con `push_error`; no se cuelga.
- **Si `LUCES_PARPADEO` (1,15 s, +2,0 s tras `T-PAS-1`) coincide con `REFLEJO_RETARDADO` (`T-PAS-2`, X 14–18, ≈ 1,6 m/s):** pueden solaparse. No se acumulan: `C02` es un cristal, no una luz, y el limitador solo cuenta cambios de luz. Tiempos reales a verificar con 21/4 en el prototipo.
- **Si `reducir_sobresaltos` y `reducir_movimiento` están activos a la vez:** una sola atenuación (regla 9).
- **Si el equipo no llega a 60 fps:** degradación en el orden de F8 (partículas, capas de gota, sombras). Los límites de destellos y los tiempos **no** se degradan.
- **Si dos efectos piden la misma luz:** prioridad: apagón > restauración > parpadeo > pulso de resolución > tubo ambiente. El menor se aplaza o se funde (regla 11).
- **Si una orden de `LUCES_*` llega durante `ESC8_ASCENSOR`** (fundido a negro propio de 21): se ejecuta igual, sin conflicto, porque 21 es dueño del fundido de pantalla y 28 solo de luces del mundo.
- **Si el HDR 4.7 o el glow 4.6 alteran la luminancia percibida del apagón:** no verificado ‡; se comprueba en AC-28-04 (umbral de luminancia) y el spike de AC-28-19.

## Dependencies

| Sistema | Tipo | Qué consume 28 / qué da | Fuente |
|---|---|---|---|
| 2 Jugador en primera persona | **Dura** | `pose_con_retardo(τ)`, `giro_acumulado()`, pose actual (para el reflejo `C02`); capa de «manos» con luz mínima | GDD 2 reglas 28–30, tabla de dependencias fila 28 |
| 3 Estado y bus de eventos | **Blanda** (3 la declara blanda; sin 3, 28 no recibe órdenes y la partida sigue) | Hechos de lectura (`caja_completa`, `llamada_completada`, `llamada_iniciada`); avisos de cambio; «efecto de escena pedido» (bus); `EV_PUZZLE_SOLVED_<ID>` (avisos de resolución). **Lista de avisos que 28 consume** en la tabla de abajo. 28 no emite ni escribe hechos | Regla 3, 21 |
| 6 Ajustes persistentes | **Blanda** (6 la declara blanda; sin 6, ambas claves = `false`) | `reducir_sobresaltos`, `reducir_movimiento` (6 solo lista la primera: añadir la segunda), «ajustes aplicados». Sin ajustes propios | Regla 18 |
| 21 Director de escenas | **Sin dependencia directa (por el bus)**; el índice lo lista en la fila 28: corregir | Órdenes `LUCES_PARPADEO`, `REFLEJO_RETARDADO`, `LUCES_APAGON`, `LUCES_RESTAURAR`, `LLUVIA_*` vía «efecto de escena pedido» ‡; 21 no lee a 28 ni espera confirmación | GDD 21 reglas 6, 9, 14, 23; Dependencies fila 23·28 |
| 23 Director de audio | **Blanda / informativa** | Comparte los nombres `LLUVIA_*`, `LUCES_APAGON`, `reducir_sobresaltos`. Ninguno depende del otro; coherencia imagen/sonido por la misma orden (regla 20) | GDD 23 R21, R22, R38 |
| 25 Menú de pausa | **Blanda** | «pausa abierta» y «pausa cerrada»: congelar y reanudar (regla 22) | GDD 21 regla 9 |
| 9/13 Marco de puzles, puzles 2, 3, 5 | **Blanda** | Avisos de resolución (`EV_PUZZLE_SOLVED_<ID>`, estado de P2 y P5). P3 declara 28 (regla 17); 28 no toca superficies de puzle | GDD 3 (marco-de-puzles) fila 28·29 |
| 29 Shaders | **Opcional** (28 no depende de 29) | 28 funciona sin él (regla 23). 29 puede sustituir `rain_glass`. **28 no entrega reflejo a `mat_glass_memo`** (regla 13): 29 posee ese material; 28 posee `C02` | Reglas 13, 23 |
| 23 (fila previa) | — | Dureza acordada con 23: informativa/blanda en ambos sentidos; 23 debe añadir fila propia hacia 28 | — |
| 4 Escena de planta | **Informativa** | Posición de `C02`, `C03`, zonas; la lista de luces por escena. 28 no lee zonas de disparo (las lee 21) | Slice A.3 |

**Avisos de 3 que consume 28** (lista para 3, bidireccional):

| Aviso / mensaje | Emisor | Uso en 28 |
|---|---|---|
| «efecto de escena pedido» {`id`, `objetivo`, `duración`, `parámetros`} ‡ | 21 vía 3 | Entrada principal: `LUCES_PARPADEO`, `REFLEJO_RETARDADO`, `LUCES_APAGON`, `LUCES_RESTAURAR`, `LLUVIA_REALCE`, `LLUVIA_CESA`, `LLUVIA_VUELVE` |
| `EV_PUZZLE_SOLVED_<ID>` (sin datos; el ID va en el nombre) | 9 / puzles | Pulsos de luz de resolución (regla 19) |
| Cambio de `caja_completa`, `llamada_completada` | 3 | Solo para recalcular al reanudar y como respaldo de una orden perdida (nunca como disparador primario) |
| «ajustes aplicados» / cambio de `reducir_sobresaltos` y `reducir_movimiento` | 6 | Regla 18 |
| «pausa abierta», «pausa cerrada» | 25 | Regla 22 |
| «interacción ejecutada» | 7 | **28 no lo consume.** Su `resultado` ampliado no le afecta; si algún día lo lee, los consumidores filtran por `HECHO` (7 D7-74, 21 AC-21-15). Las luces de resolución llegan por `EV_PUZZLE_SOLVED_<ID>` (regla 19) |
| «escena lista» de la escena cargada | 21 / 4 | Registrar `AtmosphereZone` y aplicar el estado de reanudación |

**Contratos ‡ que se cumplen:** (1) Jugador 2 espera de 28 la lectura de `pose_con_retardo` y `giro_acumulado` con umbral de «gira la cabeza» fijado por 28 (regla 16); (2) 21 espera `REFLEJO_RETARDADO` como aparición gradual con `reducir_movimiento` (regla 17) y el parpadeo como una sola atenuación (regla 9); (3) pausa (regla 22); (4) 23: `LLUVIA_*` y jerarquía de lluvia (F5); (5) 9/13: avisos de resolución de luz (regla 19); (6) el slice y la art bible esperan un límite de destellos de ≤ 3 Hz (regla 11) y atenuación con «reducir sobresaltos» (regla 18).

## Tuning Knobs

Todos en `assets/data/atmosphere/atmosphere.json` salvo los límites de seguridad, que son constantes de código.

| Clave | Valor | Rango seguro | Afecta | Regla / fórmula |
|---|---|---|---|---|
| `d_apagon_s` | 0,4 | 0,3–1,0 | Velocidad de caída de la luz | R8, F4 |
| `d_apagon_red_s` | **2,0†** (antes 0,8; DT-23) | 2,0–4,0 | Ídem con `reducir_sobresaltos` | R18 |
| `f_apagon` | 0,0† | 0,0–0,1 | Luz residual de `C03` en el apagón | R8 |
| `ambiente_apagon` | 0,06† | 0,03–0,15 | Suelo de ambiente | R8 |
| `d_restaurar_s` | 2,0 | 1,0–4,0 | Subida de luz (slice C.7) | R12 |
| `parpadeo_veces` | 3 | 1–3 | Caídas del parpadeo (dato de la orden) | R9 |
| `t_caida_s` | 0,15 | 0,08–0,30 | Duración de cada caída | F1 |
| `pausa_min_s` | 0,35 | **≥ 0,35** (constante) | Frecuencia de destellos | F1, R11 |
| `f_parpadeo` / `_red` | 0,40† / 0,65† | 0,40–0,70 / 0,50–0,80 (suelo 0,40 forzado por código) | Profundidad del parpadeo | F4, F7 |
| `f_tubo` / `_red` | 0,40† / 0,65† | 0,40–0,70 / 0,50–0,80 | Parpadeo del Archivo y Recepción | R10 |
| `retardo_reflejo_s` | 0,6 | 0,2–1,0 (≤ `T_hist`) | Retardo del reflejo | F3 |
| `t_entrada_reflejo_s` / `t_salida_reflejo_s` | 0,5† / 0,35† | 0,2–1,0 | Suavidad del reflejo | F3 |
| `t_activo_min_s` | 1,0† | 0,5–3,0 | Tiempo mínimo visible | R15 |
| `duracion_reflejo_s` | 3,0 | 1,5–5,0 | Duración del efecto (dato de la orden) | R15 |
| `umbral_giro_deg` / `T_giro_s` | 45† / 0,5† | 20–90 / 0,3–1,0 | «Gira la cabeza» | R16 |
| `pulso_resolucion` / `_red` | +0,25† / +0,15† | 0,1–0,4 | Aviso de resolución | R19 |
| `base_zona` (lluvia) | 0,35–1,0 (derivado de 23) | 0–1 | Intensidad de la lluvia por zona | F5 |
| `realce_lluvia_factor` | 1,3† | 1,0–1,6 | `LLUVIA_REALCE` (el audio: `realce_lluvia_db` de 23) | R20 |
| `lluvia_apagon` | 0,0† | 0–0,5 | Lluvia en el apagón (OQ 1) | R20 |
| `n_max_ventanal` | 200† | 50–400 | Partículas por ventanal | F5, F8 |
| `lluvia_vel_red` | 0,5† | 0,25–1,0 | Velocidad con `reducir_movimiento` | R18 |
| `max_luces_visibles` / `max_luces_sombra` | 8 / 2 | 4–12 / 1–3 | Coste de iluminación | F8 |
| `seed_archivo` | 20261109 | cualquiera | Desfase del tubo (determinista) | R10 |
| Constantes de código (no son datos) | `FLASH_MAX_HZ` 2,0, `FLASH_PAUSE_MIN_S` 0,35, 3 destellos/s, `FLASH_DEPTH_FLOOR` 0,40 | — | Seguridad fotosensible | R11 |

## Acceptance Criteria

Etiquetas: (U) prueba unitaria, (I) integración, (V) visual con captura retenida en `production/qa/evidence/` y firma del art director, (P) rendimiento.

- **AC-28-01 (R9, F1, U):** **GIVEN** una orden `LUCES_PARPADEO` con 3 veces, **THEN** la secuencia dura 1,15 s ±0,02 y el tiempo entre inicios de caída consecutivos es ≥ 0,50 s (frecuencia ≤ 2,0 Hz) con datos por defecto.
- **AC-28-02 (R11, U):** **GIVEN** datos con `pausa_min_s = 0,05` o 6 caídas pedidas en 1 s, **THEN** 28 las fuerza a ≥ 0,35 s y ≤ 3 destellos por ventana de 1,0 s; nunca emite más.
- **AC-28-03 (R8, F4, U):** **GIVEN** `LUCES_APAGON`, **THEN** la energía de las seis `C03` llega a `f_apagon·E_nom` en 0,4 s ±0,03, de forma monótona (sin segundo mínimo ni rebote); `V06` queda al 100 %.
- **AC-28-04 (R8, V):** **GIVEN** el apagón, **THEN** la captura muestra el pasillo en azul noche sin negro puro (luminancia relativa mínima de todo píxel de mundo iluminable ≥ 0,01†, medida en la captura; sin excepciones abiertas), con `V06` visible y las manos legibles (razón manos/entorno ≥ 1,5 : 1 de AC-34 de 2).
- **AC-28-05 (R12, U):** **GIVEN** `LUCES_RESTAURAR`, **THEN** la energía sube monótonamente de `E_ap` a `E_nom` en 2,0 s ±0,05 sin parpadeo; con `reducir_sobresaltos` igual.
- **AC-28-06 (R18, F7, U):** **GIVEN** `reducir_sobresaltos`, **THEN** no hay parpadeo (la energía de `C03` no cambia al llegar `LUCES_PARPADEO`) y el apagón es una rampa monótona de 2,0 s ±0,05 (≥ 2,0 s). **GIVEN** solo `reducir_movimiento`, **THEN** una única atenuación de 0,6 s hasta 0,65·E_nom (≥ 0,40·E_nom). **GIVEN** ambas, **THEN** luz fija (regla 9, DT-23).
- **AC-28-07 (R15, F3, U):** **GIVEN** `REFLEJO_RETARDADO` con 0,6 s, **THEN** a mitad de `ENTRANDO` `τ` = 0,3 s ±0,02; en `ACTIVO` la posición del proxy coincide, en el mismo tick de muestra, con la pose del jugador de hace 0,6 s reflejada por F2 (error < 3 cm; a 1,6 m/s un paso de física a 60 Hz ≈ 2,7 cm).
- **AC-28-08 (R16, U):** **GIVEN** `ACTIVO` con 1,2 s transcurridos, **WHEN** `giro_acumulado()` ≥ 45°, **THEN** pasa a `SALIENDO`; con 30° en 0,5 s, no. **WHEN** el giro llega antes de 1,0 s, **THEN** el efecto espera a 1,0 s.
- **AC-28-09 (R15, I):** **GIVEN** que el jugador no gira, **THEN** a los 3,0 s del `REFLEJO_RETARDADO` el efecto sale solo en `t_salida`; **y** no se repite si se vuelve a pasar por `T-PAS-2`.
- **AC-28-10 (R17, V):** **GIVEN** `reducir_movimiento`, **THEN** la entrada del retardo es un fundido cruzado de 0,5 s sin movimiento intermedio visible; captura retenida de dos fotogramas (inicio y fin).
- **AC-28-11 (R13, I):** **GIVEN** el puzle 2 y el puzle 5 activos, **THEN** ningún nodo de sus superficies está en el grupo `reflejo_retardado` y ninguna llamada a `pose_con_retardo` parte de ellos (comprobación estática del árbol). **Contrato 29 (I):** **THEN** 28 no llama a `set_shader_parameter` sobre `mat_glass_memo` y no existe `SubViewport` de 28 asignado a él; con 28 ausente el cristal de P2 se ve completo.
- **AC-28-12 (R20, I):** **GIVEN** `LUCES_APAGON`, **THEN** la lluvia visible baja a `lluvia_apagon` en 0,4 s ±0,05 en el mismo fotograma que 23 recibe la orden; con `LLUVIA_VUELVE`, vuelve en 2,0 s ±0,1. `LLUVIA_CESA` (6,0 s): 0 a 6,0 s ±0,2.
- **AC-28-13 (R20, V):** **GIVEN** el pasillo, el Archivo y la Sala de Reuniones con lluvia, **THEN** la lluvia es más intensa en Archivo y pasillo que en las salas (F5, `base_zona` derivado de 23); captura de cada una.
- **AC-28-14 (R21, I):** **GIVEN** una partida guardada con `caja_completa` ∧ ¬`llamada_completada`, **WHEN** «Continuar», **THEN** el pasillo y D están en `APAGON` en el primer fotograma (sin rampa ni parpadeo), con `V06` encendida y la lluvia a `lluvia_apagon`.
- **AC-28-15 (R21, I):** **GIVEN** `llamada_completada`, **WHEN** «Continuar», **THEN** `NORMAL` sin `LUCES_RESTAURAR`; **GIVEN** `reflejo` ya ocurrido, **THEN** no se repite.
- **AC-28-16 (R22, PV — depende de la pausa de `Tween` y partículas en 4.7, no verificada; ligada al spike de OQ 10 y al ADR de pausa de OQ 12):** **GIVEN** una pausa en mitad de un apagón o de un parpadeo, **THEN** `Tween` y partículas se detienen, y al reanudar el efecto continúa sin saltos ni repetición.
- **AC-28-17 (R23, I):** **GIVEN** que 29 no existe en el árbol, **THEN** 28 arranca, ejecuta todos los efectos y pasa AC-28-01 a AC-28-15 (AC-28-16 y AC-28-19 son PV y se cierran tras el spike; AC-28-17 no depende de ellos). Los puntos ‡ (API de 4.7 sin cobertura en `engine-reference`) se confirman en un spike antes de cerrar AC-28-16 y AC-28-19.
- **AC-28-18 (R10, U):** **GIVEN** la semilla `seed_archivo`, **THEN** el tubo hace exactamente 2 parpadeos por ventana de 20,0 s con ≥ 0,35 s entre ellos, y el patrón se repite igual en cada ejecución.
- **AC-28-19 (F8, PV — requiere el spike de OQ 10 y el hardware mínimo):** **GIVEN** la prueba de 30 s del pasillo en el hardware mínimo (slice §22) con lluvia, `C03` y `C02` activos, **THEN** ≥ 60 fps en el 99 % de los fotogramas; 28 ≤ 1,0 ms GPU y ≤ 0,15 ms CPU de media; ≤ 8 luces visibles, ≤ 2 con sombra, ≤ 500 partículas.
- **AC-28-20 (R19, V):** **GIVEN** la resolución de P3, **THEN** el marco se ilumina 1,0 s en una sola subida y bajada (1 ciclo) sin parpadeo; captura de la cresta.
- **AC-28-21 (R11, U):** **GIVEN** una captura de 10 s en cada una de `pasillo` (con `LUCES_PARPADEO`), `archivo` (tubo) y `recepcion` (tubo al entrar), analizada con un script de luminancia por fotograma (promedio de pantalla, en `tools/`), **THEN** no hay más de 3 **destellos** por ventana deslizante de 1 s, con «destello» = 30 regla 24 (AC-30-13); cada destello son dos cruces del umbral de ±10 %, de modo que el parpadeo por defecto (2,0 Hz, 2 destellos/s) da 4 cruces/s y cumple (art bible §8.7).
- **AC-28-23 (R11e, U):** **GIVEN** datos con `f_parpadeo` = 0,10 y `f_tubo` = 0,10, **THEN** el limitador los sube a 0,40 y la energía mínima observada en el parpadeo es ≥ 0,40·E_nom; el apagón (`f_apagon` = 0,0) no se ve afectado.
- **AC-28-24 (R13, V):** **GIVEN** la vista de `C02`, **THEN** el proxy no se espeja (sin escala negativa; caras correctas) y captura retenida confirma el aspecto (criterio de OQ 4/6).
- **AC-28-22 (R1, U):** **GIVEN** una orden desconocida, **THEN** 28 la ignora con `push_warning` y no cambia el estado.

## Decisiones tomadas

| ID | Decisión | Alternativa descartada | Motivo |
|---|---|---|---|
| DT-1 | Autoload `Atmosphere` + `AtmosphereZone` por escena | Un nodo único por escena sin autoload; o un singleton que lo posea todo | El estado (apagón, lluvia) cruza escenas y se recalcula tras cargar; las luces y ventanas pertenecen a cada escena. El autoload evita perder el estado del apagón al cambiar de escena y es testable por inyección del bus |
| DT-2 | Parpadeo con pausa mínima de 0,35 s (1,15 s total, 2,0 Hz) en vez de 3 caídas seguidas | Respetar «0,15 s cada vez» sin pausa, ≈ 3,3 Hz | 21 regla 23 ya reconoce que 3,3/s supera el límite. El slice no fija la pausa; 0,35 s cumple art bible §8.7 y WCAG 2.3.1. Cambia la duración total (de 0,45 s a 1,15 s): **no lo decide un agente, ver OQ 8 (decide el usuario)**; aquí queda como valor por defecto |
| DT-3 | Reflejo por habitación espejada con proxy (1 draw call) | `SubViewport` con cámara espejada y retardo del fotograma; reflejo de pantalla (SSR) | El viewport duplica la escena (coste de GPU alto y desfase de paralaje) y el retardo se hace con la pose, no con el vídeo. La geometría espejada da paralaje correcto, cuesta 1 draw call y es determinista. Coste: el cristal solo muestra al proxy y la sonda, no el resto del pasillo |
| DT-4 | El retardo se hace con `pose_con_retardo` del Jugador | Almacenar fotogramas o repetir la animación con un retardo propio | La memoria circular ya existe (GDD 2 regla 29); un segundo historial duplicaría estado |
| DT-5 | Apagón con suelo de ambiente (no negro puro) y `V06` como luz de emergencia | Apagón total a negro, con una linterna en las manos | Art bible: «nunca negro puro»; `V06` ya está en el slice. Una linterna sería un verbo nuevo que el slice no tiene. La señal de emergencia extra es de art director (OQ 2) |
| DT-6 | 28 sin ajustes propios; solo lee `reducir_sobresaltos` y `reducir_movimiento` | Una clave nueva `intensidad_atmosfera` | Alcance del slice y claves ya registradas; dos claves cubren destello y movimiento por separado |
| DT-7 | El reflejo retardado nunca se aplica a P2 ni P5 | Dar a los puzles un reflejo «con retardo» para reforzar el tono | Haría ilegible la solución (pilar *Tensión sin castigo*). Los puzles son dueños de sus superficies |
| DT-8 | La lluvia visible sigue a 23: baja a 0 con `LUCES_APAGON` y vuelve con `LLUVIA_VUELVE` | Lluvia visible continua y solo se calla el audio | Lluvia visible sin sonido contradice la imagen; «vuelve la lluvia» (C.7) implica que se fue. Se decide con el valor por defecto de 23 (OQ 1) |
| DT-9 | Los límites de destellos son constantes de código con prueba | Solo datos editables | Un error de datos no puede romper la seguridad fotosensible |
| DT-10 | `reducir_movimiento` afecta al reflejo, a la lluvia y (por 21 R23) a la forma del parpadeo `C03`; `reducir_sobresaltos`, al resto de luces. Si ambas: una sola atenuación de 0,6 s a `f_parpadeo_red` (regla 9) | Una sola clave; o sumar ambas atenuaciones | Es lo que hacen 21 y 23; sumar produciría dos caídas, contra el tope de destellos |
| DT-13 | Proxy de reflejo sin espejar (posición y yaw reflejados) y sin `CULL_FRONT` | Escala negativa con `CULL_FRONT` | `CULL_FRONT` sin cobertura en `engine-reference` y Godot podría corregir el determinante por sí mismo (doble corrección); la lateralidad de un maniquí sin cara no se percibe |
| DT-14 | (Ronda 9) 28 posee todo reflejo, incluido el de `B04` (sonda de sala sin retardo, con tope de 29); 29 aporta el shader y el material del cristal | (a) 29 posee el reflejo de `B04` (versión de la ronda 1); (b) 28 entrega `reflection_tex` a P2 | 29 R12 y 28 R13 se contradecían sobre quién posee el reflejo del cristal; un único dueño evita dos fuentes de verdad. Sin retardo en P2 el reflejo es solo una sonda; una textura extra costaría un `SubViewport` (DT-3) |
| DT-15 | Suelo de profundidad 0,40 en todo parpadeo; defaults `f_parpadeo` = `f_tubo` = 0,40† | Mantener 0,30/0,25 y limitar el suelo a `reducir_sobresaltos` | El art bible §8.7 (40–50 %) es el único criterio citado; una constante que sus propios datos contradicen es inverificable. Coste: caída menos profunda que la prueba del slice (OQ 3, art director) |
| DT-16 | `base_zona` de la lluvia derivado de `perfil_dB` de 23 | Tabla propia de 28 | Una sola jerarquía imagen/sonido (F5) |
| DT-17 | El tubo parpadeante de Recepción lo ejecuta 28 en «escena lista» | Orden nueva de 21; dejarlo fuera | Está en el slice (línea 681); no requiere orden ni lógica de partida |
| DT-18 | (Ronda 9) 28 usa `EV_PUZZLE_SOLVED_<ID>` (de 9 y 3) y no pide a 9 `puzzle_solved {id}` | Pedir un aviso nuevo con `id` | El aviso real ya existe (R9-B3 de la revisión cruzada) |
| DT-19 | (Ronda 9) Frecuencia del parpadeo ≤ 2,0 Hz (`FLASH_MAX_HZ`) con 1,15 s por defecto; se anota a 21 la corrección de su R23 («≈ 3,3/s») | Citar el tope de 3 Hz de 30 | La secuencia real es 2,0 Hz; 21 omitía la pausa de 0,35 s. El 1,15 s sigue en OQ 8 |
| DT-20 | (Ronda 9) AC-28-16 y AC-28-19 pasan a PV; AC-28-17 solo exige AC-28-01 a AC-28-15 | AC-28-17 dependiente del spike | Dependen de APIs ‡ y del hardware; el ADR de pausa queda en OQ 12 |
| DT-21 | (Ronda 9) El nombre del aviso de pausa es «pausa abierta»/«pausa cerrada» | `pause_opened` | Un solo nombre en 3, 23, 25, 26 y 28 |
| DT-22 | (Ronda 10) «Destello» = definición única de 30 (regla 24); AC-28-21 cuenta **destellos** (≤ 3 por ventana de 1 s, AC-30-13) y no cruces: 2,0 Hz = 2 destellos/s = 4 cruces/s; 28 no consume «interacción ejecutada» (regla de filtro `HECHO` anotada); ‡ cerradas de «pausa abierta»/«pausa cerrada» (3 las declara) | Contar cruces (límite 3 cruces/s, incompatible con el 2,0 Hz por defecto) | Unidad y valor únicos con 30; los ‡ de API (`PROCESS_MODE_PAUSABLE`, `GPUParticles3D`) siguen abiertos. |
| DT-11 | Gotas en el cristal sin lectura de pantalla (sin refracción) | Refracción con `hint_screen_texture` | Evita un pase de copia de pantalla en cada ventanal; el presupuesto de 1,0 ms no la admite en el hardware mínimo |
| DT-12 | Pulso de luz de resolución sin repetición | Pulso intermitente para llamar la atención | Evita destellos y no es una pista (las pistas son de 17) |
| DT-23 | **(Usuario, 2026-11-12.)** Con `reducir_sobresaltos`: luz de `C03` fija (sin el parpadeo de 1,15 s) y apagón en oscurecimiento gradual de **2,0 s** (`d_apagon_red`; antes 0,8 s); con `reducir_movimiento`: se apagan balanceo de cámara y movimientos decorativos (cierra «más allá del slice §14»; 30 R19, R9 de este GDD). Se enmienda slice C.4 y C.7 (v0.4.4). Cierra OQ 11 | Mantener la atenuación con rampas de 0,30 s y el apagón de 0,8 s · dejar `reducir_movimiento` en lo del slice §14 | El parpadeo y la caída brusca son lo que sobresalta; el apagón sigue siendo aviso y señal narrativa (sigue siendo ≥ 2,0 s de caída monótona, sin destello). Valor 2,0 s = el mínimo decidido: afinar en playtest |

## Open Questions

| # | Pregunta | Propietario | Valor por defecto |
|---|---|---|---|
| 1 | ¿La lluvia (imagen y sonido) cae a cero durante el apagón y la llamada? Es la OQ 1 de 23: el slice solo dice «vuelve la lluvia» (C.7) | Usuario / creative-director | Cae a 0 (0,4 s) y vuelve en 2,0 s. 28 y 23 deben decidirse juntos (DT-8) |
| 2 | ¿Hay luz de emergencia adicional (señal de salida, luz verde o roja) además de `V06` y la pantalla del teléfono? | art-director | No. Solo `V06`; 28 deja el «slot» `LuzEmergencia` desactivado |
| 3 | Valores †: energías, colores y curvas perceptuales de las luces (art bible los reserva al art director); el 28 solo da los porcentajes | art-director | Los de las tablas |
| 4 | ¿Cómo trata Godot 4.7 un proxy con determinante negativo (`CULL_FRONT`)? **No verificado, a confirmar en ADR/prototipo** (sin cobertura en `engine-reference`). Solo importa si se decide espejar | engine-programmer | No espejar (DT-13); sin impacto en reglas |
| 5 | ¿Es `limitador de destellos` suficiente para accesibilidad, o hay una prueba con un analizador externo (PEAT)? | accessibility-specialist | AC-28-21 interna; PEAT opcional antes de enseñar el slice |
| 6 | El proxy de cuerpo entero de Vera es un asset nuevo que el slice no pide («el reflejo de Vera llega un instante tarde»), visible siempre que `C02` está a la vista, y el cristal no refleja el resto del pasillo. ¿Silueta definitiva y coste de arte? | art-director | Proxy low poly con silueta de las manos, visible en `OFF`. **Alternativa de bajo coste:** visible solo durante el efecto (aparece con el fundido de `ENTRANDO`). Criterio visual: captura retenida de `C02` (AC-28-24) que se lea como «Vera» sin cara |
| 7 | El slice C.7 dice que el apagón «es completo»; ¿se acepta el suelo de ambiente 0,06† para legibilidad? | creative-director | Sí (art bible: nunca negro puro) |
| 8 | **Decide el usuario.** Ritmo del parpadeo `C03`: el slice (C.4, línea 986) fija «3 veces, 0,15 s cada vez» (≈ 0,45 s, ≈ 3,3 Hz si no hay pausa, por encima del tope de ≤ 3 destellos/s). Este GDD propone 3 × 0,15 s con pausas de 0,35 s (1,15 s, 2,0 Hz). | Usuario | **Por defecto (respeta ≤ 3 Hz):** 1,15 s con pausas de 0,35 s. **Alternativa más fiel al slice, compatible con el tope:** 3 caídas de 0,15 s con pausas de 0,19 s (≈ 0,83 s, ≈ 2,9 Hz: compatible con el tope pero casi sin margen; no recomendable) o **una sola caída de 0,15 s** (1 destello; mantiene «0,15 s», pierde el «3 veces»). Elegida una, ajustar slice C.4 y 21 (`ESC4_PASILLO_MEGA`); el limitador no cambia |
| 9 | **Decide el usuario.** Temperatura de `V06`: el slice dice 2700 K (líneas 558, 562); la versión anterior de este GDD decía 2200 K (de las lámparas de B) | Usuario / art-director | **2700 K (slice).** Si se prefiere 2200 K, cambiar el slice |
| 10 | Spike de engine-programmer para todos los puntos ‡ de API de 4.7 sin cobertura: `Tween` pause mode, `PROCESS_MODE_PAUSABLE` y pausa de `GPUParticles3D`, `distance_fade`, `ReflectionProbe` con fresnel en cristal transparente, monitor «Objects in frame», coste de luces en el clúster de Forward+, efecto de glow/HDR de 4.6/4.7 sobre el apagón, mecanismo de luz de las manos (2/ADR) | engine-programmer | Ejecutar antes de cerrar AC-28-16 y AC-28-19 |
| 11 | **CERRADA (usuario, 2026-11-12, DT-23).** Con `reducir_sobresaltos` el apagón es un oscurecimiento gradual de 2,0 s (`d_apagon_red_s`) y el parpadeo no existe (luz fija); slice C.4 y C.7 enmendados en v0.4.4 | Usuario | Aplicado |
| 12 | **ADR de pausa (`SceneTree.paused` / `process_mode`):** `docs/engine-reference/godot/` no documenta la pausa del árbol, de `Tween` ni de `GPUParticles3D`. R22 asume árbol pausado. Opciones sin decidir: (a) 25 pausa el árbol y cada sistema declara su `process_mode` (28 `PAUSABLE`); (b) 25 no lo pausa y 28 (y 29) usan su propio reloj de juego (Δ_juego) para Tween, partículas y shaders | Technical-director / 25 | Sin decidir; AC-28-16 es PV hasta entonces |

## Cambios requeridos en otros GDDs

| GDD | Cambio |
|---|---|
| **21 Director de escenas** | (0) **Corregir 21 R23** («tres destellos de 0,15 s, ≈ 3,3 por segundo»): 21 omite la pausa de 0,35 s; el parpadeo por defecto es 1,15 s a 2,0 Hz (≤ 2,0 Hz, `FLASH_MAX_HZ`); (a) Tras la decisión de OQ 8: `LUCES_PARPADEO` con el ritmo elegido; 28 impone el límite aunque 21 pida otro valor; (b) emitir `LUCES_APAGON` con duración 0 al reanudar (regla 21 de 28; confirmar contra 21 R14); (c) `LLUVIA_CESA`/`LLUVIA_VUELVE` de `ESC7_*`: la lluvia **no** es una orden de 21 en el apagón; 23 y 28 la derivan de `LUCES_APAGON` (OQ 1 de 23); (d) mantener «sin dependencia directa» con 28 y confirmar que `reducir_movimiento` gobierna la atenuación única del parpadeo (R23) y la combinación de la regla 9 de 28; verificar el solape `LUCES_PARPADEO` / `T-PAS-2`. |
| **29 Shaders y efectos** | **Contrato de reflejo (ronda 9):** 28 posee el reflejo (proxy retardado en `C02`; sonda de sala sin retardo en `B04`, con tope `reflection_strength_max`); 29 posee el shader/material `mat_glass_memo` y no dibuja el reflejo. 29 alinea sus reglas 12–14 (hecho en su ronda 9: el orden de dibujo por `render_priority` es NOT SOURCEABLE y se sustituye por la sonda) y su interfaz «28 → cristal». 29 solo puede sustituir `rain_glass`, no `C02`. |
| **2 Jugador** | Confirmar `pose_con_retardo(τ)` para τ ≤ `T_hist` (1,0 s) y `giro_acumulado()` en grados; fijar que la capa de «manos» tenga una máscara de luz separada para el apagón (regla 8). |
| **3 Estado y bus** | Registrar «efecto de escena pedido» {`id`, `objetivo`, `duración`, `parámetros`} y la lista de avisos de 28 (Dependencies), con nombres alineados: 3 los llama «apagón, parpadeo, reflejo» y a 28 «efecto de escena pedido». Dureza de 28: blanda (ya la declara 3). |
| **6 Ajustes** | Listar 28 como lector de `reducir_sobresaltos` **y** `reducir_movimiento` (hoy solo la primera), dureza blanda; descripción de `reducir_sobresaltos` con parpadeo del pasillo y apagón (art bible, línea 439). |
| **23 Director de audio** | Cerrar la OQ 1 junto con 28 (DT-8); `LLUVIA_*` y `d_lluvia_apagon` (0,4 s) como dato compartido; `perfil_dB` es la fuente de `base_zona` de 28 (F5); añadir fila propia de dependencia hacia 28 (informativa). |
| **systems-index** | Fila 28 (línea 52): quitar 21 de las dependencias («por el bus, sin dependencia directa»); línea 132: alinear. Dependencias de 28: 2 (dura), 3 y 6 (blandas). |
| **25 Menú de pausa** | Emitir «pausa abierta» y «pausa cerrada» (**aplicado:** 3 regla 10 los declara; 28 se pausa con ellos). |
| **9/13 y puzles 2, 3, 5** | Sin cambios en el aviso: 28 consume el `EV_PUZZLE_SOLVED_<ID>` que 9 y 3 ya declaran (no se añade `puzzle_solved {id}`); declarar que P2 y P5 no usan el grupo `reflejo_retardado` (regla 13); P5: definir la forma de su revelación si 28 debe aportar el pulso de luz (regla 19). |
| **4 Escena de planta / nivel** | Proveer `p0` y `n` del plano de `C02`, las posiciones de `C03` y el árbol de luces por escena; confirmar los tres ventanales. |
| **slice-v0.3.md** | C.4 (línea 986): **solo si el usuario lo decide (OQ 8)**; C.7: aclarar si la lluvia se va en el apagón (OQ 1). |
| **art-bible** | Resolver el pendiente de 2.7 (atenuación del parpadeo y del apagón) con los valores de la regla 18. |

## Entradas para el registro (†=propuesta)

| Tipo | Nombre | Valor | Nota |
|---|---|---|---|
| Sistema | `atmosphere` (28) | Presentation, Vertical Slice | Autoload `Atmosphere` + `AtmosphereZone`; sin hechos propios |
| Archivo de datos | `assets/data/atmosphere/atmosphere.json` | — | Perfiles por zona |
| Constante | `FLASH_PAUSE_MIN_S` | 0,35 | Seguridad fotosensible (R11) |
| Constante | `FLASH_MAX_HZ` | 2,0 | Límite propio, por debajo de 3 Hz |
| Constante | `FLASH_DEPTH_FLOOR` | 0,40 | Suelo de profundidad del parpadeo (R11e) |
| Datos (valores en Tuning Knobs; no se duplican aquí) | `d_apagon_s`, `d_restaurar_s`, `retardo_reflejo_s`, `duracion_reflejo_s` (slice; sin †) y los †: `d_apagon_red_s`, `umbral_giro_deg`, `T_giro_s`, `t_*_reflejo_s`, `n_max_ventanal` | — | Verificar colisiones con `/consistency-check` antes de registrar (`design/registry/entities.yaml` no revisado) |
| Presupuesto | 28 | 1,0 ms GPU, 0,15 ms CPU, ≤ 8 luces, ≤ 2 sombras, ≤ 500 partículas | F8 |
| Efectos del bus | `LUCES_PARPADEO`, `REFLEJO_RETARDADO`, `LUCES_APAGON`, `LUCES_RESTAURAR`, `LLUVIA_REALCE`, `LLUVIA_CESA`, `LLUVIA_VUELVE` | — | Ya los nombra 21/23; 28 es el consumidor |
| Grupo | `reflejo_retardado` | Solo `C02` | R13 |
| Estados | `NORMAL`, `FLICKER`, `APAGON`, `RESTAURANDO` / `OFF`, `ENTRANDO`, `ACTIVO`, `SALIENDO` | — | Memoria volátil |
| Clave de ajuste (lectura) | `reducir_sobresaltos`, `reducir_movimiento` | false | Ya registradas |

## Historial

| Fecha | Cambio |
|---|---|
| 2026-11-09 | Borrador inicial (lote autónomo, Technical Artist). Modo `standard`. Pendiente de revisión independiente y de las respuestas a las Open Questions 1, 2 y 4. |
| 2026-11-09 | Ronda de corrección 1 (informe `reviews/atmosfera-reactiva-review.md`). B-1: contrato con 29 resuelto del lado de 28 (regla 13, DT-14, fila 29). B-2: suelo 0,40 aplicado a todos los parpadeos (R11e, DT-15, AC-28-23). B-3: 3 y 6 pasan a Blanda; fila índice/3/6/23 en cambios. B-4: ritmo del parpadeo elevado al usuario (OQ 8); V06 2700 K (OQ 9). W-1, 3, 5–7, 9–15, 18 aplicados; W-2/10 spike ‡ (OQ 10); W-16 reescrito; W-17 y W-19 pendientes de verificar. Tamaño reducido. Pendiente de re-review. |
| 2026-11-10 | Ronda de corrección 9 (informe `gdd-cross-review-2026-11-10.md`). R13/DT-14: 28 posee todo reflejo y 29 aporta el shader (alineado con 29 R12); `EV_PUZZLE_SOLVED_<ID>` en lugar de `puzzle_solved {id}`; frecuencia del parpadeo ≤ 2,0 Hz y corrección de 21 R23 anotada; «pausa abierta»/«pausa cerrada»; AC-28-16/19 a PV y AC-28-17 acotado; OQ 11 (apagón 0,8 s, pendiente del usuario) y OQ 12 (ADR de pausa); DT-18 a DT-21. Estado: Revisado (ronda de corrección 9) — pendiente de re-review. |
| 2026-11-12 | Propagación de las decisiones del usuario (`gdd-cross-review-2026-11-10-r2.md`): R9 (luz fija con `reducir_sobresaltos`), R18 (apagón 2,0 s y movimientos decorativos con `reducir_movimiento`), DT-23, OQ 11 cerrada. Los AC y los knobs que citen `d_apagon_red` 0,8 s o la atenuación de 0,30 s se leen con estos valores. Pendiente de re-review |
| 2026-11-10 | Ronda de corrección 10 (R15-1/2/4): AC-28-21 y R11 alineados con la definición de «destello» de 30 (regla 24); 28 no consume «interacción ejecutada»; ‡ de pausa cerradas; DT-22. Estado: Revisado (ronda de corrección 10) — pendiente de re-review. |
