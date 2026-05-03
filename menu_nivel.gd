extends CanvasLayer

func configurar_modo_habilidades():
	$ColorRect/VBoxContainer/ATAQUE.hide()
	$ColorRect/VBoxContainer/SALTO.hide()
	$ColorRect/VBoxContainer/VELOCIDAD.hide()
	$ColorRect/VBoxContainer/CADENCIA.hide()
	$ColorRect/VBoxContainer/FUEGO.show()
	$ColorRect/VBoxContainer/HIELO.show()
	$ColorRect/VBoxContainer/RAYO.show()
	$ColorRect/VBoxContainer/VENENO.show()

func configurar_modo_atributos():
	$ColorRect/VBoxContainer/ATAQUE.show()
	$ColorRect/VBoxContainer/SALTO.show()
	$ColorRect/VBoxContainer/VELOCIDAD.show()
	$ColorRect/VBoxContainer/CADENCIA.show()
	$ColorRect/VBoxContainer/FUEGO.hide()
	$ColorRect/VBoxContainer/HIELO.hide()
	$ColorRect/VBoxContainer/RAYO.hide()
	$ColorRect/VBoxContainer/VENENO.hide()

func _aplicar_mejora(nombre_funcion: String):
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador and jugador.has_method(nombre_funcion):
		jugador.call(nombre_funcion)
	get_tree().paused = false
	hide()

func _aplicar_habilidad(nombre: String):
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador:
		jugador.desbloquear_habilidad(nombre)
	get_tree().paused = false
	hide()

func _on_boton_ataque_pressed():    _aplicar_mejora("mejorar_ataque")
func _on_boton_salto_pressed():     _aplicar_mejora("mejorar_salto")
func _on_boton_velocidad_pressed(): _aplicar_mejora("mejorar_velocidad")
func _on_boton_cadencia_pressed():  _aplicar_mejora("mejorar_cadencia")

func _on_boton_fuego_pressed():   _aplicar_habilidad("fuego")
func _on_boton_hielo_pressed():   _aplicar_habilidad("hielo")
func _on_boton_rayo_pressed():    _aplicar_habilidad("rayo")
func _on_boton_veneno_pressed():  _aplicar_habilidad("veneno")
