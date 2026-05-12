@tool
extends CharacterBody2D

@export var salud = 250
@export var velocidad = 90.0 # Es más lento, pero más resistente
@export var dano_contacto = 20

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

var pixel_art = [
	".......BBBB.......",
	"......BCCCCB......",
	".....BCCCCCCB.....",
	"....BCCCCCCCCB....",
	"...BCCCCCCCCCCB...",
	"..BMMMMMMMMMMMMB..",
	".BMMMMMMMMMMMMMMB.",
	"BBBBBBBBBBBBBBBBBB"
]

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("elites")
	
	# Usamos el Timer que creaste manualmente
	if has_node("TimerDisparo"):
		$TimerDisparo.wait_time = 3.0
		$TimerDisparo.autostart = true
		if not $TimerDisparo.timeout.is_connected(_on_timer_disparo_timeout):
			$TimerDisparo.timeout.connect(_on_timer_disparo_timeout)
		$TimerDisparo.start()

func _physics_process(delta):
	# Evitamos que se mueva dentro del editor
	if Engine.is_editor_hint(): return 
	
	# Aplicamos gravedad (por eso aquí sí usamos delta sin guion bajo)
	if not is_on_floor():
		velocity.y += gravedad * delta

	if is_instance_valid(player):
		var direccion = global_position.direction_to(player.global_position)
		velocity.x = velocidad if direccion.x > 0 else -velocidad
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)

	move_and_slide()

func _on_timer_disparo_timeout():
	# Evitamos que dispare en el editor
	if Engine.is_editor_hint() or not is_instance_valid(player) or not is_inside_tree(): return
	
	# Ráfaga de 5 disparos rápidos en línea recta
	for i in range(5):
		var bala = proyectil_escena.instantiate()
		bala.dano = 12
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		
		if bala.has_method("lanzar"):
			bala.lanzar(global_position.direction_to(player.global_position))
			
		# Pequeña pausa entre cada bala de la ráfaga
		await get_tree().create_timer(0.15).timeout

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
				"C": color = Color(0.8, 0.4, 0.1) # Naranja quemado/óxido
				"M": color = Color(0.4, 0.2, 0.05)
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)
