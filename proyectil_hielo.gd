extends Area2D

var dano = 0
var velocidad = 600
var tiempo_congelacion = 2.0
var direccion_vector = Vector2.ZERO
var tiempo = 0.0
var impactado = false
var rastro_nieve: CPUParticles2D

# Cubo de Hielo Pixel Art
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
	# --- ESTELA DE NIEVE QUE CAE ---
	rastro_nieve = CPUParticles2D.new()
	rastro_nieve.amount = 35 # Cantidad de copos
	rastro_nieve.lifetime = 0.6 
	# Hacemos que salgan en forma de caja, no de punto
	rastro_nieve.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rastro_nieve.emission_rect_extents = Vector2(5, 5)
	
	# GRAVEDAD: Esto es clave. Hace que los copos caigan hacia abajo (el suelo) 
	# mientras el proyectil sigue volando recto.
	rastro_nieve.gravity = Vector2(0, 150) 
	
	rastro_nieve.direction = Vector2(-1, 0)
	rastro_nieve.spread = 20.0 
	rastro_nieve.initial_velocity_min = 20.0
	rastro_nieve.initial_velocity_max = 50.0
	rastro_nieve.scale_amount_min = 1.0
	rastro_nieve.scale_amount_max = 3.0
	
	# Gradiente: De blanco hielo a transparente
	var gradiente = Gradient.new()
	gradiente.set_color(0, Color(0.9, 0.95, 1.0, 0.8)) 
	gradiente.set_color(1, Color(1.0, 1.0, 1.0, 0.0)) 
	rastro_nieve.color_ramp = gradiente
	
	rastro_nieve.z_index = -1
	add_child(rastro_nieve)

func lanzar(dir):
	direccion_vector = dir
	# A diferencia del fuego, aquí NO igualamos la rotación a la dirección,
	# porque queremos que el cubo gire sobre su propio eje libremente.

func _process(delta):
	if impactado:
		return
		
	tiempo += delta
	global_position += direccion_vector * velocidad * delta
	
	# ANIMACIÓN DE ROTACIÓN: El cubo va dando vueltas rápidas en el aire
	rotation += delta * 40.0 
	queue_redraw()

func _draw():
	if impactado: return
	
	var pixel_size = 3.5
	var offset_x = - (pixel_art[0].length() * pixel_size) / 2.0
	var offset_y = - (pixel_art.size() * pixel_size) / 2.0
	
	for y in range(pixel_art.size()):
		var row = pixel_art[y]
		for x in range(row.length()):
			var letra = row[x]
			if letra == ".": continue
			
			var color = Color.TRANSPARENT
			match letra:
				"B": color = Color.BLACK
				"E": color = Color(0.1, 0.4, 0.8) # Borde Azul Hielo
				"M": color = Color(0.4, 0.8, 1.0) # Medio Celeste
				"C": color = Color(0.9, 0.95, 1.0) # Reflejo Blanco
			
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if impactado:
		return
		
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
		
	if enemigo.has_method("congelar"):
		enemigo.congelar(tiempo_congelacion)
		
	_explotar()

# --- EXPLOSIÓN (Fragmentos de cristal) ---
func _explotar():
	impactado = true
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Detenemos la nieve suave y borramos el cubo
	rastro_nieve.emitting = false
	queue_redraw()
	
	# Creamos chispas que simulan pedazos de hielo rompiéndose violentamente
	var fragmentos = CPUParticles2D.new()
	fragmentos.emitting = false
	fragmentos.one_shot = true
	fragmentos.explosiveness = 1.0
	fragmentos.amount = 12 # Pocos pedazos, pero grandes
	fragmentos.lifetime = 0.4
	fragmentos.spread = 180.0
	fragmentos.initial_velocity_min = 150.0
	fragmentos.initial_velocity_max = 350.0 # Salen disparados muy rápido
	fragmentos.scale_amount_min = 2.0
	fragmentos.scale_amount_max = 6.0
	
	# Gradiente de los fragmentos: Blanco intenso que se vuelve azul pálido
	var grad_frag = Gradient.new()
	grad_frag.set_color(0, Color(0.9, 1.0, 1.0, 1.0))
	grad_frag.set_color(1, Color(0.4, 0.8, 1.0, 0.0))
	fragmentos.color_ramp = grad_frag
	
	add_child(fragmentos)
	fragmentos.emitting = true
	
	await get_tree().create_timer(0.6).timeout
	queue_free()
