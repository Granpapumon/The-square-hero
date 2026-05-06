extends Control # Este script DEBE estar en el nodo 'Contenedor'

func _ready():
	# El MenuNivel (CanvasLayer) debe tener Process Mode: Always en el inspector[cite: 2]
	get_parent().visibility_changed.connect(_on_parent_visibility_changed)
	_estilizar_interfaz(self)

func _on_parent_visibility_changed():
	# Si el CanvasLayer se muestra, pausamos el juego automáticamente[cite: 2]
	get_tree().paused = get_parent().visible
	if get_parent().visible:
		queue_redraw()

func _estilizar_interfaz(n):
	# Aplica el look de Pin Esmaltado de alta calidad[cite: 2]
	if n is Button:
		n.flat = true 
		n.add_theme_color_override("font_outline_color", Color.BLACK)
		n.add_theme_constant_override("outline_size", 14)
		n.process_mode = Node.PROCESS_MODE_ALWAYS # Permite clics en pausa
	for hijo in n.get_children():
		_estilizar_interfaz(hijo)

func _draw():
	if not get_parent().visible: return
	
	# PANEL PIXELADO CENTRADO (Gracias a Full Rect en el Contenedor)[cite: 2]
	var tam_panel = Vector2(650, 800)
	var centro = size / 2 
	var r = Rect2(centro - tam_panel / 2, tam_panel)
	
	draw_rect(r.grow(12), Color.BLACK) # Borde grueso
	draw_rect(r, Color(0.15, 0.15, 0.2)) # Fondo
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 12), Color(1, 1, 1, 0.15)) # Brillo

func configurar_modo_habilidades():
	_limpiar_botones()
	_mostrar_grupo(["FUEGO", "HIELO", "RAYO", "VENENO"])

func configurar_modo_atributos():
	_limpiar_botones()
	_mostrar_grupo(["ATAQUE", "SALTO", "VELOCIDAD", "CADENCIA"])

func _limpiar_botones():
	# Usamos la ruta hacia el VBoxContainer de tu imagen[cite: 2]
	var v_box = $ColorRect/VBoxContainer
	for boton in v_box.get_children():
		boton.hide()

func _mostrar_grupo(nombres: Array):
	var v_box = $ColorRect/VBoxContainer
	for nombre in nombres:
		var n = v_box.get_node_or_null(nombre)
		if n: n.show()

func _aplicar_mejora(nombre_funcion: String):
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador and jugador.has_method(nombre_funcion):
		jugador.call(nombre_funcion)
	get_tree().paused = false
	get_parent().hide() 

# SEÑALES: Conéctalas todas al nodo 'Contenedor'[cite: 2]
func _on_ataque_pressed():    _aplicar_mejora("mejorar_ataque")
func _on_salto_pressed():     _aplicar_mejora("mejorar_salto")
func _on_velocidad_pressed(): _aplicar_mejora("mejorar_velocidad")
func _on_cadencia_pressed():  _aplicar_mejora("mejorar_cadencia")
