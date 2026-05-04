extends CanvasLayer

func _ready():
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador:
		actualizar_xp(jugador.xp_actual, jugador.xp_necesaria)
		actualizar_nivel(jugador.nivel)
	$MensajeHabilidad.hide()

func actualizar_xp(xp_actual, xp_necesaria):
	$BarraXP.max_value = xp_necesaria
	$BarraXP.value = xp_actual

func actualizar_nivel(nivel):
	$TextoNivel.text = "Nivel: " + str(nivel)

func mostrar_mensaje(texto: String):
	$MensajeHabilidad.text = texto
	$MensajeHabilidad.show()
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		$MensajeHabilidad.hide()
