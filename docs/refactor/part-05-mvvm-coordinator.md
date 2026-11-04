# Hasil Part 5 - Fondasi MVVM-C dan daftar kebun

Tanggal: 4 November 2026 (Asia/Jakarta). Branch: `refactor/05-mvvm-coordinator`. Acuan: `4b6af89`.
Commit implementasi dan test: `05b4a53`.

Catatan verifikasi, tanpa materi tutorial baru. Pelaksanaan melalui file/Terminal, tanpa computer use, push, atau PR.

## Perubahan

- AppCoordinator memiliki path bertipe `[AppRoute]` untuk profil/developer serta state modal registrasi/pemetaan. ContentView mengikat NavigationStack dan presentasi modal ke Coordinator; Back dan dismiss dari SwiftUI tetap memperbarui binding tersebut.
- Pemilihan lokasi menutup sheet lebih dahulu sebelum membuka peta. “Cari Lagi” menunggu peta selesai ditutup lalu membuka pencarian secara langsung. Melanjutkan draf mempertahankan draftID dan source yang lama. Event berulang tidak menambahkan profil dua kali atau menyela transisi modal yang sedang berlangsung.
- GardenListViewModel memiliki pilihan filter, membentuk presentation daftar, menjalankan refresh/delete melalui `GardenListDataSource`, dan mengirim event navigasi ke Coordinator. Conformance GardenStore terhadap kontrak fitur berada di App; fitur daftar tidak mengimpor atau menyebut store konkret, Data, maupun Coordinator konkret.
- Presentation membaca nilai store bersama saat dibutuhkan, tanpa cache daftar kedua. Perubahan profil dan hasil refresh tetap terlihat melalui Observation.
- GardenListScreen merupakan entry point MVVM produksi. GardenListView mempertahankan API nilai/callback untuk preview/reference/eksperimen. Keduanya memakai GardenListContent dan aturan presentation yang sama. Isi layout dipertahankan selain penggantian kalkulasi inline dengan getter presentation; draft card dan preview lama identik.
- AppDependencies merangkai store, ViewModel, serta Coordinator secara manual. NavigationStack tetap menjadi mekanisme navigasi SwiftUI; tidak menambahkan UIKit, DI framework, atau kerangka Coordinator generik.

## Verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Domain, GardenStore, list model/presentation, dan Coordinator tanpa source UI/Data/composition | Berhasil dikompilasi dengan Foundation/Observation, DEBUG aktif, tanpa diagnostic |
| Test Debug, iPhone 18 Pro iOS 27.0 | 54 lulus, 0 gagal, 0 skipped; sebelumnya 38 test |
| Build Debug | Berhasil, 0 error, 6 warning lama |
| Build Release simulator | Berhasil, 0 error, 1 warning lama |
| Pesan/jenis/jumlah warning dibanding Part 4 | Identik |
| File tracked lama di luar empat source yang diubah dan README | 167 file identik dengan acuan |
| Format Git | `git diff --check` lulus |

Enam belas test baru memeriksa filter/badge, filter tersembunyi, empty state, urutan daftar campuran, event ViewModel, refresh/delete melalui kontrak, kegagalan delete tanpa penghapusan optimistis, invalidasi Observation dari store bersama, visibilitas edit profil, komposisi graph, Back, pemilihan berulang, registrasi/foto/draf, pembatalan, penundaan presentasi, dan transisi pencarian ulang.

Bukti: [test](evidence/part-05-tests-summary.json), [build Debug](evidence/part-05-debug-build-summary.json), [build Release](evidence/part-05-release-build-summary.json), dan [batas dependency/hash/layout](evidence/part-05-boundary-verification.json). Result bundle/log lengkap berada di `/private/tmp/palm-oil-part5.77h9n319`. Xcode 27.0 dipilih per proses melalui DEVELOPER_DIR tanpa mengubah pilihan global.

## Batas pekerjaan

Seluruh source Domain/Data, model dan konfigurasi penyimpanan, app identity, entitlements/project, key pengaturan developer, source test lama, serta implementasi status/hasil/panduan/eksperimen dipertahankan. Kebijakan SwiftData untuk draf dan CloudKit untuk submitted tetap sama, tanpa cache submitted atau migrasi data.

Part ini merupakan pilot MVVM-C pada daftar dan navigasi root. State internal registrasi, peta, profil/riwayat, dan pengajuan masih mengikuti implementasi sebelumnya sampai part masing-masing. GardenStore masih mengoordinasikan state bersama dan submit; jembatan LegacyComposition tetap tersedia bagi layar lama.

Test transisi memeriksa state dan callback Coordinator, bukan rendering/animasi SwiftUI. Belum dilakukan UI smoke test, Archive, upload TestFlight, verifikasi upgrade, atau verifikasi operator baru. Dokumen analisis lama yang untracked tidak dimasukkan ke commit.
