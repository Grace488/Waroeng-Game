# scenes/main.gd
# Scene utama — pindah antara Peta Dunia, Warung, dan layar lainnya
extends Control

# Referensi scene yang akan di-load
var scene_peta_dunia: PackedScene = preload("res://scenes/world_map/world_map.tscn")
var scene_warung: PackedScene = preload("res://scenes/stall/stall.tscn")
var scene_ringkasan: PackedScene = preload("res://scenes/ui/day_summary.tscn")
var scene_game_over: PackedScene = preload("res://scenes/ui/game_over.tscn")
var scene_lokasi: PackedScene = preload("res://scenes/world_map/location.tscn")
var scene_koleksi: PackedScene = preload("res://scenes/ui/collection_book.tscn")
var scene_upgrade: PackedScene = preload("res://scenes/upgrades/upgrade_shop.tscn")

# Container untuk scene aktif
@onready var container: Control = $Container
@onready var hud: Control = $HUD

# Scene yang sedang aktif
var scene_aktif: Node = null


func _ready() -> void:
	# Hubungkan signal dari GameData
	GameData.game_over.connect(_on_game_over)
	
	# Acak cuaca dan event hari pertama
	GameData._acak_cuaca()
	EventManager.acak_event_harian()
	
	# Mulai dari peta dunia
	pindah_ke_peta()


func _hapus_scene_aktif() -> void:
	# Hapus scene yang sedang tampil
	if scene_aktif != null:
		scene_aktif.queue_free()
		scene_aktif = null


func pindah_ke_peta() -> void:
	_hapus_scene_aktif()
	scene_aktif = scene_peta_dunia.instantiate()
	container.add_child(scene_aktif)
	# Hubungkan signal dari peta
	scene_aktif.buka_warung.connect(_on_buka_warung)
	scene_aktif.buka_lokasi.connect(_on_buka_lokasi)
	scene_aktif.buka_koleksi.connect(_on_buka_koleksi)
	scene_aktif.buka_upgrade.connect(_on_buka_upgrade)


func pindah_ke_warung() -> void:
	_hapus_scene_aktif()
	scene_aktif = scene_warung.instantiate()
	container.add_child(scene_aktif)
	# Hubungkan signal dari warung
	scene_aktif.warung_selesai.connect(_on_warung_selesai)


func pindah_ke_ringkasan() -> void:
	_hapus_scene_aktif()
	scene_aktif = scene_ringkasan.instantiate()
	container.add_child(scene_aktif)
	# Hubungkan signal dari ringkasan
	scene_aktif.hari_berikutnya.connect(_on_hari_berikutnya)


func pindah_ke_lokasi(id_lokasi: String) -> void:
	_hapus_scene_aktif()
	scene_aktif = scene_lokasi.instantiate()
	container.add_child(scene_aktif)
	scene_aktif.setup(id_lokasi)
	scene_aktif.kembali_ke_peta.connect(_on_kembali_dari_lokasi)


func pindah_ke_koleksi() -> void:
	_hapus_scene_aktif()
	scene_aktif = scene_koleksi.instantiate()
	container.add_child(scene_aktif)
	scene_aktif.kembali.connect(_on_kembali_dari_koleksi)


func pindah_ke_upgrade() -> void:
	_hapus_scene_aktif()
	scene_aktif = scene_upgrade.instantiate()
	container.add_child(scene_aktif)
	scene_aktif.kembali.connect(_on_kembali_dari_upgrade)


# --- Callbacks ---
func _on_buka_warung() -> void:
	pindah_ke_warung()


func _on_buka_lokasi(id_lokasi: String) -> void:
	pindah_ke_lokasi(id_lokasi)


func _on_buka_koleksi() -> void:
	pindah_ke_koleksi()


func _on_buka_upgrade() -> void:
	pindah_ke_upgrade()


func _on_kembali_dari_lokasi() -> void:
	pindah_ke_peta()


func _on_kembali_dari_koleksi() -> void:
	pindah_ke_peta()


func _on_kembali_dari_upgrade() -> void:
	pindah_ke_peta()


func _on_warung_selesai() -> void:
	# Setelah warung tutup, tampilkan ringkasan
	pindah_ke_ringkasan()


func _on_hari_berikutnya() -> void:
	# Mulai hari baru
	GameData.hari_berikutnya()
	EventManager.acak_event_harian()
	SaveManager.simpan_game()
	pindah_ke_peta()


func _on_game_over() -> void:
	_hapus_scene_aktif()
	scene_aktif = scene_game_over.instantiate()
	container.add_child(scene_aktif)
	scene_aktif.mulai_ulang.connect(_on_mulai_ulang)


func _on_mulai_ulang() -> void:
	GameData.reset_game()
	SaveManager.hapus_save()
	EventManager.acak_event_harian()
	pindah_ke_peta()
