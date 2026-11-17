# Hasil Part 6 - Registrasi lokasi dan foto

Tanggal: 4 November 2026 (Asia/Jakarta). Branch: `refactor/06-location-photo-registration`. Acuan: `82ef4cd`.
Commit implementasi dan test: `4ec0697`.

Catatan hasil dan verifikasi, tanpa materi tutorial baru. Pelaksanaan melalui file/Terminal, tanpa computer use, push, atau PR.

## Perubahan

- Kontrak pencarian/GPS dan galeri berada di Domain dengan nilai Foundation. View menerima ViewModel/flow; akses MapKit, CoreLocation, PHAsset, izin Photos, serta thumbnail berada di Data.
- LocationSearchViewModel memiliki query, hasil, debounce 350 ms, pesan lama, request GPS, dan penolakan respons yang sudah tidak berlaku. Pembatalan task, perubahan query, dan invalidasi saat meninggalkan layar mencegah respons lama mengubah state atau membuka peta.
- Adapter lokasi menggunakan LocationSearchService dan CurrentLocationProvider yang isinya tetap identik. Setiap permintaan GPS mempunyai provider sendiri dengan accuracy, izin, timeout, reverse-geocoding, dan fallback yang sama.
- GardenPhotoPickerViewModel memuat snapshot akses/metadata foto dan meneruskan pemilihan koordinat. Galeri yang dibuka ulang memeriksa akses kembali; foto sesi sebelumnya tidak dapat dipilih selama load atau sesudah pembatalan.
- Aturan foto dipertahankan: gambar user library dengan geotag, mengecualikan screenshot, urutan creationDate menurun, akses authorized/limited diterima. Aturan ini tidak membuktikan asal kamera suatu gambar. Thumbnail tetap 240×240, aspectFill, opportunistic, dan network-enabled; hasil disalurkan sebagai PNG dalam AsyncStream dan request dibatalkan ketika konsumen berhenti.
- GardenRegistrationCoordinator mengatur guide/search/galeri. Pemilihan foto menunggu callback penutupan galeri sebelum meneruskan lokasi ke AppCoordinator; root tetap menunggu penutupan sheet registrasi sebelum membuka peta. Jeda navigasi berbasis timer 350 ms dihapus; debounce pencarian tetap 350 ms. Callback terlambat tidak menyela galeri atau mengirim navigasi kedua.
- App merangkai flow dan layanan baru per sesi melalui GardenRegistrationFactory. Initializer lama beserta initialResults/search closure dipertahankan melalui LegacyRegistrationComposition agar reference screen dan eksperimen tidak perlu diedit. Root preview memakai stub tanpa akses Photos/GPS sungguhan.

## Verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Domain + ViewModel/Coordinator registrasi tanpa source UI/Data/composition | Berhasil dikompilasi dengan Foundation/Observation, DEBUG aktif, tanpa diagnostic |
| Test Debug iPhone 18 Pro iOS 27.0 | 84 lulus, 0 gagal, 0 skipped; sebelumnya 54 test |
| Build Debug dari folder build baru | Berhasil, 0 error, 6 warning lama |
| Build Release simulator | Berhasil, 0 error, 1 warning lama |
| Jenis/pesan/jumlah warning dibanding Part 5 | Identik |
| File tracked lama di luar scope perubahan | 173 file identik dengan acuan |
| Teks UI/status/error yang dipindahkan | Dipertahankan |
| Format Git | `git diff --check` lulus |

Tiga puluh test baru mencakup query kosong/trim/debounce/retry, respons sukses/error yang terlambat, query berubah sebelum task berikutnya dimulai, pembatalan, request GPS ganda, error lokasi, delapan kombinasi kelayakan foto, izin/urutan galeri, pemilihan metadata, load galeri tumpang tindih, pembukaan galeri ulang, thumbnail progresif, event Coordinator, dua tahap penutupan sheet, isolasi layanan per flow, serta integrasi pembatalan dengan root.

Bukti: [test](evidence/part-06-tests-summary.json), [build Debug](evidence/part-06-debug-build-summary.json), [build Release](evidence/part-06-release-build-summary.json), dan [batas dependency/hash](evidence/part-06-boundary-verification.json). Log/result bundle lengkap berada di `/private/tmp/palm-oil-part6.6wg89ok0`; hasil final memakai `DebugVerifiedTests.xcresult` dan `ReleaseVerifiedBuild.xcresult`. Xcode 27.0 dipilih per proses melalui DEVELOPER_DIR tanpa mengubah pilihan global.

## Batas pekerjaan

Seluruh model/persisted fields, store dan kebijakan draf/submitted, DTO/CloudKit adapter, konfigurasi/identity/entitlements/project, pemetaan/detail kebun, profil/riwayat, serta implementasi status/hasil/panduan/eksperimen tetap dipertahankan. Tidak menambahkan cache submitted atau migrasi storage. Mapping/details/drafts, profile/history, dan submission tetap menjadi Part 7–9.

Test memakai repository stub dan respons terkontrol, tanpa meminta izin lokasi/foto atau menulis CloudKit melalui repository test. Test state/callback tidak membuktikan perilaku permission OS, reverse-geocoding live, thumbnail iCloud/penampilan foto, maupun animasi SwiftUI di perangkat. Belum dilakukan UI smoke test, Archive, upload TestFlight, verifikasi upgrade, atau verifikasi operator baru. Dokumen analisis lama yang untracked tidak dimasukkan ke commit.
