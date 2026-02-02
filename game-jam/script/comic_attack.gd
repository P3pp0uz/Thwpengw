class_name ComicAttack extends Area2D

@export var damage = 1
@export var warning_time = 1.0 # Quanto tempo ha il player per scappare (1 secondo)
@export var active_time = 0.2  # Per quanto tempo fa danno (molto breve)

func _ready():
	# 1. INIZIO: FASE DI WARNING
	# Disattiviamo la collisione così non fa male subito
	$CollisionShape2D.disabled = true
	
	# Lo rendiamo semi-trasparente per far capire che "si sta caricando"
	modulate.a = 0.5 
	# (Opzionale) Lo facciamo diventare un po' rosso
	modulate = Color(1, 0.5, 0.5, 0.5)
	
	# Colleghiamo il segnale di contatto per quando si attiverà
	body_entered.connect(_on_body_entered)
	
	# Aspettiamo il tempo di warning
	await get_tree().create_timer(warning_time).timeout
	
	_activate_explosion()

func _activate_explosion():
	# 2. ESPLOSIONE!
	# Ora fa male
	$CollisionShape2D.disabled = false
	
	# Diventa visibile al 100% e bianco normale
	modulate = Color(1, 1, 1, 1)
	
	# (Opzionale) Qui potresti far partire un suono o cambiare sprite
	print("BOOM! Fumetto attivo")
	
	# Resta attivo per un attimo
	await get_tree().create_timer(active_time).timeout
	
	# 3. FINE
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var health = body.get_node_or_null("HealthComponent")
		if health:
			health.take_damage(damage)
			# Niente knockback per questo attacco, è un'esplosione sul posto
			# Oppure aggiungilo se vuoi che ti spinga via
