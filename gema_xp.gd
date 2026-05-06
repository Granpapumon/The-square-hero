extends RigidBody2D

var valor_xp = 1

# Matriz Diamante Pixel Art
var pixel_art = [
	"...BB...",
	"..BCCB..",
	".BCEEMB.",
	"BCEEMMMB",
	".BEMMMB.",
	"..BMMB..",
	"...BB..."
]

func _ready():
	linear_velocity = Vector2(randf_range(-80, 80), -300)
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.4
	physics_material_override.friction = 1.0

func _process(_delta):
	queue_redraw()

func _draw():
	# --- AUMENTADO A 6.0 PARA MEJORAR LA VISIBILIDAD ---
	var pixel_size = 6.0
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
				"C": color = Color.WHITE # Brillo puro
				"E": color = Color(0.2, 0.8, 0.4) # Verde Esmeralda
				"M": color = Color(0.1, 0.5, 0.2) # Sombra verde oscura
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("ganar_xp"):
			body.ganar_xp(valor_xp)
		queue_free()
