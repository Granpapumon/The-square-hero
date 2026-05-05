extends CharacterBody2D

# Hereda las estadísticas del enemigo base pero con comportamiento especial
@export var velocidad = 150.0
var velocidad_base: float
@export var salud = 15
@export var dano_contacto = 15
@export var probabilidad_gema: float = 1.0
@export var xp_que_da: int = 3  # Da más XP por ser especial

# --- ESTADOS ---
var congelado = false
var envenenado = false
var puede_hacer_daño = true

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

@onready var gema_escena = preload("res://gema_xp.tscn")
@onready var dano_flotante_escena = preload("res://dano_flotante.tscn")
@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

func _ready():
	velocidad_base = velocidad
	player = get_tree().get_first_node_in_group("player")
	# Timer de daño continuo
	var timer_daño = Timer.new()
	timer_daño.name = "TimerDaño"
	timer_daño.wait_time = 1.0
	timer_daño.one_shot = true
	timer_daño.timeout.connect(_on_timer_daño_timeout)
	add_child(timer_daño)

# --- MOVIMIENTO ---
func _physics_process(delta):
	if congelado:
		return
	if not is_on_floor():
		velocity.y += gravedad * delta
	if player:
		var direccion = global_position.direction_to(player.global_position)
		velocity.x = velocidad if direccion.x > 0 else -velocidad
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)
	move_and_slide()

	# Daño continuo por contacto
	if puede_hacer_daño:
		for area in $Hitbox.get_overlapping_areas():
			if area.name == "Hurtbox":
				if area.get_parent().has_method("recibir_daño"):
					area.get_parent().recibir_daño(dano_contacto)
					puede_hacer_daño = false
					$TimerDaño.start()
					break

func _on_timer_daño_timeout():
	puede_hacer_daño = true

# --- DISPARO HACIA EL JUGADOR ---
func _on_timer_disparo_timeout():
	if not is_instance_valid(player) or not is_inside_tree():
		return
	var bala = proyectil_escena.instantiate()
	bala.dano = 5
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position
	bala.lanzar(global_position.direction_to(player.global_position))

# --- DAÑO Y MUERTE ---
func recibir_daño(cantidad):
	salud -= cantidad
	var flotante = dano_flotante_escena.instantiate()
	get_parent().call_deferred("add_child", flotante)
	flotante.global_position = global_position + Vector2(0, -20)
	flotante.iniciar(cantidad)
	if salud <= 0:
		var gema = gema_escena.instantiate()
		get_parent().call_deferred("add_child", gema)
		gema.global_position = global_position + Vector2(0, 20)
		queue_free()

# --- EFECTOS DE HABILIDADES ---
func congelar(tiempo: float):
	if congelado:
		return
	congelado = true
	modulate = Color(0, 1, 1)
	await get_tree().create_timer(tiempo).timeout
	if not is_inside_tree():
		return
	congelado = false
	modulate = Color(1, 1, 1)

func ralentizar(porcentaje: float, tiempo: float):
	if congelado:
		return
	modulate = Color(1, 1, 0)
	velocidad = velocidad_base * (1.0 - porcentaje)
	await get_tree().create_timer(tiempo).timeout
	if not is_inside_tree():
		return
	velocidad = velocidad_base
	if not congelado and not envenenado:
		modulate = Color(1, 1, 1)

func envenenar(dano_por_tick: int):
	if envenenado:
		return
	envenenado = true
	modulate = Color(0, 1, 0)
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree():
			return
		recibir_daño(dano_por_tick)
	envenenado = false
	if not congelado:
		modulate = Color(1, 1, 1)
