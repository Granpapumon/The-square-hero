extends CanvasLayer

func _ready():
	var jugador = get_tree().get_first_node_in_group("player")
	$TextoNivel.add_theme_color_override("font_outline_color", Color.BLACK)
	$TextoNivel.add_theme_constant_override("outline_size", 12)
	$MensajeHabilidad.add_theme_color_override("font_outline_color", Color.BLACK)
	$MensajeHabilidad.add_theme_constant_override("outline_size", 12)
	$BarraXP.add_theme_stylebox_override("fill", _crear_estilo_barra(Color(0.2, 0.8, 0.4)))
	$BarraXP.add_theme_stylebox_override("background", _crear_estilo_barra(Color(0.1, 0.1, 0.1)))
	if jugador:
		actualizar_xp(jugador.xp_actual, jugador.xp_necesaria)
		actualizar_nivel(jugador.nivel)
	$MensajeHabilidad.hide()

func _crear_estilo_barra(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.border_color = Color.BLACK
	style.expand_margin_left = 2
	style.expand_margin_top = 2
	style.expand_margin_right = 2
	style.expand_margin_bottom = 2
	return style

func actualizar_xp(xp_actual, xp_necesaria):
	$BarraXP.max_value = xp_necesaria
	$BarraXP.value = xp_actual

func actualizar_nivel(nivel):
	$TextoNivel.text = "Nivel: " + str(nivel)

func mostrar_mensaje(texto: String):
	$MensajeHabilidad.text = texto
	$MensajeHabilidad.show()
	await get_tree().create_timer(2.5).timeout
	if is_inside_tree(): $MensajeHabilidad.hide()
