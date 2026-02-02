extends CanvasLayer

# Cambiamo il riferimento: non più la barra, ma il contenitore dei cuori
@onready var hearts_container = $HBoxContainer 

var player_component: HealthComponent 

func _ready():
	await get_tree().process_frame 

	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		player_component = player.get_node("HealthComponent")
		
		# Inizializziamo i cuori al primo avvio
		update_hearts(player_component.current_health)
		
		# Ci colleghiamo al segnale del danno
		player_component.on_damage.connect(_on_damage_received)
		# Ci colleghiamo anche a un eventuale segnale di cura (opzionale)
		if player_component.has_signal("on_heal"):
			player_component.on_heal.connect(_on_damage_received)
	else:
		print("ERRORE HUD: Player non trovato!")

# --- LA NUOVA LOGICA PER I CUORI ---
func update_hearts(current_health: int):
	if not hearts_container: return
	
	# Prendiamo tutti i figli (i cuori TextureRect) dell'HBoxContainer
	var hearts = hearts_container.get_children()
	
	for i in range(hearts.size()):
		# Se l'indice del cuore è minore della vita attuale, lo mostriamo
		# Esempio: Vita 2 -> Cuore 0 e 1 visibili, Cuore 2 nascosto
		if i < current_health:
			hearts[i].visible = true
		else:
			hearts[i].visible = false

# Ponte tra segnale e aggiornamento
func _on_damage_received(_amount = 0):
	if player_component:
		update_hearts(player_component.current_health)
