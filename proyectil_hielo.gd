extends Area2D

var velocidad = 600
var tiempo_congelacion = 2.0
var direccion_vector = Vector2.ZERO

func lanzar(dir):
	direccion_vector = dir
	rotation = dir.angle()

func _process(delta):
	global_position += direccion_vector * velocidad * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
	if enemigo.has_method("congelar"):
		enemigo.congelar(tiempo_congelacion)
	queue_free()
