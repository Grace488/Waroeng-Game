# autoload/event_manager.gd
# Kelola event acak harian: hujan, mati listrik, lonjakan harga
extends Node

signal event_terjadi(event: Dictionary)

# Event yang aktif hari ini
var event_hari_ini: Dictionary = {}

# Daftar event yang mungkin terjadi
var daftar_event: Array = [
	{
		"id": "lonjakan_harga",
		"nama": "Lonjakan Harga!",
		"deskripsi": "Harga bahan naik 50% hari ini karena kelangkaan.",
		"peluang": 0.15,
		"efek": "harga_naik",
		"nilai": 1.5
	},
	{
		"id": "diskon_besar",
		"nama": "Diskon Pasar!",
		"deskripsi": "Pasar sedang obral, harga turun 30%!",
		"peluang": 0.10,
		"efek": "harga_turun",
		"nilai": 0.7
	},
	{
		"id": "mati_listrik",
		"nama": "Mati Listrik!",
		"deskripsi": "Listrik padam, masak jadi 50% lebih lambat malam ini.",
		"peluang": 0.10,
		"efek": "masak_lambat",
		"nilai": 1.5
	},
	{
		"id": "pelanggan_ramai",
		"nama": "Warung Viral!",
		"deskripsi": "Warungmu masuk TikTok! Pelanggan datang lebih sering.",
		"peluang": 0.08,
		"efek": "spawn_cepat",
		"nilai": 0.5
	},
	{
		"id": "rezeki_nomplok",
		"nama": "Rezeki Nomplok!",
		"deskripsi": "Kamu menemukan uang di bawah gerobak! +5000",
		"peluang": 0.08,
		"efek": "bonus_uang",
		"nilai": 5000
	},
]

# Modifier harga dari event (reset tiap hari)
var modifier_harga: float = 1.0
# Modifier kecepatan masak dari event
var modifier_masak: float = 1.0
# Modifier spawn pelanggan dari event
var modifier_spawn: float = 1.0


func acak_event_harian() -> void:
	# Reset modifier
	modifier_harga = 1.0
	modifier_masak = 1.0
	modifier_spawn = 1.0
	event_hari_ini = {}
	
	# Coba setiap event
	for event in daftar_event:
		if randf() < event["peluang"]:
			event_hari_ini = event
			_terapkan_event(event)
			event_terjadi.emit(event)
			break  # Hanya 1 event per hari


func _terapkan_event(event: Dictionary) -> void:
	match event["efek"]:
		"harga_naik":
			modifier_harga = float(event["nilai"])
		"harga_turun":
			modifier_harga = float(event["nilai"])
		"masak_lambat":
			modifier_masak = float(event["nilai"])
		"spawn_cepat":
			modifier_spawn = float(event["nilai"])
		"bonus_uang":
			GameData.tambah_uang(int(event["nilai"]))


func harga_setelah_event(harga_dasar: int) -> int:
	# Hitung harga setelah modifier event + variasi harian
	var variasi: float = randf_range(0.85, 1.15)  # ±15% variasi acak
	return int(float(harga_dasar) * modifier_harga * variasi)
