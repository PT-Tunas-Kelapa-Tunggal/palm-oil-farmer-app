# Baseline refactor Clean Architecture + MVVM-C

Tanggal pemeriksaan: 4 November 2026 (Asia/Jakarta).

Status: baseline kode dan pengujian otomatis tersedia; pemeriksaan UI baru sebagian. Belum merupakan verifikasi upgrade TestFlight atau pengajuan end-to-end.

## Identitas baseline

| Item | Hasil pemeriksaan |
| --- | --- |
| Branch acuan | `build/testflight-prep` |
| Commit kode awal | `43e413fa5b4e8bb4e4ecb2e885a65164e6498c88` |
| Branch pekerjaan Part 1 | `refactor/01-baseline` |
| Sinkronisasi remote | `git fetch origin` berhasil; acuan lokal dan `origin/build/testflight-prep` mempunyai selisih `0 / 0` saat pemeriksaan |
| Project / scheme | `PalmOilFarmer` |
| Test target | `PalmOilFarmerTests` |
| Xcode | 27.0, build `27A266a`, `/Applications/Xcode.app` |
| SDK / destination | iOS Simulator 27.0, arm64, iPhone 18 Pro |
| Simulator ID | `BD8D68EA-DE49-4AF3-A283-69D78F6984C3` |
| Konfigurasi test | Debug / CloudKit Development |
| Konfigurasi Archive pada scheme | Release / CloudKit Production; Archive tidak dijalankan |
| Swift language mode | 5.0; app target memakai default actor isolation MainActor |
| Versi / build konfigurasi lokal | 1.0 / 1; bukan bukti identitas build TestFlight |
| Versi, build, dan commit TestFlight | Belum terverifikasi |

Developer directory global menunjuk `/Library/Developer/CommandLineTools`. Build/test berhasil dengan `DEVELOPER_DIR` khusus proses, tanpa mengubah pengaturan global atau isi `Developer.xcconfig`.

## Cakupan dan batas kepemilikan

- Target seri: Clean Architecture + MVVM-C manual yang tetap memakai SwiftUI NavigationStack.
- Refactor tanggung jawab mencakup Home, registrasi, pencarian/foto, pemetaan, profil, riwayat, sampai pengajuan berhasil.
- Status/timeline, hasil, rekomendasi, panduan area, dan eksperimen hanya boleh dipindahkan foldernya. Implementasi bagian tim dipertahankan.
- Bug dan perubahan perilaku dicatat untuk pekerjaan terpisah dari pemindahan struktur.
- Satu app target dipertahankan terlebih dahulu. Belum ada perpindahan model SwiftData ke modul baru.
- Part 1 dikerjakan oleh assistant atas permintaan pengguna. Part 2 kembali menjadi tutorial untuk dikerjakan pengguna secara manual.
- Checkpoint disimpan sebagai commit lokal. Tidak ada push, PR, atau deployment.

## Flow dan pemiliknya saat ini

| Tahap | Pemilik saat ini |
| --- | --- |
| Entry point dan ModelContainer | `App/PalmOilFarmerApp.swift`, `App/AppConfiguration.swift` |
| State root, pilihan kebun, perpindahan sheet ke mapping | `App/ContentView.swift` |
| Daftar kebun/draf | `Features/Gardens/List` |
| Guide, pencarian, foto, data kebun | `Features/Gardens/Registration` |
| Editor batas | `Features/Gardens/Mapping` |
| Profil dan editor riwayat | `Features/Gardens/Profile`, `Features/Gardens/History` |
| Informasi program dan kontak pengajuan | `Features/Gardens/Review/ReviewRequestView.swift`, `ReviewContactFormView.swift` |
| Penyimpanan lokal, refresh, submit, cleanup | `Features/Gardens/Data/GardenStore.swift` |
| Akses remote dan konversi CloudKit | `Features/Gardens/Review/Data` |

Flow utama: Home → guide → search/GPS/foto → mapping → data kebun → profil → riwayat pupuk/panen → informasi pengajuan → kontak → submit. Status dan hasil menjadi batas integrasi dengan implementasi tim.

## Aturan data yang dipertahankan

1. Lokasi yang ditunda dan kebun terpetakan yang belum diajukan disimpan sebagai `DraftPlantationRequest` di SwiftData.
2. Sesudah submit berhasil, CloudKit menjadi sumber data submitted dan implementasi sekarang membersihkan draf lokal. Cache submitted tidak ditambahkan dalam refactor ini.
3. Container/environment, identitas aplikasi, lokasi store, nama model persistence, field/keys, dan enum raw values dipertahankan.
4. Nama record dan kontrak DTO dengan operator tetap kompatibel. Koneksi operator merupakan konteks produk dari pengguna; verifikasi operator langsung belum dilakukan pada sesi ini.
5. Hasil runtime tidak disamakan dengan bukti server menerima pengajuan, operator membacanya, atau pengguna dapat mengakses hasil offline.

## Hasil build dan test

| Pemeriksaan | Hasil |
| --- | --- |
| Build Debug melalui action `test` | Berhasil; build result resmi `succeeded`, 0 error |
| Swift Testing | 18 lulus, 0 gagal, 0 skipped |
| Warning build | 8 warning dalam ringkasan resmi Xcode |
| Run melalui Xcode | Berhasil menjalankan project ini pada iPhone 18 Pro iOS 27.0 |
| Build Release / Archive | Belum dijalankan |
| Pengujian upgrade TestFlight | Belum dijalankan |

Bukti ringkas yang disimpan di Git:

- [Ringkasan test](evidence/part-01-tests-summary.json).
- [Ringkasan build dan warning](evidence/part-01-build-summary.json).

Perintah pemeriksaan otomatis yang benar-benar dijalankan, dari root repository:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project PalmOilFarmer.xcodeproj \
  -scheme PalmOilFarmer \
  -destination 'platform=iOS Simulator,id=BD8D68EA-DE49-4AF3-A283-69D78F6984C3' \
  -derivedDataPath /private/tmp/palm-oil-part1-baseline-build \
  -resultBundlePath /private/tmp/palm-oil-part1-baseline-tests.xcresult \
  -parallel-testing-enabled NO \
  -quiet
```

Result bundle dan log lengkap berada di folder sementara lokal, bukan di Git. Untuk mengulang, gunakan nama result bundle baru karena Xcode tidak menimpa result bundle yang sudah ada.

Warning awal mencakup default argument `GardenStore`, `CloudKitFarmerReviewRepository.shared`, preview `WaypointZoneThumbnail`, decoding `HarvestRecord`, dan perbandingan `GardenStage` pada test. Beberapa warning menyebut perubahan menjadi error di Swift 6 language mode. Tidak ada perubahan compiler setting atau perbaikan warning pada Part 1.

Console build juga mencetak diagnostic “command failed with exit code 0”. Outcome ditentukan dari exit code proses dan result bundle: proses berakhir 0, ringkasan build mencatat 0 error, serta semua 18 test lulus. Penyebab diagnostic tersebut belum ditentukan; baseline ini tidak mengklaim console bebas diagnostic.

## Hasil pemeriksaan UI

Hanya observasi pada app yang dijalankan dari project Xcode ini dihitung pada tabel berikut. UI tidak dioperasikan lagi setelah pengguna meminta bekerja tanpa computer use.

| ID | Skenario | Status | Bukti / batas pemeriksaan |
| --- | --- | --- | --- |
| F01 | Home dan refresh | Sebagian | Home tampil dengan filter dan kebun submitted. Gesture pull-to-refresh tidak diverifikasi tersendiri |
| F02 | Guide → pencarian → hasil → mapping | Lulus pada sesi ini | Query `Dumai` menghasilkan lokasi; memilihnya menutup pencarian dan membuka editor batas |
| F03 | Lakukan Nanti → restart → lanjutkan draf | Lulus pada sesi ini | Draf `Dumai` tampil kembali setelah Stop/Run melalui Xcode; membuka kartu masuk mapping dalam mode draf |
| F04 | Batas valid → detail → simpan | Sebagian | Empat titik menghasilkan batas 6,4 ha / perimeter 1.007 m; Konfirmasi membuka Data kebun. Input nama/tanggal terinterupsi; save belum diverifikasi |
| F05 | Kebun terpetakan bertahan setelah restart | Belum diuji UI | Test persistensi otomatis lulus, tetapi skenario UI setelah save belum selesai |
| F06 | Membatalkan edit profil/riwayat | Belum diuji UI | Tidak menyamakan pembacaan kode dengan pengujian interaksi |
| F07 | Simpan riwayat dan kesiapan pengajuan | Belum diuji UI | Pengujian filter/stage otomatis lulus; form riwayat belum diperiksa pada sesi ini |
| F08 | Submit pengajuan baru | Belum diuji | Tidak ada pengajuan baru yang dikirim pada sesi ini |
| F09 | Restart dan baca pengajuan baru | Belum diuji | Kebun remote yang sudah ada terbaca; itu bukan bukti round-trip pengajuan baru |
| F10 | Izin lokasi ditolak | Sebagian | “Don’t Allow” dipilih pada baseline; mapping dan simpan draf tetap dapat dilanjutkan. Pemulihan izin/ketepatan GPS belum diuji |
| F11 | Foto geotag dan Cari Lagi | Belum diuji | Data foto/perizinan dan interaksi belum diperiksa |
| F12 | GPS lapangan / background lifecycle | Belum diuji | Membutuhkan pemeriksaan perangkat sesuai scope terkait |

## Identitas aplikasi simulator dan efek pengujian

Simulator mempunyai dua app bernama “Palm Oil Farmer”: instalasi lama `com.hata.Kropshata` dan build lokal `com.hata.PalmOilFarmer`. Bundle identifier build lokal diverifikasi dari Info.plist hasil build. Pemeriksaan awal melalui App Library membuka instalasi lama; hasil interaksinya dikeluarkan dari tabel baseline. Setelah itu aplikasi yang benar dijalankan melalui project Xcode yang path-nya terverifikasi.

Sesi ini membuat draf lokal `Dumai` pada instalasi lama dan pada build lokal. Pada build lokal, batas kebun uji sudah digambar tetapi penyimpanan detail belum diverifikasi. Tidak ada penghapusan data, perubahan identitas aplikasi/container, atau submit remote baru. Akses lokasi ditolak pada kedua instalasi. Data simulator ini tidak dibersihkan setelah sesi dihentikan.

Perbedaan bundle identifier adalah alasan untuk memverifikasi identitas build TestFlight sebelum pengujian upgrade atau rilis berikutnya. Sesi ini tidak menentukan identifier mana yang digunakan TestFlight dan tidak mengubahnya.

## Temuan awal untuk dipisahkan dari refactor struktur

- GardenStore menggabungkan state, SwiftData, mapping, dan CloudKit konkret; profil mempunyai jalur singleton CloudKit sendiri.
- Update/delete submitted garden mengubah memori. Local save/cleanup tertentu memakai `try?`; error handling perlu dibahas sebagai pekerjaan terpisah.
- Query remote mengambil paling banyak 50 record dan belum memproses cursor.
- Hasil completed, report tersedia, dan download masih bercampur dengan data demo. Bagian ini berada di luar scope perubahan implementasi pengguna.
- Domain review menghasilkan `ReviewTimelineEntry` milik UI. GardenBoundary dan zoning masih mengimpor framework lokasi/peta. Memindahkan file belum menyelesaikan dependency tersebut.
- Beberapa bagian README masih menggambarkan JSON dan review simulasi. File `schema.ckdb` yang disebut README tidak ditemukan di checkout.
- Kontrak ACL/deployment CloudKit, pembacaan oleh operator, serta migrasi data pengguna TestFlight belum diverifikasi langsung.

## Status checkpoint

- [x] Baseline kode, scope, dan aturan data dicatat.
- [x] Branch `refactor/01-baseline` dibuat.
- [x] Build dan 18 test otomatis dijalankan dengan bukti tersimpan.
- [x] Observasi UI yang sempat dilakukan dipisahkan dari bagian yang belum diuji.
- [x] Source aplikasi, test, konfigurasi project, dan schema tidak diubah.
- [ ] Verifikasi versi/commit/identitas build TestFlight.
- [ ] Selesaikan pemeriksaan UI yang masih sebagian/belum diuji sebelum menyatakan baseline perilaku lengkap.
- [ ] Verifikasi submit dan pembacaan operator pada environment uji yang disepakati.

Part 2 dapat dipelajari sebagai tutorial penataan folder. Checkpoint ini tidak memberi klaim bahwa semua flow manual atau kompatibilitas upgrade sudah lulus.
