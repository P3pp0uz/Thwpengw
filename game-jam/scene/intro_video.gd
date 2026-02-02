extends Control

# Il percorso della tua scena di gioco (es. Level1.tscn)
# Modifica questo percorso con quello reale del tuo gioco
const GAME_SCENE_PATH = "res://scene/boss_berlusconi.tscn"

@onready var video_player = $VideoStreamPlayer

func _ready():
	# Collega il segnale "finished" del player video alla nostra funzione
	video_player.finished.connect(_on_video_finished)
	
	# Opzionale: Assicurati che il video parta se Autoplay non è spuntato
	if not video_player.is_playing():
		video_player.play()

# Funzione chiamata quando il video finisce naturalmente
func _on_video_finished():
	start_game()

# Gestione dell'input per saltare il video (Skip)
func _input(event):
	# Se il giocatore preme un tasto qualsiasi o clicca, salta il video
	# Puoi specificare un tasto preciso, es: "ui_cancel" (spesso ESC)
	if event is InputEventKey and event.pressed:
		start_game()
	elif event is InputEventMouseButton and event.pressed:
		start_game()

# Funzione per cambiare scena
func start_game():
	# Ferma il video per evitare problemi audio durante il cambio
	video_player.stop() 
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
