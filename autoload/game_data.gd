# autoload/game_data.gd
# State global game — uang, hari, nyawa, inventori, upgrade, dll.
extends Node

# --- Signals ---
signal uang_berubah(nilai_baru: int)
signal nyawa_berubah(nilai_baru: int)
signal hari_berubah(hari_baru: int)
signal inventori_berubah()
signal slot_waktu_berubah(sisa: int)
signal cuaca_berubah(cuaca_baru: String)
signal lokasi_terbuka(lokasi_id: String)
signal game_over()

# --- Konstanta ---
const UANG_AWAL: int = 50000
const NYAWA_AWAL: int = 3
const SLOT_TAS_AWAL: int = 10
const SLOT_WAKTU_PER_HARI: int = 4
const KURSI_AWAL: int = 3

# --- State ---
var uang: int = UANG_AWAL
var hari: int = 1
var nyawa: int = NYAWA_AWAL
var slot_tas_maks: int = SLOT_TAS_AWAL
var slot_waktu_sisa: int = SLOT_WAKTU_PER_HARI
var jumlah_kursi: int = KURSI_AWAL
var cuaca: String = "cerah"  # cerah, hujan, berangin

# Inventori: {"id_bahan": {"jumlah": int, "hari_beli": int}}
var inventori: Dictionary = {}

# Lokasi yang sudah terbuka (id lokasi)
var lokasi_terbuka_list: Array = ["pasar", "sawah", "hutan"]

# Upgrade yang sudah dibeli (id upgrade)
var upgrade_dibeli: Array = []

# Koleksi hidden gem yang sudah ditemukan (id gem)
var koleksi_gem: Array = []

# Pelanggan spesial yang sudah dilayani (id customer)
var pelanggan_spesial_selesai: Array = []

# Statistik hari ini
var pendapatan_hari_ini: int = 0
var pelanggan_dilayani: int = 0
var pelanggan_pergi: int = 0

# Modifier dari upgrade
var cook_speed_multiplier: float = 1.0
var patience_bonus: float = 0.0
var spoil_delay_bonus: int = 0
var spawn_rate_multiplier: float = 1.0

# Data JSON yang di-load
var data_menu: Dictionary = {}
var data_ingredients: Dictionary = {}
var data_locations: Dictionary = {}
var data_recipes: Dictionary = {}
var data_customers: Dictionary = {}
var data_hidden_gems: Dictionary = {}
var data_upgrades: Dictionary = {}


func _ready() -> void:
	# Load semua data JSON saat game mulai
	_load_semua_data()


# --- Fungsi load data JSON ---
func _load_semua_data() -> void:
	data_menu = _load_json("res://data/menu.json")
	data_ingredients = _load_json("res://data/ingredients.json")
	data_locations = _load_json("res://data/locations.json")
	data_recipes = _load_json("res://data/recipes.json")
	data_customers = _load_json("res://data/customers.json")
	data_hidden_gems = _load_json("res://data/hidden_gems.json")
	data_upgrades = _load_json("res://data/upgrades.json")


func _load_json(path: String) -> Dictionary:
	# Baca file JSON dan kembalikan sebagai Dictionary
	if not FileAccess.file_exists(path):
		push_warning("File JSON tidak ditemukan: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_error("Gagal parse JSON %s: %s" % [path, json.get_error_message()])
		return {}
	return json.data


# --- Fungsi uang ---
func tambah_uang(jumlah: int) -> void:
	uang += jumlah
	uang_berubah.emit(uang)


func kurangi_uang(jumlah: int) -> bool:
	# Kembalikan true kalau uang cukup
	if uang >= jumlah:
		uang -= jumlah
		uang_berubah.emit(uang)
		return true
	return false


# --- Fungsi nyawa ---
func kurangi_nyawa() -> void:
	nyawa -= 1
	nyawa_berubah.emit(nyawa)
	if nyawa <= 0:
		game_over.emit()


func tambah_nyawa(jumlah: int = 1) -> void:
	nyawa += jumlah
	nyawa_berubah.emit(nyawa)


# --- Fungsi inventori ---
func hitung_total_item() -> int:
	# Hitung total item di tas
	var total: int = 0
	for key in inventori:
		total += inventori[key]["jumlah"]
	return total


func tas_penuh() -> bool:
	return hitung_total_item() >= slot_tas_maks


func tambah_item(id_item: String, jumlah: int = 1) -> bool:
	# Tambah item ke inventori, return false kalau tas penuh
	if hitung_total_item() + jumlah > slot_tas_maks:
		return false
	if id_item in inventori:
		inventori[id_item]["jumlah"] += jumlah
	else:
		inventori[id_item] = {"jumlah": jumlah, "hari_beli": hari}
	inventori_berubah.emit()
	return true


func kurangi_item(id_item: String, jumlah: int = 1) -> bool:
	# Kurangi item dari inventori
	if id_item not in inventori:
		return false
	if inventori[id_item]["jumlah"] < jumlah:
		return false
	inventori[id_item]["jumlah"] -= jumlah
	if inventori[id_item]["jumlah"] <= 0:
		inventori.erase(id_item)
	inventori_berubah.emit()
	return true


func punya_bahan_menu(id_menu: String) -> bool:
	# Cek apakah bahan untuk menu ini cukup
	var menu_data: Dictionary = {}
	if id_menu in data_menu:
		menu_data = data_menu[id_menu]
	elif id_menu in data_recipes:
		menu_data = data_recipes[id_menu]
	else:
		return false
	
	var bahan_perlu: Dictionary = menu_data.get("bahan", {})
	for bahan_id in bahan_perlu:
		var perlu: int = int(bahan_perlu[bahan_id])
		if bahan_id not in inventori:
			return false
		if inventori[bahan_id]["jumlah"] < perlu:
			return false
	return true


func pakai_bahan_menu(id_menu: String) -> bool:
	# Kurangi bahan untuk masak menu
	if not punya_bahan_menu(id_menu):
		return false
	
	var menu_data: Dictionary = {}
	if id_menu in data_menu:
		menu_data = data_menu[id_menu]
	elif id_menu in data_recipes:
		menu_data = data_recipes[id_menu]
	
	var bahan_perlu: Dictionary = menu_data.get("bahan", {})
	for bahan_id in bahan_perlu:
		kurangi_item(bahan_id, int(bahan_perlu[bahan_id]))
	return true


# --- Fungsi slot waktu ---
func pakai_slot_waktu() -> bool:
	if slot_waktu_sisa <= 0:
		return false
	slot_waktu_sisa -= 1
	slot_waktu_berubah.emit(slot_waktu_sisa)
	return true


# --- Fungsi hari ---
func hari_berikutnya() -> void:
	hari += 1
	slot_waktu_sisa = SLOT_WAKTU_PER_HARI
	pendapatan_hari_ini = 0
	pelanggan_dilayani = 0
	pelanggan_pergi = 0
	
	# Cek bahan basi
	_cek_bahan_basi()
	
	# Acak cuaca baru
	_acak_cuaca()
	
	hari_berubah.emit(hari)


func _cek_bahan_basi() -> void:
	# Hapus bahan yang sudah basi
	var bahan_basi: Array = []
	for id_item in inventori:
		# Cek di data ingredients
		if id_item in data_ingredients:
			var basi_hari: int = int(data_ingredients[id_item].get("basi_hari", -1))
			if basi_hari > 0:
				var hari_beli: int = inventori[id_item].get("hari_beli", hari)
				var usia: int = hari - hari_beli
				# spoil_delay_bonus menambah ketahanan (dari upgrade Kulkas)
				if usia >= (basi_hari + spoil_delay_bonus):
					bahan_basi.append(id_item)
	
	for id_item in bahan_basi:
		inventori.erase(id_item)
	
	if bahan_basi.size() > 0:
		inventori_berubah.emit()


func _acak_cuaca() -> void:
	# Cerah 60%, Hujan 30%, Berangin 10%
	var roll: float = randf()
	if roll < 0.6:
		cuaca = "cerah"
	elif roll < 0.9:
		cuaca = "hujan"
	else:
		cuaca = "berangin"
	cuaca_berubah.emit(cuaca)


# --- Fungsi lokasi ---
func buka_lokasi(id_lokasi: String) -> void:
	if id_lokasi not in lokasi_terbuka_list:
		lokasi_terbuka_list.append(id_lokasi)
		lokasi_terbuka.emit(id_lokasi)


func cek_lokasi_terbuka(id_lokasi: String) -> bool:
	return id_lokasi in lokasi_terbuka_list


# --- Fungsi upgrade ---
func beli_upgrade(id_upgrade: String) -> bool:
	if id_upgrade in upgrade_dibeli:
		return false
	if id_upgrade not in data_upgrades:
		return false
	
	var upgrade: Dictionary = data_upgrades[id_upgrade]
	var harga: int = int(upgrade["harga"])
	
	if not kurangi_uang(harga):
		return false
	
	upgrade_dibeli.append(id_upgrade)
	_terapkan_upgrade(upgrade)
	return true


func _terapkan_upgrade(upgrade: Dictionary) -> void:
	# Terapkan efek upgrade
	var efek: String = upgrade["efek"]
	var nilai = upgrade["nilai"]
	match efek:
		"cook_speed":
			cook_speed_multiplier = float(nilai)
		"extra_seat":
			jumlah_kursi += int(nilai)
		"bag_slots":
			slot_tas_maks += int(nilai)
		"patience_bonus":
			patience_bonus = float(nilai)
		"spoil_delay":
			spoil_delay_bonus = int(nilai)
		"spawn_rate":
			spawn_rate_multiplier = float(nilai)


# --- Fungsi koleksi ---
func tambah_koleksi_gem(id_gem: String) -> bool:
	# Return true kalau ini pertama kali ditemukan
	if id_gem in koleksi_gem:
		return false
	koleksi_gem.append(id_gem)
	return true


# --- Fungsi reset game ---
func reset_game() -> void:
	uang = UANG_AWAL
	hari = 1
	nyawa = NYAWA_AWAL
	slot_tas_maks = SLOT_TAS_AWAL
	slot_waktu_sisa = SLOT_WAKTU_PER_HARI
	jumlah_kursi = KURSI_AWAL
	cuaca = "cerah"
	inventori = {}
	lokasi_terbuka_list = ["pasar", "sawah", "hutan"]
	upgrade_dibeli = []
	koleksi_gem = []
	pelanggan_spesial_selesai = []
	pendapatan_hari_ini = 0
	pelanggan_dilayani = 0
	pelanggan_pergi = 0
	cook_speed_multiplier = 1.0
	patience_bonus = 0.0
	spoil_delay_bonus = 0
	spawn_rate_multiplier = 1.0


# --- Helper: nama waktu slot ---
func nama_slot_waktu() -> String:
	match slot_waktu_sisa:
		4: return "Pagi"
		3: return "Siang"
		2: return "Sore"
		1: return "Petang"
		_: return "Malam"


# --- Helper: semua menu yang bisa dimasak ---
func menu_tersedia() -> Array:
	# Gabungkan menu biasa dan resep spesial
	var tersedia: Array = []
	for id_menu in data_menu:
		tersedia.append(id_menu)
	for id_resep in data_recipes:
		tersedia.append(id_resep)
	return tersedia
