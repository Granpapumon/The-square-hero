extends Area2D

var velocidad = 400
var dano = 5
var direccion_vector = Vector2.ZERO
var impactado = false

var pixel_art = [
	"...BB...",
	"..BCCB..",
	".BCEEMB.",
	"BCEEMMMB",
	".BEMMMB.",
	"..BMMB..",
	"...BB..."
]

func lanzar(dir):
	direccion_vector = dir
	rotation = dir.angle()

func _process(delta):
	if impactado: return
	global_position += direccion_vector * velocidad * delta
	queue_redraw()

func _draw():
	if impactado: return
	var pixel_size = 6.0
	var offset_x = - (pixel_art[0].length() * pixel_size) / 2.0
	var offset_y = - (pixel_art.size() * pixel_size) / 2.0
	for y in range(pixel_art.size()):
		var row = pixel_art[y]
		for x in range(row.length()):
			if row[x] == ".": continue
			var color = Color.TRANSPARENT
			match row[x]:
				"B": color = Color.BLACK
				"C": color = Color(1.0, 0.5, 1.0) # Rosa claro
				"E": color = Color(0.6, 0.1, 0.8) # Morado base
				"M": color = Color(0.3, 0.0, 0.4) # Morado oscuro
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if impactado: return
	if area.name == "Hurtbox" and area.get_parent().is_in_group("player"):
		if area.get_parent().has_method("recibir_daño"):
			area.get_parent().recibir_daño(dano)
		impactado = true
		queue_free()
