# scenes/ui/collection_book.gd
# Buku Koleksi — tampilkan semua hidden gem yang sudah/belum ditemukan
extends Control

signal kembali()

@onready var container: VBoxContainer = $VBox/ScrollBook/BookContainer
@onready var btn_kembali: Button = $VBox/PanelAtas/BtnKembali
@onready var label_progress: Label = $VBox/PanelAtas/LabelProgress


func _ready() -> void:
	btn_kembali.pressed.connect(func(): kembali.emit())
	_tampilkan_koleksi()


func _tampilkan_koleksi() -> void:
	# Hapus isi lama
	for child in container.get_children():
		child.queue_free()
	
	var total_gem: int = GameData.data_hidden_gems.size()
	var ditemukan: int = GameData.koleksi_gem.size()
	label_progress.text = "📖 Koleksi: %d / %d ditemukan" % [ditemukan, total_gem]
	
	for id_gem in GameData.data_hidden_gems:
		var data: Dictionary = GameData.data_hidden_gems[id_gem]
		var sudah_punya: bool = id_gem in GameData.koleksi_gem
		
		var panel := PanelContainer.new()
		container.add_child(panel)
		
		var hbox := HBoxContainer.new()
		panel.add_child(hbox)
		
		# Ikon (emas kalau sudah punya, abu-abu kalau belum)
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.color = Color(1, 0.84, 0) if sudah_punya else Color(0.3, 0.3, 0.3)
		hbox.add_child(icon)
		
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		if sudah_punya:
			var lbl_nama := Label.new()
			lbl_nama.text = "✨ " + str(data.get("nama", id_gem))
			lbl_nama.add_theme_color_override("font_color", Color(1, 0.84, 0))
			vbox.add_child(lbl_nama)
			
			var lbl_desc := Label.new()
			lbl_desc.text = str(data.get("deskripsi", ""))
			vbox.add_child(lbl_desc)
			
			var lbl_cerita := Label.new()
			lbl_cerita.text = "📜 " + str(data.get("cerita", ""))
			lbl_cerita.autowrap_mode = TextServer.AUTOWRAP_WORD
			lbl_cerita.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
			vbox.add_child(lbl_cerita)
		else:
			var lbl_unknown := Label.new()
			lbl_unknown.text = "❓ ???"
			lbl_unknown.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			vbox.add_child(lbl_unknown)
			
			# Petunjuk halus
			var lokasi: String = str(data.get("lokasi", "???"))
			var lbl_hint := Label.new()
			lbl_hint.text = "Petunjuk: ditemukan di sekitar %s..." % lokasi
			lbl_hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			vbox.add_child(lbl_hint)
