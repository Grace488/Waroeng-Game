# Warung Pixel — Project Brief (≤40 baris)

## Aturan Kerja
1. Godot 4, GDScript, resolusi 640×360, pixel art (Nearest filter).
2. Semua data game di `data/*.json`, JANGAN hardcode di script.
3. Komunikasi antar node pakai **signal**, bukan referensi langsung.
4. Logika baru → script baru, jangan tumpuk di script lama.
5. Teks in-game: **Bahasa Indonesia**. Komentar kode: **Bahasa Indonesia sederhana**.
6. UI placeholder: ColorRect, Label, emoji. Sprite ditambah nanti.
7. Warna UI: panel gelap (#1a1a2e), tombol oranye (#e94560), peta hijau (#0f3460).

## Alur Game
```
[Peta Dunia] → pilih lokasi → [Beli Bahan] → 4 slot habis →
[Warung Malam] → pelanggan datang → masak & saji →
[Ringkasan Hari] → hari+1 → ulangi
```

## Autoloads
- `GameData` — state global + signals
- `RecipeManager` — cek resep & bahan
- `SaveManager` — save/load JSON
- `EventManager` — cuaca & event acak

## Checklist Sebelum Commit
- [ ] Semua scene bisa di-load tanpa error
- [ ] Signal terhubung dengan benar
- [ ] JSON valid (test parse)
- [ ] Autoload terdaftar di project.godot
- [ ] Game bisa jalan dari scene utama (main.tscn)

## Konvensi Penamaan
- Scene: `snake_case.tscn`
- Script: `snake_case.gd`
- Node: `PascalCase`
- Signal: `snake_case`
- Data key JSON: `snake_case`
