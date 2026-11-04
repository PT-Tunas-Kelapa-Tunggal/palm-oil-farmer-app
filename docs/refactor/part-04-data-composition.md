# Hasil Part 4 - Data dan dependency injection manual

Tanggal: 4 November 2026 (Asia/Jakarta). Branch: `refactor/04-data-composition`. Acuan: `9cffc5f`.
Commit implementasi dan test: `7e61626`.

Catatan pelaksanaan dan verifikasi; tidak ada materi tutorial baru. Pekerjaan melalui file/Terminal, tanpa computer use, push, atau PR.

## Perubahan

- `GardenDraftRepository` mengembalikan snapshot Domain untuk lokasi yang belum dipetakan dan kebun lokal. `SwiftDataGardenDraftRepository` mengambil alih fetch, insert, update, delete, serta save dari GardenStore.
- GardenStore berada di `App/State` sebagai state bersama selama transisi. Initializer utamanya menerima dua kontrak repository, tanpa ModelContainer, ModelContext, mapper Data, atau default implementasi konkret.
- Proyeksi request menjadi Garden dipindahkan ke initializer Domain dengan isi perhitungan/pemetaan yang sama. Mapper DTO tetap berada di Data dan meneruskan konversi Garden ke initializer tersebut.
- `AppDependencies` merangkai container, repository lokal, repository CloudKit, dan store secara manual. App memberikan repository review yang sama kepada profil melalui environment. Profil tidak lagi menyebut implementasi CloudKit konkret.
- Data tidak membaca AppConfiguration. Container identifier diwajibkan pada initializer repository CloudKit dan diberikan oleh App; operasi query/save, DTO, serta adapter CKRecord dipertahankan.
- Root preview memakai container in-memory dan stub review tanpa pengajuan remote. Test lama juga memakai komposisi eksplisit dengan stub review.

## Verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Domain mandiri, Foundation | Berhasil tanpa diagnostic |
| Domain + GardenStore tanpa source Data/composition, Foundation dan Observation, DEBUG aktif | Berhasil tanpa diagnostic |
| Test Debug, iPhone 18 Pro iOS 27.0 | 38 lulus, 0 gagal, 0 skipped; sebelumnya 29 test |
| Build Debug dari folder build baru | Berhasil, 0 error, 6 warning lama |
| Build Release simulator | Berhasil, 0 error, 1 warning lama |
| File model/configuration/implementasi tim yang dilindungi | 26 file identik dengan acuan |
| Operasi CloudKit dan isi proyeksi request menjadi Garden | Tidak berubah |
| Format Git | `git diff --check` lulus |

Sembilan test baru mencakup pembukaan ulang store di disk dengan field/model yang sudah ada, pelestarian field yang tidak diedit, urutan snapshot, substitusi repository tanpa SwiftData, kegagalan load/write, tidak menghapus draf saat submit ditolak, promosi remote saat cleanup lokal gagal, perilaku hapus lama, edit/delete submitted yang tetap hanya di memori, serta komposisi dengan container/repository yang diberikan pemanggil. Dua warning default argument GardenStore hilang setelah dependency diwajibkan; tidak ada jenis/pesan warning baru dibanding Part 3.

Bukti: [test](evidence/part-04-tests-summary.json), [build Debug](evidence/part-04-debug-build-summary.json), [build Release](evidence/part-04-release-build-summary.json), dan [batas dependency serta hash](evidence/part-04-boundary-verification.json). Result bundle/log lengkap berada di `/private/tmp/palm-oil-part4.qsbfe33b`. Xcode 27.0 dipilih per proses melalui DEVELOPER_DIR tanpa mengubah pilihan global.

## Kompatibilitas dan batas yang tersisa

Model SwiftData, stored properties, lokasi store, app identity, entitlements, schema/payload CloudKit, dan implementasi status/hasil/panduan/eksperimen tim tetap dipertahankan. Draf masih lokal; submitted masih berasal dari CloudKit tanpa cache submitted. Test disk memakai model saat ini dan tidak membuktikan upgrade dari build TestFlight.

`App/LegacyComposition.swift` sengaja mempertahankan `GardenStore()` dan default repository review live bagi layar standalone/reference serta eksperimen yang tidak diedit. Alur utama memakai komposisi eksplisit. Default kompatibilitas ini belum dihapus seluruhnya; jangan dipakai sebagai pola untuk fitur baru.

Penanganan kegagalan lama dipertahankan: lookup tertentu menganggap fetch gagal sebagai tidak ditemukan, penghapusan kebun mengabaikan kegagalan save, dan submit remote yang berhasil tetap berhasil walau cleanup lokal gagal. Mengubah kebijakan tersebut merupakan perubahan perilaku terpisah. GardenStore masih mengoordinasikan state dan submit; ViewModel, Coordinator, serta pemisahan orkestrasi per fitur belum dikerjakan di part ini.

Tidak ada UI smoke test, Archive, upload TestFlight, verifikasi upgrade, atau pemeriksaan operator baru. Pemeriksaan manual yang belum selesai pada baseline tetap terbuka. Dokumen analisis lama yang sudah untracked tidak dimasukkan ke commit.
