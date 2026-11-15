# PLAN — IoT Fertilizer Spreader Controller (ESP32-C3)

> Status: **Draft v0.2**: struktur sudah disesuaikan dengan `Experiments/FindingWaypoint` (dari screenshot). Isi file Swift belum dibaca.
> Target: ESP32-C3 mini menerima nilai **liter** dari iOS app, lalu menyalakan relay (pompa/solenoid spreader) selama durasi yang setara dengan liter tersebut.

---

## 1. Tujuan & Alur Bisnis

1. Petani berada di **zona N** (contoh: zona 6). Penentuan zona dilakukan di **iOS app** (pilih manual / geofence GPS) — ESP tidak tahu soal zona.
2. iOS app menghitung dosis:

   ```
   liter_per_pohon = total_pupuk_zona[N] / total_pohon_zona[N]
   ```

3. Petani menekan tombol **"Kirim / Spray"** di app → app mengirim nilai liter ke ESP.
4. ESP **hanya bereaksi pada perintah eksplisit** tersebut: konversi liter → durasi, relay ON, relay OFF otomatis setelah durasi habis.
5. ESP mengirim status balik ke app (`spraying` → `done` / `error`).

**Prinsip:** ESP itu "bodoh dan aman". Semua logika bisnis (zona, pohon, pupuk) ada di iOS. ESP hanya mengeksekusi `liters → relay`, dengan batas keamanan.

---

## 2. Hardware

| Komponen | Keterangan |
|---|---|
| ESP32-C3 Super Mini | MCU + BLE 5 (C3 **tidak** punya Bluetooth Classic) |
| Relay 1ch 5V optocoupler | Switch pompa / solenoid valve |
| Pompa DC / solenoid valve | Aktuator spreader (perlu dipastikan: 12V DC?) |
| Buck converter 12V → 5V | Supply ESP + relay dari aki di lapangan |
| Dioda flyback (1N4007) | Dipasang paralel di beban induktif DC (pompa/solenoid) |
| (Opsional, fase 2) Flow sensor YF-S201 | Ukur liter aktual (closed loop) |

### 2.1 Pin yang dipakai

| Fungsi | GPIO | Catatan |
|---|---|---|
| Relay IN | **GPIO4** | Aman, bukan strapping pin |
| LED status | GPIO8 | LED onboard (active-LOW), juga strapping pin → hanya output |
| Tombol STOP lokal | GPIO9 | Tombol BOOT onboard, dibaca setelah boot sebagai emergency stop |

Hindari GPIO2, GPIO8, dan GPIO9 untuk beban eksternal (strapping pin), juga GPIO18/19 (USB) dan GPIO20/21 (UART).

### 2.2 Wiring

```
ESP32-C3            Relay module
---------           -------------
5V   ─────────────► VCC (atau JD-VCC, lihat catatan)
GND  ─────────────► GND
GPIO4 ────────────► IN

Relay contact            Beban
-------------            -----
COM  ◄──── +12V aki
NO   ─────► (+) Pompa/Solenoid (─) ──── GND aki
                 └── dioda flyback paralel (katoda ke +)
```

- Pakai terminal **NO** (Normally Open) supaya saat ESP mati/reset, pompa **mati**.

### ⚠️ 2.3 Catatan penting: logic 3.3V vs relay 5V

ESP32-C3 output-nya **3.3V**, sedangkan modul relay 5V optocoupler umumnya **active-LOW**. Saat pin HIGH (3.3V), selisih 5V − 3.3V = 1.7V kadang masih cukup menyalakan LED optocoupler, sehingga **relay tidak mau OFF**.

Solusi (pilih salah satu, diuji di Fase 1):

1. **Jika modul punya jumper JD-VCC:** lepas jumper, VCC ← **3.3V** ESP, JD-VCC ← **5V**, GND ← GND. Ini cara paling bersih (isolasi penuh).
2. **Trik open-drain:** untuk OFF, set pin jadi `INPUT` (floating) dan bukan `HIGH`; untuk ON, `OUTPUT` + `LOW`.
3. **Transistor NPN (2N2222/BC547)** sebagai level shifter.

Selain itu, set state OFF **sebelum** `pinMode(OUTPUT)` agar relay tidak "klik" saat boot.

---

## 3. Komunikasi iOS ↔ ESP: **BLE (GATT)**

**Kenapa BLE, bukan WiFi:**
- Di kebun sawit biasanya tidak ada WiFi/sinyal stabil.
- Kalau WiFi SoftAP, iPhone harus join ke AP ESP dan kehilangan internet.
- iOS tidak mendukung Bluetooth Classic SPP, sedangkan BLE didukung native lewat **CoreBluetooth**.
- ESP32-C3 sudah mendukung BLE 5.

### 3.1 GATT Service

| Item | UUID (contoh, generate ulang) | Properti | Isi |
|---|---|---|---|
| Service | `6f1a0001-5a2b-4c3d-9e8f-0a1b2c3d4e5f` | — | Fertilizer Spreader |
| CMD | `6f1a0002-…` | Write | Perintah JSON dari app |
| STATUS | `6f1a0003-…` | Read, Notify | Status JSON dari ESP |
| CONFIG | `6f1a0004-…` | Read | Konfigurasi aktif (flow rate, limit) |

Nama advertise: `SPREADER-01` (bisa ditambah suffix MAC untuk multi-device).

### 3.2 Protokol perintah (CMD, JSON)

```json
// Spray: perintah utama, dikirim saat petani tekan "Kirim"
{"cmd":"spray","id":"z6-20261113-0007","liters":0.750}

// Stop darurat
{"cmd":"stop"}

// Kalibrasi: nyalakan pompa N detik untuk ditampung ke gelas ukur
{"cmd":"calibrate","seconds":30}

// Simpan flow rate hasil kalibrasi (L/menit)
{"cmd":"set_flow","lpm":2.10}

// Cek koneksi / ambil status
{"cmd":"ping"}
```

- `id` = request ID unik dari app (mis. zona + tanggal + counter). ESP **menolak id yang sama** dua kali berturut-turut, supaya retry dari app tidak memicu dobel semprot.

### 3.3 Status (STATUS notify, JSON)

```json
{"state":"idle","flow_lpm":2.10}
{"state":"spraying","id":"z6-...","target_l":0.750,"duration_ms":21428,"elapsed_ms":5000}
{"state":"done","id":"z6-...","sprayed_l_est":0.750}
{"state":"stopped","id":"z6-...","sprayed_l_est":0.310}
{"state":"error","code":"BUSY|OVER_LIMIT|NO_CALIBRATION|BAD_JSON|DUPLICATE_ID"}
```

---

## 4. Logika Firmware

### 4.1 Konversi liter → durasi

Tanpa flow sensor, kita pakai **flow rate hasil kalibrasi** (L/menit):

```
duration_ms = (liters / flow_lpm) * 60000
```

Contoh: flow 2.1 L/menit, dosis 0.75 L → 0.75 / 2.1 × 60000 ≈ **21.4 detik**.

`flow_lpm` disimpan di **NVS (Preferences)** agar tidak hilang saat mati listrik.

### 4.2 State machine

```
        ┌──────── stop / timeout / error ─────────┐
        ▼                                          │
     [IDLE] ── spray (valid) ──► [SPRAYING] ───────┤
        ▲                            │ durasi habis│
        └──────────── done ◄─────────┘             │
     [IDLE] ── calibrate ──► [CALIBRATING] ────────┘
```

- Timer pakai `millis()` (non-blocking), **bukan `delay()`**, supaya perintah STOP dan tombol fisik tetap responsif.
- Saat `SPRAYING`, perintah `spray` baru ditolak dengan `BUSY`.

### 4.3 Safety rules (wajib)

| Rule | Default |
|---|---|
| Relay OFF saat boot / reset | selalu |
| `liters` harus > 0 dan ≤ `MAX_LITERS` | 5.0 L |
| Durasi ≤ `MAX_DURATION_MS` (hard cap) | 180 000 ms |
| Tolak `spray` kalau belum kalibrasi | `NO_CALIBRATION` |
| Tolak id duplikat | `DUPLICATE_ID` |
| Tombol BOOT (GPIO9) = emergency stop | aktif |
| Hardware watchdog (`esp_task_wdt`) | 5 s |
| BLE putus saat spraying | **lanjut sampai selesai** (dosis utuh, tetap dibatasi timer). Bisa diubah jadi stop, lihat Open Questions |

### 4.4 Struktur kode

Mengikuti pola `Experiments/FindingWaypoint/` yang sudah ada (1 folder per eksperimen, berisi View + logic + README):

```
palm-oil/
├── <App>/Experiments/
│   ├── FindingWaypoint/                 ← sudah ada (WaypointZoning = sumber zona)
│   │   ├── FindingWaypointView.swift
│   │   ├── WaypointMapView.swift
│   │   ├── WaypointZoneThumbnail.swift
│   │   ├── WaypointZoning.swift
│   │   └── README.md
│   └── FertilizerSpreader/              ← BARU (sisi iOS)
│       ├── README.md                    // = dokumen plan ini
│       ├── FertilizerSpreaderView.swift // UI: zona aktif, dosis, Kirim, STOP, progress
│       ├── SpreaderBLEManager.swift     // CoreBluetooth: scan, connect, write CMD, notify STATUS
│       ├── SpreaderDoseCalculator.swift // total pupuk zona ÷ total pohon zona
│       ├── SpreaderCalibrationView.swift// mode kalibrasi flow rate
│       └── SpreaderProtocol.swift       // Codable struct untuk JSON CMD/STATUS + UUID
│
└── firmware/                            ← BARU, DI LUAR folder Xcode target
    └── spreader_esp32c3/
        ├── spreader_esp32c3.ino   // setup/loop
        ├── config.h               // pin, UUID, limit
        ├── relay.h / .cpp         // relayOn/Off (handle active-LOW/open-drain)
        ├── sprayer.h / .cpp       // state machine + timer
        ├── ble_service.h / .cpp   // GATT server, parse JSON
        └── storage.h / .cpp       // NVS: flow_lpm, last_id
    └── relay_blink/relay_blink.ino  // Fase 1: tes relay saja
```

> ⚠️ **Firmware jangan ditaruh di dalam `Experiments/`.** Kalau project Xcode memakai *synchronized folder* (default Xcode 16+), file `.cpp/.h/.ino` di dalam folder target bisa ikut di-compile ke app iOS dan bikin build error. Simpan di `palm-oil/firmware/` (sejajar dengan folder app), lalu buka foldernya dari Arduino IDE.

**Integrasi dengan `FindingWaypoint`:** zona aktif (mis. zona 6) diambil dari `WaypointZoning`. `SpreaderDoseCalculator` cukup menerima `zoneId` dan membaca total pupuk & total pohon zona tersebut. Perlu dicek di Fase 0 apakah model zona sudah menyimpan dua data ini atau perlu ditambah.

### 4.5 Setup Arduino IDE

- Board package: **esp32 by Espressif** (core 3.x)
- Board: **ESP32C3 Dev Module** (atau "Nologo ESP32C3 Super Mini" kalau tersedia)
- **USB CDC On Boot: Enabled**, wajib supaya `Serial` muncul lewat USB-C
- Library:
  - **NimBLE-Arduino** (lebih ringan daripada BLE bawaan, cocok untuk C3)
  - **ArduinoJson** v7
  - `Preferences` (bawaan core)

---

## 5. Sisi iOS (ringkas)

1. **Hitung dosis** dari data zona yang sudah ada di app:
   ```swift
   let litersPerTree = zone.totalFertilizerLiters / Double(zone.totalTrees)
   ```
2. Tampilkan konfirmasi: *"Zona 6 — 0.750 L per pohon — Kirim?"*
3. Tombol **Kirim** → tulis JSON ke characteristic CMD (`.withResponse`).
4. Subscribe STATUS (notify) → tampilkan progress bar `elapsed_ms / duration_ms`.
5. Tombol **STOP** besar & selalu terlihat selama spraying.
6. Layar **Kalibrasi**: tombol "Jalankan 30 detik" → petani input liter tertampung → app hitung `lpm = liter / 0.5` → kirim `set_flow`.
7. Simpan log semprot lokal (zona, id, liter, waktu, status) untuk rekap per zona.

Info.plist: `NSBluetoothAlwaysUsageDescription`.

---

## 6. Fase Implementasi

| Fase | Output | Kriteria selesai |
|---|---|---|
| **0. Recon** | Baca `WaypointZoning.swift` & README `FindingWaypoint` | Tahu bagaimana zona aktif ditentukan, dan apakah model zona sudah punya total pupuk (liter/kg) & total pohon |
| **1. Hardware test** | `relay_blink.ino` | Relay ON/OFF bersih dengan GPIO4 (masalah 3.3V terselesaikan), tidak klik saat boot |
| **2. Sprayer lokal** | State machine + Serial command (`spray 0.5`) | Durasi akurat ±50 ms, STOP & tombol BOOT jalan |
| **3. BLE** | GATT service + JSON | Bisa dites pakai app **nRF Connect / LightBlue** di iPhone |
| **4. Kalibrasi** | `calibrate` + `set_flow` + NVS | flow_lpm tersimpan setelah reboot |
| **5. iOS integration** | `SpreaderBLE.swift` + UI kirim/stop/kalibrasi | End-to-end zona 6 → semprot → done |
| **6. Field test** | Uji di kebun dengan aki | Error dosis aktual vs target < 10% |
| **7. (Opsional)** | Flow sensor YF-S201 (closed loop) | Stop berdasarkan liter terukur, bukan waktu |

---

## 7. Open Questions (perlu dijawab sebelum coding)

1. **Satuan pupuk di data zona: liter atau kg?** Kalau kg (padat/granul), perlu faktor konversi atau kalibrasi kg/menit.
2. **Dosis per kirim = per pohon?** Atau satu kali kirim untuk satu zona penuh?
3. **Aktuatornya apa?** Pompa DC 12V, solenoid valve, atau motor spreader? Berapa ampere? (Relay 10A biasanya cukup untuk pompa kecil.)
4. **Kalau BLE putus saat menyemprot:** lanjut sampai selesai (default di plan) atau langsung stop?
5. **Satu ESP per spreader?** Kalau ada beberapa spreader, perlu ID device & pairing di app.
6. **Perlu otentikasi BLE?** (PIN/bonding) supaya HP lain tidak bisa memicu semprot.
7. Apakah iOS app sudah memakai CoreBluetooth, atau ini integrasi BLE pertama?
