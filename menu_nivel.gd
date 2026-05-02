extends CanvasLayer

func _aplicar_mejora(nombre_funcion: String):
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador and jugador.has_method(nombre_funcion):
		jugador.call(nombre_funcion)
	get_tree().paused = false
	hide()

func _on_boton_ataque_pressed():    _aplicar_mejora("mejorar_ataque")
func _on_boton_salto_pressed():     _aplicar_mejora("mejorar_salto")
func _on_boton_velocidad_pressed(): _aplicar_mejora("mejorar_velocidad")
func _on_boton_cadencia_pressed():  _aplicar_mejora("mejorar_cadencia")
