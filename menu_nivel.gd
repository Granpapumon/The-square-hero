extends CanvasLayer

func configurar_modo_habilidades(num_habilidad):
	# Ocultamos los botones de atributos (Ataque, Salto, etc.)
	$VBoxContainer/ATAQUE.hide()
	$VBoxContainer/SALTO.hide()
	$VBoxContainer/VELOCIDAD.hide()
	$VBoxContainer/CADENCIA.hide()
	
	# Mostramos los botones de habilidades (Fuego, Hielo, Rayo, Veneno)
	# Asegúrate de tener estos botones creados en tu VBoxContainer
	$VBoxContainer/FUEGO.show()
	$VBoxContainer/HIELO.show()
	$VBoxContainer/RAYO.show()
	$VBoxContainer/VENENO.show()

func configurar_modo_atributos():
	# Volvemos a mostrar los atributos y ocultamos las habilidades
	$VBoxContainer/ATAQUE.show()
	$VBoxContainer/SALTO.show()
	$VBoxContainer/VELOCIDAD.show()
	$VBoxContainer/CADENCIA.show()
	
	$VBoxContainer/FUEGO.hide()
	$VBoxContainer/HIELO.hide()
	$VBoxContainer/RAYO.hide()
	$VBoxContainer/VENENO.hide()

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


func _on_boton_hielo_pressed() -> void:
	pass # Replace with function body.


func _on_boton_rayo_pressed() -> void:
	pass # Replace with function body.


func _on_boton_veneno_pressed() -> void:
	pass # Replace with function body.
