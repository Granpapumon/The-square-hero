extends CanvasLayer

func actualizar_xp(xp_actual, xp_necesaria):
	# Le decimos a la barra cuál es el tope y cuánto lleva lleno
	$BarraXP.max_value = xp_necesaria
	$BarraXP.value = xp_actual

func actualizar_nivel(nivel):
	# Actualizamos el texto en pantalla
	$TextoNivel.text = "Nivel: " + str(nivel)
