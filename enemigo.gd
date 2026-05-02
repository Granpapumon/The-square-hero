extends CharacterBody2D

var velocidad = 100.0
var salud = 3
var dano_contacto = 10
# Obtenemos la gravedad del proyecto
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")

# Variable para guardar a quién vamos a perseguir
var player = null

@onready var gema_escena = preload("res://gema_xp.tscn")

func _ready():
	# Al nacer, el enemigo busca al objeto que tenga la etiqueta "player"
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	# 1. Aplicar gravedad para que no floten
	if not is_on_floor():
		velocity.y += gravedad * delta

	# 2. Perseguir al jugador
	if player:
		# Calculamos si el jugador está a la derecha o a la izquierda
		var direccion = global_position.direction_to(player.global_position)
		
		# Nos movemos solo en el eje X hacia esa dirección
		if direccion.x > 0:
			velocity.x = velocidad
		elif direccion.x < 0:
			velocity.x = -velocidad
	else:
		# Si no hay jugador, se detiene
		velocity.x = move_toward(velocity.x, 0, velocidad)

	# 3. Ejecutar el movimiento
	move_and_slide()

# Esta función la llamará la bala cuando lo golpee
#var salud = 3 # Aguantará 3 proyectiles

func recibir_daño(cantidad):
	salud -= cantidad
	
	if salud <= 0:
		# --- NUEVO: SISTEMA DE DROP DE GEMA ---
		var gema = gema_escena.instantiate()
		
		# Usamos call_deferred por seguridad del motor de físicas
		get_parent().call_deferred("add_child", gema)
		
		# Le decimos que aparezca exactamente donde estaba el enemigo
		gema.global_position = global_position + Vector2(0, 20)
		# --------------------------------------
		
		# Aquí mantienes tu código original de actualizar el contador
		# get_tree().current_scene.actualizar_contador() (o como lo tengas)
		
		queue_free() # El enemigo desaparece


func _on_hitbox_area_entered(area: Area2D) -> void:
	# Si lo que tocamos es la Hurtbox del jugador
	if area.name == "Hurtbox":
		# Buscamos al padre (el nodo Player) y llamamos a su función
		if area.get_parent().has_method("recibir_daño"):
			area.get_parent().recibir_daño(dano_contacto) # 10 es la cantidad de daño
# En enemigo.gd
