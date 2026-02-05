extends Node2D

@onready var animated_sprite_up = $AnimatedSprite2D

# Trascina qui l'immagine della Fase 2 dal FileSystem
@export var background_phase_2: Texture2D

# Riferimenti presi guardando il tuo screenshot
@onready var sfondo_sprite = $BackgroundLayer/Sfondo
@onready var boss = $Berlusconi  

func _ready():
	animated_sprite_up.play("default")
	
	if boss:
		# 1. Collegamenti esistenti (Fasi)
		boss.phase_two_started.connect(_on_cambio_fase)
		boss.end_boss.connect(_on_end_game)
		
		# 2. NUOVO: Collegamento per il Danno
		# Cerchiamo il componente salute dentro il boss
		var boss_health = boss.get_node_or_null("HealthComponent")
		if boss_health:
			# Ogni volta che il boss prende danno, esegui la funzione visiva QUI
			boss_health.on_damage.connect(_on_boss_hit_visual_reaction)
		else:
			print("Attenzione: Il Boss non ha un HealthComponent chiamato così!")
	else:
		print("ERRORE: Non trovo il nodo 'Berlusconi'!")

func _on_boss_hit_visual_reaction(amount):
	if not animated_sprite_up: return

	# --- 1. FLASH ---
	var tween = create_tween()
	# Lo rendiamo bianchissimo (Flash)
	animated_sprite_up.modulate = Color(10, 10, 10, 1)
	# Torna normale in 0.1 secondi
	tween.tween_property(animated_sprite_up, "modulate", Color(1, 1, 1, 1), 0.1)

func _on_cambio_fase():
	animated_sprite_up.visible = true
	print("Cambio sfondo per Fase 2!")
	
	# Cambia SOLO la texture del nodo Sfondo
	if sfondo_sprite and background_phase_2:
		sfondo_sprite.texture = background_phase_2
	
	# Tv, Statico e Walls non vengono toccati e rimangono lì.

func _on_end_game():
	animated_sprite_up.visible = false
