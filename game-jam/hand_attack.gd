class_name HandAttack extends Area2D

@export var damage = 1
@export var drop_speed = 800.0
@export var warning_time = 1.0 

var target_y = 0.0 
var state = "aiming" # Stati possibili: aiming, dropping, landed

@onready var anim_sprite = $AnimatedSprite2D # Assicurati che il nodo si chiami così!
@onready var anim_player = $AnimationPlayer # 

func _ready():
	anim_player.speed_scale = 2.0
	# 1. SETUP: Calcoliamo dove cadere
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		# Ci allineiamo al player
		global_position.x = player.global_position.x
		# Memorizziamo l'altezza del player (aggiungiamo 20px per arrivare ai piedi)
		target_y = player.global_position.y + 20
	else:
		# Fallback se non trova il player: cade fino a Y=500 (ad esempio)
		target_y = 500.0

	# 2. FASE PREPARAZIONE (Warning)
	print("MANO: Inizio fase mira (Warning)")
	
	# Animazione di "Mira/Attesa"
	if anim_player:
		anim_player.play("attack")
		print("animazione avviata")
	else:
		print("ERRORE: AnimationPlayer non trovato!")
		
		
	modulate.a = 0.5 # Semitrasparente
	
	# Aspettiamo il tempo di warning
	await get_tree().create_timer(warning_time).timeout
	
	_start_drop()

func _start_drop():
	# 3. INIZIO CADUTA
	print("MANO: Inizio caduta!")
	state = "dropping"
	modulate.a = 1.0 # Solida


func _physics_process(delta):
	if state == "dropping":
		position.y += drop_speed * delta
		# Quando raggiunge il target, smette di muoversi ma NON sparisce subito
		if position.y >= target_y:
			position.y = target_y # Blocca la posizione
			_check_completion()

func _check_completion():
	if state == "landed": return
	state = "landed"
	
	print("MANO: Atterrata, aspetto che finisca di chiudersi...")
	
	# Aspetta che l'animazione (e quindi i frame finali della chiusura) finisca
	if anim_player.is_playing():
		await anim_player.animation_finished
	
	queue_free()

func _hit_ground():
	if state == "landed": return 
	state = "landed"
	
	print("MANO: Impatto a terra!")
	
	# Aspettiamo che l'animazione finisca i frame di "chiusura"
	if anim_player.is_playing():
		await anim_player.animation_finished
	
	# DISATTIVA le collisioni manualmente prima di eliminare l'oggetto
	# per sicurezza, così non può più colpire durante il frame di rimozione
	$CollisionShape2D.set_deferred("disabled", true)
	
	print("MANO: Rimozione oggetto")
	queue_free()

func _on_body_entered(body):
	# Fa danno solo se sta cadendo o è appena atterrata
	if state == "aiming": return

	if body.is_in_group("Player"):
		var health = body.get_node_or_null("HealthComponent")
		if health:
			health.take_damage(damage)
