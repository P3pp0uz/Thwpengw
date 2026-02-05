extends Node
class_name HealthComponent

signal on_death
signal on_damage(amount)
signal on_invincibility_changed(is_active) 

@export var max_health: int = 3
# NUOVO INTERRUTTORE: Di base è falso (così i nemici non sono invincibili)
@export var has_invincibility_frames: bool = false 

var current_health: int
var is_invincible = false
var is_invulnerable = false

func _ready():
	current_health = max_health

func take_damage(amount):
	# Se l'invincibilità è abilitata ED è attiva, ignora il danno.
	if has_invincibility_frames and is_invincible:
		return 
		
	if is_invulnerable:
		return

	current_health -= amount
	
	if current_health <= 0:
		on_death.emit()
	else:
		on_damage.emit(amount)
		
		# 2. AVVIO CONDIZIONALE
		# Diventa invincibile SOLO se l'interruttore è attivo
		if has_invincibility_frames:
			start_invincibility()

func start_invincibility():
	is_invincible = true
	on_invincibility_changed.emit(true)
	
	await get_tree().create_timer(1.0).timeout
	
	is_invincible = false
	on_invincibility_changed.emit(false)
