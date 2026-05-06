extends Control # El script va en el nodo 'Contenedor'

func _ready():
	# Conectamos a la señal del padre (CanvasLayer) para detectar cuando se muestra
	get_parent().visibility_changed.connect(_on_parent_visibility_changed)
	_preparar_interfaz()

func _on_parent_visibility_changed():
	# Si el CanvasLayer se muestra, pausamos. Si se oculta, despausamos.
	get_tree().paused = get_parent().visible
	if get_parent().visible:
		queue_redraw()

func _preparar_interfaz():
	# Evitamos que el ColorRect bloquee los clics
	if has_node("ColorRect"):
		$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Estilizamos todos los botones y aseguramos que funcionen en pausa[cite: 3]
	for boton in find_children("*", "Button", true):
		boton.flat = true
		boton.add_theme_color_override("font_outline_color", Color.BLACK)
		boton.add_theme_constant_override("outline_size", 16)
		boton.add_theme_font_size_override("font_size", 50)
		boton.process_mode = Node.PROCESS_MODE_ALWAYS # Crucial para el clic en pausa[cite: 3]

func _process(_delta):
	if get_parent().visible:
		queue_redraw()

func _draw():
	if not get_parent().visible: return
	
	# PANEL PIXELADO DE ALTA CALIDAD (PIN)
	var tam_panel = Vector2(750, 850)
	var centro = size / 2
	var r = Rect2(centro - tam_panel / 2, tam_panel)
	var p = 14.0
	
	draw_rect(r.grow(p), Color.BLACK)
	draw_rect(r, Color(0.1, 0.1, 0.12))
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, p), Color(1, 1, 1, 0.15))

func _aplicar_perk(nombre: String):
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador:
		jugador.activar_perk(nombre)
	
	# --- LA SOLUCIÓN AL PAUSE ---
	get_tree().paused = false # Forzamos la despausa inmediatamente[cite: 3]
	get_parent().hide() # Ocultamos el menú

# --- CONEXIÓN DE SEÑALES ---
func _on_dash_pressed():        _aplicar_perk("dash")
func _on_salto_doble_pressed(): _aplicar_perk("salto_doble")
func _on_vida_doble_pressed():  _aplicar_perk("vida_doble")
func _on_rango_pressed():       _aplicar_perk("rango")
