# Hasil Part 7 - Pemetaan, detail, dan draf

Tanggal: 4 November 2026 (Asia/Jakarta). Branch: `refactor/07-mapping-details-drafts`. Acuan: `824ee67`.
Commit implementasi dan test: `25085af`.

Catatan hasil dan verifikasi, tanpa materi tutorial baru. Pelaksanaan melalui file/Terminal, tanpa computer use, push, atau PR.

## Perubahan

- GardenBoundaryViewModel memiliki state titik batas, operasi tambah/pindah/undo/clear, konfirmasi foto, pemeriksaan validitas, dan penyimpanan lokasi untuk “Lakukan Nanti”. Kamera, MapProxy, hit testing marker, drag offset, serta rendering anotasi tetap berada di View.
- GardenMappingCoordinator mengatur detail, konfirmasi keluar, dan hasil akhir pemetaan. Setelah save berhasil, penutupan peta menunggu callback penutupan sheet detail. Sesi detail mempunyai identitas tersendiri, tetap terkunci selama penutupan, dan editor yang dibatalkan/diganti tidak dapat menyimpan lewat callback lama.
- GardenDetailsViewModel memegang draft formulir, menggunakan validasi Domain yang sudah ada, serta membentuk payload Garden yang sama. Edit mempertahankan ID, lokasi, batas, history, review, dan createdAt; fallback bulan lama tetap 10, dan createdAt lama yang nil tetap nil. Save sukses berulang tidak menulis atau mengirim navigasi kedua.
- GardenDetailsCoordinator memiliki rute jenis tanah dan presentasi picker tanggal. Binding tetap diperbarui oleh Back/dismiss bawaan SwiftUI. Focus dan layout formulir tetap menjadi state UI.
- GardenMappingFactory merangkai flow serta editor baru per sesi. Kontrak GardenRegistrationSaving diimplementasikan GardenStore melalui adapter App; pemindahan data tetap menggunakan operasi store/repository sebelumnya. Draf lokasi asal dihapus oleh jalur lama hanya ketika save kebun berhasil.
- Permintaan izin pemetaan dipindahkan dari View ke adapter Data melalui GardenLocationAuthorizing. Root preview dan test menerima stub. Initializer/callback lama dipertahankan dalam LegacyMappingComposition untuk profil, reference screen, dan eksperimen yang tidak diedit.

## Verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Domain + ViewModel/Coordinator pemetaan/detail tanpa source UI/Data/composition | Berhasil dikompilasi dengan Foundation/Observation, DEBUG aktif, tanpa diagnostic |
| Test Debug iPhone 18 Pro iOS 27.0 | 108 lulus, 0 gagal, 0 skipped; sebelumnya 84 test |
| Build Debug dari folder build baru | Berhasil, 0 error, 6 warning lama |
| Build Release simulator | Berhasil, 0 error, 1 warning lama |
| Jenis/pesan/jumlah warning dibanding Part 6 | Identik |
| File tracked lama di luar scope perubahan | 191 file identik dengan acuan |
| Helper mapContent, hit test, recenter, midpoint, dan jarak | Body identik; hash dicatat |
| Perhitungan gesture drag | Identik selain mutasi titik diteruskan ke ViewModel |
| Teks UI dan pesan validasi/save | Dipertahankan |
| Format Git | `git diff --check` lulus |

Dua puluh empat test baru mencakup mutasi/validitas titik, gate foto, batas “Lakukan Nanti”, save gagal/retry, inactive flow, izin melalui stub, field wajib, payload create/edit, ID/tanggal/history/review, fallback data lama, idempotensi save, rute/picker/back, sesi dan urutan penutupan modal, callback editor lama, pencarian ulang, round-trip SwiftData melalui flow utama, kelanjutan draf tanpa menghapus draf lain, pembaruan daftar, serta isolasi dependency izin per flow.

Bukti: [test](evidence/part-07-tests-summary.json), [build Debug](evidence/part-07-debug-build-summary.json), [build Release](evidence/part-07-release-build-summary.json), dan [batas dependency/hash](evidence/part-07-boundary-verification.json). Log/result bundle lengkap berada di `/private/tmp/palm-oil-part7.yj86idlh`; hasil final memakai `DebugVerifiedTests.xcresult` dan `ReleaseVerifiedBuild.xcresult`. Xcode 27.0 dipilih per proses melalui DEVELOPER_DIR tanpa mengubah pilihan global.

## Batas pekerjaan

Seluruh source Domain lama, Data lama, GardenStore, konfigurasi/identity/entitlements/project, model/persisted fields, payload CloudKit, layout editor peta, serta implementasi profil/riwayat/status/hasil/panduan/eksperimen dipertahankan. Tidak menambahkan cache submitted atau migrasi storage. Kebijakan error store juga dipertahankan; refactor ini tidak memperbaiki save/fetch yang sebelumnya mengabaikan error atau membersihkan error lama setelah retry.

Profil/riwayat dan pengajuan tetap menjadi Part 8–9. Test memakai stub izin dan tidak menulis CloudKit melalui repository test. Test state/callback tidak membuktikan gesture/camera, animasi/dismiss SwiftUI, atau prompt izin di perangkat. Belum dilakukan UI smoke test, Archive, upload TestFlight, verifikasi upgrade, maupun pemeriksaan operator baru. Dokumen analisis lama yang untracked tidak dimasukkan ke commit.
