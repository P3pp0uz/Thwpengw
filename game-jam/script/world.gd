extends Node2D

@onready var player = $Player # Assicurati che il nodo si chiami Player
@onready var hud = $HUD

func _ready():
	# 1. Inizializza la barra con la vita attuale del player
	var health_comp = player.get_node("HealthComponent")
	hud.update_health(health_comp.current_health, health_comp.max_health)
	
	# 2. Collega il segnale 'on_damage' del componente all'HUD
	# Nota: Dobbiamo passare i nuovi valori all'HUD quando il segnale scatta
	health_comp.on_damage.connect(_on_player_damage)
	
	# 3. Gestione Game Over
	health_comp.on_death.connect(_on_player_death)

func _on_player_damage(amount):
	var health_comp = player.get_node("HealthComponent")
	hud.update_health(health_comp.current_health, health_comp.max_health)

func _on_player_death():
	print("Game Over!")
	# Ricarica la scena corrente dopo un frame
	call_deferred("reload_scene")

func reload_scene():
	get_tree().reload_current_scene()
