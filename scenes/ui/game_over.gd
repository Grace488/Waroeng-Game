# scenes/ui/game_over.gd
# Layar game over — tampilkan skor akhir dan tombol mulai ulang
extends Control

signal mulai_ulang()

@onready var label_hari: Label = $Panel/VBox/LabelHari
@onready var label_uang: Label = $Panel/VBox/LabelUang
@onready var btn_ulang: Button = $Panel/VBox/BtnUlang


func _ready() -> void:
	label_hari.text = "Bertahan %d hari" % GameData.hari
	label_uang.text = "Saldo akhir: Rp %d" % GameData.uang
	btn_ulang.pressed.connect(func(): mulai_ulang.emit())
