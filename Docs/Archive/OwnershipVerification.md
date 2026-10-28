# Verifikasi struktur Gardens berdasarkan area

> Catatan historis. Struktur folder telah diperbarui menjadi Features langsung dan Shared/Gardens. Gunakan [Architecture](../Architecture.md) untuk struktur saat ini dan [FeatureFoldersVerification](FeatureFoldersVerification.md) untuk pemeriksaan terbaru. Tautan source dalam dokumen ini mengikuti lokasi sekarang; uraian dan hasil tes tetap merujuk iterasi saat itu.


Tanggal: 28 Oktober 2026. Baseline: `5245dd4`, setelah refactor pertama. Branch: `codex/refactor-gardens-ownership`. Catatan ini khusus iterasi ownership; [Verification](Verification.md) merupakan hasil historis 27 Oktober.

## Perubahan

74 file lama dipindah ke area pemilik. GardenSectionHeader akhirnya masuk Profile/Components: pemakai runtime hanya dua section profil, sedangkan pemakaian di History hanya preview. Dua file baru: GardenProfileContent untuk komposisi isi profil dan ReviewSubmissionView untuk NavigationStack sheet informasi/kontak. Tidak membuat Flow baru atau mengganti API GardenProfileScreen.

State, ScrollView/scroll tracking, toolbar, sheet modifiers, task refresh, receivedReview, transisi onDismiss serta callback simpan tetap dimiliki profil. Submit inline menjadi fungsi bernama dengan urutan operasi yang sama. Tidak ada perubahan model, persistence, transport, JSON, aset, project/target, signing, deployment target atau AppFlow.

## Build dan test

Xcode 27.0, iOS Simulator 27, scheme PalmOilFarmer. Build Debug tahap perpindahan lulus. Build Debug dan Release setelah ekstraksi lulus. Seluruh **28 test dalam empat suite** lulus: PalmOilFarmerTests, GardenStressTests, CodedUI2FlowTests, FindingBlockTests.

Test final dijalankan pada salinan sementara source dengan satu XCTest snapshot tambahan. Source aplikasi sama secara semantik; setelahnya hanya whitespace serta pemindahan GardenSectionHeader tanpa perubahan isi. Build final di workspace memeriksa lokasi akhir. Tidak menambah test yang hanya memeriksa struktur folder.

Peringatan concurrency WaypointPreviewData yang sudah ada pada baseline tetap ada; pemberitahuan AppIntents metadata juga tetap ada. Percobaan awal build dibatasi akses simulator/compiler, lalu berhasil dengan akses yang sesuai. Dua percobaan harness snapshot awal gagal kompilasi karena environment aksesibilitas read-only dan fixture name immutable; harness diperbaiki tanpa mengubah kode aplikasi.

Log: `/tmp/krops-ownership-moves.log`, `/tmp/krops-ownership-debug-final.log`, `/tmp/krops-ownership-release.log`, `/tmp/krops-ownership-release-final.log`, `/tmp/krops-ownership-final.log`. Result bundles baseline/final: `/tmp/krops-ownership-baseline-v3.xcresult` dan `/tmp/krops-ownership-final.xcresult`.

## Visual

**32/32 pasangan identik piksel demi piksel**, 402 × 874 pt, light/dark × Dynamic Type large/accessibility3. Delapan kasus: profil standard lengkap dengan nama panjang, kosong, sebagian; overview; chart; informasi review; formulir kontak; editor panen. Snapshot informasi review final memakai ReviewSubmissionView yang baru, baseline memakai NavigationStack sebelumnya. Sampel sebelum/sesudah diperiksa berdampingan.

Hasil numerik: [OwnershipVisualComparison](OwnershipVisualComparison.json). Harness dan gambar berada di `/tmp/krops-ownership-*`, tidak menjadi source/test permanen. Snapshot mencakup viewport awal, bukan seluruh posisi scroll. Gambar profil menggunakan aset reference agar citra satelit asinkron tidak memengaruhi perbandingan. Layout/overflow lama pada varian reference tetap dipertahankan.

## Interaksi dengan fixture sintetis

Simulator khusus **Krops Refactor QA**, terpisah dari data pengguna. Salinan QA mengganti entry point dengan parent stateful berisi GardenPreviewData, callback simpan/hapus dan ReviewService stub. File produksi tidak diubah untuk memaksa pengujian lulus. Uji UI memeriksa wiring callback/presentasi; kegagalan disk sebenarnya dan perlindungan riwayat terbaru dicakup suite persistence yang sudah ada.

- Daftar → profil berhasil.
- Informasi review → persetujuan → formulir kontak berhasil; data kontak seluruhnya sintetis dan tidak dikirim ke server.
- Submit pertama melempar kegagalan koneksi; alert tampil, isian/form tetap ada.
- Submit kedua menghasilkan respons `qa-response`, lalu callback simpan pertama mengembalikan false. Alert gagal simpan tampil dan sheet tetap terbuka.
- Retry berikutnya memakai respons sama: tidak ada submit ketiga. Simpan berhasil, sheet menutup, kemudian halaman status terbuka.
- Status → hasil → kembali ke profil berhasil. Refresh stub dipanggil ketika profil muncul lagi.
- Editor pupuk dibuka dari section hasil ekstraksi dan ditutup tanpa perubahan.
- Editor panen: frekuensi 3 → 4 disimpan dan terlihat di profil.
- Edit kebun lalu batal mempertahankan nama semula. Edit lalu simpan memperbarui nama dan mempertahankan riwayat. Keyboard mengubah sebagian teks menjadi “Belakang Aka Tersimpan”; nilai yang diterima parent sama dengan yang terlihat.
- Callback hapus pertama gagal: alert “Kebun belum dihapus” dan profil tetap ada. Percobaan kedua sukses: kembali ke daftar kosong. Hanya fixture dalam memori, tidak menghapus kebun pengguna.

Log stub (disalin ke `/tmp/krops-ownership-qa-events.log`):

```text
submit 1
submit 2
review-save 1 request qa-response
review-save 2 request qa-response
refresh
review-save 3 request qa-response
update name Belakang rumah harvest 4
update name Belakang Aka Tersimpan harvest 4
delete 1
delete 2
```

## Pemeriksaan source dan batas cakupan

Seluruh perpindahan diperiksa byte-identical sebelum ekstraksi. Hasil akhir: 73 file lama tetap identik; hanya GardenProfileScreen berubah untuk mengekstrak komposisi. Aset identik dan konfigurasi proyek/test/AppFlow tidak berubah. Seluruh link lokal dokumentasi diperiksa, lokasi lama tidak menyisakan duplikat, dan delapan jalur pencarian pada rencana dapat ditelusuri.

Reduce Motion/Transparency tidak diuji sebagai matriks toggle sistem; modifier terkait tidak diubah. Back/tutup formulir sebelum submit dan kembali langsung dari halaman status tidak diuji ulang terpisah pada iterasi ini. Layanan nyata, GPS/foto, pendaftaran/pemetaan penuh dan semua posisi scroll tidak diuji ulang. Ini batas bukti pengujian, bukan klaim seluruh interaksi aplikasi tercakup.

Commit lokal memisahkan perpindahan dari ekstraksi. Tidak melakukan push, PR atau merge.
