extends CharacterBody2D

@export var salud = 10000 # El doble de salud
@export var dano_contacto = 100

var player = null
var estado = "combate" 
var material_cara = StandardMaterial3D.new()

@onready var cubo_3d = $SubViewport/CSGBox3D
@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("jefe")
	
	# Estética del Cubo Verdadero: Blanco brillante emisivo (Luz pura)
	cubo_3d.material_override = material_cara
	material_cara.albedo_color = Color(1, 1, 1)
	material_cara.emission_enabled = true
	material_cara.emission = Color(1, 1, 1)
	material_cara.emission_energy_multiplier = 2.0
	
	_bucle_ataque_divino()

func _physics_process(delta):
	if estado != "combate": return
	
	# Rotación hiper-rápida y antinatural
	cubo_3d.rotation.x += 5.0 * delta
	cubo_3d.rotation.y -= 4.0 * delta
	cubo_3d.rotation.z += 3.0 * delta
	
	move_and_slide()

func _bucle_ataque_divino():
	while estado == "combate":
		await get_tree().create_timer(1.0).timeout # Ataca casi sin descanso
		if estado != "combate" or not is_inside_tree() or not is_instance_valid(player): break
		
		var ataque_elegido = randi() % 3
		
		match ataque_elegido:
			0: await _teletransporte_y_cruz()
			1: await _infierno_fractal()
			2: await _lluvia_orbital()

# --- HABILIDADES DIVINAS (Telegrafiados de 0.35s - 0.45s) ---

func _teletransporte_y_cruz():
	# 1. DESAPARECE
	var tween_out = create_tween()
	tween_out.tween_property(cubo_3d, "scale", Vector3.ZERO, 0.15)
	await tween_out.finished
	if estado != "combate" or not is_inside_tree(): return
	
	# 2. AVISO VISUAL EN NUEVA POSICIÓN (Luz Cian: 0.35s)
	var offset = Vector2(randf_range(-300, 300), randf_range(-300, -100))
	if is_instance_valid(player):
		global_position = player.global_position + offset
	
	cubo_3d.scale = Vector3(0.2, 0.2, 0.2) # Aparece como una chispa
	material_cara.emission = Color(0, 1, 1) # Aviso Cian
	
	await get_tree().create_timer(0.35).timeout
	if estado != "combate" or not is_inside_tree(): return
	
	# 3. ACCIÓN INSTANTÁNEA
	var tween_in = create_tween()
	tween_in.tween_property(cubo_3d, "scale", Vector3.ONE, 0.05)
	
	var direcciones = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for dir in direcciones:
		var bala = proyectil_escena.instantiate()
		bala.dano = 30
		bala.velocidad = 600.0 # Láseres hiper rápidos
		bala.scale = Vector2(1.5, 3.0) 
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		if bala.has_method("lanzar"):
			bala.lanzar(dir)
			
	_restaurar_luz_divina()

func _infierno_fractal():
	# 1. AVISO VISUAL (Se apaga, se vuelve un agujero negro: 0.4s)
	material_cara.albedo_color = Color(0, 0, 0)
	material_cara.emission_enabled = false
	var tween = create_tween()
	tween.tween_property(cubo_3d, "scale", Vector3(0.5, 0.5, 0.5), 0.4)
	await tween.finished
	if estado != "combate" or not is_inside_tree(): return
	
	# 2. ACCIÓN (Explosión de 20 balas)
	cubo_3d.scale = Vector3.ONE
	var cantidad = 20
	for i in range(cantidad):
		var bala = proyectil_escena.instantiate()
		bala.dano = 20
		bala.modulate = Color.WHITE
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		if bala.has_method("lanzar"):
			bala.lanzar(Vector2.RIGHT.rotated(i * (TAU / cantidad)))
			
	_restaurar_luz_divina()

func _lluvia_orbital():
	# 1. AVISO VISUAL (Giro divino extremo y luz dorada: 0.45s)
	material_cara.emission_enabled = true
	material_cara.emission = Color(1, 0.8, 0) # Oro brillante
	var tween = create_tween()
	var rot_actual = cubo_3d.rotation
	tween.tween_property(cubo_3d, "rotation", rot_actual + Vector3(15, 15, 15), 0.45)
	await tween.finished
	if estado != "combate" or not is_inside_tree(): return
	
	# 2. ACCIÓN CONTINUA (Apuntado y salto orbital)
	for i in range(8):
		if not is_instance_valid(player) or estado != "combate" or not is_inside_tree(): break
		
		# Se mueve erraticamente por encima del jugador
		global_position = global_position.lerp(player.global_position + Vector2(randf_range(-200, 200), -250), 0.5)
		
		var bala = proyectil_escena.instantiate()
		bala.dano = 25
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		if bala.has_method("lanzar"):
			bala.lanzar(global_position.direction_to(player.global_position))
			
		# Micro-parpadeo de retroceso
		var t_retroceso = create_tween()
		t_retroceso.tween_property(cubo_3d, "scale", Vector3(0.8, 1.2, 0.8), 0.05)
		t_retroceso.tween_property(cubo_3d, "scale", Vector3.ONE, 0.05)
		
		await get_tree().create_timer(0.1).timeout
		
	_restaurar_luz_divina()

func _restaurar_luz_divina():
	material_cara.albedo_color = Color(1, 1, 1)
	material_cara.emission_enabled = true
	material_cara.emission = Color(1, 1, 1)

# --- DAÑO SEGURO Y EPÍLOGO ---
func recibir_daño(cantidad):
	if estado != "combate": return
	salud -= cantidad
	
	# Destello cian seguro al recibir daño
	var emision_previa = material_cara.emission
	material_cara.emission_enabled = true
	material_cara.emission = Color(0, 1, 1)
	
	var tween = create_tween()
	tween.tween_property(cubo_3d, "scale", Vector3(0.8, 1.2, 0.8), 0.05)
	tween.tween_property(cubo_3d, "scale", Vector3.ONE, 0.05)
	
	tween.tween_callback(func():
		if estado == "combate":
			material_cara.emission = emision_previa
	)
	
	if salud <= 0:
		animacion_derrota()

func animacion_derrota():
	estado = "muriendo"
	$Hitbox.queue_free()
	
	var tween = create_tween()
	material_cara.emission_enabled = false 
	material_cara.albedo_color = Color(0.1, 0.1, 0.1)
	
	# Se rompe en pedazos / Colapsa
	tween.tween_property(cubo_3d, "rotation", Vector3(50, 50, 50), 4.0)
	tween.parallel().tween_property(cubo_3d, "scale", Vector3.ZERO, 4.0)
	
	tween.tween_callback(func():
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud: hud.mostrar_mensaje("🏆 L E Y E N D A   A B S O L U T A 🏆")
		queue_free()
	)

func _on_hitbox_area_entered(area):
	if estado != "combate": return
	if area.name == "Hurtbox":
		var victima = area.get_parent()
		if victima.is_in_group("player") and victima.has_method("recibir_daño"):
			victima.recibir_daño(dano_contacto)
