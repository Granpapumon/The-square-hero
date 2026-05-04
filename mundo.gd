extends Node2D

@onready var enemigo_escena = preload("res://enemigo.tscn")
@onready var jefe_pentagono_escena = preload("res://jefe_pentagono.tscn")
@onready var jefe_heptagono_escena = preload("res://jefe_heptagono.tscn")
@onready var enemigo_estrella_escena = preload("res://enemigo_estrella.tscn")
@onready var enemigo_octagono_escena = preload("res://enemigo_octagono.tscn")
@onready var enemigo_heptagono_escena = preload("res://enemigo_heptagono.tscn")
@onready var enemigo_hexagono_escena = preload("res://enemigo_hexagono.tscn")
@onready var enemigo_pentagono_escena = preload("res://enemigo_pentagono.tscn")
@onready var enemigo_rectangulo_escena = preload("res://enemigo_rectangulo.tscn")
@onready var enemigo_triangulo_escena = preload("res://enemigo_triangulo.tscn")
@onready var player = get_tree().get_first_node_in_group("player")
var jefe_generado = false

const MAX_ENEMIGOS = 25

func _on_spawner_timeout():
	if not is_instance_valid(player): return
	
	var nivel_actual = player.nivel
	var nuevo_enemigo = null
	
	# --- REGLAS ESTRICTAS DE NIVELES (0 al 10) ---
	
	if nivel_actual == 10:
		# Si llegamos al 10 y no hay jefe, lo creamos.
		if not jefe_generado:
			nuevo_enemigo = jefe_pentagono_escena.instantiate()
			jefe_generado = true
			print("¡EL JEFE PENTÁGONO HA APARECIDO!")
		else:
			# Si el jefe ya está peleando, seguimos mandando rectángulos de apoyo
			nuevo_enemigo = enemigo_rectangulo_escena.instantiate()
			
	elif nivel_actual >= 6 and nivel_actual <= 9:
		# Del nivel 6 al 9: SOLO RECTÁNGULOS
		nuevo_enemigo = enemigo_rectangulo_escena.instantiate()
		
	elif nivel_actual <= 5:
		# Del nivel 0 al 5: SOLO TRIÁNGULOS
		nuevo_enemigo = enemigo_triangulo_escena.instantiate()

	# --- CONFIGURACIÓN DE POSICIÓN LATERAL ---
	if nuevo_enemigo:
		# 1. Elegimos Izquierda (-1) o Derecha (1)
		var direccion = 1 if randf() > 0.5 else -1
		
		# 2. Distancia horizontal (entre 400 y 600 píxeles de distancia)
		var distancia_x = randf_range(400, 600) * direccion
		
		# 3. Lo colocamos exactamente a la misma altura 'Y' que el jugador, pero desplazado en 'X'
		nuevo_enemigo.global_position = player.global_position + Vector2(distancia_x, 0)
		add_child(nuevo_enemigo)
