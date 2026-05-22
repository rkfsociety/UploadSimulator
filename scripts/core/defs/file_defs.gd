extends RefCounted
class_name FileDefs
## Типы передаваемых файлов (базовый — текстовый).

const DEFAULT_TYPE := "text"

const TYPES := {
	"text":
	{
		"name": "Текстовый файл",
	},
}


# Человекочитаемое название типа для UI модуля
static func get_type_label(type_id: String) -> String:
	return str(TYPES.get(type_id, TYPES[DEFAULT_TYPE]).get("name", "Файл"))
