extends RefCounted
class_name GameStorageService
## Вместимость и занятость диска (в штуках файлов).

var _data: GameStateData
var _field: GameFieldService


func _init(data: GameStateData, field: GameFieldService) -> void:
	_data = data
	_field = field


## Суммарная вместимость всех хранилищ на поле (штук файлов).
func get_storage_capacity_files() -> float:
	var total := 0.0
	for inst: BlockInstance in _data.get_placed_blocks():
		if inst.type_id == "storage":
			total += storage_capacity_for(inst.uid)
	return total


## Вместимость конкретного хранилища (уровень × множитель среды), штук файлов.
func storage_capacity_for(uid: String) -> float:
	return (
		GameBonus.storage_capacity_files(_field.get_instance_level(uid))
		* _data.get_env_multiplier("storage_capacity")
	)


## Занято файлов: в очереди скачивания, на диске и в очереди выгрузки.
func get_storage_used_files() -> int:
	return (
		_data.get_download_queue().size()
		+ _data.get_stored_files().size()
		+ _data.get_upload_queue().size()
	)


## Хватает ли места ещё на count файлов (нужно хотя бы одно хранилище на поле).
func has_storage_space(count: int = 1) -> bool:
	return get_storage_capacity_files() > 0.0 and get_storage_free_files() >= float(count)


func get_storage_free_files() -> float:
	return maxf(0.0, get_storage_capacity_files() - float(get_storage_used_files()))
