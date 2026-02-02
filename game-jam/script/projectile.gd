extends Area2D

@export var speed = 2000
var direction = 1
@export var damage = 1 # danno di base

func set_direction(dir):
	direction = dir
	if dir < 0:
		$Sprite2D.flip_h = true

func _physics_process(delta):
	position += transform.x * speed * delta
	

func _on_area_entered(area):
	colpisci(area)
	if area.has_method("take_shield_damage"):
		area.take_shield_damage(1)
		queue_free()

func _on_body_entered(body):
	print("HO TOCCATO QUALCOSA: ", body.name)
	# Cerca un nodo figlio chiamato "HealthComponent"
	var health = body.get_node_or_null("HealthComponent")
	
	if health:
		# Se lo trova, applica il danno al componente
		health.take_damage(damage)
		print("ho fatto danno:", damage)
		print(health.current_health)
		queue_free() # Il proiettile si distrugge perché ha colpito un bersaglio valido
	elif body.is_in_group("World"): 
		# Se colpisci un muro ( mettere i muri nel gruppo "World")
		queue_free()

func colpisci(bersaglio):
	print("Colpito: ", bersaglio.name)
	
	var health = bersaglio.get_node_or_null("HealthComponent")
	
	if health:
		health.take_damage(1)
		print("vita:",health.current_health)
		queue_free()
	elif bersaglio.is_in_group("World"):
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
