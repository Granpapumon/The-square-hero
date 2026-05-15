extends CharacterBody2D

@export var salud = 5000 
@export var dano_contacto = 60

var salud_jugador_al_inicio = 0
var player = null
var estado = "combate" 
var material_cara = StandardMaterial3D.new()

@onready var cubo_3d = $SubViewport/CSGBox3D
@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

var velocidad_base = 65.0
var velocidad_actual = 65.0
var direccion_movimiento = Vector2.ZERO

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("jefe")
	
	if is_instance_valid(player):
		salud_jugador_al_inicio = player.salud
	
	cubo_3d.material_override = material_cara
	material_cara.albedo_color = Color(0.8, 0.8, 0.8)
	_bucle_ataque()

func _physics_process(delta):
	if estado != "combate": return
	
	cubo_3d.rotation.x += 1.5 * delta
	cubo_3d.rotation.y += 2.0 * delta
	
	if is_instance_valid(player) and velocidad_actual == velocidad_base:
		direccion_movimiento = global_position.direction_to(player.global_position)
		
	velocity = direccion_movimiento * velocidad_actual
	move_and_slide()
	
	if is_instance_valid(player) and player.salud <= 0 and estado == "combate":
		animacion_victoria()

func _bucle_ataque():
	while estado == "combate":
		await get_tree().create_timer(2.0).timeout
		if estado != "combate" or not is_inside_tree() or not is_instance_valid(player): break
		
		var ataque_elegido = randi() % 4
		
		match ataque_elegido:
			0: await _ataque_pesado()
			1: await _ataque_radial()
			2: await _ataque_rafaga()
			3: await _ataque_embestida()

# --- HABILIDAD 1: DISPARO PESADO (Se infla y brilla rojo) ---
func _ataque_pesado():
	var tween = create_tween()
	material_cara.albedo_color = Color(0, 0, 0) 
	material_cara.emission_enabled = true
	material_cara.emission = Color(1, 0, 0)
	
	# Se infla tomando aire
	tween.tween_property(cubo_3d, "scale", Vector3(1.4, 1.4, 1.4), 0.5)
	await tween.finished
	if estado != "combate" or not is_inside_tree(): return
	
	cubo_3d.scale = Vector3.ONE # Escupe de golpe
	var bala = proyectil_escena.instantiate()
	bala.dano = 30
	bala.scale = Vector2(2.5, 2.5) 
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position
	
	if bala.has_method("lanzar") and is_instance_valid(player):
		bala.lanzar(global_position.direction_to(player.global_position))
		
	_restaurar_material()

# --- HABILIDAD 2: EXPLOSIÓN RADIAL (Se aplasta y brilla morado) ---
func _ataque_radial():
	var tween = create_tween()
	material_cara.albedo_color = Color(0.2, 0, 0.4) 
	material_cara.emission_enabled = true
	material_cara.emission = Color(1, 0, 1) 
	
	# Se aplasta acumulando presión
	tween.tween_property(cubo_3d, "scale", Vector3(1.3, 0.7, 1.3), 0.5)
	await tween.finished
	if estado != "combate" or not is_inside_tree(): return
	
	cubo_3d.scale = Vector3.ONE 
	var cantidad = 12
	var angulo_base = TAU / cantidad
	
	for i in range(cantidad):
		var bala = proyectil_escena.instantiate()
		bala.dano = 20
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		if bala.has_method("lanzar"):
			bala.lanzar(Vector2.RIGHT.rotated(i * angulo_base))
			
	_restaurar_material()

# --- HABILIDAD 3: RÁFAGA RÁPIDA (Rota muy rápido y brilla naranja) ---
func _ataque_rafaga():
	material_cara.albedo_color = Color(0.4, 0.2, 0) 
	material_cara.emission_enabled = true
	material_cara.emission = Color(1, 0.5, 0)
	
	# Gira bruscamente antes de disparar
	var tween_aviso = create_tween()
	var rot_actual = cubo_3d.rotation
	tween_aviso.tween_property(cubo_3d, "rotation", rot_actual + Vector3(0, 10, 0), 0.4)
	await tween_aviso.finished
	if estado != "combate" or not is_inside_tree(): return

	for i in range(5):
		if estado != "combate" or not is_instance_valid(player) or not is_inside_tree(): break
		var bala = proyectil_escena.instantiate()
		bala.dano = 15
		bala.velocidad = 400.0 
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		if bala.has_method("lanzar"):
			bala.lanzar(global_position.direction_to(player.global_position))
			
		# Retroceso visual por cada bala (seguro con tween)
		var t_retroceso = create_tween()
		t_retroceso.tween_property(cubo_3d, "scale", Vector3(0.9, 1.1, 0.9), 0.05)
		t_retroceso.tween_property(cubo_3d, "scale", Vector3.ONE, 0.05)
		
		await get_tree().create_timer(0.15).timeout

	_restaurar_material()

# --- HABILIDAD 4: EMBESTIDA FÍSICA (Se estira hacia atrás y brilla rojo puro) ---
func _ataque_embestida():
	material_cara.albedo_color = Color(0.3, 0, 0) 
	material_cara.emission_enabled = true
	material_cara.emission = Color(1, 0, 0) 
	
	var tween = create_tween()
	# Se estira como una liga hacia arriba
	tween.tween_property(cubo_3d, "scale", Vector3(0.5, 2.0, 0.5), 0.6)
	await tween.finished
	if estado != "combate" or not is_inside_tree(): return
	
	if is_instance_valid(player):
		direccion_movimiento = global_position.direction_to(player.global_position)
		velocidad_actual = 500.0
		cubo_3d.scale = Vector3(1.8, 0.5, 1.8) # Se aplasta por la velocidad
		
		await get_tree().create_timer(0.8).timeout 
		if not is_inside_tree(): return
		
		velocidad_actual = velocidad_base
		cubo_3d.scale = Vector3.ONE
		_restaurar_material()

func _restaurar_material():
	material_cara.emission_enabled = false
	material_cara.albedo_color = Color(0.8, 0.8, 0.8)

# --- SISTEMA DE DAÑO Y ANIMACIONES ---
func recibir_daño(cantidad):
	if estado != "combate": return
	salud -= cantidad
	
	# Destello blanco de daño rápido sin romper el material base
	var color_previo = material_cara.albedo_color
	var emision_previa = material_cara.emission_enabled
	
	material_cara.emission_enabled = true
	material_cara.emission = Color(1, 1, 1)
	
	var tween = create_tween()
	tween.tween_property(cubo_3d, "scale", Vector3(1.1, 0.9, 1.1), 0.05)
	tween.tween_property(cubo_3d, "scale", Vector3.ONE, 0.05)
	
	tween.tween_callback(func():
		if estado == "combate":
			material_cara.emission_enabled = emision_previa
			if not emision_previa: material_cara.albedo_color = color_previo
	)
	
	if salud <= 0:
		animacion_derrota()

func animacion_derrota():
	estado = "muriendo"
	$Hitbox.queue_free()
	
	var fue_no_hit = false
	if is_instance_valid(player) and player.salud >= salud_jugador_al_inicio:
		fue_no_hit = true
	
	var tween = create_tween()
	material_cara.emission_enabled = false
	material_cara.albedo_color = Color.BLACK
	tween.tween_property(cubo_3d, "rotation", Vector3(30, 30, 30), 2.5)
	tween.parallel().tween_property(cubo_3d, "scale", Vector3(0.01, 0.01, 0.01), 2.5)
	
	tween.tween_callback(func():
		var mundo = get_tree().get_first_node_in_group("mundo")
		if fue_no_hit and mundo.has_method("desbloquear_jefe_no_hit"):
			mundo.desbloquear_jefe_no_hit() 
		else:
			var hud = get_tree().get_first_node_in_group("HUD")
			if hud: hud.mostrar_mensaje("A N O M A L Í A   E R R A D I C A D A")
		
		queue_free()
	)

func animacion_victoria():
	estado = "victoria"
	velocity = Vector2.ZERO
	var tween = create_tween()
	material_cara.emission_enabled = true
	material_cara.emission = Color(1, 0.84, 0) # Color oro 
	tween.tween_property(cubo_3d, "rotation", Vector3.ZERO, 0.5) 
	tween.tween_property(cubo_3d, "position", Vector3(0, 2, 0), 0.5) 
	tween.tween_property(cubo_3d, "position", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_BOUNCE)

func _on_hitbox_area_entered(area):
	if estado != "combate": return
	if area.name == "Hurtbox":
		var victima = area.get_parent()
		if victima.is_in_group("player") and victima.has_method("recibir_daño"):
			victima.recibir_daño(dano_contacto)
