# scenes/world_map/world_map.gd
# Peta dunia — gerakkan karakter ke lokasi untuk masuk
extends Control

signal buka_warung()
signal buka_lokasi(id_lokasi: String)
signal buka_koleksi()
signal buka_upgrade()

@onready var btn_buka_warung: Button = $VBox/BottomBar/HBox/BtnBukaWarung
@onready var btn_koleksi: Button = $VBox/BottomBar/HBox/BtnKoleksi
@onready var btn_upgrade: Button = $VBox/BottomBar/HBox/BtnUpgrade
@onready var btn_save: Button = $VBox/BottomBar/HBox/BtnSave
@onready var label_tas: Label = $VBox/BottomBar/HBox/LabelTas

@onready var map_area: Control = $VBox/MapArea
@onready var lokasi_container: Node2D = $VBox/MapArea/Locations
@onready var player: CharacterBody2D = $VBox/MapArea/PlayerMap
@onready var panel_interaksi: PanelContainer = $PanelInteraksi
@onready var label_interaksi: Label = $PanelInteraksi/LabelInteraksi
@onready var warung_building: Area2D = $VBox/MapArea/WarungBuilding

var lokasi_aktif: String = ""
var scene_location_point: PackedScene = preload("res://scenes/world_map/location_point.tscn")


func _ready() -> void:
	# Cek apakah sprite warung ada
	if not ResourceLoader.exists("res://assets/sprites/warung_building.png"):
		print("WARNING: Sprite bangunan warung tidak ditemukan! Menggunakan fallback.")
		var sprite = warung_building.get_node("Sprite2D")
		if sprite: sprite.hide()
		var fallback_rect = ColorRect.new()
		fallback_rect.size = Vector2(96, 96)
		fallback_rect.position = Vector2(-48, -48)
		fallback_rect.color = Color.BROWN
		warung_building.add_child(fallback_rect)
		
	# Sembunyikan panel interaksi di awal
	panel_interaksi.hide()
	
	# Setup tombol
	btn_buka_warung.pressed.connect(func(): buka_warung.emit())
	btn_koleksi.pressed.connect(func(): buka_koleksi.emit())
	btn_upgrade.pressed.connect(func(): buka_upgrade.emit())
	btn_save.pressed.connect(func(): SaveManager.simpan_game())
	
	# Setup klik map area untuk player movement
	map_area.gui_input.connect(_on_map_area_gui_input)
	
	# Setup klik warung building
	warung_building.input_event.connect(_on_warung_input_event)
	
	# Hubungkan signal
	GameData.inventori_berubah.connect(_update_inventori)
	
	_spawn_lokasi()
	_update_inventori()


func _on_map_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		player.pindah_ke(event.position)


func _on_warung_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		buka_warung.emit()


func _process(_delta: float) -> void:
	# Batasi pergerakan pemain di dalam MapArea
	if is_instance_valid(player) and is_instance_valid(map_area):
		var size = map_area.size
		player.position.x = clamp(player.position.x, 12, size.x - 12)
		player.position.y = clamp(player.position.y, 12, size.y - 12)
		
	# Tekan Space atau Enter untuk masuk ke lokasi
	if lokasi_aktif != "" and Input.is_action_just_pressed("ui_accept"):
		_kunjungi_lokasi(lokasi_aktif)


func _spawn_lokasi() -> void:
	# Tunggu frame pertama agar MapArea punya ukuran yang valid
	await get_tree().process_frame
	var size = map_area.size
	if size.x == 0: size = Vector2(640, 296) # Fallback
	
	# Posisi berdasarkan persentase agar responsif
	# Atur posisi agar tidak bertabrakan dengan WarungBuilding di (80, 220)
	var pos_persen = {
		"pasar": Vector2(0.25, 0.35),
		"sawah": Vector2(0.8, 0.25),
		"hutan": Vector2(0.75, 0.75),
		"pelabuhan": Vector2(0.35, 0.8),
		"pasar_malam": Vector2(0.55, 0.8),
		"pasar_loak": Vector2(0.5, 0.25)
	}
	
	var margin: float = 30.0
	
	for id_lokasi in GameData.data_locations:
		var data: Dictionary = GameData.data_locations[id_lokasi]
		var terbuka: bool = GameData.cek_lokasi_terbuka(id_lokasi)
		var nama: String = str(data.get("nama", id_lokasi))
		var warna_str: String = str(data.get("warna", "#888888"))
		var warna: Color = Color.from_string(warna_str, Color.GRAY)
		var persen = pos_persen.get(id_lokasi, Vector2(0.5, 0.5))
		
		# Kalkulasi posisi, pastikan tidak melewati batas margin
		var x = clamp(size.x * persen.x, margin, size.x - margin)
		var y = clamp(size.y * persen.y, margin, size.y - margin)
		
		var loc = scene_location_point.instantiate()
		lokasi_container.add_child(loc)
		loc.setup(id_lokasi, nama, warna, not terbuka, Vector2(x, y), size)
		loc.player_masuk.connect(_on_player_masuk_lokasi)
		loc.player_keluar.connect(_on_player_keluar_lokasi)


func _on_player_masuk_lokasi(id: String, nama: String) -> void:
	lokasi_aktif = id
	var terbuka: bool = GameData.cek_lokasi_terbuka(id)
	if terbuka:
		label_interaksi.text = "Tekan [SPACE] untuk masuk:\n" + nama
		panel_interaksi.add_theme_stylebox_override("panel", _buat_stylebox(Color(0.2, 0.6, 0.2)))
	else:
		var syarat = str(GameData.data_locations[id].get("syarat_buka", "???"))
		label_interaksi.text = "🔒 " + nama + "\n(Terkunci: " + syarat + ")"
		panel_interaksi.add_theme_stylebox_override("panel", _buat_stylebox(Color(0.6, 0.2, 0.2)))
	panel_interaksi.show()


func _on_player_keluar_lokasi(id: String) -> void:
	if lokasi_aktif == id:
		lokasi_aktif = ""
		panel_interaksi.hide()


func _kunjungi_lokasi(id_lokasi: String) -> void:
	if not GameData.cek_lokasi_terbuka(id_lokasi):
		return
	
	if GameData.pakai_slot_waktu():
		buka_lokasi.emit(id_lokasi)
	else:
		# Beri efek getar/merah jika tidak bisa masuk karena waktu habis
		var tween = create_tween()
		tween.tween_property(panel_interaksi, "modulate", Color.RED, 0.1)
		tween.tween_property(panel_interaksi, "modulate", Color.WHITE, 0.1)
		label_interaksi.text = "⏰ Waktu habis! Saatnya buka warung."


func _update_inventori() -> void:
	label_tas.text = "🎒 Tas (%d/%d)" % [GameData.hitung_total_item(), GameData.slot_tas_maks]


func _buat_stylebox(warna: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = warna
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
