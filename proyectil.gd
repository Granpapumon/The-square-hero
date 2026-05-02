extends Area2D

var velocidad = 600
var dano = 1
var direccion_vector = Vector2.ZERO # Cambiamos el número por un vector

# Esta función la llama el jugador al crear la bala
func lanzar(dir):
	direccion_vector = dir
	# Opcional: Hacer que la bala "mire" hacia donde vuela
	rotation = dir.angle()

func _process(delta):
	# Ahora se mueve en el ángulo correcto hacia el enemigo
	global_position += direccion_vector * velocidad * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("enemigos"):
		var enemigo = area.get_parent()
		
		# Le pedimos al enemigo que reciba 1 de daño
		if enemigo.has_method("recibir_daño"):
			enemigo.recibir_daño(dano)
		
		# La bala sí se borra siempre al chocar
		queue_free()
