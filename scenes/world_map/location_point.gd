# scenes/world_map/location_point.gd
# Titik lokasi di peta yang bisa dimasuki pemain
extends Area2D

signal player_masuk(id_lokasi: String, nama_lokasi: String)
signal player_keluar(id_lokasi: String)

var id_lokasi: String = ""
var nama_lokasi: String = ""
var terkunci: bool = false

@onready var color_rect: ColorRect = $ColorRect
@onready var label_nama: Label = $Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func setup(id: String, nama: String, warna: Color, is_terkunci: bool, pos: Vector2, parent_size: Vector2) -> void:
	id_lokasi = id
	nama_lokasi = nama
	terkunci = is_terkunci
	position = pos
	
	if not is_node_ready():
		await ready
		
	color_rect.color = warna
	if terkunci:
		label_nama.text = "🔒 " + nama
		color_rect.color = Color(0.3, 0.3, 0.3)
	else:
		label_nama.text = "📍 " + nama
	
	# Sesuaikan posisi label agar tidak terpotong tepi layar
	# Lebar label sekitar 140px (offset -70 hingga 70)
	var left_edge = pos.x - 70.0
	var right_edge = pos.x + 70.0
	
	if left_edge < 10:
		label_nama.position.x = -24.0 # Rata kiri
		label_nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	elif right_edge > parent_size.x - 10:
		label_nama.position.x = -140.0 + 24.0 # Rata kanan
		label_nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _on_body_entered(body: Node2D) -> void:
	if body.name == "PlayerMap":
		# Beri efek membesar sedikit saat disentuh
		var tween = create_tween()
		tween.tween_property(color_rect, "scale", Vector2(1.2, 1.2), 0.1)
		player_masuk.emit(id_lokasi, nama_lokasi)


func _on_body_exited(body: Node2D) -> void:
	if body.name == "PlayerMap":
		# Kembalikan ukuran asli
		var tween = create_tween()
		tween.tween_property(color_rect, "scale", Vector2(1.0, 1.0), 0.1)
		player_keluar.emit(id_lokasi)
