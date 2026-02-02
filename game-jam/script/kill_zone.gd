extends Area2D

func _on_body_entered(body):
	# 1. Controlla se è il Player
	if body.is_in_group("Player"):
		print("KillZone: Player caduto!")
		
		# 2. Cerca il componente vita
		var health = body.get_node_or_null("HealthComponent")
		if health:
			# Fa solo 1 danno invece di 999
			health.take_damage(1)
			print("KillZone: Inflitto 1 danno. Vita rimanente: ", health.current_health)
			
			# 3. Se il player è ANCORA VIVO, lo teletrasportiamo
			if health.current_health > 0:
				teleport_player(body)
			# Se è morto (vita a 0), ci penserà l'HealthComponent a chiamare il Game Over
			# quindi non dobbiamo fare nulla qui.

func teleport_player(player):
	# Cerca il punto di respawn nella scena
	var respawn_point = get_tree().get_first_node_in_group("RespawnPoint")
	
	if respawn_point:
		# Teletrasporto
		player.global_position = respawn_point.global_position
		
		# IMPORTANTE: Resetta la velocità! 
		# Altrimenti il player conserva la velocità di caduta e si schianta giù di nuovo.
		player.velocity = Vector2.ZERO
		print("KillZone: Player teletrasportato al sicuro.")
	else:
		print("ERRORE: Non trovo nessun nodo nel gruppo 'RespawnPoint'!")
