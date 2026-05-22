extends RefCounted
## Типы файлов: пока в пуле только текст.

var case_count := 2


func run() -> Array[String]:
	var errors: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for _i in 30:
		if FileDefs.pick_random_download_type(rng) != "text":
			errors.append("пока должен выпадать только текстовый тип")
			break
	if FileDefs.get_type_label("image") != "Изображение":
		errors.append("заготовка image должна иметь имя")
	return errors
