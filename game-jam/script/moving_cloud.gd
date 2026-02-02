extends CharacterBody2D

@export var speed: float = 150.0           
@export var reset_x: float = 650.0        
@export var respawn_x: float = 2300.0      
@export var loop_width: float = 800

@export var bob_speed: float = 2.0
@export var bob_amplitude: float = 10.0

var time_passed: float = 0.0
var initial_y: float = 0.0

func _ready():
	initial_y = position.y
	time_passed = randf_range(0, 10)
	
	# Opzionale: Imposta il motion mode su Floating se non vuoi gravità sulla nuvola
	# (Anche se con questo script non applichiamo gravità comunque)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _physics_process(delta):
	# 1. Movimento Orizzontale Falsato (Solo Velocità)
	# Impostiamo la velocity: questo dice al motore "mi sto muovendo a questa velocità".
	# Il player leggerà questo valore e si muoverà insieme alla nuvola in modo fluido.
	velocity.x = -speed
	velocity.y = 0
	
	# Applica il movimento fisico
	move_and_slide()
	
	# 2. Movimento Verticale (Ondulazione)
	# Per l'ondulazione puramente estetica, possiamo toccare direttamente la posizione Y.
	# Questo non influenza la velocity orizzontale, quindi è sicuro.
	time_passed += delta
	position.y = initial_y + sin(time_passed * bob_speed) * bob_amplitude
	
	# 3. Teletrasporto (Loop)
	# Qui sta la magia: Cambiare 'position' direttamente su un CharacterBody2D
	# NON cambia la sua 'velocity'. Quindi per il motore fisico, la nuvola
	# si è spostata, ma non ha "lanciat" il player.
	if position.x < reset_x:
		position.x += loop_width
