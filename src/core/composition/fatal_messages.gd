## Hard-coded fatal messages per code (ADR-0009 D8). Independent of the text system (18),
## so corrupted content cannot corrupt them. Spanish UI text is allowed here as data.
class_name FatalMessages extends RefCounted

const CATALOGO_INVALIDO_TEXT: String = "No se pudo cargar el catálogo de datos del juego."
const DATOS_ESCENA_INVALIDOS_TEXT: String = "Los datos de esta escena no son válidos."
const DEPENDENCIA_AUSENTE_TEXT: String = "Falta un servicio necesario para esta escena."
const CONTENIDO_INVALIDO_TEXT: String = "El contenido del juego no es válido."
const UNKNOWN_TEXT: String = "Error irrecuperable."


## Message for a fatal code; unknown codes get UNKNOWN_TEXT.
static func for_code(code: StringName) -> String:
	match code:
		FatalErrorHandler.CATALOGO_INVALIDO:
			return CATALOGO_INVALIDO_TEXT
		FatalErrorHandler.DATOS_ESCENA_INVALIDOS:
			return DATOS_ESCENA_INVALIDOS_TEXT
		FatalErrorHandler.DEPENDENCIA_AUSENTE:
			return DEPENDENCIA_AUSENTE_TEXT
		FatalErrorHandler.CONTENIDO_INVALIDO:
			return CONTENIDO_INVALIDO_TEXT
		_:
			return UNKNOWN_TEXT
