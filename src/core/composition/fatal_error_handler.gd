## Sink for unrecoverable data/catalog errors. Systems never decide how to die (ADR-0009 D8).
## code: CATALOGO_INVALIDO | DATOS_ESCENA_INVALIDOS | DEPENDENCIA_AUSENTE | CONTENIDO_INVALIDO.
## detail: {param, value, owner, ...}; the offending parameter is mandatory when one exists.
@abstract
class_name FatalErrorHandler extends RefCounted

const CATALOGO_INVALIDO: StringName = &"CATALOGO_INVALIDO"
const DATOS_ESCENA_INVALIDOS: StringName = &"DATOS_ESCENA_INVALIDOS"
const DEPENDENCIA_AUSENTE: StringName = &"DEPENDENCIA_AUSENTE"
const CONTENIDO_INVALIDO: StringName = &"CONTENIDO_INVALIDO"


## Reports an unrecoverable error. Example: `ctx.fatal.raise_fatal(FatalErrorHandler.CATALOGO_INVALIDO, {&"param": &"x"})`.
@abstract func raise_fatal(code: StringName, detail: Dictionary) -> void


## True after the first raise_fatal() call.
@abstract func has_failed() -> bool
