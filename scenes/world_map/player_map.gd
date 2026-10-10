# scenes/world_map/player_map.gd
# Skrip untuk karakter yang bergerak di peta
extends CharacterBody2D

const SPEED = 180.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var tween: Tween
var is_moving: bool = false
var facing: String = "down"

func _ready() -> void:
	# Cek apakah sprite ada, jika tidak beri warning
	if not ResourceLoader.exists("res://assets/sprites/player_sheet.png"):
		print("WARNING: Sprite pemain tidak ditemukan! Menggunakan kotak merah sebagai fallback.")
		var fallback_rect = ColorRect.new()
		fallback_rect.size = Vector2(24, 24)
		fallback_rect.position = Vector2(-12, -12)
		fallback_rect.color = Color.RED
		add_child(fallback_rect)
		sprite.hide()
	else:
		_update_animation()

func pindah_ke(target: Vector2) -> void:
	if tween and tween.is_running():
		tween.kill()
	
	var dist = global_position.distance_to(target)
	if dist < 5.0:
		return
		
	var dur = dist / SPEED
	
	# Tentukan arah (facing)
	var dir = global_position.direction_to(target)
	if abs(dir.x) > abs(dir.y):
		facing = "right" if dir.x > 0 else "left"
	else:
		facing = "down" if dir.y > 0 else "up"
		
	is_moving = true
	_update_animation()
	
	tween = create_tween()
	tween.tween_property(self, "global_position", target, dur)
	tween.finished.connect(_on_tween_selesai)

func _on_tween_selesai() -> void:
	is_moving = false
	_update_animation()

func _update_animation() -> void:
	if not anim_player.has_animation("walk_" + facing):
		return
		
	if is_moving:
		anim_player.play("walk_" + facing)
	else:
		anim_player.play("idle_" + facing)
