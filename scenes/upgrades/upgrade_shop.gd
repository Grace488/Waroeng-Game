# scenes/upgrades/upgrade_shop.gd
# Toko upgrade warung — beli peningkatan untuk warung
extends Control

signal kembali()

@onready var container: VBoxContainer = $VBox/ScrollUpgrade/UpgradeContainer
@onready var btn_kembali: Button = $VBox/PanelAtas/BtnKembali
@onready var label_uang: Label = $VBox/PanelAtas/LabelUang
@onready var label_status: Label = $VBox/LabelStatus


func _ready() -> void:
	btn_kembali.pressed.connect(func(): kembali.emit())
	GameData.uang_berubah.connect(func(_v): _update_tampilan())
	_update_tampilan()


func _update_tampilan() -> void:
	label_uang.text = "💰 Rp %d" % GameData.uang
	
	# Hapus isi lama
	for child in container.get_children():
		child.queue_free()
	
	# Judul
	var judul := Label.new()
	judul.text = "🔧 UPGRADE WARUNG"
	judul.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	container.add_child(judul)
	
	for id_upgrade in GameData.data_upgrades:
		var data: Dictionary = GameData.data_upgrades[id_upgrade]
		var sudah_beli: bool = id_upgrade in GameData.upgrade_dibeli
		var harga: int = int(data.get("harga", 0))
		var syarat_hari: int = int(data.get("syarat_hari", 1))
		var bisa_beli: bool = not sudah_beli and GameData.uang >= harga and GameData.hari >= syarat_hari
		
		var panel := PanelContainer.new()
		container.add_child(panel)
		
		var hbox := HBoxContainer.new()
		panel.add_child(hbox)
		
		# Info upgrade
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		var lbl_nama := Label.new()
		lbl_nama.text = str(data.get("nama", id_upgrade))
		if sudah_beli:
			lbl_nama.text += " ✅"
			lbl_nama.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		vbox.add_child(lbl_nama)
		
		var lbl_desc := Label.new()
		lbl_desc.text = str(data.get("deskripsi", ""))
		lbl_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(lbl_desc)
		
		# Tombol beli
		var btn := Button.new()
		if sudah_beli:
			btn.text = "Sudah dibeli"
			btn.disabled = true
		elif GameData.hari < syarat_hari:
			btn.text = "Buka di hari %d" % syarat_hari
			btn.disabled = true
		else:
			btn.text = "Beli Rp %d" % harga
			btn.disabled = not bisa_beli
			var id_capture: String = id_upgrade
			btn.pressed.connect(func(): _beli(id_capture))
		hbox.add_child(btn)


func _beli(id_upgrade: String) -> void:
	if GameData.beli_upgrade(id_upgrade):
		var data: Dictionary = GameData.data_upgrades[id_upgrade]
		label_status.text = "✅ %s berhasil dibeli!" % str(data.get("nama", id_upgrade))
		_update_tampilan()
	else:
		label_status.text = "❌ Gagal membeli upgrade."
