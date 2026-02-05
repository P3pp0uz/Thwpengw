extends CharacterBody2D

@export var projectile_scene: PackedScene
@export var hand_scene: PackedScene 
@export var win_screen_image: Texture2D 

@onready var health_component = $HealthComponent
@onready var muzzle = $Muzzle
@onready var attack_timer = $AttackTimer
@onready var sprite = $Sprite2D 
@onready var shield = $Shield
@onready var intro_sound = $IntroSound

# CONFIGURAZIONE DANNO E SPINTA
var knockback_power = 500.0
@export var contact_damage: int = 1 

var player_ref = null
var time_passed = 0.0
@export var hover_speed = 2.0
@export var hover_amplitude = 100.0
var start_y = 0.0

# --- NUOVA VARIABILE DI STATO ---
var is_shield_active: bool = false

func _ready():
	sprite.play("default")
	
	if intro_sound:
		intro_sound.play()
	
	start_y = position.y
	print("BOSS ANIMATED: Sono vivo (Start Y: ", start_y, ")")

	if not projectile_scene: print("BOSS ERRORE: Manca projectile_scene")
	if not hand_scene: print("BOSS ERRORE: Manca hand_scene")

	if attack_timer:
		attack_timer.wait_time = 4.0 # Puoi abbassarlo se vuoi attacchi più frequenti durante lo scudoo
		attack_timer.one_shot = false
		if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
			attack_timer.timeout.connect(_on_attack_timer_timeout)
		attack_timer.start()

	health_component.on_damage.connect(_on_damage)
	health_component.on_death.connect(_on_death)
	
	# Collega l'Area2D per il contatto se esiste (o fallo da editor)
	var contact_area = get_node_or_null("ContactArea")
	if contact_area:
		if not contact_area.body_entered.is_connected(_on_contact_area_body_entered):
			contact_area.body_entered.connect(_on_contact_area_body_entered)

func _physics_process(delta):
	if health_component.current_health > 0:
		time_passed += delta
		
		# --- FISICA ANTI-TELETRASPORTO ---
		var target_y = start_y + sin(time_passed * hover_speed) * hover_amplitude
		velocity.y = (target_y - position.y) / delta
		velocity.x = 0 
		move_and_slide()

# --- CERVELLO DEGLI ATTACCHI ---
func _on_attack_timer_timeout():
	# 1. Spara SEMPRE la palla di fuoco
	_shoot_fireball()
	if randf() < 0.5:
		_use_shield()
		print("BOSS: Tentativo mano con scudo attivo")
	else:
		_spawn_hand_attack()
		print("BOSS: Tentativo mano normale")
	# 2. Logica casuale per il SECONDO attacco
	if is_shield_active:
		_spawn_hand_attack()
		print("BOSS: Tentativo mano normale")



func _use_shield():
	print("BOSS: Attivo lo scudo!")
	
	# 1. Imposta stato
	is_shield_active = true
	
	# 2. Avvia animazione visiva
	if sprite.sprite_frames.has_animation("shield_pos"):
		sprite.play("shield_pos")
	
	# 3. Attiva la meccanica
	shield.activate_shield()
	
	# NOTA: NON fermiamo più attack_timer.stop() qui, così continua ad attaccare!
	
	# 4. Aspetta finché non viene distrutto
	await shield.shield_destroyed
	
	# 5. Scudo rotto: resetta stato
	is_shield_active = false
	
	# Torna all'animazione di base
	sprite.play("default")

# --- ATTACCO 1: PALLA DI FUOCO ---
func _shoot_fireball():
	if not projectile_scene: return
	if not player_ref: player_ref = get_tree().get_first_node_in_group("Player")
	
	if player_ref:
		# NON usare sprite.play("qualcosa") qui, altrimenti interrompi 
		# l'animazione della mano o dello scudo che sta partendo contemporaneamente.
		
		# Facciamo solo il flash rosso
		sprite.modulate = Color(1, 0.5, 0.5) 
		
		var fireball = projectile_scene.instantiate()
		get_parent().add_child(fireball)
		fireball.position = muzzle.global_position
		fireball.look_at(player_ref.global_position)
		
		await get_tree().create_timer(0.2).timeout
		sprite.modulate = Color(1, 1, 1)
	
# --- ATTACCO 2: MANO DALL'ALTO ---
func _spawn_hand_attack():
	print("ATTACCO CON LA MANO")
	if not hand_scene: 
		print("ERRORE: hand_scene non è assegnata nell'Inspector del Boss!")
		return
	
	# Forza l'animazione attacco anche se la fireball è partita
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	
	var hand = hand_scene.instantiate()
	get_parent().add_child(hand)
	
	if not player_ref: player_ref = get_tree().get_first_node_in_group("Player")
	if player_ref:
		hand.global_position = Vector2(player_ref.global_position.x, start_y - 200)
	
	if sprite.sprite_frames.has_animation("attack"):
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
		
	# Controlliamo dove tornare
	if is_shield_active:
		sprite.play("shield_pos")
	else:
		sprite.play("default")


func _on_damage(amount):
	# Piccolo feedback visivo danno
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(10, 10, 10), 0.05) 
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)

# --- MORTE ---
func _on_death():
	print("BOSS: Sconfitto!")
	set_physics_process(false)
	attack_timer.stop()
	
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

# --- GESTIONE CONTATTO ---
func _on_contact_area_body_entered(body):
	if body.is_in_group("Player"):
		var direction_vector = body.global_position.x - global_position.x
		var push_direction = sign(direction_vector)
		if push_direction == 0: push_direction = 1 
			
		if body.has_method("apply_knockback"):
			body.apply_knockback(push_direction * knockback_power)
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
