extends CanvasLayer

func actualizar_xp(actual, necesaria):
	$BarraXP.max_value = necesaria
	$BarraXP.value = actual

func actualizar_nivel(nivel_actual):
	$TextoNivel.text = "NIVEL " + str(nivel_actual)
