extends CharacterBody2D

@export var velocidad = 150.0
var velocidad_base: float
@export var salud = 15
@export var dano_contacto = 15
@export var probabilidad_gema: float = 1.0
@export var xp_que_da: int = 3

var congelado = false
var envenenado = false
var puede_hacer_daño = true

# --- SISTEMA DE SALTO AUTOMÁTICO ---
var raycast_vacio: RayCast2D
var saltando_vacio = false
var fuerza_salto = -750.0

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

@onready var gema_escena = preload("res://gema_xp.tscn")
@onready var dano_flotante_escena = preload("res://dano_flotante.tscn")
@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

var pixel_art = [
	"........BB........",
	".......BEEB.......",
	".......BEMB.......",
	"......BEEEB.......",
	"......BEMMEB......",
	"BBBBBBEEEEEBBBBBB.",
	".BEMMMEEMMEEMMMEB.",
	"..BEEEEEEEEEEEEB..",
	"...BEMMMEEMMMEB...",
	"....BEEEEEEEEB....",
	"....BEMCCEECCB....",
	"...BEEEDDBDDMEB...",
	"...BEMMMMBMMMMEB..",
	"..BEEEEEEEEEEEEB..",
	"..BEMMEB..BEMMEB..",
	".BEEEB......BEEEB.",
	".BEMB........BEMB.",
	"BBBB..........BBBB"
]

func _ready():
	velocidad_base = velocidad
	player = get_tree().get_first_node_in_group("player")
	var timer_daño = Timer.new()
	timer_daño.name = "TimerDaño"
	timer_daño.wait_time = 1.0
	timer_daño.one_shot = true
	timer_daño.timeout.connect(_on_timer_daño_timeout)
	add_child(timer_daño)
	
	# --- SENSOR DE VACÍO ---
	raycast_vacio = RayCast2D.new()
	raycast_vacio.target_position = Vector2(0, 150)
	add_child(raycast_vacio)

func _physics_process(delta):
	if congelado: return
	
	if not is_on_floor(): 
		velocity.y += gravedad * delta
	else:
		saltando_vacio = false
		
	if player:
		var direccion = global_position.direction_to(player.global_position)
		
		if saltando_vacio:
			velocity.x = (velocidad * 2.5) * (1 if direccion.x > 0 else -1)
		else:
			velocity.x = velocidad if direccion.x > 0 else -velocidad
			
		if is_on_floor() and velocity.x != 0:
			raycast_vacio.position = Vector2(sign(velocity.x) * 90, 0)
			raycast_vacio.force_raycast_update()
			
			if not raycast_vacio.is_colliding() and player.global_position.y <= global_position.y + 150:
				velocity.y = fuerza_salto
				saltando_vacio = true
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)
		
	move_and_slide()
	
	if puede_hacer_daño:
		for area in $Hitbox.get_overlapping_areas():
			if area.name == "Hurtbox" and area.get_parent().has_method("recibir_daño"):
				area.get_parent().recibir_daño(dano_contacto)
				puede_hacer_daño = false
				$TimerDaño.start()
				break

func _on_timer_daño_timeout():
	puede_hacer_daño = true

func _on_timer_disparo_timeout():
	if not is_instance_valid(player) or not is_inside_tree(): return
	var bala = proyectil_escena.instantiate()
	bala.dano = 5
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position
	bala.lanzar(global_position.direction_to(player.global_position))

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

func congelar(tiempo: float):
	if congelado: return
	congelado = true
	modulate = Color(0, 1, 1)
	await get_tree().create_timer(tiempo).timeout
	if not is_inside_tree(): return
	congelado = false
	modulate = Color(1, 1, 1)

func ralentizar(porcentaje: float, tiempo: float):
	if congelado: return
	modulate = Color(1, 1, 0)
	velocidad = velocidad_base * (1.0 - porcentaje)
	await get_tree().create_timer(tiempo).timeout
	if not is_inside_tree(): return
	velocidad = velocidad_base
	if not congelado and not envenenado: modulate = Color(1, 1, 1)

func envenenar(dano_por_tick: int):
	if envenenado: return
	envenenado = true
	modulate = Color(0, 1, 0)
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree(): return
		recibir_daño(dano_por_tick)
	envenenado = false
	if not congelado: modulate = Color(1, 1, 1)

func _process(_delta):
	var pulso = 1.0 + (sin(Time.get_ticks_msec() * 0.005) * 0.05)
	scale = Vector2(pulso, 1.0 / pulso)
	queue_redraw()

func _draw():
	var pixel_size = 10.0
	var offset_x = -(pixel_art[0].length() * pixel_size) / 2.0
	var offset_y = -(pixel_art.size() * pixel_size) / 2.0
	var avisando_disparo = false
	if is_instance_valid($TimerDisparo):
		if $TimerDisparo.time_left < 0.5:
			avisando_disparo = true
	for y in range(pixel_art.size()):
		var row = pixel_art[y]
		for x in range(row.length()):
			var letra = row[x]
			if letra == ".": continue
			var color = Color.TRANSPARENT
			match letra:
				"B": color = Color.BLACK
				"C": color = Color.WHITE if not avisando_disparo else Color(0.5, 0.8, 1.0)
				"D": color = Color.BLACK
				"E": color = Color(1.0, 0.6, 0.0) if not avisando_disparo else Color(1.0, 0.2, 0.2)
				"M": color = Color(0.8, 0.3, 0.0) if not avisando_disparo else Color(0.5, 0, 0)
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)
