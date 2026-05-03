extends Area2D

var velocidad = 600
var porcentaje_ralentizacion = 0.60
var tiempo_efecto = 1.0
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
	if enemigo.has_method("ralentizar"):
		enemigo.ralentizar(porcentaje_ralentizacion, tiempo_efecto)
	queue_free()
