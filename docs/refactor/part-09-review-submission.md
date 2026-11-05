# Hasil Part 9 - Persetujuan, kontak, dan pengajuan

Tanggal: 4 November 2026 (Asia/Jakarta). Branch: `refactor/09-review-submission`. Acuan: `7a06601`.
Commit implementasi dan test: `54d2560`.

Catatan hasil dan verifikasi, tanpa materi tutorial baru. Pelaksanaan melalui file/Terminal, tanpa computer use, push, atau PR.

## Perubahan

- Informasi/persetujuan program memakai ReviewRequestViewModel. Formulir kontak memakai ReviewContactFormViewModel untuk draft, validasi Domain yang sudah ada, pengiriman, error, dan retry. Copy, checkbox, urutan focus, scroll, keyboard, dan layout field dipertahankan.
- ReviewRequestCoordinator memiliki rute kontak bertipe dan ID sesi. Native Back lalu lanjut kembali membuat sesi/form baru. Close dan callback dari sesi yang sudah ditutup/diganti tidak dapat mengubah atau menutup sesi baru.
- ReviewRequestFactory dirangkai eksplisit di AppDependencies dan GardenProfileFactory. Screen profil tidak lagi mengorkestrasi submit lewat method async pada View. GardenProfileReviewBridge menjadi GardenProfileReviewPresentation; body presentasi dan assertion test lamanya tetap sama setelah penggantian nama.
- SubmitGardenReview membaca kebun terbaru melalui ReviewSubmissionGateway, memeriksa keberadaan, kelengkapan, dan status belum diajukan. Satu instance bersama menolak pengiriman bersamaan untuk kebun yang sama; kebun berbeda tetap dapat dikirim. Tap berulang pada formulir juga ditahan selama mengirim dan setelah sukses.
- GardenStore mengimplementasikan gateway melalui extension; body operasi submit/promotion/cleanup lama tidak berubah. Sukses remote tetap dipromosikan dan draf dibersihkan meskipun layar sudah ditutup atau caller dibatalkan setelah pengiriman dimulai. Sesi UI yang masih aktif menerima completion; sesi lama mengabaikan error/completion yang terlambat. Gagal remote mempertahankan draf dan isian untuk retry.
- API callback ReviewRequestView/ReviewContactFormView tetap tersedia melalui App/LegacyReviewComposition.swift untuk caller lama. Source reference/eksperimen dan wiring profil legacy dipertahankan.

## Verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Test Debug iPhone 18 Pro, iOS 27.0 | 159 lulus, 0 gagal, 0 skipped; sebelumnya 138 |
| Build Debug app + target test dari folder build baru | Berhasil, 0 error, 6 warning lama |
| Build Release simulator | Berhasil, 0 error, 1 warning lama |
| Jenis/pesan/jumlah warning dibanding Part 8 | Identik |
| Domain terpisah | 20 file, Foundation saja, berhasil dikompilasi tanpa diagnostic |
| Inti alur utama terpisah | 48 file Domain/Store/model/Coordinator dengan Foundation/Observation, DEBUG aktif, tanpa source UI/Data/composition, berhasil tanpa diagnostic; presentasi report/profil tidak termasuk module ini |
| File tracked lama di luar scope | 235 dari 245 file lama identik; 10 path lama yang diperbolehkan berubah dicatat pada bukti |
| UI copy, checkbox, helper field kontak, body presentasi review | Dipertahankan; perbandingan dan hash dicatat |
| Format Git | Staged diff bersih sebelum commit implementasi |

Dua puluh satu test baru mencakup kedua persetujuan, validasi/normalisasi kontak dan nomor telepon mentah, field keyboard, tap ganda, pengiriman serentak per kebun, retry, profil hilang/tidak lengkap/sudah diajukan, snapshot terbaru, cancellation sebelum/sesudah pengiriman, native Back, sesi yang ditutup/diganti, serta pemulihan data dari repository setelah store dibuka ulang.

Test integrasi memakai graph AppDependencies dan repository stub: Home → lokasi → pemetaan → detail → riwayat pupuk/panen → persetujuan → kontak → submit → promotion/eviction → store baru → refresh remote. Identitas kebun/record pupuk, koordinat, tahun/bulan, tanah, panen, dan kontak diperiksa. Test ini memanggil model/Coordinator secara langsung; bukan UI automation atau pengiriman CloudKit sungguhan.

Bukti: [test](evidence/part-09-tests-summary.json), [build Debug](evidence/part-09-debug-build-summary.json), [build Release](evidence/part-09-release-build-summary.json), dan [batas dependency/hash](evidence/part-09-boundary-verification.json). Log/result bundle di `/private/tmp/palm-oil-part9.q4w5z7r_`; hasil final memakai `DebugTestsFinal.xcresult`, `DebugCleanBuild.xcresult`, dan `ReleaseBuild.xcresult`. Build test final yang inkremental memiliki 0 warning; pembandingan baseline memakai build Debug bersih agar warning lama tetap terhitung. Xcode 27.0 dipilih per proses melalui DEVELOPER_DIR.

## Batas akhir

Implementasi sembilan part untuk alur utama Home sampai pengajuan berhasil telah selesai. View menangani render/focus/map gestures, ViewModel menangani state dan aksi fitur, Coordinator menangani transisi/sesi, Domain menangani nilai/aturan/use case, Data menangani adapter penyimpanan/framework, dan App merangkai dependency manual. Tetap satu app module; batas folder/protocol belum berupa target/package terpisah. GardenStore tetap menjadi sumber state bersama dan gateway side effect. Entry legacy dipertahankan untuk kompatibilitas; pekerjaan baru memakai factory eksplisit.

Seluruh source Data, Domain lama, GardenStore lama, schema/store path/identity/entitlements/project, registration/mapping/history lama, serta implementasi status/hasil/rekomendasi/panduan/unduh peta/eksperimen tidak diubah di Part 9. SwiftData tetap hanya menyimpan draf, dan submitted tetap mengikuti CloudKit tanpa cache lokal baru. Kebijakan cleanup error serta edit/delete submitted yang hanya di memori tetap seperti sebelumnya.

Penahan submit bersamaan berlaku pada instance use case alur utama dalam proses app yang sama. Tidak menambah idempotency server, request ID tersimpan, atau solusi untuk timeout ambigu setelah server mungkin sudah menyimpan. Strategi request ID dan payload CloudKit tetap sama. Penutupan layar bukan pembatalan transaksi remote yang sudah berjalan.

Belum dilakukan UI smoke test perangkat/simulator, pemeriksaan permission/focus/gesture/dismiss visual, signed Archive, upload TestFlight, verifikasi upgrade dari build TestFlight terpasang, atau pemeriksaan operator baru. Hasil unit/build tidak membuktikan seluruh pemeriksaan rilis tersebut. Repository test memakai stub; tidak menulis CloudKit melalui repository test. Dokumen analisis lama yang untracked tidak dimasukkan ke commit.
