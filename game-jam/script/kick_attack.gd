class_name KickAttack extends Area2D

# Cambiamo il riferimento: ora ci serve il Player, non lo Sprite
@onready var animation_player = $AnimationPlayer
@onready var health_component = $HealthComponent

signal kick_died

func _ready():

	# Facciamo partire la sequenza
	animation_player.play("kick_sequence")
	
	if health_component.has_signal("on_damage"):
		health_component.on_damage.connect(_on_take_damage_visual)
	
	health_component.on_death.connect(die)

func _on_body_entered(body):
	# Questo rimane uguale: se la collisione (che ora si muove) tocca il player, fa danno.
	if body.is_in_group("Player"):
		var forza_spinta = 600.0
		var direzione_spinta = scale.x
		if body.has_method("apply_knockback"):
			body.apply_knockback(direzione_spinta * forza_spinta)
			
			
		var health = body.get_node_or_null("HealthComponent")
		if health:
			health.take_damage(1)
			
			
func _on_take_damage_visual(amount):
# 1. Crea un Tween (animazione via codice leggera)
	var tween = create_tween()
	
	# 2. Cambia il colore in ROSSO (o BIANCO) istantaneamente
	# Modulate agisce su questo nodo e tutti i figli (sprite compreso)
	modulate = Color(10, 10, 10, 1) # Valori > 1 fanno un effetto "Glow" molto luminoso (Bianco Flash)
	# Se preferisci il rosso classico usa: modulate = Color(1, 0, 0, 1)
	
	# 3. Torna al colore normale (Bianco standard) in 0.1 secondi
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
	

func die():
	kick_died.emit()
	queue_free()
