extends Area2D

var velocidad = 400 # Un poco más lento que las balas del jugador para que sea esquivable
var dano = 10
var direccion_vector = Vector2.ZERO

func lanzar(dir):
	direccion_vector = dir
	rotation = dir.angle()

func _process(delta):
	global_position += direccion_vector * velocidad * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Verificamos si chocamos con la Hurtbox del jugador
	if area.name == "Hurtbox":
		var objetivo = area.get_parent()
		if is_instance_valid(objetivo) and objetivo.is_in_group("player"):
			if objetivo.has_method("recibir_daño"):
				objetivo.recibir_daño(dano)
				# Nos destruimos al impactar al jugador
				queue_free()
