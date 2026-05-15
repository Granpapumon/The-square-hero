extends CharacterBody2D

@export var salud = 7500 # Más vida que el normal
@export var dano_contacto = 80

var player = null
var estado = "combate" 
var material_cara = StandardMaterial3D.new()

@onready var cubo_3d = $SubViewport/CSGBox3D
@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

var velocidad_base = 120.0 # Mucho más rápido persiguiendo
var velocidad_actual = 120.0
var direccion_movimiento = Vector2.ZERO

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("jefe")
	
	# Estética No-Hit: Negro con brillo rojo neón
	cubo_3d.material_override = material_cara
	material_cara.albedo_color = Color(0.05, 0.05, 0.05) # Casi negro puro
	material_cara.emission_enabled = true
	material_cara.emission = Color(1, 0, 0) # Luz roja
	material_cara.emission_energy_multiplier = 1.5
	
	_bucle_ataque_frenetico()

func _physics_process(delta):
	if estado != "combate": return
	
	# Rotación más violenta
	cubo_3d.rotation.x += 3.0 * delta
	cubo_3d.rotation.y += 4.0 * delta
	
	if is_instance_valid(player) and velocidad_actual == velocidad_base:
		direccion_movimiento = global_position.direction_to(player.global_position)
		
	velocity = direccion_movimiento * velocidad_actual
	move_and_slide()

func _bucle_ataque_frenetico():
	while estado == "combate":
		await get_tree().create_timer(1.2).timeout # Ataca mucho más seguido
		if estado != "combate" or not is_inside_tree() or not is_instance_valid(player): break
		
		var ataque_elegido = randi() % 3
		
		match ataque_elegido:
			0: await _ataque_radial_doble()
			1: await _ataque_rafaga_persecucion()
			2: await _ataque_embestida_oscura()

# --- HABILIDADES MEJORADAS Y TELEGRAFIADAS ---
func _ataque_radial_doble():
	# 1. AVISO VISUAL (Se aplasta rápido, brilla morado: 0.4s)
	material_cara.emission = Color(1, 0, 1) 
	var tween = create_tween()
	tween.tween_property(cubo_3d, "scale", Vector3(1.3, 0.7, 1.3), 0.4)
	await tween.finished
	if estado != "combate" or not is_inside_tree(): return
	
	# 2. ACCIÓN
	cubo_3d.scale = Vector3.ONE
	var cantidad = 24 
	var angulo_base = TAU / cantidad
	for i in range(cantidad):
		var bala = proyectil_escena.instantiate()
		bala.dano = 25
		bala.modulate = Color.RED
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		if bala.has_method("lanzar"):
			bala.lanzar(Vector2.RIGHT.rotated(i * angulo_base))
			
	_restaurar_material()

func _ataque_rafaga_persecucion():
	# 1. AVISO VISUAL (Giro brusco, brilla naranja: 0.4s)
	material_cara.emission = Color(1, 0.5, 0)
	var tween_aviso = create_tween()
	var rot_actual = cubo_3d.rotation
	tween_aviso.tween_property(cubo_3d, "rotation", rot_actual + Vector3(0, 15, 0), 0.4)
	await tween_aviso.finished
	if estado != "combate" or not is_inside_tree(): return

	# 2. ACCIÓN
	for i in range(8): 
		if estado != "combate" or not is_instance_valid(player) or not is_inside_tree(): break
		var bala = proyectil_escena.instantiate()
		bala.dano = 20
		bala.velocidad = 500.0 
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		if bala.has_method("lanzar"):
			bala.lanzar(global_position.direction_to(player.global_position))
			
		# Pequeño retroceso al disparar
		var t_retroceso = create_tween()
		t_retroceso.tween_property(cubo_3d, "scale", Vector3(0.9, 1.1, 0.9), 0.05)
		t_retroceso.tween_property(cubo_3d, "scale", Vector3.ONE, 0.05)
		
		await get_tree().create_timer(0.1).timeout
		
	_restaurar_material()

func _ataque_embestida_oscura():
	# 1. AVISO VISUAL (Se estira, rojo cegador: 0.5s)
	material_cara.emission = Color(3, 0, 0) 
	var tween = create_tween()
	tween.tween_property(cubo_3d, "scale", Vector3(0.5, 2.0, 0.5), 0.5)
	await tween.finished
	if estado != "combate" or not is_inside_tree(): return
	
	# 2. ACCIÓN
	if is_instance_valid(player):
		direccion_movimiento = global_position.direction_to(player.global_position)
		velocidad_actual = 600.0 # Embestida rapidísima
		cubo_3d.scale = Vector3(2.0, 0.5, 2.0)
		
		await get_tree().create_timer(0.6).timeout 
		if not is_inside_tree(): return
		
		velocidad_actual = velocidad_base
		cubo_3d.scale = Vector3.ONE
		_restaurar_material()

func _restaurar_material():
	material_cara.emission = Color(1, 0, 0) # Vuelve a su luz roja normal

# --- DAÑO SEGURO Y CONEXIÓN CON EL CUBO VERDADERO ---
func recibir_daño(cantidad):
	if estado != "combate": return
	salud -= cantidad
	
	# Destello blanco veloz al recibir daño
	var emision_previa = material_cara.emission
	material_cara.emission = Color(2, 2, 2)
	
	var tween = create_tween()
	tween.tween_property(cubo_3d, "scale", Vector3(1.1, 0.9, 1.1), 0.05)
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
	tween.tween_property(cubo_3d, "rotation", Vector3(40, 40, 40), 1.5)
	tween.parallel().tween_property(cubo_3d, "scale", Vector3(0.01, 0.01, 0.01), 1.5)
	
	tween.tween_callback(func():
		var mundo = get_tree().get_first_node_in_group("mundo")
		if mundo and mundo.has_method("evaluar_cubo_verdadero"):
			mundo.evaluar_cubo_verdadero() 
		queue_free()
	)

func _on_hitbox_area_entered(area):
	if estado != "combate": return
	if area.name == "Hurtbox":
		var victima = area.get_parent()
		if victima.is_in_group("player") and victima.has_method("recibir_daño"):
			victima.recibir_daño(dano_contacto)
