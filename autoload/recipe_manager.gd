# autoload/recipe_manager.gd
# Kelola resep — cek ketersediaan, cari resep dari bahan
extends Node


func cek_resep_tersedia() -> Array:
	# Kembalikan daftar id resep spesial yang bahannya tersedia
	var tersedia: Array = []
	for id_resep in GameData.data_recipes:
		if GameData.punya_bahan_menu(id_resep):
			tersedia.append(id_resep)
	return tersedia


func cek_menu_tersedia() -> Array:
	# Kembalikan daftar id menu biasa yang bahannya tersedia
	var tersedia: Array = []
	for id_menu in GameData.data_menu:
		if GameData.punya_bahan_menu(id_menu):
			tersedia.append(id_menu)
	return tersedia


func ambil_data_menu(id_menu: String) -> Dictionary:
	# Ambil data menu (biasa atau resep spesial)
	if id_menu in GameData.data_menu:
		return GameData.data_menu[id_menu]
	elif id_menu in GameData.data_recipes:
		return GameData.data_recipes[id_menu]
	return {}


func semua_menu_dan_resep() -> Dictionary:
	# Gabungkan semua menu biasa dan resep jadi satu dictionary
	var gabungan: Dictionary = {}
	for key in GameData.data_menu:
		gabungan[key] = GameData.data_menu[key]
	for key in GameData.data_recipes:
		gabungan[key] = GameData.data_recipes[key]
	return gabungan
