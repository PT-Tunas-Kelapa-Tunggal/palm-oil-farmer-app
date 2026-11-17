# Hasil Part 8 - Profil dan riwayat kebun

Tanggal: 4 November 2026 (Asia/Jakarta). Branch: `refactor/08-profile-history`. Acuan: `81e9a3a`.
Commit implementasi dan test: `389310d`.

Catatan hasil dan verifikasi, tanpa materi tutorial baru. Pelaksanaan melalui file/Terminal, tanpa computer use, push, atau PR.

## Perubahan

- App memakai GardenProfileScreen dengan GardenProfileViewModel dan GardenProfileCoordinator. Model membaca kebun terbaru melalui GardenProfileDataSource; implementasi sumber dan update/delete tetap GardenStore yang sama.
- Save pupuk/panen mengubah hanya riwayat terkait pada snapshot terbaru. Save detail menggabungkan field yang dapat diedit ke kebun terbaru sehingga history, review, lokasi, batas, ID, dan createdAt yang sudah berubah tidak ditimpa snapshot editor lama.
- Coordinator profil memiliki satu sesi sheet aktif untuk detail/pupuk/panen/pengajuan, konfirmasi hapus, serta handoff ke status/hasil yang sudah ada. Sesi tetap terkunci selama penutupan; callback editor lama, salah jenis, atau profil yang sudah ditutup tidak dapat menulis.
- ViewModel editor pupuk/panen memiliki draft, validasi Domain lama, error, dan save. Save gagal mempertahankan draft; save sukses berulang tidak menulis dua kali. History pupuk kosong tetap diperbolehkan, baris parsial tetap ditolak, dan ID record yang diedit dipertahankan.
- Focus, scroll, wheel/stepper, dan layout tetap di UI. Identifier focus FertilizerField dipindahkan tanpa perubahan body ke file Foundation. Entry card pupuk serta card/stepper/wheel panen mempertahankan body identik.
- GardenProfileContent dipakai bersama oleh screen produksi dan GardenProfileView lama. API callback/reference/eksperimen tetap tersedia; wiring review legacy dan helpernya dipertahankan. Root produksi menerima factory eksplisit dari AppDependencies.
- GardenProfileReviewBridge mempertahankan presentasi status/timeline/report dan menolak hasil load yang sudah dibatalkan atau kedaluwarsa. Consent/contact serta orkestrasi submit lengkap tetap Part 9; screen produksi sementara meneruskan submit ke operasi GardenStore yang lama.

## Verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Domain + model/Coordinator inti profil/riwayat tanpa source UI/Data/composition | Berhasil dikompilasi dengan Foundation/Observation, DEBUG aktif, tanpa diagnostic; bridge presentasi review tidak termasuk pemeriksaan module ini |
| Test Debug iPhone 18 Pro iOS 27.0 | 138 lulus, 0 gagal, 0 skipped; sebelumnya 108 test |
| Build Debug dari folder build baru | Berhasil, 0 error, 6 warning lama |
| Build Release simulator | Berhasil, 0 error, 1 warning lama |
| Jenis/pesan/jumlah warning dibanding Part 7 | Identik |
| File tracked lama di luar scope perubahan | 216 file identik dengan acuan |
| Layout profil | Identik setelah penggantian aksi navigasi dengan parameter callback |
| Body kontrol riwayat dan helper review legacy | Identik; hash dicatat |
| Format Git | Pemeriksaan staged/commit bersih setelah perapian satu baris kosong EOF |

Tiga puluh test baru mencakup draft/identitas/validasi pupuk, history kosong, field keyboard, default/range/weight panen, kegagalan/retry/save berulang, pembatalan, source terbaru dan Observation, merge detail/history, profil hilang, delete gagal/sukses, sesi sheet, native Back/dismiss, status/hasil handoff, round-trip SwiftData, kesiapan profil di daftar, callback kedaluwarsa, kebijakan submitted yang hanya di memori, serta load review yang terlambat/gagal/dibatalkan.

Bukti: [test](evidence/part-08-tests-summary.json), [build Debug](evidence/part-08-debug-build-summary.json), [build Release](evidence/part-08-release-build-summary.json), dan [batas dependency/hash/layout](evidence/part-08-boundary-verification.json). Log/result bundle lengkap berada di `/private/tmp/palm-oil-part8.1tbvix51`; hasil final memakai `DebugTests.xcresult` dan `ReleaseBuild.xcresult`. Xcode 27.0 dipilih per proses melalui DEVELOPER_DIR tanpa mengubah pilihan global.

## Batas pekerjaan

Seluruh source Domain/Data, GardenStore lama, model/persisted fields, konfigurasi/identity/entitlements/project, registration/mapping, implementasi status/hasil/rekomendasi/panduan/eksperimen, dan test lama dipertahankan. Tidak menambah cache submitted atau migrasi data. Update/delete submitted masih hanya mengubah memori dan kembali mengikuti CloudKit setelah refresh, sesuai perilaku awal. Kebijakan error store tidak diubah.

GardenProfileView callback lama tetap memakai wiring/state lama untuk reference screen dan eksperimen; alur utama telah memakai model/Coordinator baru. Consent/contact/submission masih merupakan batas transisi Part 9. Test memakai repository stub dan tidak menulis CloudKit melalui repository test. Belum dilakukan UI smoke test untuk navigasi/focus/wheel/dismiss, Archive, upload TestFlight, verifikasi upgrade, atau pemeriksaan operator baru. Dokumen analisis lama yang untracked tidak dimasukkan ke commit.
