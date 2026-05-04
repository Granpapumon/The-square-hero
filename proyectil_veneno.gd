extends Area2D

var dano = 0
var velocidad = 500
var dano_veneno = 2
var direccion_vector = Vector2.ZERO
var tiempo = 0.0

func lanzar(dir):
	direccion_vector = dir

func _process(delta):
	tiempo += delta
	# Movimiento ondulante perpendicular a la dirección
	var perp = Vector2(-direccion_vector.y, direccion_vector.x)
	global_position += direccion_vector * velocidad * delta
	global_position += perp * sin(tiempo * 15) * 2
	queue_redraw()

func _draw():
	# Gota de veneno verde
	draw_circle(Vector2.ZERO, 6, Color(0.2, 0.8, 0.1))
	# Burbuja encima
	draw_circle(Vector2(-2, -3), 2, Color(0.5, 1.0, 0.3, 0.7))

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
	if enemigo.has_method("envenenar"):
		enemigo.envenenar(dano_veneno)
	queue_free()
