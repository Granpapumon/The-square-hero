extends CharacterBody2D

# --- ESTADÍSTICAS REBALANCEADAS ---
var tipo_enemigo = ""
@export var velocidad = 100.0
var velocidad_base: float
var velocidad_actual: float
@export var salud = 3
@export var dano_contacto = 10
@export var probabilidad_gema: float = 1.0
@export var xp_que_da: int = 1
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
var pixel_art = []
var color_base = Color(1, 1, 1)
var color_sombra = Color(0, 0, 0)

var art_triangulo = [
	".......B.......", "......BEB......", "......BEB......", ".....BEMEB.....",
	".....BEEEB.....", "....BEMMMEB....", "....BEEEEEB....", "...BEMMMMMEB...",
	"...BEEEEEEEB...", "..BEMMMMMMMEB..", "..BEEEEEEEEEB..", ".BEMMMMMMMMMEB.",
	".BEEEEEEEEEEEB.", "BEMMMMMMMMMMMEB", "BEECCCEEECCCEEB", "BECDDEBEEDDEEEB",
	"BEMMMMBBBMMMMEB", "BEEEEEBMBEEEEEB", "BEMMMMMMMMMEEEB", "BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB", "BEEEEEEEEEEEEEB", "BEMMMMMMMMMMMEB", "BBBBBBBBBBBBBBB"
]

var art_rectangulo = [
	"BBBBBBBBBBBBBBB", "BEEEEEEEEEEEEEB", "BEMMMMMMMMMMMEB", "BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB", "BEEEEEEEEEEEEEB", "BEMMMMMMMMMMMEB", "BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB", "BEEEEEEEEEEEEEB", "BEECCCEEECCCEEB", "BECDDEBEEDDEEEB",
	"BEMMMMBBBMMMMEB", "BEEEEEBMBEEEEEB", "BEMMMMMMMMMMMEB", "BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB", "BEEEEEEEEEEEEEB", "BEMMMMMMMMMMMEB", "BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB", "BEEEEEEEEEEEEEB", "BEMMMMMMMMMMMEB", "BBBBBBBBBBBBBBB"
]

var art_pentagono = [
	".......B.......", "......BEB......", ".....BEMEB.....", "....BEEEEEB....",
	"...BEMMMMMEB...", "..BEEEEEEEEEB..", ".BEMMCCCCCMEEB.", "BEEECDDDCDEEEEB",
	"BEMMMCCCCCMEEEB", "BEEEEEEEEEEEEEB", ".BMMMMMMMMMMMB.", "..BEEEEEEEEEB..",
	"...BMMMMMMMB...", "....BBBBBBB...."
]

var art_hexagono = [
	"....BBBBBBB....", "...BEEEEEEEB...", "..BEMMMMMMMEB..", ".BEEEEEEEEEEEB.",
	"BEMMCCCCCMMMEEB", "BEECDDDCDEEEEEB", "BEMMCCCCCMMMEEB", "BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB", ".BEEEEEEEEEEEB.", "..BMMMMMMMMMB..", "...BEEEEEEEB...",
	"....BBBBBBB...."
]

var art_octagono = [
	".....BBBBB.....", "...BBEEEEEBB...", "..BEMMMMMMMEB..", ".BEEEEEEEEEEEB.",
	"BEMMCCCCCMMMEEB", "BEECDDDCDEEEEEB", "BEMMCCCCCMMMEEB", "BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB", ".BEEEEEEEEEEEB.", "..BMMMMMMMMMB..", "...BBEEEEEBB...",
	".....BBBBB....."
]

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	# Aseguramos que pertenezca a ambos grupos para las balas
	add_to_group("enemigos")
	add_to_group("enemigo") 
	
	_configurar_tipo_y_stats()
	velocidad_base = velocidad
	velocidad_actual = velocidad
	
	# Timer Daño de Contacto
	var timer_dano = Timer.new()
	timer_dano.name = "TimerDaño"
	timer_dano.wait_time = 1.0
	timer_dano.one_shot = true
	timer_dano.timeout.connect(_on_timer_daño_timeout)
	add_child(timer_dano)
	
	# Timer de IA (Ataque Telegrafiado)
	var timer_atk = Timer.new()
	timer_atk.name = "TimerDisparo"
	timer_atk.wait_time = randf_range(2.5, 4.0) 
	timer_atk.autostart = true
	timer_atk.timeout.connect(_on_timer_ataque_timeout)
	add_child(timer_atk)
	
	# Sensor de Vacío
	raycast_vacio = RayCast2D.new()
	raycast_vacio.target_position = Vector2(0, 150)
	add_child(raycast_vacio)
	
	# CONEXIÓN SEGURA DEL HURTBOX
	if has_node("Hurtbox"):
		if not $Hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
			$Hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _configurar_tipo_y_stats():
	var id_nodo = name.to_lower() + scene_file_path.to_lower()
	
	if "rectangulo" in id_nodo:
		tipo_enemigo = "rectangulo"
		salud = 5; velocidad = 50.0; xp_que_da = 2
		pixel_art = art_rectangulo; color_base = Color(1.0, 0.5, 0.1); color_sombra = Color(0.8, 0.3, 0.0)
	elif "pentagono" in id_nodo:
		tipo_enemigo = "pentagono"
		salud = 8; velocidad = 80.0; xp_que_da = 3
		pixel_art = art_pentagono; color_base = Color(0.6, 0.2, 0.8); color_sombra = Color(0.3, 0.1, 0.5)
	elif "hexagono" in id_nodo:
		tipo_enemigo = "hexagono"
		salud = 10; velocidad = 60.0; xp_que_da = 4
		pixel_art = art_hexagono; color_base = Color(0.2, 0.4, 1.0); color_sombra = Color(0.1, 0.2, 0.8)
	elif "heptagono" in id_nodo:
		tipo_enemigo = "heptagono"
		salud = 12; velocidad = 40.0; xp_que_da = 5
		pixel_art = art_octagono; color_base = Color(0.9, 0.1, 0.8); color_sombra = Color(0.6, 0.0, 0.5)
	elif "octagono" in id_nodo:
		tipo_enemigo = "octagono"
		salud = 15; velocidad = 30.0; xp_que_da = 6
		pixel_art = art_octagono; color_base = Color(0.8, 0.1, 0.2); color_sombra = Color(0.5, 0.0, 0.1)
	else:
		tipo_enemigo = "triangulo"
		salud = 3; velocidad = 180.0; xp_que_da = 1
		pixel_art = art_triangulo; color_base = Color(1.0, 0.9, 0.1); color_sombra = Color(0.8, 0.6, 0.0)

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
		if tipo_enemigo == "heptagono" and Engine.get_frames_drawn() % 45 == 0:
			velocity.x = randf_range(-1, 1) * velocidad_actual
		elif tipo_enemigo != "heptagono":
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
	
	# Polling para hacer daño al jugador
	if puede_hacer_daño and has_node("Hitbox"):
		for area in $Hitbox.get_overlapping_areas():
			if area.name == "Hurtbox" and area.get_parent().has_method("recibir_daño"):
				area.get_parent().recibir_daño(dano_contacto)
				puede_hacer_daño = false
				$TimerDaño.start()
				break

# --- INTELIGENCIA ARTIFICIAL Y TELEGRAFIADO ---
func _on_timer_ataque_timeout():
	if not is_instance_valid(player) or esta_detenido or congelado: return
	
	cargando_ataque = true
	var color_previo = modulate
	var tween = create_tween()
	
	if tipo_enemigo == "heptagono":
		tween.tween_property(self, "modulate", Color(2, 0, 2), 0.1).set_loops(4)
	elif tipo_enemigo == "pentagono":
		tween.tween_property(self, "scale", Vector2(1.3, 0.6), 0.4)
		modulate = Color(2, 1, 0)
	else:
		tween.tween_property(self, "modulate", Color(2.5, 2.0, 0.0), 0.4) 
		if tipo_enemigo == "triangulo":
			tween.parallel().tween_property(self, "scale", Vector2(0.6, 1.4), 0.4)
			
	await tween.finished
	if not is_inside_tree(): return
	
	_ejecutar_ataque()
	
	modulate = color_previo
	scale = Vector2.ONE
	cargando_ataque = false

func _ejecutar_ataque():
	match tipo_enemigo:
		"triangulo":
			var dir = global_position.direction_to(player.global_position)
			velocity = dir * 600.0
			move_and_slide()
			await get_tree().create_timer(0.3).timeout 
		"rectangulo":
			_disparar_balas([Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT], 300.0)
		"pentagono":
			if is_on_floor(): velocity.y = -600.0 
			var angulos = []
			for i in range(5): angulos.append(Vector2.RIGHT.rotated((i * TAU / 5) - PI/2))
			_disparar_balas(angulos, 250.0)
		"hexagono":
			var bala = proyectil_escena.instantiate()
			bala.velocidad = 600.0 
			get_tree().current_scene.add_child(bala)
			bala.global_position = global_position
			if bala.has_method("lanzar"):
				bala.lanzar(global_position.direction_to(player.global_position))
		"heptagono":
			var angulos = []
			for i in range(7): angulos.append(Vector2.RIGHT.rotated(randf_range(0, TAU)))
			_disparar_balas(angulos, randf_range(200.0, 450.0))
		"octagono":
			var angulos = []
			for i in range(8): angulos.append(Vector2.RIGHT.rotated(i * TAU / 8))
			_disparar_balas(angulos, 200.0)

func _disparar_balas(direcciones: Array, vel: float):
	for dir in direcciones:
		var b = proyectil_escena.instantiate()
		b.dano = 10
		b.velocidad = vel
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		if b.has_method("lanzar"): b.lanzar(dir)

# --- SISTEMAS DE RECEPCIÓN DE DAÑO ---

func _on_timer_daño_timeout():
	puede_hacer_daño = true

# Esta función se asegura de que cualquier bala que toque el Hurtbox haga daño
func _on_hurtbox_area_entered(area):
	if area.is_in_group("bala_jugador") or "bala" in area.name.to_lower():
		if "dano" in area:
			recibir_daño(area.dano)
		elif area.has_method("get_dano"):
			recibir_daño(area.get_dano())

# Compatibilidad por si la bala usa la N en lugar de la Ñ
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
			explosion.iniciar("triangulo", Color(1.0, 0.4, 0.0)) 
			explosion.global_position = global_position
			get_parent().add_child(explosion)
			
			explosion.iniciar("estrella", Color(1.0, 0.8, 0.0)) 
			explosion.global_position = global_position
			get_parent().add_child(explosion)
			
			explosion.iniciar("rectangulo", color_base) 
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
