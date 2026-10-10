# scenes/world_map/world_map.gd
# Peta dunia — pilih lokasi untuk beli bahan atau buka warung
extends Control

signal buka_warung()
signal buka_lokasi(id_lokasi: String)
signal buka_koleksi()
signal buka_upgrade()

@onready var lokasi_container: VBoxContainer = $VBox/ScrollLokasi/LokasiContainer
@onready var label_info: Label = $VBox/PanelInfo/LabelInfo
@onready var btn_buka_warung: Button = $VBox/PanelBawah/HBox/BtnBukaWarung
@onready var btn_koleksi: Button = $VBox/PanelBawah/HBox/BtnKoleksi
@onready var btn_upgrade: Button = $VBox/PanelBawah/HBox/BtnUpgrade
@onready var btn_save: Button = $VBox/PanelBawah/HBox/BtnSave
@onready var label_slot: Label = $VBox/PanelInfo/LabelSlot
@onready var panel_inventori: VBoxContainer = $VBox/PanelBawah/InvScroll/InvContainer
@onready var label_event: Label = $VBox/PanelInfo/LabelEvent


func _ready() -> void:
	# Tombol buka warung
	btn_buka_warung.pressed.connect(func(): buka_warung.emit())
	btn_koleksi.pressed.connect(func(): buka_koleksi.emit())
	btn_upgrade.pressed.connect(func(): buka_upgrade.emit())
	btn_save.pressed.connect(_on_save)
	
	# Hubungkan signal
	GameData.slot_waktu_berubah.connect(_on_slot_berubah)
	GameData.inventori_berubah.connect(_update_inventori)
	
	# Tampilkan lokasi
	_update_lokasi()
	_update_info()
	_update_inventori()


func _update_lokasi() -> void:
	# Hapus tombol lokasi lama
	for child in lokasi_container.get_children():
		child.queue_free()
	
	# Judul
	var judul := Label.new()
	judul.text = "🗺️ PETA DUNIA — Pilih lokasi untuk dikunjungi"
	judul.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	lokasi_container.add_child(judul)
	
	# Buat tombol untuk setiap lokasi
	for id_lokasi in GameData.data_locations:
		var data: Dictionary = GameData.data_locations[id_lokasi]
		var terbuka: bool = GameData.cek_lokasi_terbuka(id_lokasi)
		
		var hbox := HBoxContainer.new()
		lokasi_container.add_child(hbox)
		
		# Kotak warna lokasi
		var color_box := ColorRect.new()
		color_box.custom_minimum_size = Vector2(20, 20)
		var warna_str: String = str(data.get("warna", "#888888"))
		color_box.color = Color.from_string(warna_str, Color.GRAY)
		hbox.add_child(color_box)
		
		var btn := Button.new()
		var nama: String = str(data.get("nama", id_lokasi))
		var deskripsi: String = str(data.get("deskripsi", ""))
		
		if terbuka:
			btn.text = "%s — %s" % [nama, deskripsi]
			btn.disabled = GameData.slot_waktu_sisa <= 0
			var lokasi_id_capture: String = id_lokasi
			btn.pressed.connect(func(): _kunjungi_lokasi(lokasi_id_capture))
		else:
			btn.text = "🔒 %s (Terkunci: %s)" % [nama, str(data.get("syarat_buka", "???"))]
			btn.disabled = true
		
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(btn)


func _kunjungi_lokasi(id_lokasi: String) -> void:
	if GameData.pakai_slot_waktu():
		buka_lokasi.emit(id_lokasi)
	else:
		label_info.text = "⏰ Slot waktu habis! Saatnya buka warung."


func _update_info() -> void:
	label_slot.text = "⏰ Slot waktu: %d/%d (%s)" % [
		GameData.slot_waktu_sisa, GameData.SLOT_WAKTU_PER_HARI, GameData.nama_slot_waktu()
	]
	label_info.text = "Hari %d | Cuaca: %s | Uang: Rp %d" % [
		GameData.hari, GameData.cuaca.capitalize(), GameData.uang
	]
	
	# Tampilkan event
	if EventManager.event_hari_ini.size() > 0:
		label_event.text = "⚡ %s: %s" % [
			str(EventManager.event_hari_ini.get("nama", "")),
			str(EventManager.event_hari_ini.get("deskripsi", ""))
		]
	else:
		label_event.text = ""
	
	# Disable tombol warung kalau masih ada slot
	btn_buka_warung.disabled = false  # Selalu bisa buka warung


func _on_slot_berubah(_sisa: int) -> void:
	_update_info()
	_update_lokasi()


func _update_inventori() -> void:
	for child in panel_inventori.get_children():
		child.queue_free()
	
	var header := Label.new()
	header.text = "🎒 Tas (%d/%d)" % [GameData.hitung_total_item(), GameData.slot_tas_maks]
	header.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	panel_inventori.add_child(header)
	
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


func _on_save() -> void:
	SaveManager.simpan_game()
	label_info.text = "💾 Game berhasil disimpan!"
