extends Area2D

var velocidad = 600
var dano = 1
var direccion_vector = Vector2.ZERO
var tiempo = 0.0
var impactado = false
var rastro_ki: CPUParticles2D

# --- MAPA DE PIXEL ART (Estilo Hadouken Street Fighter) ---
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
	# --- ESTELA DE ENERGÍA KI ---
	rastro_ki = CPUParticles2D.new()
	rastro_ki.amount = 30 
	rastro_ki.lifetime = 0.25 # Muy corto, para que se vea rápido
	rastro_ki.gravity = Vector2.ZERO
	
	# Dispara el Ki hacia atrás
	rastro_ki.direction = Vector2(-1, 0)
	rastro_ki.spread = 15.0 
	rastro_ki.initial_velocity_min = 80.0
	rastro_ki.initial_velocity_max = 150.0
	rastro_ki.scale_amount_min = 10.0
	rastro_ki.scale_amount_max = 15.0
	
	# Gradiente: Blanco brillante a Azul Cian transparente
	var gradiente = Gradient.new()
	gradiente.set_color(0, Color(1.0, 1.0, 1.0, 1.0)) # Blanco
	gradiente.set_color(1, Color(0.0, 0.5, 1.0, 0.0)) # Cian transparente
	rastro_ki.color_ramp = gradiente
	
	rastro_ki.z_index = -1
	add_child(rastro_ki)

func lanzar(dir):
	direccion_vector = dir
	rotation = dir.angle()

func _process(delta):
	if impactado:
		return
		
	tiempo += delta
	global_position += direccion_vector * velocidad * delta
	
	# El Hadouken parpadea y tiembla muy rápido por la energía inestable
	scale = Vector2.ONE * randf_range(0.85, 1.15)
	queue_redraw()

func _draw():
	if impactado: return
	
	var pixel_size = 3.5 # Tamaño de cada "cuadrito"
	var offset_x = - (pixel_art[0].length() * pixel_size) / 2.0
	var offset_y = - (pixel_art.size() * pixel_size) / 2.0
	
	for y in range(pixel_art.size()):
		var row = pixel_art[y]
		for x in range(row.length()):
			var letra = row[x]
			if letra == ".": continue
			
			var color = Color.TRANSPARENT
			match letra:
				"B": color = Color.BLACK # Borde
				"E": color = Color(0.1, 0.3, 0.8) # Borde Azul Oscuro
				"M": color = Color(0.2, 0.8, 1.0) # Medio Azul Claro/Cian
				"C": color = Color(1.0, 1.0, 1.0) # Núcleo Blanco Puro
			
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if impactado:
		return
		
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
		
	if enemigo.has_method("recibir_daño"):
		enemigo.recibir_daño(dano)
		
	_explotar()

# --- EXPLOSIÓN DE KI AL IMPACTAR ---
func _explotar():
	impactado = true
	$CollisionShape2D.set_deferred("disabled", true)
	
	if is_instance_valid(rastro_ki):
		rastro_ki.emitting = false
		
	queue_redraw()
	
	# Estallido de chispas de energía cian
	var impacto_ki = CPUParticles2D.new()
	impacto_ki.emitting = false
	impacto_ki.one_shot = true
	impacto_ki.explosiveness = 1.0 
	impacto_ki.amount = 20
	impacto_ki.lifetime = 0.3
	impacto_ki.spread = 180.0
	impacto_ki.initial_velocity_min = 150.0
	impacto_ki.initial_velocity_max = 300.0 
	impacto_ki.scale_amount_min = 2.0
	impacto_ki.scale_amount_max = 5.0
	
	# Pasa de blanco a azul cian intenso
	var grad_impacto = Gradient.new()
	grad_impacto.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad_impacto.set_color(1, Color(0.0, 0.4, 1.0, 0.0))
	impacto_ki.color_ramp = grad_impacto
	
	add_child(impacto_ki)
	impacto_ki.emitting = true
	
	await get_tree().create_timer(0.4).timeout
	queue_free()
