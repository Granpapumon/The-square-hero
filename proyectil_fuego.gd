extends Area2D

var velocidad = 600
var dano = 2
var direccion_vector = Vector2.ZERO
var tiempo = 0.0
var impactado = false
var rastro_fuego: CPUParticles2D

var pixel_art = [
	"......BBBB......",
	"....BBEEEEBB....",
	"...BEEEEMMMBB...",
	"..BEEEMMCCCCBB..",
	"BBEEEMCCCCCCCB..",
	"BEEMMCCCCCCCCB..",
	"BEMMCCCCCCCCCB..",
	"BEEMCCCCCCCCCB..",
	"BEMMCCCCCCCCCB..",
	"BEEMMCCCCCCCCB..",
	"BBEEEMCCCCCCCB..",
	"..BEEEMMCCCCBB..",
	"...BEEEEMMMBB...",
	"....BBEEEEBB....",
	"......BBBB......"
]

func _ready():
	rastro_fuego = CPUParticles2D.new()
	rastro_fuego.amount = 200
	rastro_fuego.lifetime = 0.5
	rastro_fuego.gravity = Vector2.ZERO
	rastro_fuego.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	rastro_fuego.emission_sphere_radius = 20.0
	rastro_fuego.direction = Vector2(-1, 0)
	rastro_fuego.spread = 25.0
	rastro_fuego.initial_velocity_min = 50.0
	rastro_fuego.initial_velocity_max = 120.0
	rastro_fuego.scale_amount_min = 2.0
	rastro_fuego.scale_amount_max = 7.0
	var gradiente = Gradient.new()
	gradiente.set_color(0, Color(1.0, 0.9, 0.0, 1.0))
	gradiente.set_color(1, Color(1.0, 0.1, 0.0, 0.0))
	rastro_fuego.color_ramp = gradiente
	rastro_fuego.z_index = -1
	add_child(rastro_fuego)

func lanzar(dir):
	direccion_vector = dir
	rotation = dir.angle()

func _process(delta):
	if impactado: return
	tiempo += delta
	global_position += direccion_vector * velocidad * delta
	scale = Vector2.ONE * randf_range(0.9, 1.1)
	queue_redraw()

func _draw():
	if impactado: return
	var pixel_size = 3.5
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
				"E": color = Color(0.8, 0.1, 0.1)
				"M": color = Color(1.0, 0.5, 0.0)
				"C": color = Color(1.0, 0.9, 0.0)
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if impactado: return
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
	if enemigo.has_method("recibir_daño"):
		enemigo.recibir_daño(dano)
	_explotar()

func _explotar():
	impactado = true
	$CollisionShape2D.set_deferred("disabled", true)
	rastro_fuego.emitting = false
	queue_redraw()
	var chispas = CPUParticles2D.new()
	chispas.emitting = false
	chispas.one_shot = true
	chispas.explosiveness = 1.0
	chispas.amount = 20
	chispas.lifetime = 0.35
	chispas.spread = 180.0
	chispas.initial_velocity_min = 100.0
	chispas.initial_velocity_max = 250.0
	chispas.scale_amount_min = 3.0
	chispas.scale_amount_max = 6.0
	var grad_chispa = Gradient.new()
	grad_chispa.set_color(0, Color(1.0, 0.5, 0.0, 1.0))
	grad_chispa.set_color(1, Color(0.5, 0.1, 0.0, 0.0))
	chispas.color_ramp = grad_chispa
	add_child(chispas)
	chispas.emitting = true
	await get_tree().create_timer(0.4).timeout
	queue_free()
