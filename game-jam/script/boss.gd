extends CharacterBody2D

@export var projectile_scene: PackedScene
@export var hand_scene: PackedScene 
@export var win_screen_image: Texture2D 

@onready var health_component = $HealthComponent
@onready var muzzle = $Muzzle
@onready var attack_timer = $AttackTimer

# Anche se si chiama "Sprite2D", Godot sa che è un AnimatedSprite se il nodo è giusto
@onready var sprite = $Sprite2D 

@onready var shield = $Shield
@onready var intro_sound = $IntroSound

var knockback_power = 500.0
var player_ref = null
var time_passed = 0.0
@export var hover_speed = 2.0
@export var hover_amplitude = 100.0
var start_y = 0.0

func _ready():
	# Ora che è animated, QUESTA riga funziona e serve!
	sprite.play("default")
	
	if intro_sound:
		intro_sound.play()
	
	start_y = position.y
	print("BOSS ANIMATED: Sono vivo (Start Y: ", start_y, ")")

	if not projectile_scene: print("BOSS ERRORE: Manca projectile_scene")
	if not hand_scene: print("BOSS ERRORE: Manca hand_scene")

	if attack_timer:
		attack_timer.wait_time = 4.0
		attack_timer.one_shot = false
		if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
			attack_timer.timeout.connect(_on_attack_timer_timeout)
		attack_timer.start()

	health_component.on_damage.connect(_on_damage)
	health_component.on_death.connect(_on_death)

func _physics_process(delta):
	if health_component.current_health > 0:
		time_passed += delta
		
		# --- FISICA ANTI-TELETRASPORTO ---
		# Calcoliamo dove deve andare
		var target_y = start_y + sin(time_passed * hover_speed) * hover_amplitude
		
		# Calcoliamo la velocità per arrivarci invece di forzare la posizione
		velocity.y = (target_y - position.y) / delta
		velocity.x = 0 
		
		move_and_slide()

# --- CERVELLO DEGLI ATTACCHI ---
func _on_attack_timer_timeout():
	var scelta = randf()
	if scelta < 0.5:
		_spawn_hand_attack()
	else:
		_use_shield()

func _use_shield():
	print("BOSS: Attivo lo scudo!")
	
	# Animazione scudo
	if sprite.sprite_frames.has_animation("shield_pos"):
		sprite.play("shield_pos")
	
	shield.activate_shield()
	await shield.shield_destroyed
	
	# Torna normale
	sprite.play("default")

# --- ATTACCO 1: PALLA DI FUOCO ---
func _shoot_fireball():
	if not projectile_scene: return

	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("Player")
	
	if player_ref:
		print("BOSS: FUOCO!")
		
		# Opzionale: Se hai un'animazione di sparo, mettila qui
		# sprite.play("attack") 
		
		sprite.modulate = Color(1, 0.5, 0.5) # Flash rosso
		var fireball = projectile_scene.instantiate()
		get_parent().add_child(fireball)
		fireball.position = muzzle.global_position
		fireball.look_at(player_ref.global_position)
		
		await get_tree().create_timer(0.2).timeout
		sprite.modulate = Color(1, 1, 1)
		sprite.play("default")

# --- ATTACCO 2: MANO DALL'ALTO ---
func _spawn_hand_attack():
	if not hand_scene: return
	
	# Qui usiamo l'animazione perché il nodo è Animated!
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	
	print("BOSS: EVOCO LA MANO!")
	var hand = hand_scene.instantiate()
	get_parent().add_child(hand)
	
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("Player")
		
	if player_ref:
		hand.global_position = Vector2(player_ref.global_position.x, start_y - 200)
	
	# Se è un'animazione, possiamo aspettare che finisca
	if sprite.sprite_frames.has_animation("attack"):
		await sprite.animation_finished
		sprite.play("default")
	else:
		await get_tree().create_timer(0.5).timeout

func _on_damage(amount):
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05) 
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)

# --- MORTE ---
func _on_death():
	print("BOSS: Sconfitto!")
	
	set_physics_process(false)
	attack_timer.stop()
	
	# Se hai un'animazione di morte, usala!
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	
	sprite.visible = false
	shield.visible = false 
	
	if win_screen_image:
		var canvas = CanvasLayer.new() 
		add_child(canvas)
		
		var rect = TextureRect.new()
		rect.texture = win_screen_image
		rect.set_anchors_preset(Control.PRESET_FULL_RECT) 
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		canvas.add_child(rect)
	
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()

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
