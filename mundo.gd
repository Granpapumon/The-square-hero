extends Node2D

@onready var enemigo_escena = preload("res://enemigo.tscn")
@onready var player = get_tree().get_first_node_in_group("player")

const MAX_ENEMIGOS = 25

func _on_spawner_timeout() -> void:
	if not is_instance_valid(player):
		return
	if get_tree().get_nodes_in_group("enemigos").size() >= MAX_ENEMIGOS:
		return

	var nuevo_enemigo = enemigo_escena.instantiate()

	var x_min = -1200
	var x_max = 1200
	var radio_seguro = 400
	var x_al_azar = 0.0
	var posicion_valida = false

	while not posicion_valida:
		x_al_azar = randf_range(x_min, x_max)
		if abs(x_al_azar - player.global_position.x) > radio_seguro:
			posicion_valida = true

	nuevo_enemigo.global_position = Vector2(x_al_azar, 130)
	add_child(nuevo_enemigo)
