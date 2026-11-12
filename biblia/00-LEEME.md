# Biblia narrativa · El Nido en la Niebla · «Turno de noche»

**Versión:** 1.0 · **Fecha:** 2026-11-12
**Para quién:** el equipo que va a construir los puzles jugables. No necesitas leer nada más del repositorio para trabajar.
**Qué es:** la historia completa del vertical slice, cada puzle hilado con esa historia, y los puzles, construidos con **las mismas mecánicas del piloto «La Caja»** (el `index.html` en three.js), cambiando la temática.

---

## Cómo está organizada

| Archivo | Qué contiene | Léelo si… |
|---|---|---|
| `01-historia.md` | Premisa, personajes, cronología, objetos con historia, lo que el juego **no** decide y las reglas de escritura | Vas a escribir un solo texto o a decidir qué se ve en una foto |
| `02-recorrido.md` | La noche escena a escena: dónde está el jugador, qué sabe, qué descubre, qué bandera se activa | Necesitas saber en qué orden pasa todo |
| `03-kit-de-mecanicas.md` | Las mecánicas del piloto, desmontadas con sus números exactos (pasos, tiempos, sonidos, avisos) | Vas a programar o a ajustar el «tacto» |
| `04-puzles.md` | **Los puzles.** Tres objetos-puzle (cajetín del Archivo, lámparas de la Sala B, caja del Guardián) con especificación completa | Vas a construir los puzles |
| `05-textos.md` | Todos los textos con ID: voces, documentos, avisos en pantalla, pistas | Vas a meter textos o subtítulos |
| `06-trazabilidad.md` | Matriz: cada pista, de dónde sale, qué abre y qué cambia más tarde. Lista de comprobación de coherencia | Vas a revisar que nada quede suelto |

## Tres reglas para usar esta biblia

1. **La historia es canon; los puzles de `04` también.** Todo lo de `01`, `02` y `05` (salvo lo marcado como **[NUEVO]**) viene del documento del slice (`design/slice/slice-v0.3.md`, contenido v0.4.4) y no se cambia sin el autor. Lo de `04` **sustituye a las mecánicas de puzle del slice** (§10 y Anexo B): el autor aprobó las decisiones D-B1 a D-B10 el 2026-11-12. Donde el slice y esta biblia no coincidan en un puzle, vale la biblia.
2. **Las mecánicas no se inventan, se reutilizan.** Cada puzle usa piezas del kit de `03` (M1 a M8). Si algo nuevo hace falta, se marca **[EXTENSIÓN]** y se justifica. Hay cuatro en todo el documento.
3. **Menos es más.** Cada objeto-puzle se puede jugar solo, en una escena aislada, sin el resto del juego. Construid primero la caja del Guardián (`04` §4): es el piloto con otra piel y concentra cuatro de los seis puzles.

## Marcas que vas a ver

- **[CANON]**: viene del slice. No tocar.
- **[NUEVO]**: decisión nueva de esta biblia, aprobada por el autor el 2026-11-12. Es canon como el resto.
- **[EXTENSIÓN]**: mecánica que el piloto no tiene tal cual y que se añade con el mínimo cambio.
- **[ABIERTO]**: lo deja sin resolver la propia historia, a propósito. No lo resolváis.
- IDs como `VO_G_07`, `caja_c1` o `EV_PUZZLE_SOLVED_P3`: se conservan tal cual en código, audio y subtítulos.

## Resumen en diez líneas

Vera lleva tres días al frente de una unidad nueva y se queda de noche en la planta nueve, con lluvia. Su antiguo responsable, El Guardián, ya no está: su número «ya no está disponible». En los correos, en el Archivo y en un memorando aparece que su traslado se pidió a su nombre, con una firma que parece suya, mientras ella estaba en un avión. En el despacho del Guardián hay una caja de madera, un juego de los que él hacía para el equipo, con la foto del grupo, y en esa foto Vera no está. Al abrirla, Vera escucha una grabación en la que él confiesa a medias, y encuentra una carta escrita con su propia letra a la que le falta la primera frase. El jugador elige esa frase. Se va la luz, suena el teléfono desde la extensión de Vera y la voz del Guardián le lee lo que ella acaba de elegir. Al salir, en el libro de visitas, Vera ya estuvo allí hace nueve días. O alguien que firma como ella.
