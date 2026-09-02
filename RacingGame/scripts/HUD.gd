extends CanvasLayer

@export var car_path: NodePath
var _car: Node

@onready var _speed_label: Label = $SpeedLabel

func _ready() -> void:
	_car = get_node_or_null(car_path)
	_speed_label.add_theme_font_size_override("font_size", 28)
	_speed_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_speed_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_speed_label.add_theme_constant_override("outline_size", 4)

func _process(_delta: float) -> void:
	if _car and _car.has_method("get_speed_kmh"):
		_speed_label.text = "%d km/h" % int(_car.get_speed_kmh())
