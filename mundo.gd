extends Node2D
var enemigos_derrotados = 0

func actualizar_contador():
	enemigos_derrotados += 1
	# Buscamos dentro del player -> camera -> contador
	$Player/Camera2D/ContadorEnemigos.text = str(enemigos_derrotados)
# 1. Cargamos la escena del enemigo (revisa que el nombre sea exacto)
@onready var enemigo_escena = preload("res://enemigo.tscn")

# 2. Referencia al jugador para saber dónde está
@onready var player = get_tree().get_first_node_in_group('player')

func _on_spawner_timeout() -> void:
	if not is_instance_valid(player):
		return
	
	var nuevo_enemigo = enemigo_escena.instantiate()
	
	# 1. Definimos los límites del suelo y la "zona segura"
	var x_min = -1200
	var x_max = 1200
	var radio_seguro = 400 # Distancia mínima a la que puede aparecer un enemigo
	
	var x_al_azar = 0.0
	var posicion_valida = false
	
	# 2. Bucle para encontrar una posición aleatoria que no esté cerca del jugador
	while not posicion_valida:
		x_al_azar = randf_range(x_min, x_max)
		
		# Calculamos la distancia absoluta entre el punto al azar y el jugador
		var distancia_al_player = abs(x_al_azar - player.global_position.x)
		
		if distancia_al_player > radio_seguro:
			posicion_valida = true
	
	# 3. Asignar la posición final (usando el 130 de altura que detectamos antes)
	nuevo_enemigo.global_position = Vector2(x_al_azar, 130)
	add_child(nuevo_enemigo)
