extends Node2D

@onready var animated_sprite_up = $AnimatedSprite2D

# Trascina qui l'immagine della Fase 2 dal FileSystem
@export var background_phase_2: Texture2D

# Riferimenti presi guardando il tuo screenshot
@onready var sfondo_sprite = $BackgroundLayer/Sfondo
@onready var boss = $Berlusconi  # Nello screen si chiama "Berlusconi", giusto?

func _ready():
	animated_sprite_up.play("default")
	# Controlliamo che il boss esista per evitare crash
	if boss:
		# Colleghiamo il segnale che hai creato nel Boss a questa funzione
		boss.phase_two_started.connect(_on_cambio_fase)
	else:
		print("ERRORE: Non trovo il nodo 'Berlusconi'!")

func _on_cambio_fase():
	animated_sprite_up.visible = false
	print("Cambio sfondo per Fase 2!")
	
	# Cambia SOLO la texture del nodo Sfondo
	if sfondo_sprite and background_phase_2:
		sfondo_sprite.texture = background_phase_2
	
	# Tv, Statico e Walls non vengono toccati e rimangono lì.
