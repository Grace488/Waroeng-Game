# scenes/stall/customer.gd
# Pelanggan — kotak warna dengan pesanan dan bar kesabaran
extends PanelContainer

signal pelanggan_pergi(pelanggan: Control)
signal pelanggan_diklik(pelanggan: Control)

# Data pelanggan
var pesanan_id: String = ""
var kesabaran_maks: float = 25.0
var kesabaran_sisa: float = 25.0
var is_spesial: bool = false
var spesial_id: String = ""
var data_spesial: Dictionary = {}
var sudah_pergi: bool = false  # Guard supaya signal cuma dikirim sekali

# Node referensi
@onready var color_box: ColorRect = $VBox/ColorBox
@onready var label_pesanan: Label = $VBox/LabelPesanan
@onready var bar_kesabaran: ProgressBar = $VBox/BarKesabaran
@onready var label_nama: Label = $VBox/LabelNama


func _ready() -> void:
	# Klik pada pelanggan
	gui_input.connect(_on_gui_input)
	# Warna & nama diatur di setup() / setup_spesial()


func setup(id_pesanan: String, maks_kesabaran: float) -> void:
	# Setup pelanggan biasa
	pesanan_id = id_pesanan
	kesabaran_maks = maks_kesabaran
	kesabaran_sisa = maks_kesabaran
	is_spesial = false
	
	# Warna acak untuk pelanggan biasa
	if color_box:
		var warna: Color = Color(randf_range(0.3, 0.9), randf_range(0.3, 0.9), randf_range(0.3, 0.9))
		color_box.color = warna
	if label_nama:
		label_nama.text = _nama_acak()
	
	# Update label pesanan
	var data: Dictionary = RecipeManager.ambil_data_menu(id_pesanan)
	if label_pesanan:
		label_pesanan.text = "💬 " + str(data.get("nama", id_pesanan))


func setup_spesial(id_cust: String, id_pesanan: String, maks_kesabaran: float, data: Dictionary) -> void:
	# Setup pelanggan spesial
	pesanan_id = id_pesanan
	kesabaran_maks = maks_kesabaran
	kesabaran_sisa = maks_kesabaran
	is_spesial = true
	spesial_id = id_cust
	data_spesial = data
	
	# Tampilan spesial — warna unik & bintang
	if color_box:
		var warna_str: String = str(data.get("warna", "#ffeb3b"))
		color_box.color = Color.from_string(warna_str, Color.YELLOW)
	if label_nama:
		label_nama.text = "⭐ " + str(data.get("nama", "???"))
	
	var data_menu: Dictionary = RecipeManager.ambil_data_menu(id_pesanan)
	if label_pesanan:
		label_pesanan.text = "💬 " + str(data_menu.get("nama", id_pesanan))


func _process(delta: float) -> void:
	# Jangan proses kalau sudah pergi
	if sudah_pergi:
		return
	
	# Kurangi kesabaran
	kesabaran_sisa -= delta
	bar_kesabaran.value = (kesabaran_sisa / kesabaran_maks) * 100.0
	
	# Ganti warna bar berdasarkan sisa kesabaran
	var persen: float = kesabaran_sisa / kesabaran_maks
	if persen > 0.5:
		bar_kesabaran.add_theme_color_override("font_color", Color.GREEN)
	elif persen > 0.25:
		bar_kesabaran.add_theme_color_override("font_color", Color.YELLOW)
	else:
		bar_kesabaran.add_theme_color_override("font_color", Color.RED)
	
	# Pelanggan pergi kalau kesabaran habis (cuma sekali)
	if kesabaran_sisa <= 0:
		sudah_pergi = true
		pelanggan_pergi.emit(self)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pelanggan_diklik.emit(self)


func _nama_acak() -> String:
	# Nama pelanggan acak untuk variasi
	var nama_list: Array = [
		"Pak Budi", "Bu Sari", "Mas Joko", "Mbak Dewi",
		"Pak Haji", "Bu Tini", "Kang Asep", "Neng Rani",
		"Mas Agus", "Mbak Lina", "Pak RT", "Bu Guru"
	]
	return nama_list[randi() % nama_list.size()]

