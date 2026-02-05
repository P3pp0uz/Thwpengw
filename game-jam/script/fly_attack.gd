class_name FlyAttack extends Area2D

@export var speed = 500.0 
@export var damage = 1
@export var knockback_force = 400.0

var has_hit_ground = false 

func _physics_process(delta):
	# Blocca movimento se ha toccato terra
	if not has_hit_ground:
		position.y += speed * delta

func _on_body_entered(body):
	# 1. IMPATTO COL PLAYER
	if body.is_in_group("Player"):
		
		if body.has_method("apply_knockback"):
				var direction = sign(body.global_position.x - global_position.x)
				if direction == 0: direction = 1
				body.apply_knockback(direction * knockback_force)

		var health = body.get_node_or_null("HealthComponent")
		if health:
			health.take_damage(damage)
			
		
		# Sparisce dopo aver colpito
		queue_free()

	# 2. IMPATTO COL PAVIMENTO
	# Ho aggiunto "StaticBody2D" per massima compatibilità
	elif (body.is_in_group("World") or body is TileMap or body is StaticBody2D) and not has_hit_ground:
		hit_ground_logic()

func hit_ground_logic():
	has_hit_ground = true
	print("STOMP! Bloccato a terra.")
	
	# Qui puoi aggiungere screen shake o suoni
	
	await get_tree().create_timer(0.5).timeout
	queue_free()
