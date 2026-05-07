extends Area2D

var dano = 0
var velocidad = 600
var tiempo_congelacion = 2.0
var direccion_vector = Vector2.ZERO
var tiempo = 0.0
var impactado = false
var rastro_nieve: CPUParticles2D

var pixel_art = [
	"..BBBBBBBB..",
	".BEEEEEEEEB.",
	"BEEEMMMMMMEEB",
	"BEEMMCCCCMMEB",
	"BEMMCCCCCCMMEB",
	"BEMMCCCCCCMMEB",
	"BEMMCCCCCCMMEB",
	"BEMMCCCCCCMMEB",
	"BEEMMCCCCMMEB",
	"BEEEMMMMMMEEB",
	".BEEEEEEEEB.",
	"..BBBBBBBB.."
]

func _ready():
	rastro_nieve = CPUParticles2D.new()
	rastro_nieve.amount = 35
	rastro_nieve.lifetime = 0.6
	rastro_nieve.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rastro_nieve.emission_rect_extents = Vector2(5, 5)
	rastro_nieve.gravity = Vector2(0, 150)
	rastro_nieve.direction = Vector2(-1, 0)
	rastro_nieve.spread = 20.0
	rastro_nieve.initial_velocity_min = 20.0
	rastro_nieve.initial_velocity_max = 50.0
	rastro_nieve.scale_amount_min = 1.0
	rastro_nieve.scale_amount_max = 3.0
	var gradiente = Gradient.new()
	gradiente.set_color(0, Color(0.9, 0.95, 1.0, 0.8))
	gradiente.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	rastro_nieve.color_ramp = gradiente
	rastro_nieve.z_index = -1
	add_child(rastro_nieve)

func lanzar(dir):
	direccion_vector = dir

func _process(delta):
	if impactado: return
	tiempo += delta
	global_position += direccion_vector * velocidad * delta
	rotation += delta * 40.0
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
				"E": color = Color(0.1, 0.4, 0.8)
				"M": color = Color(0.4, 0.8, 1.0)
				"C": color = Color(0.9, 0.95, 1.0)
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if impactado: return
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
	if enemigo.has_method("congelar"):
		enemigo.congelar(tiempo_congelacion)
	_explotar()

func _explotar():
	impactado = true
	$CollisionShape2D.set_deferred("disabled", true)
	rastro_nieve.emitting = false
	queue_redraw()
	var fragmentos = CPUParticles2D.new()
	fragmentos.emitting = false
	fragmentos.one_shot = true
	fragmentos.explosiveness = 1.0
	fragmentos.amount = 12
	fragmentos.lifetime = 0.4
	fragmentos.spread = 180.0
	fragmentos.initial_velocity_min = 150.0
	fragmentos.initial_velocity_max = 350.0
	fragmentos.scale_amount_min = 2.0
	fragmentos.scale_amount_max = 6.0
	var grad_frag = Gradient.new()
	grad_frag.set_color(0, Color(0.9, 1.0, 1.0, 1.0))
	grad_frag.set_color(1, Color(0.4, 0.8, 1.0, 0.0))
	fragmentos.color_ramp = grad_frag
	add_child(fragmentos)
	fragmentos.emitting = true
	await get_tree().create_timer(0.6).timeout
	queue_free()
