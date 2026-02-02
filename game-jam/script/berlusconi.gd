extends CharacterBody2D

@export var kick_scene: PackedScene 
@export var left_spawn_point: Node2D
@export var right_spawn_point: Node2D
@export var falling_kick_scene: PackedScene
@export var arena_min_x: float = 85 
@export var arena_max_x: float = 908  
@export var spawn_y: float = -50 
@onready var animated_sprite = $Sprite2D
@export var soccer_player_scene: PackedScene
@export var nuovo_nemico_scene: PackedScene
@export var comic_attack_scene: PackedScene
@onready var intro_sound = $IntroSound
@onready var canvas_layer = $CanvasLayer
@onready var boss_defeated_img = $CanvasLayer/BossDefeatedImage
@onready var transition_img = $CanvasLayer/TransitionImage
@onready var background_img = $CanvasLayer/TextureRect # Il tuo sfondo
@onready var unlock_img = $CanvasLayer/UnlockImage


# Riferimenti ai calci attivi
var left_kick_instance = null
var right_kick_instance = null

signal phase_two_started

@onready var health_component = $HealthComponent
@onready var stomp_timer = $FlyKickTimer

var current_phase = 1

func _ready():
	if intro_sound:
		intro_sound.play()

	health_component.on_damage.connect(check_phase)
	health_component.on_death.connect(die)
	
	animated_sprite.play("default")
	
	# Collega i timer di respawn
	$LeftRespawnTimer.timeout.connect(spawn_left_kick)
	$RightRespawnTimer.timeout.connect(spawn_right_kick)
	
	# Collega il timer principale in modo sicuro
	if not stomp_timer.timeout.is_connected(_on_stomp_timer_timeout):
		stomp_timer.timeout.connect(_on_stomp_timer_timeout)
	
	# START FASE 1
	var tempo_random = randf_range(2.0, 6.0)
	$LeftRespawnTimer.start(tempo_random)
	$RightRespawnTimer.start(tempo_random)
	stomp_timer.start(tempo_random)

func check_phase(amount):
	# Controllo per entrare in fase 2
	if current_phase == 1 and health_component.current_health <= (health_component.max_health / 2):
		enter_phase_two()

func enter_phase_two():
	if current_phase == 2: return # Evita doppi trigger
	
	print("ATTENZIONE: INIZIO FASE 2! STOP TOTALE ATTACCHI.")
	current_phase = 2
	
	# 1. BLOCCA I TIMER DEI VECCHI ATTACCHI
	# Fondamentale: altrimenti tra 10 secondi respawnano i calci laterali!
	$LeftRespawnTimer.stop()
	$RightRespawnTimer.stop()
	
	# 2. PULIZIA ARENA (Distrugge tutto ciò che è vivo ora)
	var tutti_i_nodi = get_parent().get_children()
	for nodo in tutti_i_nodi:
		# Usa "is" per controllare la classe (assicurati che gli script abbiano class_name)
		if nodo is FlyAttack: 
			nodo.queue_free()
		if nodo is KickAttack: # Assumi che il calcio laterale abbia class_name KickAttack
			nodo.queue_free()
			
	# Resettiamo i riferimenti
	left_kick_instance = null
	right_kick_instance = null
	
	# 3. EMETTI SEGNALE E CAMBIA LOGICA
	phase_two_started.emit()
	
	# Riduciamo il timer, pronto per i nuovi attacchi futuri
	stomp_timer.wait_time = 2.0 

# --- IL CERVELLO (Loop Principale) ---
func _on_stomp_timer_timeout():
	if current_phase == 1:
		spawn_stomp_attack()
		stomp_timer.wait_time = randf_range(3.0, 6.0)
	else:
		# --- FASE 2: DOPPIA MINACCIA ---
		
		# 1. SPAWN NEMICI LATERALI (Garantito: o uno o l'altro)
		# Questo dado decide SOLO quale corridore far partire
		if randf() > 0.5:
			spawn_runner(soccer_player_scene)
		else:
			spawn_runner(nuovo_nemico_scene)
			
		# 2. SPAWN FUMETTO (Indipendente)
		# Tiriamo un secondo dado per vedere se aggiungere ANCHE il fumetto
		# Esempio: > 0.4 significa che hai il 60% di probabilità che esca
		if randf() > 0.4:
			# Opzionale: Aspetta un attimo (0.5s) per sfasare gli attacchi
			# così il giocatore non deve saltare e scappare nello stesso micro-istante
			get_tree().create_timer(randf_range(0.1, 0.8)).timeout.connect(spawn_comic_attack)
		
		# Timer rapido per mantenere il ritmo alto
		stomp_timer.wait_time = randf_range(2.0, 3.5)


# --- FUNZIONI DI SPAWN (Fase 1) ---
func spawn_stomp_attack():
	if not falling_kick_scene: return
	var stomp = falling_kick_scene.instantiate()
	get_parent().add_child(stomp)
	var random_x = randf_range(arena_min_x, arena_max_x)
	stomp.global_position = Vector2(random_x, spawn_y)
	

func spawn_left_kick():
	if left_kick_instance != null: return
	if not left_spawn_point or not kick_scene: return
	
	var kick = kick_scene.instantiate()
	get_parent().call_deferred("add_child", kick)
	kick.global_position = left_spawn_point.global_position
	kick.scale.x = 1 
	left_kick_instance = kick
	kick.kick_died.connect(_on_left_kick_died)

func _on_left_kick_died():
	# Se siamo in Fase 2, non riavviare il timer!
	if current_phase == 1:
		left_kick_instance = null
		$LeftRespawnTimer.start(10)

func spawn_right_kick():
	if right_kick_instance != null: return
	if not right_spawn_point or not kick_scene: return
	
	var kick = kick_scene.instantiate()
	get_parent().call_deferred("add_child", kick)
	kick.global_position = right_spawn_point.global_position
	kick.scale.x = -1 
	right_kick_instance = kick
	kick.kick_died.connect(_on_right_kick_died)

func _on_right_kick_died():
	# Se siamo in Fase 2, non riavviare il timer!
	if current_phase == 1:
		right_kick_instance = null
		$RightRespawnTimer.start(10)

func spawn_soccer_player():
	if not soccer_player_scene: 
		print("ERRORE: Manca la scena del Calciatore!")
		return

	# Decidiamo a caso se parte da Sinistra (va a destra) o viceversa
	var start_from_left = randf() > 0.5
	
	var soccer = soccer_player_scene.instantiate()
	var sprite = soccer.get_node("AnimatedSprite2D")
	
	# Usiamo call_deferred per sicurezza fisica
	get_parent().call_deferred("add_child", soccer)
	
	# Aspettiamo un frame per settare la posizione (sicurezza)
	await get_tree().process_frame
	
	if start_from_left:
		# Parte da SINISTRA, corre verso DESTRA (1)
		if left_spawn_point:
			soccer.global_position = left_spawn_point.global_position
			soccer.direction = 1 
	else:
		# Parte da DESTRA, corre verso SINISTRA (-1)
		if right_spawn_point:
			soccer.global_position = right_spawn_point.global_position
			soccer.direction = -1
			if sprite: sprite.flip_h = true

func spawn_runner(scena_da_spawnare):
	if not scena_da_spawnare:
		print("manca scena nemico")
		return
	
	var start_from_left = randf() > 0.5
	var nemico = scena_da_spawnare.instantiate()
	var sprite = nemico.get_node("AnimatedSprite2D")
	
	get_parent().call_deferred("add_child", nemico)
	await get_tree().process_frame
	if start_from_left:
		if left_spawn_point:
			nemico.global_position = left_spawn_point.global_position
			nemico.direction = 1
	else:
		if right_spawn_point:
			nemico.global_position = right_spawn_point.global_position
			nemico.direction = -1
			if sprite: sprite.flip_h = true
			
func spawn_comic_attack():
	if not comic_attack_scene: return
	
	# TROVA IL PLAYER
	# Usiamo i gruppi per trovarlo in scena
	var player_node = get_tree().get_first_node_in_group("Player")
	
	if player_node:
		var fumetto = comic_attack_scene.instantiate()
		get_parent().add_child(fumetto)
		
		# Posiziona il fumetto esattamente dove è il player ORA
		fumetto.global_position = player_node.global_position - Vector2(100, 50)
		
		print("Fumetto spawnato sulla testa del player!")
	else:
		print("Non trovo il player per mirare!")
		
func die():
	# 1. Ferma il boss
	set_physics_process(false)
	set_process(false)
	Global.can_dash = true
	for child in get_children():
		if child is Timer:
			child.stop()
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	
	if canvas_layer:
		canvas_layer.visible = true

	# --- SEQUENZA RIGOROSA ---

	# Assicuriamoci che tutto sia invisibile all'inizio
	boss_defeated_img.visible = false
	transition_img.visible = false
	background_img.visible = false
	unlock_img.visible = false

	# 1. MOSTRA BOSS DEFEATED
	if boss_defeated_img:
		print("Fase 1: Boss Defeated")
		await fade_in_out(boss_defeated_img, 2.0)
		# Dopo fade_in_out, l'immagine viene già messa a visible = false dalla funzione

	# 2. MOSTRA TRANSITION IMAGE
	if transition_img:
		print("Fase 2: Transition")
		await fade_in_out(transition_img, 2.0)

	# 3. MOSTRA SFONDO E UNLOCK INSIEME
	# 3. MOSTRA SFONDO E UNLOCK INSIEME
	if background_img and unlock_img:
		print("Fase 3: Avvio animazione finale...")
		background_img.modulate.a = 0
		unlock_img.modulate.a = 0
		background_img.visible = true
		unlock_img.visible = true
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(background_img, "modulate:a", 1.0, 0.5)
		tw.tween_property(unlock_img, "modulate:a", 1.0, 0.5)
		
		# Usiamo un Timer che ignora la pausa del gioco (se presente)
		await get_tree().create_timer(3.0, false).timeout
		print("Fase 3: Timer completato. Inizio chiusura.")
		
		var tw_out = create_tween().set_parallel(true)
		tw_out.tween_property(background_img, "modulate:a", 0.0, 0.5)
		tw_out.tween_property(unlock_img, "modulate:a", 0.0, 0.5)
		await tw_out.finished
		
		background_img.visible = false
		unlock_img.visible = false
		if canvas_layer:
			canvas_layer.visible = false
		print("Fase 3: Tutto pulito.")

	# 1. VERIFICA IL PERCORSO ESATTO (Case Sensitive!)
	var prossima_scena = "res://scene/boss_papa.tscn" 
	
	# Controllo di sicurezza:
	if not FileAccess.file_exists(prossima_scena):
		# Proviamo le varianti comuni se hai sbagliato a scrivere
		if FileAccess.file_exists("res://scenes/boss_papa.tscn"):
			prossima_scena = "res://scenes/boss_papa.tscn"
			print("Corretto percorso in: scenes/...")
		elif FileAccess.file_exists("res://scene/Boss_Papa.tscn"):
			prossima_scena = "res://scene/Boss_Papa.tscn"
			print("Corretto percorso in: Boss_Papa...")
	
	# 2. CAMBIO SCENA
	var error = get_tree().change_scene_to_file(prossima_scena)
	
	if error == OK:
		print("Cambio scena avviato con successo.")
	else:
		print("ERRORE CRITICO nell'export: Codice ", error)
		print("Controlla che il file esista e sia incluso nell'export.")
		queue_free()

# FUNZIONE DI SUPPORTO
func fade_in_out(img: TextureRect, wait_time: float):
	img.modulate.a = 0
	img.visible = true
	
	# Appare
	var tw_in = create_tween()
	tw_in.tween_property(img, "modulate:a", 1.0, 0.5)
	await tw_in.finished
	
	# Aspetta
	await get_tree().create_timer(wait_time).timeout
	
	# Sparisce
	var tw_out = create_tween()
	tw_out.tween_property(img, "modulate:a", 0.0, 0.5)
	await tw_out.finished
	
	img.visible = false

func show_and_hide_image(img: TextureRect, wait_time: float):
	if img:
		img.visible = true
		img.modulate.a = 0
		
		# Fade In
		var tween_in = create_tween()
		tween_in.tween_property(img, "modulate:a", 1.0, 0.4)
		await tween_in.finished
		
		# Attesa
		await get_tree().create_timer(wait_time).timeout
		
		# Fade Out
		var tween_out = create_tween()
		tween_out.tween_property(img, "modulate:a", 0.0, 0.4)
		await tween_out.finished
		img.visible = false
