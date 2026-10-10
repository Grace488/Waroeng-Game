# scenes/world_map/world_map.gd
# Peta dunia — gerakkan karakter ke lokasi untuk masuk
extends Node2D

signal buka_warung()
signal buka_lokasi(id_lokasi: String)
signal buka_koleksi()
signal buka_upgrade()

@onready var label_info: Label = $UILayer/UI/PanelInfo/VBox/LabelInfo
@onready var label_slot: Label = $UILayer/UI/PanelInfo/VBox/LabelSlot
@onready var label_event: Label = $UILayer/UI/PanelInfo/VBox/LabelEvent
@onready var panel_inventori: VBoxContainer = $UILayer/UI/PanelBawah/InvScroll/InvContainer

@onready var btn_buka_warung: Button = $UILayer/UI/PanelBawah/HBoxKiri/VBoxBtn/HBoxAtas/BtnBukaWarung
@onready var btn_koleksi: Button = $UILayer/UI/PanelBawah/HBoxKiri/VBoxBtn/HBoxAtas/BtnKoleksi
@onready var btn_upgrade: Button = $UILayer/UI/PanelBawah/HBoxKiri/VBoxBtn/HBoxBawah/BtnUpgrade
@onready var btn_save: Button = $UILayer/UI/PanelBawah/HBoxKiri/VBoxBtn/HBoxBawah/BtnSave

@onready var lokasi_container: Node2D = $Locations
@onready var player: CharacterBody2D = $PlayerMap
@onready var panel_interaksi: PanelContainer = $UILayer/PanelInteraksi
@onready var label_interaksi: Label = $UILayer/PanelInteraksi/LabelInteraksi

var lokasi_aktif: String = ""
var scene_location_point: PackedScene = preload("res://scenes/world_map/location_point.tscn")


func _ready() -> void:
	# Sembunyikan panel interaksi di awal
	panel_interaksi.hide()
	
	# Setup tombol
	btn_buka_warung.pressed.connect(func(): buka_warung.emit())
	btn_koleksi.pressed.connect(func(): buka_koleksi.emit())
	btn_upgrade.pressed.connect(func(): buka_upgrade.emit())
	btn_save.pressed.connect(func(): 
		SaveManager.simpan_game()
		label_info.text = "✅ Game berhasil disimpan!"
	)
	
	# Hubungkan signal
	GameData.slot_waktu_berubah.connect(_on_slot_berubah)
	GameData.inventori_berubah.connect(_update_inventori)
	GameData.uang_berubah.connect(func(_v): _update_info())
	
	_spawn_lokasi()
	_update_info()
	_update_inventori()


func _process(_delta: float) -> void:
	# Tekan Space atau Enter untuk masuk ke lokasi
	if lokasi_aktif != "" and Input.is_action_just_pressed("ui_accept"):
		_kunjungi_lokasi(lokasi_aktif)


func _spawn_lokasi() -> void:
	# Posisi manual untuk tiap lokasi (bisa disesuaikan nanti)
	var posisi_lokasi = {
		"pasar": Vector2(180, 160),
		"sawah": Vector2(480, 120),
		"hutan": Vector2(350, 240),
		"pelabuhan": Vector2(100, 260),
		"pasar_malam": Vector2(500, 260),
		"pasar_loak": Vector2(250, 80)
	}
	
	for id_lokasi in GameData.data_locations:
		var data: Dictionary = GameData.data_locations[id_lokasi]
		var terbuka: bool = GameData.cek_lokasi_terbuka(id_lokasi)
		var nama: String = str(data.get("nama", id_lokasi))
		var warna_str: String = str(data.get("warna", "#888888"))
		var warna: Color = Color.from_string(warna_str, Color.GRAY)
		var pos = posisi_lokasi.get(id_lokasi, Vector2(randf_range(100, 500), randf_range(100, 300)))
		
		var loc = scene_location_point.instantiate()
		lokasi_container.add_child(loc)
		loc.setup(id_lokasi, nama, warna, not terbuka, pos)
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
		label_info.text = "⏰ Waktu habis! Saatnya buka warung."


func _update_info() -> void:
	label_info.text = "Hari %d | 💰 Rp %d" % [GameData.hari, GameData.uang]
	label_slot.text = "⏰ Waktu: %s (%d/4)" % [GameData.nama_slot_waktu(), GameData.slot_waktu_sisa]
	
	var nama_cuaca: String = "☀️ Cerah"
	if GameData.cuaca == "hujan": nama_cuaca = "🌧️ Hujan"
	elif GameData.cuaca == "berangin": nama_cuaca = "💨 Berangin"
	
	var teks_event: String = "Cuaca: " + nama_cuaca
	if EventManager.event_aktif != "":
		teks_event += " | 📢 " + EventManager.nama_event
	label_event.text = teks_event


func _on_slot_berubah(_sisa: int) -> void:
	_update_info()


func _update_inventori() -> void:
	# Hapus list lama
	for child in panel_inventori.get_children():
		child.queue_free()
	
	var label_header := Label.new()
	label_header.text = "🎒 Tas (%d/%d)" % [GameData.hitung_total_item(), GameData.slot_tas_maks]
	label_header.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	panel_inventori.add_child(label_header)
	
	for id_item in GameData.inventori:
		var info: Dictionary = GameData.inventori[id_item]
		var nama: String = id_item
		if id_item in GameData.data_ingredients:
			nama = str(GameData.data_ingredients[id_item].get("nama", id_item))
		elif id_item in GameData.data_hidden_gems:
			nama = str(GameData.data_hidden_gems[id_item].get("nama", id_item))
		
		var lbl := Label.new()
		lbl.text = "  %s x%d" % [nama, int(info["jumlah"])]
		panel_inventori.add_child(lbl)


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
