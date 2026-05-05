extends Node2D

@onready var player = get_tree().get_first_node_in_group("player")

@onready var escena_triangulo       = preload("res://enemigo_triangulo.tscn")
@onready var escena_rectangulo      = preload("res://enemigo_rectangulo.tscn")
@onready var escena_pentagono       = preload("res://enemigo_pentagono.tscn")
@onready var escena_hexagono        = preload("res://enemigo_hexagono.tscn")
@onready var escena_heptagono       = preload("res://enemigo_heptagono.tscn")
@onready var escena_octagono        = preload("res://enemigo_octagono.tscn")
@onready var escena_jefe_pentagono  = preload("res://jefe_pentagono.tscn")

const MAX_ENEMIGOS = 25
var jefe_activo = false

func _ready():
	add_to_group("mundo")

func _obtener_escena_enemigo() -> PackedScene:
	var nivel = player.nivel
	if nivel <= 5:    return escena_triangulo
	elif nivel <= 10: return escena_rectangulo
	elif nivel <= 15: return escena_pentagono
	elif nivel <= 20: return escena_hexagono
	elif nivel <= 25: return escena_heptagono
	else:             return escena_octagono

func _on_spawner_timeout() -> void:
	if not is_instance_valid(player) or jefe_activo:
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
	nuevo_enemigo.global_position = Vector2(x_al_azar, -50)
	add_child(nuevo_enemigo)

func spawner_jefe_pentagono():
	jefe_activo = true
	for e in get_tree().get_nodes_in_group("enemigos"):
		e.queue_free()
	var jefe = escena_jefe_pentagono.instantiate()
	jefe.global_position = Vector2(player.global_position.x + 400, -50)
	add_child(jefe)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.mostrar_mensaje("⚠ ¡JEFE APARECE!")

func jefe_derrotado():
	jefe_activo = false
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.mostrar_mensaje("¡JEFE DERROTADO!")
