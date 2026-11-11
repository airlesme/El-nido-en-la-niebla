# Hito: S0 · Setup del proyecto

> Línea base creada el 2026-11-11 al entrar en Pre-Production (PR-PHASE-GATE C12).
> Plantilla: `.claude/docs/templates/milestone-definition.md`, adaptada a un equipo
> de **una persona con agentes** y **sin fecha de demo** (plazos relativos).

## Overview

- **Fecha objetivo**: ninguna fija. Plazo relativo: semana 0 → fin de S0.
- **Tipo**: Prototype (infraestructura)
- **Duración**: 1–2 semanas (esperado 1,5). **Confianza: baja** (ver § Plazo).
- **Sprints**: 1 (no hay `production/sprints/` con historia; sin velocidad medida)
- **Estado**: **En curso** — parte ya hecha antes de la línea base (ver § Estado de partida).

## Objetivo del hito

Dejar un proyecto Godot 4.7.2 que abre, corre, pasa los tests en CI y exporta una escena
vacía a Windows y Linux con presets versionados, y aceptar la capa Foundation de la
arquitectura (ADR-0001, -0002, -0009) para que ninguna historia de M1 nazca bloqueada
por un ADR `Proposed`. Fuente: `docs/PLAN-TECNICO.md` § 4 (fila S0).

## Estado de partida (leído en el repo, 2026-11-11)

| Elemento | Estado | Fuente |
|---|---|---|
| `project.godot` | Existe | repo |
| gdUnit4 6.2.3 en `addons/gdUnit4/` | Instalado; 3 tests de ejemplo PASS en 4.7.2 headless (2026-11-10) | `tests/README.md` |
| CI de tests (`.github/workflows/tests.yml`) | Existe; **verde declarado por el usuario** (2026-11-10). Run id no registrado (ADR-0018 O5) | ADR-0018 § Summary, O5 |
| `export_presets.cfg` | **No existe**; además `.gitignore` lo ignora (ADR-0018 O7) | repo, ADR-0018 |
| Export templates 4.7.2 | No instalados/registrados (V-18-3 NOT RUN) | ADR-0018 D2 |
| `project.yaml` `performance.*` | Aplicado como provisional (ADR-0019 OI-1) | commit `780e0eb` |
| Versión del editor local | No registrada en `VERSION.md` (ADR-0019 OI-2) | `VERSION.md` |
| D-16 (orden de la caja) | **Cerrada** por el usuario 2026-11-10 (c1→c3→c4, c2 libre) | slice § 20 |

## Alcance

**Dentro:** presets de export, templates 4.7.2 fijados por hash, scripts de build de un
comando, pasos de CI de ADR-0018 D6 (pins → import → parse → data check → grep de API
prohibida → gdUnit4), autoloads vacíos según ADR-0009 (`Boot` como única raíz de
composición), `InputMap` base, el log manual de S4 del spike de pausa, y la aceptación
de 0001/0002/0009.

**Fuera:** cualquier contenido jugable (M1), el pasillo de atmósfera (S0b), el preset
`profiling` *si* se decide en S0b (ver Dependencias), el `export.yml` en cada push
(ADR-0018 Alt. 4, descartado).

## Criterios de salida (todos medibles)

- [ ] **C-S0-1** `export_presets.cfg` versionado con los 4 presets de ADR-0018 D1
      (`playtest-windows`, `playtest-linux`, `demo-windows`, `demo-linux`); `.gitignore` corregido (O7).
- [ ] **C-S0-2** V-18-3 registrado: templates 4.7.2 instalados en local y en el runner,
      nombre de archivo, carpeta y SHA-512 escritos en `tools/godot/version.txt`.
- [ ] **C-S0-3** V-18-1: desde un clon limpio, export de un comando de los 4 presets en
      Windows; los 4 artefactos arrancan y muestran la escena vacía. **Captura retenida**
      de cada uno en `production/qa/evidence/` (regla run-and-observe).
- [ ] **C-S0-4** V-18-2: `BuildFlavor` imprime true / true / false (editor, `playtest-*`, `demo-*`).
- [ ] **C-S0-5** V-18-4: el job de CI se pone rojo con test fallido, con huérfano y con cero tests.
- [ ] **C-S0-6** V-18-5 y V-18-6: `src/dev/` ausente en `demo-*` con control positivo y negativo.
- [ ] **C-S0-7** V-18-7, V-18-8, V-18-9 registrados (boot report, clon limpio, caché de clases idéntica 5 veces).
- [ ] **C-S0-8** V-18-10: tiempos de import/test/export y tamaño del artefacto **medidos** y escritos
      en ADR-0018 (sustituyen «NOT MEASURED»). Hasta entonces, cualquier cifra es NOT VERIFIED.
- [ ] **C-S0-9** Log manual de **S4** del spike de pausa (foco con teclado y mando, conectar y
      desconectar mando), escucha de S8 y revisión visual de S11 → ADR-0002 a `Accepted` por el usuario.
- [ ] **C-S0-10** ADR-0001: V-ENG-1…6 y decisión C1 (NS-7, entrega del bus en el mismo fotograma
      que la entrada) → `Accepted` por el usuario. Si C1 necesita el spike S-0006, se registra
      y 0001 se acepta con C1 diferida a M1 (decisión del usuario).
- [ ] **C-S0-11** ADR-0009 `Accepted` (0001 y 0002 aceptados; C9 anotada para la historia de Recepción).
- [ ] **C-S0-12** Versión del editor local registrada en `VERSION.md` (ADR-0019 OI-2).
- [ ] **C-S0-13** CI verde con el run id anotado en `tests/README.md` (O5) tras añadir los pasos nuevos.

## Lista de funcionalidades

### Imprescindible (el hito falla sin esto)

| Elemento | Doc | Dueño | Estado |
|---|---|---|---|
| 4 presets + templates fijados | ADR-0018 D1, D2 | devops-engineer | Pendiente |
| Scripts `tools/build/export.ps1` / `.sh` | ADR-0018 D1 | devops-engineer | Pendiente |
| Pasos de CI D6 (sin data check si ADR-0005 no está listo) | ADR-0018 D6 | devops-engineer | Pendiente |
| Autoloads vacíos + `Boot` | ADR-0009, PLAN § 2.1 | lead-programmer | Pendiente |
| Log S4 del spike de pausa | ADR-0002 § Spike Plan | engine-programmer + usuario (manual) | Pendiente |
| Aceptación 0001 / 0002 / 0009 | review 2026-11-10 | usuario | Pendiente |

### Recortable (planificado)

| Elemento | Impacto del recorte | Pasa a |
|---|---|---|
| Paso de CI «data check» (ADR-0018 D7, `tools/data_check/`) | M1 valida JSON solo en tests locales | M1 (cuando exista ADR-0005 aceptado) |
| V-18-9 (caché de clases idéntica Win/Linux 5 veces) | Riesgo de diffs ruidosos en `.godot/` | M1 |
| Export de Windows desde el runner Linux (O8) | Windows se exporta a mano o en runner Windows | Antes de M5 |

## ADR y spikes que cierra (de los 19, todos `Proposed` hoy)

| ADR | Qué exige S0 | Estado tras S0 (objetivo) |
|---|---|---|
| 0001 Event bus | V-ENG-1…6; decisión C1 | Accepted |
| 0002 Pause and game time | Log S4 manual (resto del spike ya PASS en 4.7.2) | Accepted |
| 0009 Service composition | 0001 + 0002 aceptados | Accepted |
| 0018 Build/export/CI | V-18-1…V-18-9 (V-18-10 medido) | Accepted, o Proposed con V-18 pendientes listados |
| 0019 Perf budgets | Solo OI-2 (versión local). OI-1 ya aplicado | Sigue Proposed (se cierra en S0b) |

No le conciernen: 0003–0008, 0010–0017.

## Cola de diseño pendiente que le afecta (contada, no resuelta)

De `docs/architecture/adr-reconciliation-2026-11-10.md` (ronda 1, § 2): **12** cambios
cuyo ADR origen es Foundation — G1, G2, G3, G4 (0001), G6, G7 (0002; G7 se cierra
tras el spike de pausa), G25, G26 (0009), A1, A2, A5, A7 (`architecture.md`).
Ronda 2 (R2.2, H1–H35): **0**.
Decisiones del usuario de `design/gdd/gdd-cross-review-2026-11-10-r2.md`: **0** de 6.
Estado de aplicación de los 12: NOT VERIFIED (no se abrieron los GDD).

## Puertas de calidad

| Puerta | Umbral | Método |
|---|---|---|
| Tests | CI verde; 0 tests saltados | job gdUnit4 |
| Arranque | Los 4 exports arrancan; 0 errores en consola | V-18-1 + captura retenida |
| Aislamiento dev | `src/dev/` ausente en `demo-*` | V-18-6 |
| Rendimiento | **No aplica** (escena vacía no mide nada; ver S0b) | — |

## Riesgos

| Riesgo | Prob. | Impacto | Mitigación | Dueño |
|---|---|---|---|---|
| R-S0-1 Nombres de propiedades del filtro de export y archivo de templates NOT SOURCEABLE (E3/E4) | Media | Medio | V-18-3 primero; registrar lo observado en ADR-0018 | devops-engineer |
| R-S0-2 Export Windows desde runner Linux no funciona sin herramientas extra | Media | Bajo | ADR-0018 D1.7: runner Windows | devops-engineer |
| R-S0-3 La auditoría de bytes es ciega (ADR-0018 R1) | Baja | Alto (demo con herramientas dev) | Control positivo V-18-6; rollback del Migration Plan | devops-engineer |
| R-S0-4 C1 (NS-7) no se puede decidir sin el spike de entrada | Media | Medio | Aceptar 0001 con C1 diferida a S-0006 en M1 (usuario) | technical-director |
| R-S0-5 El log manual de S4 depende de que el usuario tenga mando a mano | Baja | Medio (0002 sin aceptar bloquea todo) | Programarlo el primer día | usuario |
| R-S0-6 El preset `profiling` que exige ADR-0019 (OI-3) no existe en ADR-0018 | Alta | Medio (S0b no puede medir con el método de D5) | Revisión de ADR-0018 en S0 o primera tarea de S0b | devops-engineer |

## Orden de recorte (S0)

1. V-18-9 → M1. 2. Data check en CI → M1. 3. Export Windows en runner Linux → antes de M5.
**No se recorta:** presets versionados, templates fijados, export que arranca en Win y Linux,
aceptación de 0001/0002/0009.

## Plazo

| Escenario | Semanas | Supuesto |
|---|---|---|
| Optimista | 1 | V-18-3 funciona a la primera; C1 se decide sin spike |
| Esperado | 1,5 | Una ronda de ajuste en presets/filtros |
| Pesimista | 2 | E3/E4 obligan a iterar; Windows en runner propio |

**Confianza baja:** no hay historia de sprints ni velocidad medida; la mitad del trabajo
depende de hechos del motor NOT SOURCEABLE. No se ha rellenado holgura en silencio: el
pesimista ya es la holgura.

## Dependencias

| Depende de | Estado | Si se retrasa |
|---|---|---|
| Usuario: confirmar `Accepted` de 0001/0002/0009/0018 | Pendiente | M1 no puede abrir historias (ADR `Proposed` bloquea) |
| Usuario: sesión manual S4 (teclado + mando) | Pendiente | 0002 sigue `Proposed` |
| Releases oficiales 4.7.2 (templates + SHA512-SUMS) | Disponibles (no verificado hoy) | Bloquea C-S0-2 |

## Revisión

| Cuándo | Qué |
|---|---|
| Mitad (≈ día 4) | ¿V-18-3 pasa? Si no, decidir runner Windows |
| Fin | `/gate-check` informal del hito; actualizar este fichero a «Cerrado» |

## Progreso (2026-11-11)

| Criterio | Estado | Evidencia |
|---|---|---|
| C-S0-1 presets versionados + `.gitignore` | **Hecho** | `export_presets.cfg` commiteado; los 4 presets exportan |
| C-S0-2 templates (V-18-3) | **Hecho (Windows/Linux)** | `Godot_v4.7.2-stable_export_templates.tpz` (1.281.349.702 B), SHA-512 verificado contra `SHA512-SUMS.txt` oficial; fijado en `tools/godot/version.txt`; instaladas en `%APPDATA%\Godot\export_templates\4.7.2.stable` (`version.txt` = `4.7.2.stable`). `LINUX_*` (editor Linux de CI) sigue NOT VERIFIED |
| C-S0-3 export de los 4 presets (V-18-1) | **Parcial** | Los 4 exportan con `--export-debug/--export-release` sin errores (solo el aviso por `prototypes/pause-spike/project.godot`); tamaños: `demo-windows` 109 MB, `playtest-windows` 103 MB, `demo-linux` 73,5 MB, `playtest-linux` 73,7 MB (+ `.pck` 13 KB). Arrancan solo los de Windows (`--headless --quit-after 5`, exit 0). Faltan: captura retenida en ventana, y arranque de Linux (no hay runner/WSL probado) |
| C-S0-4 `BuildFlavor` true/true/false (V-18-2) | Pendiente | Solo hay test unitario; no se ha mostrado desde los exportados |
| C-S0-6 `src/dev/` ausente en `demo-*` (V-18-5/6) | **Parcial** | Auditoría ingenua del `.pck` de `demo-windows`: no contiene `src/dev`, `gdUnit4` ni `tests/`. Control positivo imposible: `src/dev/` aún no existe y `tools/ci/audit_artifact.sh` tampoco |
| C-S0-8 tiempos medidos (V-18-10) | Pendiente | Solo hay tamaños; no se midieron tiempos |
| C-S0-12 versión del editor local | **Hecho** | `docs/engine-reference/godot/VERSION.md` |
| Autoloads vacíos + `Boot` | **Hecho** | 16/16 tests gdUnit4, import y arranque limpios |
| C-S0-5, 7, 9, 10, 11, 13 | Pendiente | S4 manual del usuario; aceptación 0001/0002/0009; CI con run id |

Nota de nombres: los presets escriben `el-nido.exe` / `el-nido.x86_64`. Los nombres de propiedades de `export_presets.cfg` quedan ahora **verificados en la práctica** (Godot 4.7.2 los acepta y exporta), no contra la documentación.

### Actualización 2026-11-11 (tarde)

- **C-S0-9** S4 manual: el usuario informa «ha ido bien»; no precisó si usó mando. ADR-0002 → **Accepted** (puntos de mando 4 y 5 sin confirmar por separado).
- **C-S0-13** CI: enlace del run verde aportado por el usuario (`actions/runs/42980040179`), declarado y no verificable por el agente (repo privado). Anotado en `tests/README.md`.
- PATH: el usuario añadió Godot al PATH (C10 cerrada por su parte; no verificado desde esta sesión hasta reiniciar el shell).
- **C-S0-10/11** siguen pendientes: ADR-0001 (V-ENG-1…6 y C1) y ADR-0009.

### Actualización 2026-11-11 (cierre de Foundation)

- **C-S0-10** ADR-0001: V-ENG-1…6 PASS en 4.7.2 (suite 31/31, verificada); **Accepted** con C1 diferida al spike S-0006 de M1 (decisión del usuario).
- **C-S0-11** ADR-0009: **Accepted** (0001 y 0002 aceptados; C9 anotada para la historia de Recepción).
- Foundation (0001, 0002, 0009) aceptada: ninguna historia de M1 nace bloqueada por esos tres ADR. Siguen Proposed los otros 16 ADR.
