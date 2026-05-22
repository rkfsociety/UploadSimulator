extends RefCounted
class_name UiFonts
## Векторные системные шрифты UI (без растровых .ttf в репозитории).


static var _default: Font
static var _bold: Font


# Базовый шрифт интерфейса: системный, сглаживание для мелкого текста на карте
static func default_font() -> Font:
	if _default == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Segoe UI", "Roboto", "Noto Sans", "Arial", "sans-serif"])
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.hinting = TextServer.HINTING_LIGHT
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_default = f
	return _default


# Чуть жирнее для заголовков модулей
static func title_font() -> Font:
	if _bold == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Segoe UI Semibold", "Roboto Medium", "Noto Sans", "Arial", "sans-serif"])
		f.font_weight = 600
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.hinting = TextServer.HINTING_LIGHT
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_bold = f
	return _bold


static func apply_to_theme(theme: Theme, title_size: int, body_size: int, small_size: int) -> void:
	var body := default_font()
	var title := title_font()
	theme.default_font = body
	theme.default_font_size = body_size
	for variation in [&"title", &"metric", &"balance", &"shop_icon"]:
		theme.set_font("font", variation, title)
	for variation in [&"state", &"dim", &"hint", &"action", &"upgrade", &"balance_small", &"icon"]:
		theme.set_font("font", variation, body)
