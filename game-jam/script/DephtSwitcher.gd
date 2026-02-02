extends Area2D

@export var target_z_index: int = 20 
# Aggiungiamo una variabile per decidere CHI può attivarlo
@export var target_group: String = "FallingKick"

func _ready():
	# Collega i segnali se non lo hai fatto dall'editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _on_body_entered(body):
	check_and_switch(body)

func _on_area_entered(area):
	check_and_switch(area)

func check_and_switch(node):
	# IL FILTRO:
	# Procedi SOLO se il nodo fa parte del gruppo giusto
	if node.is_in_group(target_group):
		if "z_index" in node:
			print("Cambio Z-Index di ", node.name)
			node.z_index = target_z_index
