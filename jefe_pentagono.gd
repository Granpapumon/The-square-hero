extends CharacterBody2D

# --- ESTADÍSTICAS DEL JEFE ---
@export var salud = 500
@export var velocidad = 100.0
@export var dano_contacto = 30 # ¡Es un jefe, pega fuerte!

var player = null
var saltando = false # Estado para saber si está en el aire

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	# Solo persigue al jugador si NO está a la mitad de un salto
	if is_instance_valid(player) and not saltando:
		var direccion = global_position.direction_to(player.global_position)
		velocity = direccion * velocidad
		move_and_slide()

# --- DAÑO Y HABILIDAD DE ESQUIVAR ---
func recibir_daño(cantidad):
	# HABILIDAD: 30% de probabilidad de esquivar el ataque
	if randf() <= 0.30:
		print("¡El Jefe esquivó el ataque!")
		$Sprite2D.modulate = Color(1, 1, 1, 0.5) # Se hace un poco transparente para que notes el esquive
		await get_tree().create_timer(0.2).timeout
		$Sprite2D.modulate = Color(1, 1, 1, 1) # Vuelve a la normalidad
		return # ¡Cancelamos el daño y salimos de la función!
		
	# Si no esquivó, recibe el daño normal
	salud -= cantidad
	
	# Muerte del Jefe
	if salud <= 0:
		print("¡JEFE PENTÁGONO DERROTADO!")
		queue_free()

# --- HABILIDAD: SALTO AL AZAR ---
func _on_timer_salto_timeout():
	saltando = true
	
	# Elige una dirección completamente al azar
	var direccion_azar = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# Da un impulso muy rápido (4 veces su velocidad normal)
	velocity = direccion_azar * (velocidad * 4)
	move_and_slide()
	
	# Se queda quieto un instante después de saltar antes de volver a perseguirte
	await get_tree().create_timer(0.4).timeout
	saltando = false
# --- DAÑO AL JUGADOR ---
func _on_hitbox_area_entered(area):
	# Si lo que tocamos tiene la función de recibir daño (el jugador), lo atacamos
	if area.get_parent().has_method("recibir_daño"):
		area.get_parent().recibir_daño(dano_contacto)
