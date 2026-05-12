@tool
extends CharacterBody2D

@export var salud = 350
@export var velocidad = 150.0 # Muy rápido y escurridizo
@export var dano_contacto = 25

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

# Arte de un círculo perfecto
var pixel_art = [
	"......BBBBBB......",
	"....BBCCCCCCBB....",
	"...BCCCCCCCCCCB...",
	"..BCCCCCCCCCCCCB..",
	".BCCCCCCCCCCCCCCB.",
	".BCCCCCCCCCCCCCCB.",
	"BCCCCCCCCCCCCCCCCB",
	"BCCCCCCCCCCCCCCCCB",
	"BCCCCCCCCCCCCCCCCB",
	"BCCCCCCCCCCCCCCCCB",
	".BCCCCCCCCCCCCCCB.",
	".BCCCCCCCCCCCCCCB.",
	"..BCCCCCCCCCCCCB..",
	"...BCCCCCCCCCCB...",
	"....BBCCCCCCBB....",
	"......BBBBBB......"
]

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("elites")
	
	if has_node("TimerDisparo"):
		$TimerDisparo.wait_time = 2.0
		$TimerDisparo.autostart = true
		if not $TimerDisparo.timeout.is_connected(_on_timer_disparo_timeout):
			$TimerDisparo.timeout.connect(_on_timer_disparo_timeout)
		$TimerDisparo.start()

func _physics_process(delta):
	if Engine.is_editor_hint(): return 
	
	if not is_on_floor():
		velocity.y += gravedad * delta

	if is_instance_valid(player):
		var direccion = global_position.direction_to(player.global_position)
		velocity.x = velocidad * sign(direccion.x)
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)

	move_and_slide()

func _on_timer_disparo_timeout():
	if Engine.is_editor_hint() or not is_inside_tree(): return
	
	# Pulso Radial: 8 direcciones simultáneas
	var cantidad_balas = 8
	var angulo_separacion = TAU / cantidad_balas
	
	for i in range(cantidad_balas):
		var bala = proyectil_escena.instantiate()
		bala.dano = 15
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		
		if bala.has_method("lanzar"):
			var direccion_bala = Vector2.RIGHT.rotated(i * angulo_separacion)
			bala.lanzar(direccion_bala)

func recibir_daño(cantidad):
	salud -= cantidad
	if salud <= 0: queue_free()

func _on_hitbox_area_entered(area):
	if area.name == "Hurtbox":
		var victima = area.get_parent()
		if victima.is_in_group("player") and victima.has_method("recibir_daño"):
			victima.recibir_daño(dano_contacto)

func _process(_delta):
	queue_redraw()

func _draw():
	var pixel_size = 10.0
	var offset_x = -(pixel_art[0].length() * pixel_size) / 2.0
	var offset_y = -(pixel_art.size() * pixel_size) / 2.0
	
	for y in range(pixel_art.size()):
		var row = pixel_art[y]
		for x in range(row.length()):
			var letra = row[x]
			if letra == ".": continue
			var color = Color.TRANSPARENT
			match letra:
				"B": color = Color.BLACK
				"C": color = Color(0.9, 0.1, 0.3) # Rojo carmesí
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)
