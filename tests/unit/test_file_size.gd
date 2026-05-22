extends RefCounted
## Размер скачиваемого текстового файла: случайный, с потолком speed × 50.

var case_count := 3


func run() -> Array[String]:
	var errors: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var speed := 100.0
	var cap := speed * GameConstants.DOWNLOAD_SIZE_SPEED_MULTIPLIER
	for _i in 50:
		var sz := FileDefs.random_download_size_bytes(FileDefs.DEFAULT_TYPE, speed, rng)
		if sz > cap + 0.01:
			errors.append("размер %.0f превышает speed×50 (%.0f)" % [sz, cap])
		if sz > GameConstants.TEXT_FILE_BYTES_MAX + 0.01:
			errors.append("текстовый файл больше TEXT_FILE_BYTES_MAX")
		if sz < GameConstants.TEXT_FILE_BYTES_MIN - 0.01:
			errors.append("текстовый файл меньше TEXT_FILE_BYTES_MIN")
	var fast := 500.0
	var big_cap := fast * GameConstants.DOWNLOAD_SIZE_SPEED_MULTIPLIER
	var sz_fast := FileDefs.random_download_size_bytes(FileDefs.DEFAULT_TYPE, fast, rng)
	if sz_fast > GameConstants.TEXT_FILE_BYTES_MAX + 0.01:
		errors.append("при высокой скорости текст всё равно ограничен абсолютным максимумом")
	if sz_fast > big_cap + 0.01:
		errors.append("размер превышает cap по скорости")
	return errors
