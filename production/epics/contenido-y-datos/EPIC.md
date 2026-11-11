# Epic: Contenido narrativo y datos validados

> **Layer**: Foundation
> **GDD**: design/gdd/base-de-contenido-narrativo.md (§ Overview l. 15, § Acceptance Criteria l. 285)
> **Architecture Module**: Capa 1 — 18 Contenido (`ContentDB`, autoload n.º 1)
> **Status**: **LISTO** — 17/17 TR libres; implementar los hallazgos de S-0005-A (claves duplicadas, BOM en bytes, comas finales)
> **Actualizado 2026-11-11**: desbloqueado por ADR-0005
> **Stories**: 12 historias (12 Ready, 0 Blocked) — índice con estimaciones y diferidos en `stories.md` (2026-11-11, manifiesto 2026-11-11b)
> **Control manifest**: v2026-11-11 — § Foundation Layer Rules (sin reglas de Contenido: ADR-0005 excluido)
> **Engine Risk**: MEDIUM (`FileAccess`/JSON)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | `FileStore` y `JsonText` | Logic | Ready | ADR-0005, ADR-0009 |
| 002 | `DataSchema`, `DataReader`, `to_int` | Logic | Ready | ADR-0005 |
| 003 | `DataCatalog`, `RefIndex`, `DataValidator` | Logic | Ready | ADR-0005, ADR-0009 |
| 004 | Carga de `ContentDB` y ciclo de vida | Logic | Ready | ADR-0005, ADR-0009 |
| 005 | Capa de idioma y marcadores | Logic | Ready | ADR-0005 |
| 006 | Líneas, documentos y `audio` | Logic | Ready | ADR-0005 |
| 007 | Correos y fichas | Logic | Ready | ADR-0005 |
| 008 | Variantes, IDs retirados, duplicados | Logic | Ready | ADR-0005 |
| 009 | Datos narrativos de M1 | Config/Data | Ready | ADR-0005 |
| 010 | Verificador `tools/data_check` | Logic | Ready | ADR-0005 |
| 011 | Comparación con §12 | Logic | Ready | ADR-0005 |
| 012 | Escaneo de literales | Logic | Ready | ADR-0005 |

Diferido por ADR-0018 (recarga en caliente, CI), ADR-0016/ADR-0008 (AC-19) y ADR-0016 (TR-content-017): ver `stories.md` § Diferido.

## Overview

Catálogo de solo lectura validado al arrancar, con capa de idioma propia. En M1: líneas de las
escenas 1–3, `flags.json` y la entrada `P1` de `puzzles.json`; D-04 (nombre de Vera en megafonía
y formulario) se lee de datos. Es el **desbloqueo de mayor alcance de M1**: ADR-0005 está
co-citado en acceso (15 TR), bolsillo (14), ordenador (14), puzles (6), estado, jugador, director,
escena y prompt.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0005: Data schema validation and content catalog (Accepted) | Esquemas, validación al arrancar, catálogo | MEDIUM |
| ADR-0009 (Accepted) | `ContentDB` como autoload n.º 1 (D1); no cubre ningún TR de este sistema | LOW |

## Criterios de aceptación del épico (trazables al hito)

- **C-M1-1 / C-M1-9**: los datos de escenas 1–3 validan al arrancar; 0 errores en consola.
- **C-M1-2**: la entrada `P1` valida (solución `2 · 1 · 3 · 4`).
- **C-M1-4**: los 5 flags de M1 existen en `flags.json` con su `owner`.

## GDD Requirements

Fuente: `docs/architecture/tr-registry.yaml` (v2, 2026-11-10), filas `system:` content; todas `active`. Texto recortado a 200 caracteres: el registro es la fuente.

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-content-001 | Catálogo de 8 tipos de contenido (línea, documento, correo, ficha de tarea T1-T4, pista, texto de interfaz/mensaje del sistema, sonido no verbal con subtítulo `SUB_…`, texto de objeto), cada u... | ADR-0005 ✅ |
| TR-content-002 | Contenido inicial del slice: 28 entradas del §12 (21 líneas audibles + 7 de documento), 6 correos, fichas T1-T4 y 8 claves `PISTA_*`; la lista de claves `UI_…`/`OBJ_…` de la regla 23 es provi... | ADR-0005 ✅ |
| TR-content-003 | Identificadores estables y sensibles a mayúsculas (`VO_G_12A`, `MEGA_02`, `DOC_01`…, prefijos `PISTA_P<n>_N<k>`, `UI_`, `SUB_<EVENTO>`, `OBJ_<id>`, `MAIL_1-4`/`MAIL_X1-X2`); nunca se reutilizan ... | ADR-0005 ✅ |
| TR-content-004 | Grupos de variantes declarados en datos con prefijo y sufijos (incluidos sufijos de varias letras): `CARTA_` A-C, `VO_G_12` A-C, `VO_G_13` A-D, `VO_G_14` `RET`/`ASG`, `VO_V_12` A-D; el consumidor c... | ADR-0005 ✅ |
| TR-content-005 | Capa de idioma obligatoria en toda lectura: texto por (identificador, idioma); fallback a `es` con log, y «no encontrado» si falta también en `es`; solo `es` en el slice, idioma fijo durante la ... | ADR-0005 ✅ |
| TR-content-006 | Ningún texto visible al jugador en scripts ni escenas (solo por identificador); escaneo estático de literales en propiedades de texto de nodos de interfaz con lista de excepciones (únicas: «…... | ADR-0005 ✅ |
| TR-content-007 | Sustitución en lectura de 4 marcadores `{vera}`, `{guardian}`, `{vera_inicial}`, `{guardian_inicial}` desde una tabla de nombres; marcador desconocido inválido (verificador falla); tabla sin algu... | ADR-0005 ✅ |
| TR-content-008 | Línea = 1..n segmentos con pausa previa opcional (subtítulo = secuencia de segmentos); documento en fragmentos ordenados (`DOC_01` F1-F3, concatenación con espacio) | ADR-0005 ✅ |
| TR-content-009 | Un dato, un registro: día/hora/remitente/asunto/etiquetas de correo en un único registro (la impresión `I-01` se compone de ellos); orden de presentación como lista explícita (3, X1, 1, 4, X2,... | ADR-0005 ✅ |
| TR-content-010 | Líneas audibles con campo `audio` (ruta o nulo); sin audio o fichero ausente se trata como «sin audio» (solo subtítulo, duración decidida por 26), con log y sin error en juego | ADR-0005 ✅ |
| TR-content-011 | Ciclo de vida del catálogo Sin cargar → Cargando → Listo / Error; carga única al arrancar (ficheros leídos una vez), petición en Sin cargar/Cargando = error visible en dev y «…» con log... | ADR-0005 ✅ |
| TR-content-012 | Solo lectura en juego (sin operaciones de escritura en la interfaz pública, sin leer estado); recarga en caliente solo en dev como intercambio atómico (validar catálogo nuevo aparte, servir el a... | ADR-0005 ✅ |
| TR-content-013 | Verificador en `tools/` con código de salida 0/≠0 y parámetro `--hito=calidad`: sin ids duplicados, referencias existentes, líneas audibles con texto, grupos completos, marcadores y nombres li... | ADR-0005 ✅ |
| TR-content-014 | Verificación contra el slice: entradas `fuente: slice_§12` comparadas con la tabla §12 de `design/slice/slice-v0.3.md` (texto entre « », marcadores sustituidos, `[pausa]` → segmentos, fragme... | ADR-0005 ✅ |
| TR-content-015 | Duplicados entre ficheros: en dev detiene la ejecución, en build final gana el primero cargado con log; en recarga que retira un id en uso, el consumidor conserva el último texto con log y el sig... | ADR-0005 ✅ |
| TR-content-016 | Contrato con 9: un efecto `TEXT` de pista referencia siempre una clave `PISTA_P<n>_N<k>` (no `UI_…`) y la carga de `puzzles.json` falla si no existe; las pistas no textuales no llevan clave | ADR-0005 ✅ |
| TR-content-017 | Gramática de token `{accion:<id>}` en textos de interfaz, sustituida por 24 con el glifo y texto de `get_binding_label`; id desconocido se muestra como nombre de la acción | ADR-0005 ✅ |

## Requisitos bloqueados (al 2026-11-11)

Ninguno: todos los TR citan solo ADR `Accepted`.

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of the GDD(s) above verified, **within the M1 scope** of
  `production/milestones/m1-gray-prototype.md` § Alcance
- Logic and Integration stories have passing tests in the test root (`tests/unit/`, `tests/integration/`)
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- No story is written on a TR whose row cites a `Proposed` ADR (hito M1 § ADR y spikes, Regla)
