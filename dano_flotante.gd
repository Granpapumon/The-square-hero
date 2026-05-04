extends Node2D

var tiempo = 0.0
var duracion = 0.8
var velocidad_subida = 60.0

func iniciar(cantidad: int, critico: bool = false):
	var label = Label.new()
	label.text = str(cantidad)
	label.add_theme_font_size_override("font_size", 18 if not critico else 26)
	label.add_theme_color_override("font_color", Color(1, 0.2, 0.2) if not critico else Color(1, 0.8, 0))
	label.position = Vector2(-10, 0)
	add_child(label)

func _process(delta):
	tiempo += delta
	position.y -= velocidad_subida * delta
	modulate.a = 1.0 - (tiempo / duracion)
	if tiempo >= duracion:
		queue_free()
