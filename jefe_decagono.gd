@tool
extends CharacterBody2D

@export var salud = 1500
@export var velocidad = 110.0
@export var dano_contacto = 45
@export var fuerza_salto = -700.0

var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

var en_furia = false
var angulo_espiral = 0.0
var tiempo_furia = 0.0

@onready var proyectil_escena = preload("res://proyectil_enemigo.tscn")

# --- ARTE PIXEL: DECÁGONO IRREGULAR E INESTABLE ---
var pixel_art = [
	"........BBBB........", 
	"......BBCCCCBB......",
	".....BCCCCCCCCB.....", 
	"...BBCCCCCCCCCCBB...", 
	"..BCCCCCCCCCCCCCCB..",
	".BCCCCCCCCCCCCCCCCB.",
	"BCCCCCCCCCCCCCCCCCCB", 
	"BCCCCCCCCCCCCCCCCCCB",
	".BCCCCCCCCCCCCCCCCB.",
	"..BBCCCCCCCCCCCCCCCB", 
	"....BCCCCCCCCCCCCCCB",
	".....BCCCCCCCCCCCCB.",
	"...BBCCCCCCCCCCCCB..", 
	"..BCCCCCCCCCCCCCB...",
	".BCCCCCCCCCCCCBB....", 
	"..BBCCCCCCCCCB......",
	"....BBCCCCCCB.......", 
	"......BCCCCBB.......",
	".......BCCCB........", 
	"........BBB........."  
]

func _ready():
	player = get_tree().get_first_node_in_group("player")
	add_to_group("jefe")
	
	if has_node("TimerDisparo"):
		$TimerDisparo.wait_time = 1.8
		$TimerDisparo.autostart = true
		if not $TimerDisparo.timeout.is_connected(_on_timer_disparo_timeout):
			$TimerDisparo.timeout.connect(_on_timer_disparo_timeout)
		$TimerDisparo.start()
		
	if has_node("TimerMovimiento"):
		$TimerMovimiento.wait_time = 3.0
		$TimerMovimiento.autostart = true
		if not $TimerMovimiento.timeout.is_connected(_on_timer_movimiento_timeout):
			$TimerMovimiento.timeout.connect(_on_timer_movimiento_timeout)
		$TimerMovimiento.start()

func _physics_process(delta):
	if Engine.is_editor_hint(): return
	
	if en_furia:
		tiempo_furia += delta
		queue_redraw()

	if not is_on_floor():
		velocity.y += gravedad * delta

	# Movimiento pesado y errático
	if is_instance_valid(player) and is_on_floor():
		var direccion = global_position.direction_to(player.global_position)
		var variacion = sin(Time.get_ticks_msec() * 0.003) * 30.0
		velocity.x = move_toward(velocity.x, (velocidad + variacion) * sign(direccion.x), 10.0)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, velocidad)

	move_and_slide()

# --- ACTUALIZADO: SALTO CON TELEGRAFIADO SQUASH ---
func _on_timer_movimiento_timeout():
	if Engine.is_editor_hint() or not is_inside_tree() or not is_on_floor(): return
	if not is_instance_valid(player): return
	
	# 1. AVISO VISUAL (Se aplasta tomando impulso)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 0.75), 0.35)
	await tween.finished
	if not is_inside_tree(): return
	scale = Vector2.ONE
	
	# 2. ACCIÓN (Embestida pesada)
	var direccion = sign(player.global_position.x - global_position.x)
	velocity.x = velocidad * 3.0 * direccion
	velocity.y = fuerza_salto * (0.85 if en_furia else 1.0)

# --- ACTUALIZADO: DISPARO CON TELEGRAFIADO ADAPTATIVO ---
func _on_timer_disparo_timeout():
	if Engine.is_editor_hint() or not is_inside_tree(): return
	
	# 1. AVISO VISUAL 
	var color_original = modulate
	
	if not en_furia:
		# Fase 1: Telegrafiado largo con temblor para dar tiempo a esquivar
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(2.5, 1.5, 0.0), 0.3)
		
		var pos_original = position
		for i in range(3):
			position.x = pos_original.x + randf_range(-6, 6)
			await get_tree().create_timer(0.1).timeout
			if not is_inside_tree(): return
		position = pos_original
		self.modulate = color_original
	else:
		# Fase 2 (Espiral): Micropulso de luz
		self.modulate = Color(2.5, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree(): return
		self.modulate = color_original
	
	# 2. ACCIÓN (Generación de balas decagonales)
	var cantidad_balas = 10
	var angulo_base = TAU / cantidad_balas
	
	if en_furia:
		angulo_espiral += 0.35 
	else:
		angulo_espiral = 0.0
	
	for i in range(cantidad_balas):
		var bala = proyectil_escena.instantiate()
		bala.dano = 15
		
		var variacion_irregular = randf_range(-0.15, 0.15) if not en_furia else 0.0
		
		if en_furia:
			bala.modulate = Color(1, 0, 0)
			bala.velocidad = 300.0 
		else:
			bala.modulate = Color(0.8, 0.2, 0.2)
			
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		
		if bala.has_method("lanzar"):
			var angulo_final = (i * angulo_base) + angulo_espiral + variacion_irregular
			var direccion_bala = Vector2.RIGHT.rotated(angulo_final)
			var mod_velocidad = randf_range(0.9, 1.1) if not en_furia else 1.0
			bala.lanzar(direccion_bala * mod_velocidad)

# --- CORRECCIÓN: Feedback visual seguro con Tween ---
func recibir_daño(cantidad):
	salud -= cantidad
	
	var tween = create_tween()
	modulate = Color(3.0, 3.0, 3.0) # Brilla en blanco por un instante
	
	# Regresa a su color normal o al rojo furia dependiendo de la fase
	var color_normal = Color(1, 1, 1) if not en_furia else Color(1, 0.2, 0.2)
	tween.tween_property(self, "modulate", color_normal, 0.05)
	
	# --- FASE 2: ESPIRAL AL 50% (750 HP) ---
	if salud <= 750 and not en_furia:
		en_furia = true
		if has_node("TimerDisparo"):
			$TimerDisparo.wait_time = 0.4 
			
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud:
			hud.mostrar_mensaje("⚠ ¡FORMA DECAGONAL COLAPSANDO! ⚠")

	if salud <= 0:
		var mundo = get_tree().get_first_node_in_group("mundo")
		if mundo and mundo.has_method("jefe_derrotado"): 
			mundo.jefe_derrotado()
		queue_free()

func _on_hitbox_area_entered(area):
	if area.name == "Hurtbox":
		var victima = area.get_parent()
		if victima.is_in_group("player") and victima.has_method("recibir_daño"):
			victima.recibir_daño(dano_contacto)

func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()

func _draw():
	var pixel_size = 10.0
	var offset_x = -(pixel_art[0].length() * pixel_size) / 2.0
	var offset_y = -(pixel_art.size() * pixel_size) / 2.0
	
	var color_borde = Color.BLACK
	if en_furia and fmod(tiempo_furia * 10.0, 2.0) < 1.0:
		color_borde = Color(1, 0, 0)
	
	for y in range(pixel_art.size()):
		var row = pixel_art[y]
		for x in range(row.length()):
			var letra = row[x]
			if letra == ".": continue
			var color = Color.TRANSPARENT
			match letra:
				"B": color = color_borde
				"C": color = Color(0.25, 0.1, 0.1) 
			
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)
