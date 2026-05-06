extends CharacterBody2D

# --- ESTADÍSTICAS ---
@export var velocidad = 100.0
var velocidad_base: float
@export var salud = 3
@export var dano_contacto = 10
@export var probabilidad_gema: float = 1.0
@export var xp_que_da: int = 1
var expresion = "normal"

var congelado = false
var envenenado = false
var puede_hacer_daño = true

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

@onready var gema_escena = preload("res://gema_xp.tscn")
@onready var dano_flotante_escena = preload("res://dano_flotante.tscn")

var pixel_art = []
var color_base = Color(1, 1, 1)
var color_sombra = Color(0, 0, 0)

var art_triangulo = [
	".......B.......",
	"......BEB......",
	"......BEB......",
	".....BEMEB.....",
	".....BEEEB.....",
	"....BEMMMEB....",
	"....BEEEEEB....",
	"...BEMMMMMEB...",
	"...BEEEEEEEB...",
	"..BEMMMMMMMEB..",
	"..BEEEEEEEEEB..",
	".BEMMMMMMMMMEB.",
	".BEEEEEEEEEEEB.",
	"BEMMMMMMMMMMMEB",
	"BEECCCEEECCCEEB",
	"BECDDEBEEDDEEEB",
	"BEMMMMBBBMMMMEB",
	"BEEEEEBMBEEEEEB",
	"BEMMMMMMMMMEEEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BBBBBBBBBBBBBBB"
]

var art_rectangulo = [
	"BBBBBBBBBBBBBBB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BEEEEEEEEEEEEEB",
	"BEECCCEEECCCEEB",
	"BECDDEBEEDDEEEB",
	"BEMMMMBBBMMMMEB",
	"BEEEEEBMBEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	"BBBBBBBBBBBBBBB"
]

var art_pentagono = [
	".......B.......",
	"......BEB......",
	".....BEMEB.....",
	"....BEEEEEB....",
	"...BEMMMMMEB...",
	"..BEEEEEEEEEB..",
	".BEMMCCCCCMEEB.",
	"BEEECDDDCDEEEEB",
	"BEMMMCCCCCMEEEB",
	"BEEEEEEEEEEEEEB",
	".BMMMMMMMMMMMB.",
	"..BEEEEEEEEEB..",
	"...BMMMMMMMB...",
	"....BBBBBBB...."
]

var art_hexagono = [
	"....BBBBBBB....",
	"...BEEEEEEEB...",
	"..BEMMMMMMMEB..",
	".BEEEEEEEEEEEB.",
	"BEMMCCCCCMMMEEB",
	"BEECDDDCDEEEEEB",
	"BEMMCCCCCMMMEEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	".BEEEEEEEEEEEB.",
	"..BMMMMMMMMMB..",
	"...BEEEEEEEB...",
	"....BBBBBBB...."
]

var art_octagono = [
	".....BBBBB.....",
	"...BBEEEEEBB...",
	"..BEMMMMMMMEB..",
	".BEEEEEEEEEEEB.",
	"BEMMCCCCCMMMEEB",
	"BEECDDDCDEEEEEB",
	"BEMMCCCCCMMMEEB",
	"BEEEEEEEEEEEEEB",
	"BEMMMMMMMMMMMEB",
	".BEEEEEEEEEEEB.",
	"..BMMMMMMMMMB..",
	"...BBEEEEEBB...",
	".....BBBBB....."
]

func _ready():
	velocidad_base = velocidad
	player = get_tree().get_first_node_in_group("player")
	var timer = Timer.new()
	timer.name = "TimerDaño"
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_daño_timeout)
	add_child(timer)
	var id_nodo = name.to_lower() + scene_file_path.to_lower()
	if "rectangulo" in id_nodo:
		pixel_art = art_rectangulo
		color_base = Color(1.0, 0.5, 0.1)
		color_sombra = Color(0.8, 0.3, 0.0)
	elif "pentagono" in id_nodo:
		pixel_art = art_pentagono
		color_base = Color(0.6, 0.2, 0.8)
		color_sombra = Color(0.3, 0.1, 0.5)
	elif "hexagono" in id_nodo:
		pixel_art = art_hexagono
		color_base = Color(0.2, 0.4, 1.0)
		color_sombra = Color(0.1, 0.2, 0.8)
	elif "heptagono" in id_nodo or "octagono" in id_nodo:
		pixel_art = art_octagono
		color_base = Color(0.8, 0.1, 0.2)
		color_sombra = Color(0.5, 0.0, 0.1)
	else:
		pixel_art = art_triangulo
		color_base = Color(1.0, 0.9, 0.1)
		color_sombra = Color(0.8, 0.6, 0.0)

func _physics_process(delta):
	if congelado: return
	if not is_on_floor(): velocity.y += gravedad * delta
	if player:
		var direccion = global_position.direction_to(player.global_position)
		velocity.x = velocidad if direccion.x > 0 else -velocidad
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

func recibir_daño(cantidad):
	salud -= cantidad
	expresion = "dolor"
	get_tree().create_timer(0.4).timeout.connect(func(): expresion = "normal")
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
