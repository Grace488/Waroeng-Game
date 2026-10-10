# autoload/save_manager.gd
# Simpan dan muat progress game ke file JSON
extends Node

const SAVE_PATH: String = "user://save.json"


func simpan_game() -> void:
	# Kumpulkan semua data yang perlu disimpan
	var data: Dictionary = {
		"uang": GameData.uang,
		"hari": GameData.hari,
		"nyawa": GameData.nyawa,
		"slot_tas_maks": GameData.slot_tas_maks,
		"jumlah_kursi": GameData.jumlah_kursi,
		"cuaca": GameData.cuaca,
		"inventori": GameData.inventori,
		"lokasi_terbuka": GameData.lokasi_terbuka_list,
		"upgrade_dibeli": GameData.upgrade_dibeli,
		"koleksi_gem": GameData.koleksi_gem,
		"pelanggan_spesial_selesai": GameData.pelanggan_spesial_selesai,
		"cook_speed_multiplier": GameData.cook_speed_multiplier,
		"patience_bonus": GameData.patience_bonus,
		"spoil_delay_bonus": GameData.spoil_delay_bonus,
		"spawn_rate_multiplier": GameData.spawn_rate_multiplier,
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Gagal membuka file save: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("Game berhasil disimpan!")


func muat_game() -> bool:
	# Muat data dari file save, return false kalau gagal
	if not FileAccess.file_exists(SAVE_PATH):
		print("Tidak ada file save.")
		return false
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Gagal membuka file save untuk dibaca.")
		return false
	
	var text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_error("Gagal parse file save: " + json.get_error_message())
		return false
	
	var data: Dictionary = json.data
	
	# Terapkan data ke GameData
	GameData.uang = int(data.get("uang", GameData.UANG_AWAL))
	GameData.hari = int(data.get("hari", 1))
	GameData.nyawa = int(data.get("nyawa", GameData.NYAWA_AWAL))
	GameData.slot_tas_maks = int(data.get("slot_tas_maks", GameData.SLOT_TAS_AWAL))
	GameData.jumlah_kursi = int(data.get("jumlah_kursi", GameData.KURSI_AWAL))
	GameData.cuaca = str(data.get("cuaca", "cerah"))
	GameData.inventori = data.get("inventori", {})
	GameData.lokasi_terbuka_list = Array(data.get("lokasi_terbuka", ["pasar", "sawah", "hutan"]))
	GameData.upgrade_dibeli = Array(data.get("upgrade_dibeli", []))
	GameData.koleksi_gem = Array(data.get("koleksi_gem", []))
	GameData.pelanggan_spesial_selesai = Array(data.get("pelanggan_spesial_selesai", []))
	GameData.cook_speed_multiplier = float(data.get("cook_speed_multiplier", 1.0))
	GameData.patience_bonus = float(data.get("patience_bonus", 0.0))
	GameData.spoil_delay_bonus = int(data.get("spoil_delay_bonus", 0))
	GameData.spawn_rate_multiplier = float(data.get("spawn_rate_multiplier", 1.0))
	
	# Emit semua signal supaya UI update
	GameData.uang_berubah.emit(GameData.uang)
	GameData.nyawa_berubah.emit(GameData.nyawa)
	GameData.hari_berubah.emit(GameData.hari)
	GameData.inventori_berubah.emit()
	GameData.cuaca_berubah.emit(GameData.cuaca)
	
	print("Game berhasil dimuat!")
	return true


func hapus_save() -> void:
	# Hapus file save
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("File save dihapus.")


func ada_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
