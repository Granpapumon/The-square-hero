extends RigidBody2D

var valor_xp = 1

func _ready():
	linear_velocity = Vector2(randf_range(-80, 80), -300)
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.4
	physics_material_override.friction = 1.0

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("ganar_xp"):
			body.ganar_xp(valor_xp)
		queue_free()
