# Warung Pixel — Game Design Document

## Konsep
Game 2D pixel-art mengelola warung kaki lima bertema Indonesia.
Siklus 1 hari: pagi–sore jelajahi peta beli bahan, malam buka warung layani pelanggan.

## Fitur & Prioritas

| Prioritas | Fitur |
|-----------|-------|
| MUST | Warung: pelanggan, kesabaran, masak, saji, nyawa |
| MUST | Peta Dunia: 3 lokasi awal, 4 slot waktu/hari |
| MUST | Beli bahan: daftar per lokasi, tas terbatas (10 slot) |
| MUST | Resep & menu: bahan → masakan |
| MUST | Save/Load (user://save.json) |
| IMPORTANT | Hidden gem: 8+ bahan langka, kondisi muncul, cerita lucu |
| IMPORTANT | Buku Koleksi, cuaca harian, bahan basi |
| IMPORTANT | Pelanggan spesial, permintaan rahasia, cerita pendek |
| IMPORTANT | Harga dinamis, mini-game tawar-menawar |
| IMPORTANT | Upgrade warung, buka lokasi baru |
| BONUS | Event acak (hujan, mati listrik, lonjakan harga) |

## Alur 1 Hari
1. **Pagi** — Pilih lokasi di peta, beli bahan (slot 1-4).
2. **Malam** — Buka warung, pelanggan datang, masak & sajikan.
3. **Ringkasan** — Pendapatan, pelanggan terlayani/pergi.
4. **Hari berikutnya** — Harga berubah, cuaca acak, event.

## Lokasi & Bahan Khas

| Lokasi | Bahan Khas | Buka Awal? |
|--------|-----------|------------|
| Pasar Tradisional | Beras, Telur, Minyak, Bumbu, Sayur | Ya |
| Sawah/Desa | Beras Organik, Ayam Kampung, Kelapa | Ya |
| Hutan/Gunung | Jamur, Rempah Langka, Madu | Ya |
| Pelabuhan | Ikan Segar, Udang, Rumput Laut | Tidak |
| Pasar Malam | Sosis, Keju, Susu, Coklat | Tidak |
| Pasar Loak | Resep Kuno, Bumbu Antik, Peralatan | Tidak |
