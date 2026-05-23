extends RefCounted
## Размер скачиваемого текстового файла: случайный, с потолком speed × 50.

var case_count := 3


func run() -> Array[String]:
	var errors: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var speed := 100.0
	var cap := speed * GameConstants.MAX_TRANSFER_JOB_DURATION_SEC
	for _i in 50:
		var sz := FileDefs.random_download_size_bytes(FileDefs.DEFAULT_TYPE, speed, rng)
		if sz > cap + 0.01:
			errors.append("размер %.0f превышает speed×50 (%.0f)" % [sz, cap])
		var text_def: Dictionary = FileDefs.TYPES["text"]
		if sz > float(text_def["bytes_max"]) + 0.01:
			errors.append("текстовый файл больше bytes_max типа")
		if sz < float(text_def["bytes_min"]) - 0.01:
			errors.append("текстовый файл меньше bytes_min типа")
	var fast := 500.0
	var big_cap := fast * GameConstants.MAX_TRANSFER_JOB_DURATION_SEC
	var sz_fast := FileDefs.random_download_size_bytes(FileDefs.DEFAULT_TYPE, fast, rng)
	if sz_fast > float(FileDefs.TYPES["text"]["bytes_max"]) + 0.01:
		errors.append("при высокой скорости текст всё равно ограничен абсолютным максимумом")
	if sz_fast > big_cap + 0.01:
		errors.append("размер превышает cap по скорости")
	return errors
