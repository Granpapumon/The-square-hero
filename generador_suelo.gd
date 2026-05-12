extends Node

@export var plataforma_escena: PackedScene
var jugador: CharacterBody2D

# --- CONFIGURACIÓN PROCEDURAL ---
const TAMAÑO_CHUNK = 700 # Distancia matemática entre plataformas
const ANCHO_MIN = 400     # Plataforma más pequeña posible
const ANCHO_MAX = 900     # Plataforma más grande posible
const CHUNKS_VISIBLES = 2 # Cuántas zonas cargar adelante y atrás

var chunks_activos = {} # Memoria de lo que está dibujado en pantalla

func _ready():
	jugador = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if not is_instance_valid(jugador): return

	# 1. Calcular en qué "Sector" está el jugador usando su posición X
	var chunk_actual = int(round(jugador.global_position.x / TAMAÑO_CHUNK))

	# 2. Generar el suelo alrededor del jugador
	for i in range(chunk_actual - CHUNKS_VISIBLES, chunk_actual + CHUNKS_VISIBLES + 1):
		if not chunks_activos.has(i):
			_generar_chunk(i)

	# 3. Borrar los suelos lejanos (Previene Fugas de Memoria y Lag)
	var chunks_a_borrar = []
	for indice in chunks_activos.keys():
		if abs(indice - chunk_actual) > CHUNKS_VISIBLES + 1:
			chunks_activos[indice].queue_free()
			chunks_a_borrar.append(indice)
			
	for indice in chunks_a_borrar:
		chunks_activos.erase(indice)

func _generar_chunk(indice: int):
	# Usamos el número de sector como "Semilla". 
	# Así la aleatoriedad es permanente: si vuelves atrás, el salto será idéntico.
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(indice)

	var nueva_plataforma = plataforma_escena.instantiate()
	
	# La zona de inicio (Chunk 0) siempre es un piso sólido y largo para no morir al aparecer
	@warning_ignore("incompatible_ternary")
	var ancho_final = TAMAÑO_CHUNK if indice == 0 else rng.randf_range(ANCHO_MIN, ANCHO_MAX)
	
	# IMPORTANTE: Ajusta este '500' a la altura en el eje Y donde quieres tu suelo
	nueva_plataforma.global_position = Vector2(indice * TAMAÑO_CHUNK, 126) 
	
	add_child(nueva_plataforma)
	nueva_plataforma.configurar(ancho_final)
	
	chunks_activos[indice] = nueva_plataforma
# --- SISTEMA DE SPAWN SEGURO ---
func obtener_posicion_segura(pos_jugador_x: float) -> Vector2:
	if chunks_activos.is_empty(): 
		return Vector2.ZERO

	# 1. Averiguamos en qué bloque está el jugador
	var chunk_jugador = int(round(pos_jugador_x / TAMAÑO_CHUNK))
	var plataformas_lejanas = []

	# 2. Buscamos plataformas activas que NO sean en la que está el jugador (para no caerle en la cabeza)
	for indice in chunks_activos.keys():
		if indice != chunk_jugador:
			plataformas_lejanas.append(chunks_activos[indice])

	# (Por seguridad, si no hay lejanas, usamos la actual)
	if plataformas_lejanas.is_empty():
		plataformas_lejanas.append(chunks_activos.values()[0])

	# 3. Elegimos una plataforma lejana al azar
	var plataforma_elegida = plataformas_lejanas.pick_random()

	# 4. Calculamos sus bordes para no spawnear en la orilla y que el enemigo se caiga
	var colision = plataforma_elegida.get_node("CollisionShape2D")
	var ancho = colision.shape.size.x
	var margen = 100.0 # Píxeles de seguridad lejos del borde
	
	var x_aleatorio = randf_range(
		plataforma_elegida.global_position.x - (ancho / 2.0) + margen, 
		plataforma_elegida.global_position.x + (ancho / 2.0) - margen
	)

	# 5. Devolvemos la posición. Le restamos 150 a la Y para que caigan suavemente desde el cielo.
	var y_segura = plataforma_elegida.global_position.y - 150.0
	
	return Vector2(x_aleatorio, y_segura)
