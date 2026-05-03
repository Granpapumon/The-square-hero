extends CharacterBody2D

# --- ESTADÍSTICAS ---
var velocidad = 100.0
var velocidad_base = 100.0
var salud = 3
var dano_contacto = 10

# --- ESTADOS ---
var congelado = false
var envenenado = false

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

@onready var gema_escena = preload("res://gema_xp.tscn")

func _ready():
	player = get_tree().get_first_node_in_group("player")

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

# --- DAÑO Y MUERTE ---
func recibir_daño(cantidad):
	salud -= cantidad
	if salud <= 0:
		var gema = gema_escena.instantiate()
		get_parent().call_deferred("add_child", gema)
		gema.global_position = global_position + Vector2(0, 20)
		queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent().has_method("recibir_daño"):
			area.get_parent().recibir_daño(dano_contacto)

# --- EFECTOS DE HABILIDADES ---
func congelar(tiempo: float):
	if congelado:
		return
	congelado = true
	$Sprite2D.modulate = Color(0, 1, 1)
	await get_tree().create_timer(tiempo).timeout
	if not is_inside_tree():
		return
	congelado = false
	$Sprite2D.modulate = Color(1, 1, 1)

func ralentizar(porcentaje: float, tiempo: float):
	if congelado:
		return
	$Sprite2D.modulate = Color(1, 1, 0)
	velocidad = velocidad_base * (1.0 - porcentaje)
	await get_tree().create_timer(tiempo).timeout
	if not is_inside_tree():
		return
	velocidad = velocidad_base
	if not congelado and not envenenado:
		$Sprite2D.modulate = Color(1, 1, 1)

func envenenar(dano_por_tick: int):
	if envenenado:
		return
	envenenado = true
	$Sprite2D.modulate = Color(0, 1, 0)
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree():
			return
		recibir_daño(dano_por_tick)
	envenenado = false
	if not congelado:
		$Sprite2D.modulate = Color(1, 1, 1)
