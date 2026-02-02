extends HBoxContainer

# Trascina qui i tuoi 3 cuori dall'albero delle scene
@onready var hearts = get_children()

func update_hearts(current_health: int):
	# Cicliamo su tutti i cuori che abbiamo nell'HBoxContainer
	for i in range(hearts.size()):
		# Se l'indice è minore della vita attuale, mostra il cuore, altrimenti nascondilo
		if i < current_health:
			hearts[i].visible = true
		else:
			hearts[i].visible = false
