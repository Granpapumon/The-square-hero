extends Area2D

var valor_xp = 1 # Según TSH.xlsx para Fase 1

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Verificamos que el player tenga la función antes de llamarla
		if body.has_method("ganar_xp"):
			body.ganar_xp(valor_xp)
		queue_free() # La gema desaparece
