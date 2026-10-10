# scenes/ui/hud.gd
# HUD atas — tampilkan uang, nyawa, hari, cuaca, slot waktu
extends PanelContainer

@onready var label_uang: Label = $HBox/LabelUang
@onready var label_nyawa: Label = $HBox/LabelNyawa
@onready var label_hari: Label = $HBox/LabelHari
@onready var label_cuaca: Label = $HBox/LabelCuaca
@onready var label_waktu: Label = $HBox/LabelWaktu


func _ready() -> void:
	# Hubungkan signal dari GameData
	GameData.uang_berubah.connect(_on_uang_berubah)
	GameData.nyawa_berubah.connect(_on_nyawa_berubah)
	GameData.hari_berubah.connect(_on_hari_berubah)
	GameData.cuaca_berubah.connect(_on_cuaca_berubah)
	GameData.slot_waktu_berubah.connect(_on_slot_waktu_berubah)
	
	# Tampilkan nilai awal
	_update_semua()


func _update_semua() -> void:
	_on_uang_berubah(GameData.uang)
	_on_nyawa_berubah(GameData.nyawa)
	_on_hari_berubah(GameData.hari)
	_on_cuaca_berubah(GameData.cuaca)
	_on_slot_waktu_berubah(GameData.slot_waktu_sisa)


func _on_uang_berubah(nilai: int) -> void:
	label_uang.text = "💰 Rp %s" % _format_uang(nilai)


func _on_nyawa_berubah(nilai: int) -> void:
	label_nyawa.text = "❤️ " + "♥".repeat(max(nilai, 0))


func _on_hari_berubah(hari: int) -> void:
	label_hari.text = "📅 Hari %d" % hari


func _on_cuaca_berubah(cuaca: String) -> void:
	var emoji: String = "☀️"
	match cuaca:
		"hujan": emoji = "🌧️"
		"berangin": emoji = "💨"
	label_cuaca.text = emoji + " " + cuaca.capitalize()


func _on_slot_waktu_berubah(_sisa: int) -> void:
	label_waktu.text = "⏰ " + GameData.nama_slot_waktu()


func _format_uang(nilai: int) -> String:
	# Format angka dengan titik pemisah ribuan
	var s: String = str(nilai)
	var hasil: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			hasil = "." + hasil
		hasil = s[i] + hasil
		count += 1
	return hasil
