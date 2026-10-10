# scenes/stall/stall.gd
# Scene warung malam — pelanggan datang, masak, sajikan
extends Control

signal warung_selesai()

# Referensi scene pelanggan
var scene_pelanggan: PackedScene = preload("res://scenes/stall/customer.tscn")

# Node referensi
@onready var kursi_container: HBoxContainer = $VBox/AreaWarung/KursiContainer
@onready var menu_container: VBoxContainer = $VBox/PanelBawah/HBox/MenuScroll/MenuContainer
@onready var inventori_container: VBoxContainer = $VBox/PanelBawah/HBox/InvScroll/InvContainer
@onready var label_status: Label = $VBox/PanelBawah/HBox/StatusPanel/LabelStatus
@onready var timer_spawn: Timer = $TimerSpawn
@onready var timer_warung: Timer = $TimerWarung
@onready var label_timer: Label = $VBox/AreaWarung/LabelTimer
@onready var btn_selesai: Button = $VBox/PanelBawah/HBox/StatusPanel/BtnSelesai
@onready var progress_masak: ProgressBar = $VBox/PanelBawah/HBox/StatusPanel/ProgressMasak

# State warung
var pelanggan_aktif: Array = []  # Node pelanggan yang sedang duduk
var sedang_masak: bool = false
var menu_sedang_dimasak: String = ""
var waktu_masak_total: float = 0.0
var waktu_masak_sisa: float = 0.0
var durasi_warung: float = 90.0  # 90 detik per malam
var waktu_warung_sisa: float = 0.0

# Antrian pesanan yang sudah dimasak (siap disajikan)
var masakan_siap: Array = []  # Array of menu id yang sudah selesai dimasak


func _ready() -> void:
	# Setup timer spawn pelanggan
	timer_spawn.wait_time = randf_range(4.0, 8.0) * GameData.spawn_rate_multiplier
	timer_spawn.one_shot = true
	timer_spawn.timeout.connect(_on_timer_spawn_timeout)
	timer_spawn.start()
	
	# Setup timer durasi warung
	waktu_warung_sisa = durasi_warung
	timer_warung.wait_time = 1.0
	timer_warung.timeout.connect(_on_timer_warung_tick)
	timer_warung.start()
	
	# Setup tombol selesai
	btn_selesai.pressed.connect(_on_btn_selesai_pressed)
	
	# Tampilkan menu yang tersedia
	_update_menu()
	_update_inventori()
	
	# Hubungkan signal inventori
	GameData.inventori_berubah.connect(_update_inventori)
	GameData.inventori_berubah.connect(_update_menu)
	
	# Cek sprite background warung
	if ResourceLoader.exists("res://assets/sprites/warung_interior.png"):
		var tex = load("res://assets/sprites/warung_interior.png")
		var trect = TextureRect.new()
		trect.texture = tex
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		trect.set_anchors_preset(Control.PRESET_FULL_RECT)
		trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		# Sembunyikan warna solid lama
		var bg_warung = $VBox/AreaWarung/BGWarung
		if bg_warung:
			bg_warung.hide()
			
		$VBox/AreaWarung.add_child(trect)
		$VBox/AreaWarung.move_child(trect, 0)
	else:
		print("WARNING: Sprite interior warung tidak ditemukan! Menggunakan latar warna solid.")

	# Progress masak awalnya tersembunyi
	progress_masak.visible = false
	
	label_status.text = "Warung buka! Pelanggan akan datang..."


func _process(delta: float) -> void:
	# Update progress masak
	if sedang_masak:
		waktu_masak_sisa -= delta
		if waktu_masak_sisa <= 0:
			_selesai_masak()
		else:
			progress_masak.value = (1.0 - waktu_masak_sisa / waktu_masak_total) * 100.0


func _on_timer_warung_tick() -> void:
	waktu_warung_sisa -= 1.0
	var menit: int = floori(waktu_warung_sisa / 60.0)
	var detik: int = int(waktu_warung_sisa) % 60
	label_timer.text = "⏰ %d:%02d" % [menit, detik]
	
	if waktu_warung_sisa <= 0:
		_warung_tutup()


func _on_timer_spawn_timeout() -> void:
	# Spawn pelanggan baru kalau masih ada kursi kosong
	if pelanggan_aktif.size() < GameData.jumlah_kursi and waktu_warung_sisa > 0:
		_spawn_pelanggan()
	
	# Set timer berikutnya
	if waktu_warung_sisa > 10:  # Jangan spawn di detik-detik terakhir
		timer_spawn.wait_time = randf_range(4.0, 8.0) * GameData.spawn_rate_multiplier
		timer_spawn.start()


func _spawn_pelanggan() -> void:
	var pelanggan: Control = scene_pelanggan.instantiate()
	kursi_container.add_child(pelanggan)
	pelanggan_aktif.append(pelanggan)
	
	# Pilih pesanan acak dari menu yang tersedia
	var menu_tersedia: Array = []
	for id_menu in GameData.data_menu:
		menu_tersedia.append(id_menu)
	
	if menu_tersedia.size() == 0:
		return
	
	var pesanan: String = menu_tersedia[randi() % menu_tersedia.size()]
	var kesabaran: float = randf_range(20.0, 35.0) + GameData.patience_bonus
	
	# Cek apakah ini pelanggan spesial
	var pelanggan_spesial_id: String = _cek_pelanggan_spesial()
	if pelanggan_spesial_id != "":
		var data_spesial: Dictionary = GameData.data_customers[pelanggan_spesial_id]
		var pesanan_rahasia = data_spesial.get("pesanan_rahasia", null)
		# Kalau pesanan_rahasia null (seperti kolektor), pakai pesanan biasa
		if pesanan_rahasia != null and str(pesanan_rahasia) != "<null>" and str(pesanan_rahasia) != "null":
			pesanan = str(pesanan_rahasia)
		kesabaran = float(data_spesial.get("kesabaran", kesabaran))
		pelanggan.setup_spesial(pelanggan_spesial_id, pesanan, kesabaran, data_spesial)
	else:
		pelanggan.setup(pesanan, kesabaran)
	
	# Hubungkan signal pelanggan
	pelanggan.pelanggan_pergi.connect(_on_pelanggan_pergi)
	pelanggan.pelanggan_diklik.connect(_on_pelanggan_diklik)


func _cek_pelanggan_spesial() -> String:
	# Cek apakah pelanggan spesial bisa muncul
	for id_cust in GameData.data_customers:
		if id_cust in GameData.pelanggan_spesial_selesai:
			continue
		var data: Dictionary = GameData.data_customers[id_cust]
		var hari_min: int = int(data.get("muncul_hari_min", 999))
		if GameData.hari < hari_min:
			continue
		# Cek syarat cuaca
		var syarat_cuaca: String = str(data.get("syarat_cuaca", ""))
		if syarat_cuaca != "" and syarat_cuaca != "<null>" and GameData.cuaca != syarat_cuaca:
			continue
		# Peluang 20% muncul
		if randf() < 0.2:
			return id_cust
	return ""


func _on_pelanggan_pergi(pelanggan_node: Control) -> void:
	# Pelanggan pergi karena kehabisan kesabaran
	pelanggan_aktif.erase(pelanggan_node)
	GameData.pelanggan_pergi += 1
	GameData.kurangi_nyawa()
	label_status.text = "😠 Pelanggan pergi! Nyawa berkurang!"
	pelanggan_node.queue_free()


func _on_pelanggan_diklik(pelanggan_node: Control) -> void:
	# Coba sajikan makanan ke pelanggan
	var pesanan_id: String = pelanggan_node.pesanan_id
	
	if pesanan_id in masakan_siap:
		# Sajikan makanan
		masakan_siap.erase(pesanan_id)
		pelanggan_aktif.erase(pelanggan_node)
		
		# Ambil harga jual
		var data_menu: Dictionary = RecipeManager.ambil_data_menu(pesanan_id)
		var harga: int = int(data_menu.get("harga_jual", 0))
		GameData.tambah_uang(harga)
		GameData.pendapatan_hari_ini += harga
		GameData.pelanggan_dilayani += 1
		
		# Cek pelanggan spesial
		if pelanggan_node.is_spesial:
			_hadiah_pelanggan_spesial(pelanggan_node.spesial_id)
		
		label_status.text = "😊 Pesanan %s disajikan! +Rp %d" % [data_menu.get("nama", ""), harga]
		pelanggan_node.queue_free()
		_update_menu()
	else:
		# Belum ada masakan yang sesuai
		label_status.text = "❌ Belum ada %s yang siap!" % RecipeManager.ambil_data_menu(pesanan_id).get("nama", pesanan_id)


func _hadiah_pelanggan_spesial(id_cust: String) -> void:
	GameData.pelanggan_spesial_selesai.append(id_cust)
	var data: Dictionary = GameData.data_customers[id_cust]
	var hadiah: Dictionary = data.get("hadiah", {})
	
	if "uang" in hadiah:
		GameData.tambah_uang(int(hadiah["uang"]))
	if "buka_lokasi" in hadiah:
		GameData.buka_lokasi(str(hadiah["buka_lokasi"]))
	if "item" in hadiah:
		GameData.tambah_item(str(hadiah["item"]))
	
	label_status.text = "⭐ Pelanggan spesial %s senang! %s" % [data.get("nama", ""), data.get("cerita", "")]


# --- Memasak ---
func _mulai_masak(id_menu: String) -> void:
	if sedang_masak:
		label_status.text = "⏳ Masih memasak, tunggu sebentar..."
		return
	
	# Cek dan pakai bahan
	if not GameData.pakai_bahan_menu(id_menu):
		label_status.text = "❌ Bahan tidak cukup!"
		return
	
	var data: Dictionary = RecipeManager.ambil_data_menu(id_menu)
	var waktu: float = float(data.get("waktu_masak", 3.0))
	waktu *= GameData.cook_speed_multiplier * EventManager.modifier_masak
	
	sedang_masak = true
	menu_sedang_dimasak = id_menu
	waktu_masak_total = waktu
	waktu_masak_sisa = waktu
	
	progress_masak.visible = true
	progress_masak.value = 0
	
	label_status.text = "🍳 Memasak %s... (%.1f detik)" % [data.get("nama", ""), waktu]
	_update_menu()


func _selesai_masak() -> void:
	sedang_masak = false
	progress_masak.visible = false
	masakan_siap.append(menu_sedang_dimasak)
	
	var data: Dictionary = RecipeManager.ambil_data_menu(menu_sedang_dimasak)
	label_status.text = "✅ %s siap! Klik pelanggan untuk menyajikan." % data.get("nama", "")
	menu_sedang_dimasak = ""
	_update_menu()


# --- Update UI Menu ---
func _update_menu() -> void:
	# Hapus tombol menu lama
	for child in menu_container.get_children():
		child.queue_free()
	
	# Buat tombol untuk setiap menu
	var semua_menu: Dictionary = RecipeManager.semua_menu_dan_resep()
	for id_menu in semua_menu:
		var data: Dictionary = semua_menu[id_menu]
		var btn := Button.new()
		var punya_bahan: bool = GameData.punya_bahan_menu(id_menu)
		var nama: String = str(data.get("nama", id_menu))
		var harga: int = int(data.get("harga_jual", 0))
		var waktu: float = float(data.get("waktu_masak", 0))
		
		btn.text = "%s (Rp%d, %.0fs)" % [nama, harga, waktu]
		btn.disabled = not punya_bahan or sedang_masak
		
		# Warna berbeda untuk resep spesial
		if id_menu in GameData.data_recipes:
			btn.add_theme_color_override("font_color", Color(1, 0.84, 0))  # Emas
		
		var menu_id_capture: String = id_menu
		btn.pressed.connect(func(): _mulai_masak(menu_id_capture))
		menu_container.add_child(btn)


# --- Update UI Inventori ---
func _update_inventori() -> void:
	for child in inventori_container.get_children():
		child.queue_free()
	
	var label_header := Label.new()
	label_header.text = "🎒 Tas (%d/%d)" % [GameData.hitung_total_item(), GameData.slot_tas_maks]
	label_header.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	inventori_container.add_child(label_header)
	
	for id_item in GameData.inventori:
		var info: Dictionary = GameData.inventori[id_item]
		var nama: String = id_item
		# Cari nama asli dari data
		if id_item in GameData.data_ingredients:
			nama = str(GameData.data_ingredients[id_item].get("nama", id_item))
		elif id_item in GameData.data_hidden_gems:
			nama = str(GameData.data_hidden_gems[id_item].get("nama", id_item))
		
		var lbl := Label.new()
		lbl.text = "  %s x%d" % [nama, int(info["jumlah"])]
		inventori_container.add_child(lbl)


func _warung_tutup() -> void:
	# Warung tutup — pelanggan sisa pergi
	timer_spawn.stop()
	timer_warung.stop()
	
	for p in pelanggan_aktif:
		if is_instance_valid(p):
			p.queue_free()
	pelanggan_aktif.clear()
	
	label_status.text = "🌙 Warung tutup! Waktunya istirahat."
	
	# Tunggu sebentar lalu pindah ke ringkasan
	await get_tree().create_timer(2.0).timeout
	warung_selesai.emit()


func _on_btn_selesai_pressed() -> void:
	# Tombol tutup warung manual
	_warung_tutup()
