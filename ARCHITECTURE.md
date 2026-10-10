# Warung Pixel — Arsitektur

## Struktur Folder
```
project.godot
scenes/
  main.tscn / main.gd            — scene utama, pindah antara peta & warung
  stall/
    stall.tscn / stall.gd        — scene warung malam
    customer.tscn / customer.gd  — pelanggan (box + order + bar)
    cook_panel.tscn / cook_panel.gd — panel tombol masak
  world_map/
    world_map.tscn / world_map.gd   — peta lokasi
    location.tscn / location.gd     — scene beli bahan
  ui/
    hud.tscn / hud.gd               — HUD atas (uang, nyawa, hari)
    inventory_panel.tscn / inventory_panel.gd — panel tas
    day_summary.tscn / day_summary.gd — ringkasan hari
    game_over.tscn / game_over.gd    — layar game over
    collection_book.tscn / collection_book.gd — buku koleksi
    haggle_minigame.tscn / haggle_minigame.gd — mini-game tawar
    popup_hidden_gem.tscn / popup_hidden_gem.gd — popup item langka
  upgrades/
    upgrade_shop.tscn / upgrade_shop.gd — toko upgrade warung
autoload/
  game_data.gd     — state global (uang, hari, nyawa, inventori, cuaca)
  recipe_manager.gd — load resep, cek bahan cukup
  save_manager.gd  — save/load JSON
  event_manager.gd — event acak harian
data/
  ingredients.json  — semua bahan + harga + lokasi
  menu.json         — menu warung + bahan + waktu masak
  recipes.json      — resep spesial dari bahan langka
  locations.json    — lokasi + bahan tersedia
  customers.json    — pelanggan spesial + cerita
  hidden_gems.json  — bahan langka + kondisi + cerita
  upgrades.json     — daftar upgrade warung
```

## Autoloads (di project.godot)
| Nama | Script | Fungsi |
|------|--------|--------|
| GameData | autoload/game_data.gd | State global, signals |
| RecipeManager | autoload/recipe_manager.gd | Kelola resep |
| SaveManager | autoload/save_manager.gd | Save/load |
| EventManager | autoload/event_manager.gd | Event & cuaca |

## Format Data JSON

### ingredients.json
```json
{
  "beras": {
    "nama": "Beras",
    "harga_dasar": 2000,
    "lokasi": ["pasar", "sawah"],
    "deskripsi": "Beras pulen pilihan.",
    "basi_hari": 5,
    "langka": false
  }
}
```

### menu.json
```json
{
  "kopi": {
    "nama": "Kopi Tubruk",
    "harga_jual": 3000,
    "waktu_masak": 2.0,
    "bahan": {"kopi_bubuk": 1, "gula": 1},
    "deskripsi": "Kopi hitam pekat khas warung."
  }
}
```

### recipes.json
```json
{
  "nasi_goreng_langit": {
    "nama": "Nasi Goreng Langit",
    "harga_jual": 25000,
    "waktu_masak": 6.0,
    "bahan": {"beras_langit": 1, "telur_naga": 1, "bumbu": 1},
    "deskripsi": "Nasi goreng legendaris dari bahan langka."
  }
}
```

### Signal Flow (teks)
```
GameData ──signal──> HUD (update uang/nyawa/hari)
         ──signal──> Stall (cek inventori)
         ──signal──> WorldMap (cek slot waktu)

Customer ──signal──> Stall (pelanggan pergi / dilayani)
Stall    ──signal──> Main (hari selesai → summary)
WorldMap ──signal──> Main (buka warung / pindah lokasi)
Main     ──signal──> GameData (ganti hari)
```
