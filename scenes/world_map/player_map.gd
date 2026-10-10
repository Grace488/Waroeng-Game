# scenes/world_map/player_map.gd
# Skrip untuk karakter yang bergerak di peta
extends CharacterBody2D

const SPEED = 180.0

func _physics_process(_delta: float) -> void:
	# Ambil input gerakan (WASD atau Panah)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	
	# Gerakkan karakter
	move_and_slide()
