extends CharacterBody2D

@export var salud = 500
@export var velocidad = 100.0
@export var dano_contacto = 30

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null
var saltando = false 

# --- SISTEMA DE SALTO DE ABISMOS ---
var raycast_vacio: RayCast2D
var saltando_vacio = false
var fuerza_salto_vacio = -850.0

# --- SISTEMA DE DISPARO ---
@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

# --- NUEVO: SISTEMA DE FASE 2 (FURIA) ---
var en_furia = false
@onready var escena_onda = preload("res://onda_choque.tscn")

var pixel_art = [
	"............BBBB..............",
	"...........BEEEEB.............",
	"..........BEMMMMEB............",
	".........BEEEEEEEEB...........",
	"........BEMMMMMMMMEB..........",
	".......BEEEEEEEEEEEEB.........",
	"......BEMMMMMMMMMMMMEB........",
	".....BEEEEEEEEEEEEEEEEB.......",
	"....BEMMMMMMMMMMMMMMMMEB......",
	"...BEEEEEEEEEEEEEEEEEEEEB.....",
	"..BEMMMMMMMMMMMMMMMMMMMMEB....",
	".BEEEEEEEEEEECCEEEECCEEEEEB...",
	"BEMMMMMMMMMMCDDCEMMDDCEMMMMEB.",
	"BBBBEEEEEEEECCCCEEECCCCEEEEEEB",
	"...BBBBMMMMMMMMMMMMMMMMMMMMMME",
	"......BBBBEEEEEEEEEEEEEEEEEEEB",
	".........BBBBMMMMMMMMMMMMMMMEB",
	"............BBBBEEEEEEEEEEEEEB",
	"..............BBBBMMMMMMMMMMEB",
	"................BBBBEEEEEEEEEB",
	"..................BBBBMMMMMMEB",
	"....................BBBBEEEEEB",
	"......................BBBBMMMB",
	"........................BBBBEE",
	"..........................BBBM",
	"............................BB",
	"..............................",
	"..............................",
	"..............................",
	".............................."
]

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("jefe")
	
	raycast_vacio = RayCast2D.new()
	raycast_vacio.target_position = Vector2(0, 150)
	add_child(raycast_vacio)
	
	var timer_disparo = Timer.new()
	timer_disparo.name = "TimerDisparo"
	timer_disparo.wait_time = 2.0
	timer_disparo.autostart = true
	timer_disparo.timeout.connect(_on_timer_disparo_timeout)
	add_child(timer_disparo)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravedad * delta
	else:
		saltando_vacio = false 
		
	if is_instance_valid(player) and not saltando:
		var direccion = global_position.direction_to(player.global_position)
		
		if saltando_vacio:
			velocity.x = (velocidad * 2.5) * (1 if direccion.x > 0 else -1)
		else:
			velocity.x = velocidad if direccion.x > 0 else -velocidad
			
		if is_on_floor() and velocity.x != 0:
			raycast_vacio.position = Vector2(sign(velocity.x) * 180, 0)
			raycast_vacio.force_raycast_update()
			
			if not raycast_vacio.is_colliding() and player.global_position.y <= global_position.y + 150:
				velocity.y = fuerza_salto_vacio
				saltando_vacio = true
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)
		
	move_and_slide()

func _on_timer_disparo_timeout():
	if not is_instance_valid(player) or not is_inside_tree(): return
	var bala = proyectil_escena.instantiate()
	bala.dano = 10 
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position
	if bala.has_method("lanzar"):
		bala.lanzar(global_position.direction_to(player.global_position))

func recibir_daño(cantidad):
	if randf() <= 0.30:
		modulate = Color(1, 1, 1, 0.5)
		await get_tree().create_timer(0.2).timeout
		if not is_inside_tree(): return
		modulate = Color(1, 1, 1, 1)
		return
		
	salud -= cantidad
	
	# --- DETECTAR ENTRADA A FASE 2 ---
	if salud <= 250 and not en_furia:
		en_furia = true
		modulate = Color(1, 0.2, 0.2) # Cambio visual a rojo furia
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud:
			hud.mostrar_mensaje("💢 ¡EL JEFE HA ENTRADO EN FURIA! 💢")
	
	if salud <= 0:
		var mundo = get_tree().get_first_node_in_group("mundo")
		if mundo: mundo.jefe_derrotado()
		queue_free()

func _on_timer_salto_timeout():
	saltando = true
	
	# --- GENERAR ONDA DE CHOQUE EN FASE 2 ---
	if en_furia:
		var onda = escena_onda.instantiate()
		get_parent().add_child(onda)
		onda.global_position = global_position
	
	var direccion_azar = Vector2(randf_range(-1, 1), -1).normalized()
	velocity = direccion_azar * (velocidad * 4)
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree(): return
	saltando = false

func _on_hitbox_area_entered(area):
	if area.name == "Hurtbox":
		if area.get_parent().has_method("recibir_daño"):
			area.get_parent().recibir_daño(dano_contacto)

func _process(_delta):
	queue_redraw()

func _draw():
	var pixel_size = 10.0
	var offset_x = -(pixel_art[0].length() * pixel_size) / 2.0
	var offset_y = -(pixel_art.size() * pixel_size) / 2.0
	var direccion_espejo = -1 if velocity.x < 0 else 1
	draw_set_transform(Vector2.ZERO, 0, Vector2(direccion_espejo, 1))
	for y in range(pixel_art.size()):
		var row = pixel_art[y]
		for x in range(row.length()):
			var letra = row[x]
			if letra == ".": continue
			var color = Color.TRANSPARENT
			match letra:
				"B": color = Color.BLACK
				"C": color = Color.WHITE
				"D": color = Color.RED
				"E": color = Color(0.8, 0.2, 0.2)
				"M": color = Color(0.4, 0.1, 0.1)
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)
