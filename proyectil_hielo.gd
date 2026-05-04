extends Area2D

var dano = 0  # ← agrega esta línea
var velocidad = 600
var tiempo_congelacion = 2.0
var direccion_vector = Vector2.ZERO
var tiempo = 0.0

func lanzar(dir):
	direccion_vector = dir
	rotation = dir.angle()

func _process(delta):
	tiempo += delta
	global_position += direccion_vector * velocidad * delta
	rotation += delta * 5.0
	queue_redraw()

func _draw():
	# Cubo de hielo celeste
	draw_rect(Rect2(-7, -7, 14, 14), Color(0.5, 0.9, 1.0))
	# Brillo blanco encima
	draw_rect(Rect2(-4, -6, 4, 3), Color(1.0, 1.0, 1.0, 0.6))

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
	if enemigo.has_method("congelar"):
		enemigo.congelar(tiempo_congelacion)
	queue_free()
