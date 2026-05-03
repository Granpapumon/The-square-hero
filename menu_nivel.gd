extends CanvasLayer

func configurar_modo_habilidades(_num_habilidad):
	# Ocultamos los botones de atributos
	$ColorRect/VBoxContainer/ATAQUE.hide()
	$ColorRect/VBoxContainer/SALTO.hide()
	$ColorRect/VBoxContainer/VELOCIDAD.hide()
	$ColorRect/VBoxContainer/CADENCIA.hide()
	
	# Mostramos los botones de habilidades
	$ColorRect/VBoxContainer/FUEGO.show()
	$ColorRect/VBoxContainer/HIELO.show()
	$ColorRect/VBoxContainer/RAYO.show()
	$ColorRect/VBoxContainer/VENENO.show()

func configurar_modo_atributos():
	# Volvemos a mostrar los atributos
	$ColorRect/VBoxContainer/ATAQUE.show()
	$ColorRect/VBoxContainer/SALTO.show()
	$ColorRect/VBoxContainer/VELOCIDAD.show()
	$ColorRect/VBoxContainer/CADENCIA.show()
	
	# Ocultamos las habilidades
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

func _on_boton_ataque_pressed():    _aplicar_mejora("mejorar_ataque")
func _on_boton_salto_pressed():     _aplicar_mejora("mejorar_salto")
func _on_boton_velocidad_pressed(): _aplicar_mejora("mejorar_velocidad")
func _on_boton_cadencia_pressed():  _aplicar_mejora("mejorar_cadencia")
func _on_boton_fuego_pressed():
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador.nivel == 5:
		jugador.habilidad_1 = "fuego"
		jugador.nivel_habilidad_1 = 1
		jugador.desbloquear_fuego() # La función que ya hicimos
	elif jugador.nivel == 15:
		jugador.habilidad_2 = "fuego"
		jugador.nivel_habilidad_2 = 1
		jugador.desbloquear_fuego()
		
	get_tree().paused = false
	hide()

func _on_boton_rayo_pressed():
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador.nivel == 5:
		jugador.habilidad_1 = "rayo"
		jugador.nivel_habilidad_1 = 1
		jugador.desbloquear_rayo()
	elif jugador.nivel == 15:
		jugador.habilidad_2 = "rayo"
		jugador.nivel_habilidad_2 = 1
		jugador.desbloquear_rayo()
	get_tree().paused = false
	hide()

func _on_boton_veneno_pressed():
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador.nivel == 5:
		jugador.habilidad_1 = "veneno"
		jugador.nivel_habilidad_1 = 1
		jugador.desbloquear_veneno()
	elif jugador.nivel == 15:
		jugador.habilidad_2 = "veneno"
		jugador.nivel_habilidad_2 = 1
		jugador.desbloquear_veneno()
	get_tree().paused = false
	hide()
