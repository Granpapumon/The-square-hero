extends Area2D

var velocidad = 800
var porcentaje_ralentizacion = 0.60
var tiempo_efecto = 1.0
var tiempo = 0.0

# El rayo no usa direccion_vector — cae recto hacia abajo
func lanzar(_dir):
	# Ignora la dirección, siempre cae hacia abajo
	rotation = PI / 2

func _process(delta):
	tiempo += delta
	global_position.y += velocidad * delta
	queue_redraw()

func _draw():
	# Rayo amarillo/blanco vertical
	draw_rect(Rect2(-3, -20, 6, 40), Color(1.0, 1.0, 0.2))
	# Núcleo blanco
	draw_rect(Rect2(-1, -20, 2, 40), Color(1.0, 1.0, 1.0))

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
	if enemigo.has_method("ralentizar"):
		enemigo.ralentizar(porcentaje_ralentizacion, tiempo_efecto)
	queue_free()
