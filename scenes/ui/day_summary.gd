# scenes/ui/day_summary.gd
# Ringkasan hari — pendapatan, pelanggan dilayani, pelanggan pergi
extends Control

signal hari_berikutnya()

@onready var label_hari: Label = $Panel/VBox/LabelHari
@onready var label_pendapatan: Label = $Panel/VBox/LabelPendapatan
@onready var label_dilayani: Label = $Panel/VBox/LabelDilayani
@onready var label_pergi: Label = $Panel/VBox/LabelPergi
@onready var label_saldo: Label = $Panel/VBox/LabelSaldo
@onready var label_cuaca: Label = $Panel/VBox/LabelCuaca
@onready var label_event: Label = $Panel/VBox/LabelEvent
@onready var label_basi: Label = $Panel/VBox/LabelBasi
@onready var btn_lanjut: Button = $Panel/VBox/BtnLanjut


func _ready() -> void:
	# Tampilkan ringkasan
	label_hari.text = "📅 Ringkasan Hari %d" % GameData.hari
	label_pendapatan.text = "💰 Pendapatan: Rp %d" % GameData.pendapatan_hari_ini
	label_dilayani.text = "😊 Pelanggan Dilayani: %d" % GameData.pelanggan_dilayani
	label_pergi.text = "😠 Pelanggan Pergi: %d" % GameData.pelanggan_pergi
	label_saldo.text = "💵 Saldo: Rp %d" % GameData.uang
	label_cuaca.text = "🌤️ Cuaca besok: (akan ditentukan)"
	label_event.text = ""
	label_basi.text = ""
	
	# Info event hari ini
	if EventManager.event_hari_ini.size() > 0:
		label_event.text = "⚡ Event: %s" % str(EventManager.event_hari_ini.get("nama", ""))
	
	btn_lanjut.pressed.connect(_on_btn_lanjut)


func _on_btn_lanjut() -> void:
	hari_berikutnya.emit()
