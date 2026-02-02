class_name KickAttack extends Area2D

# Cambiamo il riferimento: ora ci serve il Player, non lo Sprite
@onready var animation_player = $AnimationPlayer
@onready var health_component = $HealthComponent

signal kick_died

func _ready():

	# Facciamo partire la sequenza
	animation_player.play("kick_sequence")
	
	health_component.on_death.connect(die)

func _on_body_entered(body):
	# Questo rimane uguale: se la collisione (che ora si muove) tocca il player, fa danno.
	if body.is_in_group("Player"):
		var health = body.get_node_or_null("HealthComponent")
		if health:
			health.take_damage(1)
		if body.has_method("apply_knockback"):
			var forza_spinta = 600.0
			var direzione_spinta = scale.x
			
			body.apply_knockback(direzione_spinta * forza_spinta)

func die():
	kick_died.emit()
	queue_free()
