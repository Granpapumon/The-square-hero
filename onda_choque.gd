extends Area2D

var velocidad_expansion = 600.0
var radio_maximo = 450.0
var dano_onda = 20

func _process(delta):
	# Hacemos que el círculo de colisión crezca cada frame
	$CollisionShape2D.shape.radius += velocidad_expansion * delta
	
	# Se va volviendo transparente poco a poco
	modulate.a -= 1.2 * delta
	
	# Si llega al tamaño máximo o es invisible, se borra
	if $CollisionShape2D.shape.radius >= radio_maximo or modulate.a <= 0:
		queue_free()

func _on_area_entered(area):
	if area.name == "Hurtbox" and area.get_parent().is_in_group("player"):
		if area.get_parent().has_method("recibir_daño"):
			area.get_parent().recibir_daño(dano_onda)
