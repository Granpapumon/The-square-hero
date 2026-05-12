@tool
extends CharacterBody2D

@export var salud = 850 # Un poco más de vida por ser nivel 20
@export var velocidad = 130.0
@export var dano_contacto = 35
@export var fuerza_salto = -650.0

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

var en_furia = false
var estaba_en_suelo = true
var tiempo_furia = 0.0

@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")
# Ruta al enemigo triángulo/básico para invocar
@onready var escena_esbirro = preload("res://enemigo.tscn") 

# --- NUEVO ARTE PIXEL: HEPTÁGONO IRREGULAR E INESTABLE ---
# Se han definido 7 vértices claros que rompen la simetría central.
var pixel_art = [
	".........BB.........BB..", # Vértice 1 (Superior Izq), Vértice 2 (Superior Der)
	"........BCCB.......BCB..",
	".......BCCCCB.....BCCB..",
	"......BCCCCCCBBBBBBCCB..",
	".....BCCCCCCCCCCCCCCCB..",
	"....BCCCCCCCCCCCCCCCCB..",
	"...BCCCCCCCCCCCCCCCCCB..",
	"..BCCCCCCCCCCCCCCCCCCB..",
	".BCCCCCCCCCCCCCCCCCCCCB.", # Vértice 3 (Extremo Derecho Central)
	"BCCCCCCCCCCCCCCCCCCCCCB.",
	"BBCCCCCCCCCCCCCCCCCCCB..",
	"..BBCCCCCCCCCCCCCCBBB...",
	"....BBCCCCCCCCCCCB......", # Vértice 4 (Inferior Derecho)
	"......BCCCCCCCCCB.......",
	".....BCCBBCCCCBMB.......", # Vértice 5 (Inferior Central "hundido")
	"....BCCB..BBCCBMB.......",
	"...BCCB.....BBBB........", # Vértice 6 (Inferior Izquierdo)
	".BBCCB..................",
	"BCCCCB..................",
	"BBBBBB.................."  # Vértice 7 (Extremo Izquierdo Central)
]

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("jefe")
	
	# Configurar Timers si existen en la escena
	if has_node("TimerDisparo"):
		$TimerDisparo.wait_time = 2.2 # Disparo base ligeramente más lento
		$TimerDisparo.autostart = true
		if not $TimerDisparo.timeout.is_connected(_on_timer_disparo_timeout):
			$TimerDisparo.timeout.connect(_on_timer_disparo_timeout)
		$TimerDisparo.start()
		
	if has_node("TimerSalto"):
		$TimerSalto.wait_time = 2.8
		$TimerSalto.autostart = true
		if not $TimerSalto.timeout.is_connected(_on_timer_salto_timeout):
			$TimerSalto.timeout.connect(_on_timer_salto_timeout)
		$TimerSalto.start()

func _physics_process(delta):
	if Engine.is_editor_hint(): return
	
	# Efecto visual inestable si está en furia
	if en_furia:
		tiempo_furia += delta
		queue_redraw() # Forzar redibujado para el efecto de parpadeo

	if not is_on_floor():
		velocity.y += gravedad * delta

	# Movimiento hacia el jugador si está en el suelo
	if is_instance_valid(player) and is_on_floor():
		var direccion = global_position.direction_to(player.global_position)
		# Movimiento ligeramente errático
		var variacion = sin(Time.get_ticks_msec() * 0.005) * 20.0
		velocity.x = move_toward(velocity.x, (velocidad + variacion) * sign(direccion.x), 15.0)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, velocidad)

	# Detección de aterrizaje
	var tocando_suelo_ahora = is_on_floor()
	move_and_slide()
	
	if is_on_floor() and not estaba_en_suelo and en_furia:
		_invocar_esbirros_irregular()
		
	estaba_en_suelo = tocando_suelo_ahora

func _on_timer_salto_timeout():
	if Engine.is_editor_hint() or not is_inside_tree() or not is_on_floor(): return
	if not is_instance_valid(player): return
	
	# Salto agresivo hacia el jugador
	var distancia_x = player.global_position.x - global_position.x
	# Clamp para no saltar infinito horizontalmente
	velocity.x = clamp(distancia_x * 1.5, -velocidad * 3.0, velocidad * 3.0)
	# Si está en furia, salta un poco más bajo pero más rápido horizontalmente
	velocity.y = fuerza_salto * (0.9 if en_furia else 1.0)

func _on_timer_disparo_timeout():
	if Engine.is_editor_hint() or not is_inside_tree(): return
	
	# --- NUEVO DISPARO IRREGULAR (HEPTÁGONO IRRACIONAL) ---
	var cantidad_balas = 7
	var angulo_base = TAU / cantidad_balas # TAU = 360 grados en radianes
	
	for i in range(cantidad_balas):
		var bala = proyectil_escena.instantiate()
		bala.dano = 15
		if en_furia: bala.scale = Vector2(1.2, 1.2) # Balas más grandes en furia
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		
		if bala.has_method("lanzar"):
			# Añadimos una variación irracional al ángulo de cada bala
			# Esto hace que no sea un círculo perfecto, sino una dispersión caótica
			var variacion_irregular = randf_range(-0.3, 0.3) 
			var angulo_final = (i * angulo_base) + variacion_irregular
			var direccion_bala = Vector2.RIGHT.rotated(angulo_final)
			
			# Velocidad de bala ligeramente aleatoria también
			var mod_velocidad = randf_range(0.9, 1.2)
			bala.lanzar(direccion_bala * mod_velocidad)

func _invocar_esbirros_irregular():
	# Invoca 3 triángulos en posiciones caóticas alrededor del jefe al caer
	for i in range(3):
		var esbirro = escena_esbirro.instantiate()
		get_parent().add_child(esbirro)
		# Posiciones irregulares alrededor
		var offset = Vector2(randf_range(-100, 100), randf_range(-50, 0))
		esbirro.global_position = global_position + offset
		# Pequeño efecto visual al aparecer
		esbirro.modulate = Color(1, 0, 1) # Aparecen morados
		get_tree().create_timer(0.5).timeout.connect(func(): if is_instance_valid(esbirro): esbirro.modulate = Color(1,1,1))

func recibir_daño(cantidad):
	# Baja probabilidad de esquivar (inestabilidad cuántica)
	if randf() <= 0.20:
		modulate = Color(1, 1, 1, 0.1) # Casi invisible
		await get_tree().create_timer(0.15).timeout
		if is_inside_tree(): _restaurar_color_base()
		return
		
	salud -= cantidad
	
	# --- FASE 2: FURIA IRRACIONAL AL 50% (425 HP) ---
	if salud <= 425 and not en_furia:
		en_furia = true
		$TimerDisparo.wait_time = 1.4 # Dispara mucho más rápido y caótico
		$TimerSalto.wait_time = 2.0 # Salta más seguido
		
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud:
			hud.mostrar_mensaje("🌀 ¡ESTABILIDAD HEPTAGONAL PERDIDA! 🌀")

	if salud <= 0:
		var mundo = get_tree().get_first_node_in_group("mundo")
		if mundo: mundo.jefe_derrotado()
		queue_free()

func _restaurar_color_base():
	if en_furia:
		modulate = Color(1, 0.3, 1) # Rosa/Morado brillante inestable
	else:
		modulate = Color(1, 1, 1)

func _on_hitbox_area_entered(area):
	if area.name == "Hurtbox":
		var victima = area.get_parent()
		if victima.is_in_group("player") and victima.has_method("recibir_daño"):
			victima.recibir_daño(dano_contacto)

func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()

func _draw():
	var pixel_size = 10.0
	# Centrado irregular basado en el dibujo
	var offset_x = -(pixel_art[8].length() * pixel_size) / 2.0
	var offset_y = -(pixel_art.size() * pixel_size) / 2.0
	
	# Color de borde inestable si está en furia
	var color_borde = Color.BLACK
	if en_furia:
		# Parpadeo rápido entre negro y morado eléctrico
		if fmod(tiempo_furia * 10.0, 2.0) < 1.0:
			color_borde = Color(0.5, 0, 1)

	for y in range(pixel_art.size()):
		var row = pixel_art[y]
		for x in range(row.length()):
			if x >= row.length(): continue
			var letra = row[x]
			if letra == ".": continue
			var color = Color.TRANSPARENT
			match letra:
				"B": color = color_borde
				"C": color = Color(0.4, 0.0, 0.6) # Morado oscuro irracional
				"M": color = Color(0.2, 0.0, 0.3) # Zonas oscuras
			
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)
