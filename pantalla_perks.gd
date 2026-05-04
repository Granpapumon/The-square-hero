extends CanvasLayer

func _ready():
	get_tree().paused = true

func _aplicar_perk(nombre: String):
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador:
		jugador.activar_perk(nombre)
	get_tree().paused = false
	hide()

func _on_boton_dash_pressed():        _aplicar_perk("dash")
func _on_boton_salto_doble_pressed(): _aplicar_perk("salto_doble")
func _on_boton_vida_doble_pressed():  _aplicar_perk("vida_doble")
func _on_boton_rango_pressed():       _aplicar_perk("rango")


func _on_dash_pressed() -> void:
	pass # Replace with function body.


func _on_salto_doble_pressed() -> void:
	pass # Replace with function body.


func _on_vida_doble_pressed() -> void:
	pass # Replace with function body.


func _on_rango_pressed() -> void:
	pass # Replace with function body.
