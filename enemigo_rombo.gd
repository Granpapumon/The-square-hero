extends CharacterBody2D

@export var salud = 180 # Más vida por ser un Élite
@export var velocidad = 115.0
@export var dano_contacto = 15

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

# Cargamos el proyectil estándar, pero lo modificaremos al disparar
@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

var pixel_art = [
	"........BB........",
	".......BCCB.......",
	"......BCCCCB......",
	".....BCCCCCCB.....",
	"....BCCCCCCCCB....",
	"...BCCCCCCCCCCB...",
	"..BCCCCCCCCCCCCB..",
	".BCCCCCCCCCCCCCCB.",
	"BCCCCCCCCCCCCCCCCB",
	".BCCCCCCCCCCCCCCB.",
	"..BCCCCCCCCCCCCB..",
	"...BCCCCCCCCCCB...",
	"....BCCCCCCCCB....",
	".....BCCCCCCB.....",
	"......BCCCCB......",
	".......BCCB.......",
	"........BB........"
]

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("elites")
	
	# Le decimos al código que use el TimerDisparo que tú creaste en el editor
	if has_node("TimerDisparo"):
		$TimerDisparo.wait_time = 2.5
		$TimerDisparo.autostart = true
		
		# Conectamos la señal por código para que no tengas que hacerlo a mano
		if not $TimerDisparo.timeout.is_connected(_on_timer_disparo_timeout):
			$TimerDisparo.timeout.connect(_on_timer_disparo_timeout)
		
		$TimerDisparo.start()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravedad * delta

	if is_instance_valid(player):
		var direccion = global_position.direction_to(player.global_position)
		velocity.x = velocidad if direccion.x > 0 else -velocidad
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)

	move_and_slide()

func _on_timer_disparo_timeout():
	if not is_instance_valid(player) or not is_inside_tree(): return

	# Calculamos la dirección central hacia el jugador
	var direccion_base = global_position.direction_to(player.global_position)
	var angulo_base = direccion_base.angle()

	# Disparo en abanico: 3 ángulos distintos (Centro, Arriba, Abajo)
	var angulos = [angulo_base - 0.4, angulo_base, angulo_base + 0.4]

	for angulo in angulos:
		var bala = proyectil_escena.instantiate()
		bala.dano = 10
		# Hacemos las balas un poco más pequeñas para que el jugador tenga espacio para esquivar
		bala.scale = Vector2(0.8, 0.8) 
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position

		if bala.has_method("lanzar"):
			# Convertimos el ángulo de vuelta a un Vector2 de dirección
			bala.lanzar(Vector2.RIGHT.rotated(angulo))

func recibir_daño(cantidad):
	salud -= cantidad
	if salud <= 0:
		queue_free()

func _on_hitbox_area_entered(area):
	if area.name == "Hurtbox":
		var victima = area.get_parent()
		if victima.is_in_group("player"):
			if victima.has_method("recibir_dano"):
				victima.recibir_dano(dano_contacto)
			elif victima.has_method("recibir_daño"):
				victima.recibir_daño(dano_contacto)

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
				# Un color cian o verde agua para empezar a dar ese toque marítimo oscuro
				"C": color = Color(0.1, 0.8, 0.7) 
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)
