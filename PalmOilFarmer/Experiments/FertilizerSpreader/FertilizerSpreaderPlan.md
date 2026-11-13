# PLAN — Fertilizer Spreader IoT (ESP32-C3 + Relay + BLE)

> Status: **v0.4: koneksi app ↔ ESP sudah diimplementasi** (lihat §9).
> Sebelumnya Draft v0.3, disusun setelah membaca `Experiments/FindingWaypoint`, `Garden.swift`, `DemoReviewReport.swift`, dan `project.pbxproj`.
> Target: ketika petani berada di zona N dan menekan **Kirim**, iOS app mengirim dosis ke ESP32-C3. ESP lalu menyalakan relay (pompa/aktuator spreader) selama durasi yang setara dengan dosis tersebut.

---

## 0. Temuan dari kode yang ada (penting sebelum mulai)

| Temuan | Lokasi | Dampak ke plan |
|---|---|---|
| Zona = **6 zona luas-sama**, dihitung ulang dari batas kebun, **tidak disimpan** | `WaypointZoning.zones(for:)` | ID zona (1–6) cukup dikirim/dipakai di app. Tidak perlu migrasi data. |
| Zona aktif dipilih di `WaypointMapView` (`selectedZoneID`, default 5), lalu ada indikator **"Dekat titik tujuan"** (≤15 m, akurasi ≤10 m) | `WaypointMapView.swift` | Titik integrasi paling alami: panel **Semprot** muncul di layar ini. |
| Satuan pupuk di model adalah **kg**, bukan liter: `FertilizerRecord.doseKgPerTree`, `bagWeightKg` | `Core/Gardens/Domain/Garden.swift` | ⚠️ Perlu keputusan satuan (lihat §1.2). |
| Jumlah pohon **tidak disimpan**. Demo memakai estimasi `areaHectares / 6 × 136 pohon/ha` | `DemoReviewReport.areas(for:)` | ⚠️ "total pupuk zona ÷ total pohon zona" saat ini **selalu = dosis per pohon** (lihat §1.1). |
| Pupuk per zona ada **3 jenis** (Urea, KCl/MOP, Kiserite) × 2 periode | `DemoReviewReport.fertilizers` | Perlu memilih pupuk yang sedang disebar. |
| Project memakai **`PBXFileSystemSynchronizedRootGroup`** untuk `PalmOilFarmer/` | `project.pbxproj` | Semua file di `PalmOilFarmer/` otomatis masuk target. **Firmware harus di luar folder ini.** |
| `README.md` di `FindingWaypoint/` ikut ter-copy sebagai resource (tidak ada membership exception) | `project.pbxproj` | Jangan membuat `README.md` kedua di target, karena akan muncul error *"Multiple commands produce README.md"*. Karena itu file ini bernama `FertilizerSpreaderPlan.md`. |
| Permission dideklarasikan lewat `INFOPLIST_KEY_*` di build settings, deployment target iOS 27 | `project.pbxproj` | Tambah `INFOPLIST_KEY_NSBluetoothAlwaysUsageDescription` di sana. |

---

## 1. Alur bisnis & rumus dosis

1. Petani membuka **Pemupukan → pilih kebun → pilih zona → Mulai panduan** (alur `FindingWaypoint` yang sudah ada).
2. Setelah sampai di zona, panel **Semprot** menampilkan pupuk aktif, dosis per pohon, dan tombol **Kirim**.
3. App menghitung dosis:

   ```
   dosis_per_pohon = total_pupuk_zona[N] / total_pohon_zona[N]
   ```

4. Saat petani menekan **Kirim**, app menulis perintah ke ESP lewat BLE. ESP hanya bereaksi pada perintah eksplisit ini.
5. ESP mengubah dosis menjadi durasi, menyalakan relay, mematikannya otomatis, lalu mengirim status balik (`spraying` → `done`).

### 1.1 ⚠️ Rumus saat ini masih sirkular

Dengan data yang ada:

```
total_pohon_zona  = luas_kebun / 6 × 136
total_pupuk_zona  = total_pohon_zona × doseKgPerTree
→ total_pupuk_zona / total_pohon_zona = doseKgPerTree
```

Artinya pembagian zona tidak mengubah apa pun, dan hasilnya selalu sama dengan `doseKgPerTree`. Rumus zona baru bermakna kalau **minimal salah satu** dari ini tersedia:

- **Jumlah pohon aktual per zona** (diinput petani atau dihitung saat survei), atau
- **Total pupuk per zona** yang berbeda antar zona (dari rekomendasi berbasis analisis tanah/daun per zona).

**Usulan Fase 0:** buat model kecil `ZoneFertilizerPlan` (in-memory dulu, sesuai prinsip eksperimen: "tidak disimpan") yang berisi `zoneID`, `treeCount`, `fertilizerName`, dan `totalAmount`. Nilai awalnya diisi estimasi demo, dan `treeCount` bisa diedit di layar.

### 1.2 ⚠️ kg vs liter

Data app memakai **kg pupuk granul** (Urea, KCl, Kiserite), sedangkan rencana awal ESP memakai **liter**. Ada 3 kemungkinan:

| Opsi | Kapan dipakai | Kalibrasi ESP |
|---|---|---|
| **A. Granul (kg)**: relay menggerakkan motor/gate spreader | Pupuk disebar kering | `kg/menit` (tampung hasil sebar N detik, lalu timbang) |
| **B. Cair (liter)**: pupuk dilarutkan lalu dipompa | Fertigasi/semprot larutan | `L/menit` (tampung N detik ke gelas ukur) |
| **C. Cair dengan konversi kg → L** | Dosis tetap dalam kg pupuk, tetapi yang dialirkan adalah larutan | App menghitung `liter = kg / konsentrasi (kg/L)`, ESP kalibrasi `L/menit` |

**Desain protokol dibuat netral satuan:** ESP menerima `amount` + `unit` dan menyimpan laju kalibrasi `rate_per_min` beserta satuannya. Firmware cukup ditulis sekali dan berlaku untuk A, B, maupun C. ESP akan **menolak** perintah kalau satuannya tidak sama dengan satuan kalibrasi.

---

## 2. Hardware

| Komponen | Keterangan |
|---|---|
| ESP32-C3 Super Mini | MCU + BLE 5 (C3 **tidak** punya Bluetooth Classic) |
| Relay 1ch 5V optocoupler | Switch aktuator |
| Pompa DC / solenoid valve / motor spreader | Ditentukan oleh opsi §1.2 |
| Buck converter 12V → 5V | Supply ESP + relay dari aki |
| Dioda flyback 1N4007 | Paralel di beban induktif DC |
| (Fase lanjut) Flow sensor YF-S201 / load cell HX711 | Pengukuran aktual (closed loop) |

### 2.1 Pin

| Fungsi | GPIO | Catatan |
|---|---|---|
| Relay IN | **GPIO3** | Bukan strapping pin |
| LED status | GPIO8 | LED onboard, active-LOW |
| Emergency STOP lokal | GPIO9 | Tombol BOOT onboard, dibaca setelah boot |

Hindari GPIO2/8/9 untuk beban eksternal (strapping pin), GPIO18/19 (USB), dan GPIO20/21 (UART).

### 2.2 Wiring

```
ESP32-C3            Relay module
5V   ─────────────► DC+
GND  ─────────────► DC−
GPIO3 ────────────► IN

+12V aki ── COM   NO ── (+) Aktuator (−) ── GND aki
                         └─ dioda flyback paralel (katoda ke +)
```

Pakai terminal **NO** supaya aktuator mati saat ESP mati/reset.

### 2.3 ⚠️ Logic 3.3V vs relay 5V

Output GPIO ESP32-C3 adalah 3.3V, sedangkan modul relay 5V umumnya **active-LOW**. Saat pin HIGH (3.3V), optocoupler bisa tetap menyala, sehingga **relay tidak mau OFF**. Solusinya (diuji di Fase 1):

1. Kalau modul punya jumper **JD-VCC**: lepas jumper, VCC ← 3.3V, JD-VCC ← 5V.
2. **Open-drain**: untuk OFF, set pin ke `INPUT`; untuk ON, `OUTPUT` + `LOW`.
3. Transistor NPN sebagai level shifter.

Set state OFF **sebelum** `pinMode(OUTPUT)` agar tidak terdengar "klik" saat boot.

---

## 3. Komunikasi: BLE (GATT)

BLE dipilih karena tidak bergantung pada WiFi di kebun, iPhone tetap bisa memakai data seluler (dibutuhkan peta MapKit online di `WaypointMapView`), dan didukung native oleh CoreBluetooth.

| Item | UUID (generate ulang sebelum implementasi) | Properti |
|---|---|---|
| Service | `6f1a0001-5a2b-4c3d-9e8f-0a1b2c3d4e5f` | — |
| CMD | `6f1a0002-…` | Write (with response) |
| STATUS | `6f1a0003-…` | Read, Notify |
| CONFIG | `6f1a0004-…` | Read |

Nama advertise: `KROPS-SPREADER-XXXX` (4 digit terakhir MAC).

### 3.1 Perintah (CMD, JSON)

```json
{"cmd":"spray","id":"g<gardenShort>-z6-0007","amount":1.500,"unit":"kg"}
{"cmd":"stop"}
{"cmd":"calibrate","seconds":30}
{"cmd":"set_rate","rate_per_min":2.10,"unit":"kg"}
{"cmd":"ping"}
```

`id` unik per perintah. ESP menolak `id` yang sama dua kali berturut-turut, supaya retry tidak memicu semprot dobel.

### 3.2 Status (STATUS notify, JSON)

```json
{"state":"idle","rate_per_min":2.10,"unit":"kg"}
{"state":"spraying","id":"...","target":1.5,"duration_ms":42857,"elapsed_ms":5000}
{"state":"done","id":"...","amount_est":1.5}
{"state":"stopped","id":"...","amount_est":0.62}
{"state":"error","code":"BUSY|OVER_LIMIT|NO_CALIBRATION|UNIT_MISMATCH|BAD_JSON|DUPLICATE_ID"}
```

---

## 4. Firmware

### 4.1 Konversi

```
duration_ms = amount / rate_per_min × 60000
```

Contoh: laju 2.1 kg/menit, dosis 1.5 kg → ≈ 42.9 detik.
`rate_per_min`, `unit`, dan `last_id` disimpan di NVS (`Preferences`).

### 4.2 State machine

```
[IDLE] ── spray valid ──► [SPRAYING] ── durasi habis ──► [IDLE] (notify done)
   │                          │
   │                          └── stop / tombol BOOT / error ──► [IDLE] (notify stopped)
   └── calibrate ──► [CALIBRATING] ── selesai/stop ──► [IDLE]
```

Timer memakai `millis()` (non-blocking), sehingga STOP tetap responsif.

### 4.3 Safety

| Rule | Default |
|---|---|
| Relay OFF saat boot/reset | selalu |
| `0 < amount ≤ MAX_AMOUNT` | 5.0 |
| Hard cap durasi | 180 000 ms |
| Tolak jika belum kalibrasi / satuan beda | `NO_CALIBRATION` / `UNIT_MISMATCH` |
| Tolak id duplikat | `DUPLICATE_ID` |
| Tolak saat sedang menyemprot | `BUSY` |
| Tombol BOOT = emergency stop | aktif |
| Watchdog (`esp_task_wdt`) | 5 s |
| BLE putus saat menyemprot | lanjut sampai selesai, tetap dibatasi timer (bisa diubah) |

### 4.4 Arduino IDE

- Board package **esp32 by Espressif** (core 3.x), board **ESP32C3 Dev Module**
- **USB CDC On Boot: Enabled** (supaya Serial muncul lewat USB-C)
- Library: **tidak ada tambahan**. BLE & `Preferences` bawaan paket ESP32 3.3.x, JSON diparse minimal di firmware

---

## 5. Struktur file

```
palm-oil/
├── PalmOilFarmer/Experiments/
│   ├── FindingWaypoint/                    (sudah ada)
│   │   └── WaypointMapView.swift           ← + tombol/sheet "Semprot" (perubahan minimal)
│   └── FertilizerSpreader/                 ← BARU
│       ├── FertilizerSpreaderPlan.md       ← dokumen ini (BUKAN README.md, lihat §0)
│       ├── ZoneFertilizerPlan.swift        // zoneID, treeCount, fertilizer, totalAmount, unit
│       ├── SpreaderDoseCalculator.swift    // total ÷ pohon + validasi
│       ├── SpreaderProtocol.swift          // Codable CMD/STATUS, UUID
│       ├── SpreaderBLEManager.swift        // @Observable, CoreBluetooth
│       ├── SpreaderPanelView.swift         // dosis, Kirim, STOP, progress
│       └── SpreaderCalibrationView.swift
│
├── PalmOilFarmerTests/
│   ├── SpreaderDoseCalculatorTests.swift   ← BARU
│   └── SpreaderProtocolTests.swift         ← BARU (encode/decode JSON)
│
└── firmware/                               ← BARU, di LUAR PalmOilFarmer/ (synchronized group)
    ├── spreader_esp32c3/
    │   ├── spreader_esp32c3.ino
    │   ├── config.h
    │   ├── relay.h/.cpp
    │   ├── sprayer.h/.cpp
    │   ├── ble_service.h/.cpp
    │   └── storage.h/.cpp
    └── relay_blink/relay_blink.ino
```

Perubahan di luar folder eksperimen dibatasi seminimal mungkin:
- `project.pbxproj`: tambah `INFOPLIST_KEY_NSBluetoothAlwaysUsageDescription = "Bluetooth digunakan untuk mengirim dosis pupuk ke alat penyebar.";` di konfigurasi Debug & Release.
- `WaypointMapView.swift`: satu tombol yang membuka `SpreaderPanelView(garden:zone:)`.

---

## 6. Sisi iOS

- **`SpreaderDoseCalculator`**: input `ZoneFertilizerPlan`, output `amount` per pohon. Validasi: `treeCount > 0`, nilai finite, dan ≤ `MAX_AMOUNT`, mengikuti pola `FertilizerRecord.validated(...)` di `GardenHistoryValidation.swift`.
- **`SpreaderBLEManager`** (`@Observable`, sama dengan pola `WaypointLocationSession`): scan service UUID → connect → discover → subscribe STATUS → `send(_:)` ke CMD. BLE juga dihentikan saat layar ditutup, sama seperti GPS di eksperimen ini.
- **`SpreaderPanelView`**: zona aktif, pupuk (picker 3 jenis), `treeCount` yang bisa diedit, dosis per pohon, tombol **Kirim** dengan konfirmasi ("Zona 6 • Urea • 1,5 kg/pohon"), **STOP** besar saat menyemprot, dan progress dari `elapsed_ms / duration_ms`.
- **Gate opsional:** tombol Kirim hanya aktif kalau status "Dekat titik tujuan" sudah terpenuhi, atau petani menekan "Saya sudah di zona".
- Teks mengikuti gaya UI yang ada (Bahasa Indonesia, `KropsTheme`).

---

## 7. Fase

| Fase | Output | Selesai bila |
|---|---|---|
| **0. Keputusan data** | Jawaban §1.1 (sumber jumlah pohon) & §1.2 (kg/L, aktuator) | Satuan & sumber data disepakati |
| **1. Relay test** | `firmware/relay_blink` | ON/OFF bersih (masalah 3.3V beres), tidak klik saat boot |
| **2. Sprayer via Serial** | state machine, perintah `spray 1.5 kg` lewat Serial Monitor | Durasi akurat ±50 ms, STOP & tombol BOOT jalan |
| **3. BLE** | GATT + JSON | Teruji dengan **nRF Connect / LightBlue** di iPhone |
| **4. Kalibrasi** | `calibrate` + `set_rate` + NVS | Laju tersimpan setelah reboot |
| **5. iOS** | 6 file Swift + 2 test + pbxproj key | Unit test hijau, build berhasil, end-to-end zona → semprot → done |
| **6. Integrasi Waypoint** | Tombol di `WaypointMapView` | Alur: pilih zona → jalan → dekat → Kirim |
| **7. Uji lapangan** | Aki + aktuator nyata | Selisih dosis aktual vs target < 10% |
| **8. (Opsional)** | Flow sensor / load cell | Stop berdasarkan pengukuran, bukan waktu |

---

## 8. Open questions

1. **Pupuknya granul (kg) atau larutan (liter)?** Aktuatornya pompa, solenoid, atau motor/gate spreader? Berapa ampere?
2. **Jumlah pohon per zona** didapat dari mana: input manual, estimasi 136/ha, atau survei?
3. Satu kali **Kirim = satu pohon**? Kalau ya, petani menekan Kirim di tiap pohon. Atau satu kali untuk satu zona?
4. Dari 3 jenis pupuk, apakah satu spreader = satu jenis pupuk per sesi?
5. BLE putus saat menyemprot: **lanjut** (default) atau **stop**?
6. Perlu **pairing/bonding BLE** supaya HP lain tidak bisa memicu semprot?
7. Apakah tombol Kirim wajib menunggu indikator "Dekat titik tujuan"?

---

## 9. Implementasi koneksi (v0.4)

Wiring final: ESP 5V → DC+, GND → DC−, **GPIO3 → IN**. Tutorial lengkap: **`firmware/README.md`**.

Keputusan: pupuk berbentuk **larutan**, debit pompa **2,9 L/menit**. Konversi kg → liter dan jumlah pohon per zona akan datang dari *assessment result* (dikerjakan terpisah). Untuk sekarang petani mengetik liter di panel.

### File

| File | Isi |
|---|---|
| `firmware/spreader_esp32c3/config.h` | Pin, relay mode, batas, UUID |
| `firmware/spreader_esp32c3/spreader_esp32c3.ino` | BLE GATT, state machine, STOP, Serial test |
| `firmware/relay_blink/relay_blink.ino` | Tes relay saja (Fase 1) |
| `Experiments/FertilizerSpreader/SpreaderProtocol.swift` | UUID, `SpreaderCommand`, `SpreaderStatus`, `SpreaderDose` |
| `Experiments/FertilizerSpreader/SpreaderBLEManager.swift` | CoreBluetooth central (`@Observable`) |
| `Experiments/FertilizerSpreader/FertilizingModeView.swift` | Layar **Mode Pemupukan** (desain Sketch HI-FID): peta + panel |
| `Experiments/FertilizerSpreader/FertilizingMapView.swift` | Peta satelit, garis zona putih, label kg, posisi petani |
| `Experiments/FertilizerSpreader/FertilizingPanel.swift` | 6 state: Not Connected, Searching, Found, Ready, Dispensing, Disconnected |
| `Experiments/FertilizerSpreader/FertilizingStyle.swift` | Warna, ikon Bluetooth, dosis contoh, deteksi zona dari GPS |
| `Experiments/FertilizerSpreader/Assets/SpreaderDeviceIcon@2x/@3x.png` | Ikon alat dari Sketch |
| `PalmOilFarmerTests/FertilizingModeTests.swift` | Dosis contoh, deteksi zona, format |
| `PalmOilFarmerTests/SpreaderProtocolTests.swift` | Format JSON & hitungan dosis |
| `WaypointMapView.swift` | + tombol **Semprot** → layar penuh Mode Pemupukan |
| `project.pbxproj` | + `NSBluetoothAlwaysUsageDescription` |

### Menjalankan

1. **Arduino IDE**: install board *esp32 by Espressif Systems* 3.3.x. Tidak perlu library tambahan. Pilih board *ESP32C3 Dev Module*, set **USB CDC On Boot: Enabled**.
2. Upload `relay_blink` (tanpa pompa). Pastikan relay ON/OFF bersih. Kalau relay tidak mau OFF, ikuti komentar di sketch, lalu salin setting yang berhasil ke `config.h`.
3. Upload `spreader_esp32c3`. Di Serial Monitor (115200, Newline) akan muncul `Krops spreader … ready as KROPS-SPR-XXXX`. Tes tanpa app: `spray 0.5`, `stop`, `status`.
4. (Opsional) Cek dari iPhone dengan **nRF Connect**: device `KROPS-SPR-XXXX`, tulis `{"cmd":"ping"}` ke characteristic `4B470002…`.
5. **Xcode**: jalankan test `SpreaderProtocolTests`, lalu Run ke iPhone (Bluetooth tidak tersedia di Simulator). Buka eksperimen FindingWaypoint → Pemupukan → kebun → pilih zona → **Semprot** → isi liter → **Kirim ke alat**.

LED onboard: kedip lambat = menunggu koneksi, menyala = terhubung, kedip cepat = relay ON. Tombol BOOT = STOP darurat.

### Belum dikerjakan
- Dosis dari assessment result: ganti `FertilizingZonePlan.sample(for:)` (saat ini contoh: 136 pohon/ha, 1,5 kg/pohon, 0,5 L/kg → 0,75 L/pohon).
- Penghitung pohon masih di memori (hilang saat layar ditutup).
- UI kalibrasi (perintah `calibrate` / `set_rate` sudah ada di firmware & `SpreaderBLEManager`).
- Pairing/bonding BLE.
