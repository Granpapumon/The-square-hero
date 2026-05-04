extends Area2D

var velocidad = 600
var dano = 2
var direccion_vector = Vector2.ZERO
var tiempo = 0.0

func lanzar(dir):
	direccion_vector = dir
	rotation = dir.angle()

func _process(delta):
	tiempo += delta
	global_position += direccion_vector * velocidad * delta
	scale = Vector2.ONE * (1.0 + sin(tiempo * 20) * 0.1)
	queue_redraw()

func _draw():
	# Llama central naranja
	draw_circle(Vector2.ZERO, 8, Color(1.0, 0.4, 0.0))
	# Núcleo amarillo
	draw_circle(Vector2.ZERO, 4, Color(1.0, 0.9, 0.0))

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
	if enemigo.has_method("recibir_daño"):
		enemigo.recibir_daño(dano)
	queue_free()
