extends CharacterBody2D

@onready var animated_sprite = $Visuals/AnimatedSprite2D
@onready var visuals = $Visuals
@onready var default_muzzle_x = abs($MuzzleLeft.position.x)
@export var speed = 200.0
@export var jump_velocity = -300.0
@export var projectile_scene: PackedScene
@onready var shoot_timer = $ShootTimer 
@onready var shoot_sound = $ShootSound
@export var fire_rate: float = 0.2
var fire_cooldown: float = 0.0
var is_invincible_active: bool = false
@export var dash_speed = 1000.0
@export var dash_duration = 0.2
@export var dash_cooldown = 1.0

var knockback_power = 500.0
var is_dashing = false
var can_dash_timer = true

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
# Assicurati di avere il riferimento al componente
@onready var health_component = $HealthComponent

var can_move = true

func _ready():
	health_component.on_invincibility_changed.connect(_on_invincibility_changed)
	# 1. Collega il segnale di morte alla funzione die()
	health_component.on_death.connect(die)
	
func _on_invincibility_changed(is_active):
	is_invincible_active = is_active
	if is_active:
		# Diventa semi-trasparente (Alpha = 0.5)
		modulate.a = 0.5 
		
		# (Opzionale) Disabilita collisioni con i nemici se vuoi passarci attraverso
		# set_collision_layer_value(1, false) 
	else:
		# Torna opaco (Alpha = 1.0)
		modulate.a = 1.0 
		# Reset del colore bianco puro (per togliere eventuali residui rossi del danno)
		modulate = Color(1, 1, 1, 1)

func die():
	print("Il Player è morto! Riavvio la scena...")
	
	$CollisionShape2D.set_deferred("disabled", true)
	
	call_deferred("riavvia_partita")

# Funzione per ricaricare la scena corrente
func riavvia_partita():
	# Ricarica la scena attiva (fa ripartire il livello da capo)
	get_tree().reload_current_scene()

func _physics_process(delta):
	
	if not is_on_floor() and not is_dashing:
		#position += transform.x * speed * delta
		velocity.y += gravity * delta

	if fire_cooldown > 0:
		fire_cooldown -= delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	if Input.is_action_pressed("shoot") and fire_cooldown <= 0:
		shoot()
		fire_cooldown = fire_rate 
		
	if Input.is_action_just_pressed("dash") and Global.can_dash and can_dash_timer:
		start_dash()
	
	if is_dashing:
		var dash_dir = Input.get_axis("move_left", "move_right")
		if dash_dir == 0:
			dash_dir = 1 if animated_sprite.flip_h else -1
			
		velocity.x = dash_dir * dash_speed
		velocity.y = 0
		print("Sto dashando")
		move_and_slide()
		return

	if can_move:
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed if speed != null else 200.0)
	else:
		velocity.x = move_toward(velocity.x, 0, 10.0)

	update_animation()
	move_and_slide()
	

func start_dash():
	is_dashing = true
	can_dash_timer = false
	
	# Rallenta l'animazione (es: 0.5 è metà velocità, 1.0 è normale)
	animated_sprite.speed_scale = 0.5 
	
	if animated_sprite.sprite_frames.has_animation("dash"):
		animated_sprite.play("dash")
		visuals.position.y = -200
	
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	# IMPORTANTE: Torna alla velocità normale per le altre animazioni (walk, idle)
	animated_sprite.speed_scale = 1.0 
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash_timer = true

func update_animation():
	visuals.position = Vector2.ZERO 
	
	if animated_sprite.flip_h:
		$MuzzleLeft.position.x = -100
	else:
		$MuzzleLeft.position.x = -default_muzzle_x
	
	
	if Input.is_action_pressed("shoot"):
		if Input.is_action_pressed("up"):
			animated_sprite.play("shoot_up")
			if animated_sprite.flip_h:
				$MuzzleUp.position.y = -580
				$MuzzleUp.position.x = -350
			else:
				$MuzzleUp.position.y = -580
				$MuzzleUp.position.x = -480
			visuals.position.y = -200
			visuals.position.x = 0
			
		else:
			animated_sprite.play("shoot_side")
			
			var offset_correttivo = 130
			
			if animated_sprite.flip_h:
				# Guardo a DESTRA -> Sposto a Sinistra (Negativo)
				visuals.position.x = offset_correttivo
				$MuzzleLeft.position.x += offset_correttivo
			else:                      
				# Guardo a SINISTRA -> Sposto a Destra (Positivo)
				visuals.position.x = -offset_correttivo
				$MuzzleLeft.position.x += -offset_correttivo
			
	elif velocity.x != 0:
		animated_sprite.play("walk")
		
		animated_sprite.flip_h = (velocity.x > 0) 
		
		if velocity.x > 0:
			$MuzzleLeft.position.x = abs($MuzzleLeft.position.x)
		else:
			$MuzzleLeft.position.x = -abs($MuzzleLeft.position.x)
	
	else:
		animated_sprite.play("idle")
		
	if not is_on_floor() and not Input.is_action_pressed("shoot"):
		# animated_sprite.play("jump") 
		pass

func shoot():
	var bullet = projectile_scene.instantiate()
	shoot_sound.play()
	shoot_sound.pitch_scale = randf_range(0.9, 1.1)
	
	if Input.is_action_pressed("up"):
		bullet.global_position = $MuzzleUp.global_position
		bullet.rotation_degrees = -90 
		bullet.speed = abs(bullet.speed)
	else:
		bullet.global_position = $MuzzleLeft.global_position
		bullet.rotation_degrees = 0
		
		if animated_sprite.flip_h == true:
			bullet.speed = abs(bullet.speed)
		else:
			bullet.speed = -abs(bullet.speed)
		
	get_parent().add_child(bullet)

func apply_knockback(force_x: float):
	
	if is_invincible_active:
		return
		
	if health_component.current_health <= 0 or not is_inside_tree():
		return
	# 1. Disabilita i controlli
	can_move = false

	# 2. Applica la spinta (X = direzione forza, Y = saltello in alto)
	velocity.x = force_x
	velocity.y = -200 # Un piccolo saltello rende la spinta più realistica

	# 3. Diventa rosso per feedback visivo (Opzionale)
	modulate = Color(1, 0, 0, modulate.a) 

	# 4. Aspetta 0.3 secondi
	await get_tree().create_timer(0.3).timeout

	if is_inside_tree():
		can_move = true
		modulate = Color(1, 1, 1, modulate.a) # Torna normale
		velocity.x = 0 # Ferma lo scivolamento

func _on_contact_area_body_entered(body):
	# Controlliamo se chi è entrato è il Player
	if body.is_in_group("Player"): # Assicurati che il Player sia nel gruppo "Player"
		
		# 1. Calcola la direzione della spinta
		# Sottraendo la X del boss dalla X del player otteniamo un vettore che punta VERSO il player
		var direction_vector = body.global_position.x - global_position.x
		
		# 'sign' restituisce 1 se positivo (destra), -1 se negativo (sinistra)
		var push_direction = sign(direction_vector)
		
		# Se sono perfettamente allineati (0), spingiamo a caso a destra o sinistra per evitare bug
		if push_direction == 0:
			push_direction = 1 
			
		# 2. Applica il Knockback
		if body.has_method("apply_knockback"):
			# Moltiplichiamo la direzione (-1 o 1) per la potenza
			body.apply_knockback(push_direction * knockback_power)
			
		# 3. (Opzionale) Applica Danno qui se non lo fai già altrove
		# if body.has_method("take_damage"):
		#    body.take_damage(1)
