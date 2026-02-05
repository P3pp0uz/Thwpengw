class_name SoccerPlayer extends CharacterBody2D

@export var speed = 300.0
@export var damage = 1
@export var knockback_force = 400.0

var direction = 0 
var gravity = 980

# NUOVA VARIABILE: All'inizio è falsa, quindi è immortale contro i muri
var can_die_on_wall = false 

func _ready():
	$AnimatedSprite2D.play("run")
	
	# Se esiste il notifier, lo colleghiamo
	if has_node("VisibleOnScreenNotifier2D"):
		if not $VisibleOnScreenNotifier2D.screen_exited.is_connected(_on_screen_exited):
			$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	
	if direction == -1:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false

	# --- IL TRUCCO ---
	# Aspettiamo 0.5 secondi prima di attivare la morte sui muri.
	# In questo modo ha il tempo di uscire dal muro di spawn.
	await get_tree().create_timer(0.5).timeout
	can_die_on_wall = true

func _physics_process(delta):
	if direction == 0: return

	# 1. GRAVITÀ
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. MOVIMENTO
	velocity.x = direction * speed
	
	move_and_slide()
	
	# 3. CONTROLLO MURO SICURO
	# Muore SOLO se sta toccando un muro E se è passato il tempo di grazia
	if is_on_wall() and can_die_on_wall:
		queue_free()

# --- GESTIONE DANNO ---
func _on_hitbox_body_entered(body):
	if body.is_in_group("Player"):
		var health = body.get_node_or_null("HealthComponent")
		if body.has_method("apply_knockback"):
				body.apply_knockback(direction * knockback_force)
		if health:
			health.take_damage(damage)
			

func _on_screen_exited():
	queue_free()
