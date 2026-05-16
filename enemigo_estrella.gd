extends CharacterBody2D

# --- ESTADÍSTICAS REBALANCEADAS (ESTRELLA) ---
@export var velocidad = 150.0
var velocidad_base: float
var velocidad_actual: float
@export var salud = 7
@export var dano_contacto = 10
@export var probabilidad_gema: float = 1.0
@export var xp_que_da: int = 3
var expresion = "normal"

# --- SISTEMA DE ESTADOS Y CONTROL ---
var raycast_vacio: RayCast2D
var saltando_vacio = false
var fuerza_salto = -750.0 

var congelado = false
var envenenado = false
var esta_detenido = false
var puede_hacer_daño = true
var cargando_ataque = false

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

# --- NODOS ---
@onready var gema_escena = preload("res://gema_xp.tscn")
@onready var dano_flotante_escena = preload("res://dano_flotante.tscn")
@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

# --- ARTE Y COLOR ---
var color_base = Color(1.0, 0.6, 0.0)
var color_sombra = Color(0.8, 0.3, 0.0)

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
	player = get_tree().get_first_node_in_group("player")
	
	# Grupos de colisión
	add_to_group("enemigos")
	add_to_group("enemigo") 
	
	velocidad_base = velocidad
	velocidad_actual = velocidad
	
	# Timers automáticos
	var timer_dano = Timer.new()
	timer_dano.name = "TimerDaño"
	timer_dano.wait_time = 1.0
	timer_dano.one_shot = true
	timer_dano.timeout.connect(_on_timer_daño_timeout)
	add_child(timer_dano)
	
	var timer_atk = Timer.new()
	timer_atk.name = "TimerDisparo"
	# Ataca un poco más rápido que los polígonos pesados
	timer_atk.wait_time = randf_range(2.0, 3.5) 
	timer_atk.autostart = true
	timer_atk.timeout.connect(_on_timer_ataque_timeout)
	add_child(timer_atk)
	
	# Sensor de abismos
	raycast_vacio = RayCast2D.new()
	raycast_vacio.target_position = Vector2(0, 150)
	add_child(raycast_vacio)
	
	# Conexión del Hurtbox
	if has_node("Hurtbox"):
		if not $Hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
			$Hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta):
	if esta_detenido or congelado or cargando_ataque:
		if not is_on_floor(): velocity.y += gravedad * delta
		velocity.x = 0
		move_and_slide()
		return
		
	if not is_on_floor(): 
		velocity.y += gravedad * delta
	else:
		saltando_vacio = false
		
	if is_instance_valid(player):
		var direccion = global_position.direction_to(player.global_position)
		
		if saltando_vacio:
			velocity.x = (velocidad_actual * 2.5) * (1 if direccion.x > 0 else -1)
		else:
			velocity.x = velocidad_actual if direccion.x > 0 else -velocidad_actual
		
		if is_on_floor() and velocity.x != 0:
			raycast_vacio.position = Vector2(sign(velocity.x) * 90, 0)
			raycast_vacio.force_raycast_update()
			
			if not raycast_vacio.is_colliding() and player.global_position.y <= global_position.y + 150:
				velocity.y = fuerza_salto
				saltando_vacio = true
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
		
	move_and_slide()
	
	# Polling para hacer daño
	if puede_hacer_daño and has_node("Hitbox"):
		for area in $Hitbox.get_overlapping_areas():
			if area.name == "Hurtbox" and area.get_parent().has_method("recibir_daño"):
				area.get_parent().recibir_daño(dano_contacto)
				puede_hacer_daño = false
				$TimerDaño.start()
				break

# --- INTELIGENCIA ARTIFICIAL: ATAQUE ESTRELLA ---
func _on_timer_ataque_timeout():
	if not is_instance_valid(player) or esta_detenido or congelado: return
	
	cargando_ataque = true
	var color_previo = modulate
	var rot_previa = rotation
	var tween = create_tween()
	
	# AVISO (0.4s): Gira rápidamente 360 grados y brilla intensamente
	tween.tween_property(self, "rotation", rot_previa + TAU, 0.4)
	tween.parallel().tween_property(self, "modulate", Color(3.0, 3.0, 1.5), 0.4)
	await tween.finished
	if not is_inside_tree(): return
	
	# ATAQUE: Escopeta de 3 balas en cono
	var dir = global_position.direction_to(player.global_position)
	var angulos = [dir.rotated(-0.3), dir, dir.rotated(0.3)]
	
	for d in angulos:
		var b = proyectil_escena.instantiate()
		b.dano = 10
		b.velocidad = 450.0
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		if b.has_method("lanzar"): b.lanzar(d)
	
	# RECUPERACIÓN
	modulate = color_previo
	rotation = 0 # Reiniciar la rotación para no arruinar el dibujo
	cargando_ataque = false

# --- DAÑO Y ESTADOS ---
func _on_timer_daño_timeout():
	puede_hacer_daño = true

func _on_hurtbox_area_entered(area):
	if area.is_in_group("bala_jugador") or "bala" in area.name.to_lower():
		if "dano" in area:
			recibir_daño(area.dano)
		elif area.has_method("get_dano"):
			recibir_daño(area.get_dano())

func recibir_dano(cantidad):
	recibir_daño(cantidad)

func recibir_daño(cantidad):
	salud -= cantidad
	
	modulate = Color(5, 5, 5) 
	scale = Vector2(0.8, 1.2) 
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.15) 
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	if is_instance_valid(dano_flotante_escena):
		var flotante = dano_flotante_escena.instantiate()
		get_parent().call_deferred("add_child", flotante)
		flotante.global_position = global_position + Vector2(0, -20)
		if flotante.has_method("iniciar"): flotante.iniciar(cantidad)
	
	if salud <= 0:
		if ClassDB.class_exists("EfectoExplosion") or ResourceLoader.exists("res://efecto_explosion.gd"):
			var explosion = EfectoExplosion.new()
			explosion.iniciar("estrella", color_base) 
			explosion.global_position = global_position
			get_parent().add_child(explosion)
		
		if randf() <= probabilidad_gema:
			var gema = gema_escena.instantiate()
			gema.valor_xp = xp_que_da
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
	velocidad_actual = velocidad_base * (1.0 - porcentaje)
	await get_tree().create_timer(tiempo).timeout
	if not is_inside_tree(): return
	velocidad_actual = velocidad_base
	if not congelado and not envenenado: modulate = Color(1, 1, 1)

func envenenar(dano_por_tick: int):
	if envenenado: return
	envenenado = true
	_bucle_veneno(3.0, dano_por_tick)

func aplicar_estado(tipo, duracion, valor = 0):
	match tipo:
		"detener":
			esta_detenido = true
			await get_tree().create_timer(duracion).timeout
			esta_detenido = false
		"ralentizar":
			ralentizar(valor, duracion)
		"envenenar":
			_bucle_veneno(duracion, valor)

func _bucle_veneno(tiempo, dano):
	for i in range(int(tiempo)):
		if not is_instance_valid(self): break
		recibir_daño(dano)
		modulate = Color(0, 1, 0) 
		await get_tree().create_timer(1.0).timeout
		modulate = Color(1, 1, 1)
	envenenado = false

# --- DIBUJO Y PULSO ---
func _process(_delta):
	var pulso = 1.0 + (sin(Time.get_ticks_msec() * 0.005) * 0.05)
	scale = Vector2(pulso, 1.0 / pulso)
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
				"C": color = Color.WHITE if expresion == "normal" else Color(1, 0.4, 0.4)
				"D": color = Color(0.8, 0.1, 0.1) if expresion == "normal" else Color.WHITE
				"E": color = color_base
				"M": color = color_sombra
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)
