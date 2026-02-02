extends Area2D

@export var speed = 400
@export var rotation_speed = 500.0
@onready var sprite = $Sprite2D

func _ready():
	# Distruzione automatica dopo 5 secondi per sicurezza
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta):
	# Movimento in avanti
	position += transform.x * speed * delta
	
	if sprite:
		sprite.rotation_degrees += rotation_speed * delta

# IMPORTANTE: Questo è il segnale che deve essere collegato!
func _on_body_entered(body):
	print("PROIETTILE: Ho toccato ", body.name) # DEBUG 1
	
	var health = body.get_node_or_null("HealthComponent")
	
	if health:
		print("PROIETTILE: Ho trovato la vita! Faccio danno.") # DEBUG 2
		health.take_damage(1)
		queue_free() # Mi distruggo dopo aver colpito
	else:
		# Se tocca il player ma non trova la vita, ci dice perché
		print("PROIETTILE: Toccato ", body.name, " ma NON trovo 'HealthComponent'.")
		# Stampa i figli per capire come si chiamano davvero
		if body.name == "Player":
			for child in body.get_children():
				print(" - Figlio trovato: ", child.name)
		
	# Se tocca i muri (World)
	if body.is_in_group("World") or body is TileMapLayer or body is TileMap:
		print("PROIETTILE: Ho toccato un muro.")
		queue_free()
