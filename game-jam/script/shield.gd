extends Area2D

@export var shield_health = 5  # Quanti colpi serve per romperlo
var current_shield_health = 0

@onready var anim_player = $AnimationPlayer
@onready var collision = $CollisionShape2D
@onready var health_component = get_parent().get_node("HealthComponent")

signal shield_destroyed

func _ready():
	visible = false
	collision.disabled = true

# Chiamata dal Boss per attivare lo scudo
func activate_shield():
	current_shield_health = shield_health # Resetta la vita dello scudo
	if health_component:
		health_component.is_invulnerable = true
	
	visible = true
	collision.disabled = false
	
	anim_player.play("grow")
	await anim_player.animation_finished
	
	# Ora lo scudo resta in questo loop finché non viene chiamato _deactivate()
	anim_player.play("idle_shield")

# Questa funzione deve essere chiamata dal proiettile del giocatore
func take_shield_damage(amount: int):
	current_shield_health -= amount
	print("SCUDO COLPITO! Vita rimasta: ", current_shield_health)
	
	# Effetto visivo di "colpo ricevuto" (flash o vibrazione dello scudo)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2), 0.1) # Flash luminoso
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	
	if current_shield_health <= 0:
		_deactivate()

func _deactivate():
	if health_component:
		health_component.is_invulnerable = false
	
	## Animazione di distruzione (se ne hai una "shrink" o "break")
	#if anim_player.has_animation("shrink"):
		#anim_player.play("shrink")
		#await anim_player.animation_finished
	
	hide()
	$CollisionShape2D.set_deferred("disabled", true)
	
	emit_signal("shield_destroyed")
	visible = false
	#collision.disabled = true
	shield_destroyed.emit()
	anim_player.stop()
