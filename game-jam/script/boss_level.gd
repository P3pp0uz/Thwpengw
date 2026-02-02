extends Node2D

@onready var player = $Player
# Aggiungi il riferimento all'HUD
@onready var hud = $HUD 

func _ready():
	# 1. Trova il componente salute
	var health_comp = player.get_node("HealthComponent")
	
	# 2. Inizializza la barra con la vita attuale (es. 10/10)
	hud.update_health(health_comp.current_health, health_comp.max_health)
	
	# 3. Collega i segnali
	health_comp.on_death.connect(_on_player_death)
	health_comp.on_damage.connect(_on_player_damage) # <--- NUOVO COLLEGAMENTO

# Quando il player viene colpito, aggiorna la barra
func _on_player_damage(amount):
	var health_comp = player.get_node("HealthComponent")
	hud.update_health(health_comp.current_health, health_comp.max_health)

func _on_player_death():
	print("MORTALE! Il player è caduto o morto.")
	call_deferred("reload_scene")

func reload_scene():
	get_tree().reload_current_scene()
