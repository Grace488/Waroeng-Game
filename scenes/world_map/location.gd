# scenes/world_map/location.gd
# Scene lokasi — daftar bahan yang bisa dibeli, termasuk hidden gem
extends Control

signal kembali_ke_peta()

var id_lokasi: String = ""
var data_lokasi: Dictionary = {}

@onready var label_nama: Label = $VBox/PanelAtas/VBoxInfo/LabelNama
@onready var label_deskripsi: Label = $VBox/PanelAtas/VBoxInfo/LabelDeskripsi
@onready var label_uang: Label = $VBox/PanelAtas/VBoxInfo/LabelUang
@onready var label_tas: Label = $VBox/PanelAtas/VBoxInfo/LabelTas
@onready var bahan_container: VBoxContainer = $VBox/ScrollBahan/BahanContainer
@onready var btn_kembali: Button = $VBox/PanelAtas/BtnKembali
@onready var label_status: Label = $VBox/LabelStatus

# Popup hidden gem
var popup_gem: Control = null


func _ready() -> void:
	btn_kembali.pressed.connect(func(): kembali_ke_peta.emit())
	GameData.inventori_berubah.connect(_update_tampilan)
	GameData.uang_berubah.connect(func(_v): _update_tampilan())


func setup(lokasi_id: String) -> void:
	id_lokasi = lokasi_id
	data_lokasi = GameData.data_locations.get(lokasi_id, {})
	
	# Tunggu node siap
	if not is_node_ready():
		await ready
	
	_update_tampilan()
	_cek_hidden_gem()


func _update_tampilan() -> void:
	label_nama.text = "📍 " + str(data_lokasi.get("nama", id_lokasi))
	label_deskripsi.text = str(data_lokasi.get("deskripsi", ""))
	label_uang.text = "💰 Rp %d" % GameData.uang
	label_tas.text = "🎒 Tas: %d/%d" % [GameData.hitung_total_item(), GameData.slot_tas_maks]
	
	# Hapus tombol bahan lama
	for child in bahan_container.get_children():
		child.queue_free()
	
	# Header
	var header := Label.new()
	header.text = "🛒 Bahan Tersedia:"
	header.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	bahan_container.add_child(header)
	
	# Tampilkan bahan yang dijual di lokasi ini
	var bahan_list: Array = Array(data_lokasi.get("bahan_tersedia", []))
	for id_bahan in bahan_list:
		if id_bahan not in GameData.data_ingredients:
			continue
		var data_bahan: Dictionary = GameData.data_ingredients[id_bahan]
		_buat_tombol_bahan(id_bahan, data_bahan, false)


func _buat_tombol_bahan(id_bahan: String, data_bahan: Dictionary, is_gem: bool) -> void:
	var hbox := HBoxContainer.new()
	bahan_container.add_child(hbox)
	
	# Kotak warna (emas untuk hidden gem)
	var color_box := ColorRect.new()
	color_box.custom_minimum_size = Vector2(16, 16)
	color_box.color = Color(1, 0.84, 0) if is_gem else Color(0.5, 0.8, 0.5)
	hbox.add_child(color_box)
	
	# Harga dengan modifier event & variasi harian
	var harga_dasar: int = int(data_bahan.get("harga_dasar", data_bahan.get("harga_beli", 1000)))
	var harga_akhir: int = EventManager.harga_setelah_event(harga_dasar)
	
	# Info bahan
	var nama: String = str(data_bahan.get("nama", id_bahan))
	var deskripsi: String = str(data_bahan.get("deskripsi", ""))
	
	var lbl := Label.new()
	lbl.text = "%s — Rp %d" % [nama, harga_akhir]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_gem:
		lbl.add_theme_color_override("font_color", Color(1, 0.84, 0))
	hbox.add_child(lbl)
	
	# Tombol beli
	var btn_beli := Button.new()
	btn_beli.text = "Beli"
	btn_beli.disabled = GameData.uang < harga_akhir or GameData.tas_penuh()
	
	# Cek apakah lokasi bisa tawar
	var bisa_tawar: bool = bool(data_lokasi.get("bisa_tawar", false))
	
	var bahan_id_capture: String = id_bahan
	var harga_capture: int = harga_akhir
	var harga_dasar_capture: int = harga_dasar
	var nama_capture: String = nama
	
	btn_beli.pressed.connect(func(): _beli_bahan(bahan_id_capture, harga_capture, nama_capture))
	hbox.add_child(btn_beli)
	
	# Tombol tawar (kalau lokasi mendukung)
	if bisa_tawar:
		var btn_tawar := Button.new()
		btn_tawar.text = "Tawar!"
		btn_tawar.disabled = GameData.uang < harga_akhir or GameData.tas_penuh()
		btn_tawar.pressed.connect(func(): _mulai_tawar(bahan_id_capture, harga_dasar_capture, harga_capture, nama_capture))
		hbox.add_child(btn_tawar)
	
	# Deskripsi di bawah
	var lbl_desc := Label.new()
	lbl_desc.text = "    %s" % deskripsi
	lbl_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	bahan_container.add_child(lbl_desc)


func _beli_bahan(id_bahan: String, harga: int, nama: String) -> void:
	if GameData.tas_penuh():
		label_status.text = "❌ Tas penuh! Tidak bisa beli lagi."
		return
	if not GameData.kurangi_uang(harga):
		label_status.text = "❌ Uang tidak cukup!"
		return
	
	GameData.tambah_item(id_bahan)
	label_status.text = "✅ Membeli %s seharga Rp %d" % [nama, harga]
	
	# Cek kalau ini hidden gem pertama kali
	if id_bahan in GameData.data_hidden_gems:
		var baru: bool = GameData.tambah_koleksi_gem(id_bahan)
		if baru:
			_tampilkan_popup_gem(id_bahan)


func _cek_hidden_gem() -> void:
	# Cek apakah ada hidden gem yang muncul di lokasi ini
	for id_gem in GameData.data_hidden_gems:
		var data_gem: Dictionary = GameData.data_hidden_gems[id_gem]
		
		# Cek lokasi
		if str(data_gem.get("lokasi", "")) != id_lokasi:
			continue
		
		# Cek syarat waktu
		var syarat_waktu: String = str(data_gem.get("syarat_waktu", ""))
		if syarat_waktu != "" and syarat_waktu != "<null>":
			var waktu_sekarang: String = GameData.nama_slot_waktu().to_lower()
			if syarat_waktu != waktu_sekarang:
				continue
		
		# Cek syarat cuaca
		var syarat_cuaca: String = str(data_gem.get("syarat_cuaca", ""))
		if syarat_cuaca != "" and syarat_cuaca != "<null>" and syarat_cuaca != "null":
			if GameData.cuaca != syarat_cuaca:
				continue
		
		# Cek peluang
		var peluang: float = float(data_gem.get("peluang", 0.1))
		if randf() > peluang:
			continue
		
		# Hidden gem muncul! Tampilkan di daftar bahan
		_buat_tombol_bahan(id_gem, data_gem, true)


# --- Mini-game tawar-menawar ---
func _mulai_tawar(id_bahan: String, harga_dasar: int, harga_normal: int, nama: String) -> void:
	# Buat popup tawar-menawar sederhana
	# Marker bergerak dari kiri ke kanan, tekan tombol saat di zona hijau
	var popup := PanelContainer.new()
	popup.anchors_preset = Control.PRESET_CENTER
	popup.offset_left = -150
	popup.offset_top = -60
	popup.offset_right = 150
	popup.offset_bottom = 60
	popup.z_index = 100
	add_child(popup)
	
	var vbox := VBoxContainer.new()
	popup.add_child(vbox)
	
	var lbl := Label.new()
	lbl.text = "🤝 Tawar %s! Klik saat marker di zona hijau!" % nama
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	
	# Bar tawar
	var bar_container := Control.new()
	bar_container.custom_minimum_size = Vector2(280, 30)
	vbox.add_child(bar_container)
	
	# Background bar
	var bar_bg := ColorRect.new()
	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.color = Color(0.8, 0.2, 0.2)
	bar_container.add_child(bar_bg)
	
	# Zona hijau (posisi acak, lebar 60-80px)
	var zona_hijau := ColorRect.new()
	var zona_start: float = randf_range(0.2, 0.6)
	var zona_width: float = randf_range(0.15, 0.25)
	zona_hijau.position = Vector2(zona_start * 280, 0)
	zona_hijau.size = Vector2(zona_width * 280, 30)
	zona_hijau.color = Color(0.2, 0.8, 0.2)
	bar_container.add_child(zona_hijau)
	
	# Marker bergerak
	var marker := ColorRect.new()
	marker.size = Vector2(4, 30)
	marker.color = Color.WHITE
	bar_container.add_child(marker)
	
	# Tombol tekan
	var btn_tekan := Button.new()
	btn_tekan.text = "TEKAN!"
	vbox.add_child(btn_tekan)
	
	# Animasi marker
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(marker, "position:x", 276.0, 1.5)
	tween.tween_property(marker, "position:x", 0.0, 1.5)
	
	btn_tekan.pressed.connect(func():
		tween.kill()
		var marker_pos: float = marker.position.x
		var zona_min: float = zona_hijau.position.x
		var zona_max: float = zona_hijau.position.x + zona_hijau.size.x
		
		popup.queue_free()
		
		if marker_pos >= zona_min and marker_pos <= zona_max:
			# Berhasil tawar! Diskon 20-40%
			var diskon: float = randf_range(0.6, 0.8)
			var harga_tawar: int = int(float(harga_normal) * diskon)
			label_status.text = "🎉 Berhasil tawar! Harga turun ke Rp %d" % harga_tawar
			_beli_bahan(id_bahan, harga_tawar, nama)
		else:
			# Gagal tawar, harga tetap
			label_status.text = "😅 Gagal tawar! Harga tetap Rp %d" % harga_normal
	)


func _tampilkan_popup_gem(id_gem: String) -> void:
	# Popup penemuan hidden gem
	var data: Dictionary = GameData.data_hidden_gems[id_gem]
	
	var popup := PanelContainer.new()
	popup.anchors_preset = Control.PRESET_CENTER
	popup.offset_left = -160
	popup.offset_top = -80
	popup.offset_right = 160
	popup.offset_bottom = 80
	popup.z_index = 100
	add_child(popup)
	
	var vbox := VBoxContainer.new()
	popup.add_child(vbox)
	
	var lbl_judul := Label.new()
	lbl_judul.text = "✨ HIDDEN GEM DITEMUKAN! ✨"
	lbl_judul.add_theme_color_override("font_color", Color(1, 0.84, 0))
	lbl_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_judul)
	
	var lbl_nama := Label.new()
	lbl_nama.text = str(data.get("nama", id_gem))
	lbl_nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_nama)
	
	var lbl_cerita := Label.new()
	lbl_cerita.text = str(data.get("cerita", ""))
	lbl_cerita.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(lbl_cerita)
	
	var btn_ok := Button.new()
	btn_ok.text = "Keren!"
	btn_ok.pressed.connect(func(): popup.queue_free())
	vbox.add_child(btn_ok)
