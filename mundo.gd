extends Node2D

@onready var player = get_tree().get_first_node_in_group("player")

# --- ESCENAS DE ENEMIGOS ---
@onready var escena_triangulo   = preload("res://enemigo_triangulo.tscn")
@onready var escena_rectangulo  = preload("res://enemigo_rectangulo.tscn")
@onready var escena_pentagono   = preload("res://enemigo_pentagono.tscn")
@onready var escena_hexagono    = preload("res://enemigo_hexagono.tscn")
@onready var escena_heptagono   = preload("res://enemigo_heptagono.tscn")
@onready var escena_octagono    = preload("res://enemigo_octagono.tscn")

const MAX_ENEMIGOS = 25

func _obtener_escena_enemigo() -> PackedScene:
	var nivel = player.nivel
	if nivel <= 5:
		return escena_triangulo
	elif nivel <= 10:
		return escena_rectangulo
	elif nivel <= 15:
		return escena_pentagono
	elif nivel <= 20:
		return escena_hexagono
	elif nivel <= 25:
		return escena_heptagono
	else:
		return escena_octagono

func _on_spawner_timeout() -> void:
	if not is_instance_valid(player):
		return
	if get_tree().get_nodes_in_group("enemigos").size() >= MAX_ENEMIGOS:
		return

	var nuevo_enemigo = _obtener_escena_enemigo().instantiate()

	var x_min = -1200
	var x_max = 1200
	var radio_seguro = 400
	var x_al_azar = 0.0
	var posicion_valida = false

	while not posicion_valida:
		x_al_azar = randf_range(x_min, x_max)
		if abs(x_al_azar - player.global_position.x) > radio_seguro:
			posicion_valida = true

	nuevo_enemigo.global_position = Vector2(x_al_azar, 100)
	add_child(nuevo_enemigo)
