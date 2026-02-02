extends CharacterBody2D

@export var speed = 100.0
@export var damage_to_player = 1

# Gravità standard
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = -1 # -1 va a sinistra, 1 a destra

@onready var sprite = $Sprite2D
@onready var health_component = $HealthComponent
@onready var explosion_sound = $ExplosionSound
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Quando l'HealthComponent dice "sono morto", esegui la funzione _on_death
	health_component.on_death.connect(_on_death)

func _physics_process(delta):
	# Applica gravità
	if not is_on_floor():
		velocity.y += gravity * delta

	# Gestione semplice del pattugliamento
	# Se sbatte contro un muro, inverte la direzione
	if is_on_wall():
		direction *= -1
		sprite.flip_h = (direction > 0) # Gira lo sprite se va a destra
	
	velocity.x = direction * speed
	move_and_slide()

# Questa funzione viene chiamata dal segnale del componente
func _on_death():
	set_physics_process(false) # Ferma il movimento
	
	# 1. Disabilita le collisioni (così non puoi colpirlo mentre "muore")
	collision_shape.set_deferred("disabled", true)
	
	# 2. Nascondi lo sprite (visivamente morto)
	sprite.visible = false 
	
	# 3. Suona
	explosion_sound.play()
	
	# 4. Aspetta che il suono finisca prima di distruggere l'oggetto
	await explosion_sound.finished
	
	# 5. Ora puoi morire 
	queue_free()


func _on_damage_area_body_entered(body: Node2D) -> void:
	var health = body.get_node_or_null("HealthComponent")
	if health:
		health.take_damage(damage_to_player)
		# Opzionale: Distruggi il nemico dopo aver colpito (tipo Kamikaze)
		# O applica una forza di spinta (Knockback) al player
