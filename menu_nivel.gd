extends Control

func configurar_modo_habilidades():
	# Pasamos por ColorRect -> VBoxContainer para ocultar atributos
	$ColorRect/VBoxContainer/ATAQUE.hide()
	$ColorRect/VBoxContainer/SALTO.hide()
	$ColorRect/VBoxContainer/VELOCIDAD.hide()
	$ColorRect/VBoxContainer/CADENCIA.hide()
	
	# Pasamos por ColorRect -> VBoxContainer para mostrar magias
	$ColorRect/VBoxContainer/FUEGO.show()
	$ColorRect/VBoxContainer/HIELO.show()
	$ColorRect/VBoxContainer/RAYO.show()
	$ColorRect/VBoxContainer/VENENO.show()

func configurar_modo_atributos():
	# Pasamos por ColorRect -> VBoxContainer para mostrar atributos
	$ColorRect/VBoxContainer/ATAQUE.show()
	$ColorRect/VBoxContainer/SALTO.show()
	$ColorRect/VBoxContainer/VELOCIDAD.show()
	$ColorRect/VBoxContainer/CADENCIA.show()
	
	# Pasamos por ColorRect -> VBoxContainer para ocultar magias
	$ColorRect/VBoxContainer/FUEGO.hide()
	$ColorRect/VBoxContainer/HIELO.hide()
	$ColorRect/VBoxContainer/RAYO.hide()
	$ColorRect/VBoxContainer/VENENO.hide()

func _aplicar_mejora(nombre_funcion: String):
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador and jugador.has_method(nombre_funcion):
		jugador.call(nombre_funcion)
	get_tree().paused = false
	get_parent().hide() # Oculta el MenuNivel entero (el CanvasLayer)

func _aplicar_habilidad(nombre: String):
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador:
		jugador.desbloquear_habilidad(nombre)
	get_tree().paused = false
	get_parent().hide() # Oculta el MenuNivel entero (el CanvasLayer)

# --- TUS SEÑALES ORIGINALES ---
func _on_ataque_pressed():    _aplicar_mejora("mejora_ataque")
func _on_salto_pressed():     _aplicar_mejora("mejora_salto")
func _on_velocidad_pressed(): _aplicar_mejora("mejora_velocidad")
func _on_cadencia_pressed():  _aplicar_mejora("mejora_cadencia")

func _on_fuego_pressed():     _aplicar_habilidad("fuego")
func _on_hielo_pressed():     _aplicar_habilidad("hielo")
func _on_rayo_pressed():      _aplicar_habilidad("rayo")
func _on_veneno_pressed():    _aplicar_habilidad("veneno")
