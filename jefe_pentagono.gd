extends CharacterBody2D

@export var salud = 500
@export var velocidad = 100.0
@export var dano_contacto = 30

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null
var saltando = false

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

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravedad * delta
	if is_instance_valid(player) and not saltando:
		var direccion = global_position.direction_to(player.global_position)
		velocity.x = velocidad if direccion.x > 0 else -velocidad
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)
	move_and_slide()

func recibir_daño(cantidad):
	if randf() <= 0.30:
		modulate = Color(1, 1, 1, 0.5)
		await get_tree().create_timer(0.2).timeout
		if not is_inside_tree():
			return
		modulate = Color(1, 1, 1, 1)
		return
	salud -= cantidad
	if salud <= 0:
		var mundo = get_tree().get_first_node_in_group("mundo")
		if mundo:
			mundo.jefe_derrotado()
		queue_free()

func _on_timer_salto_timeout():
	saltando = true
	var direccion_azar = Vector2(randf_range(-1, 1), -1).normalized()
	velocity = direccion_azar * (velocidad * 4)
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		return
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
