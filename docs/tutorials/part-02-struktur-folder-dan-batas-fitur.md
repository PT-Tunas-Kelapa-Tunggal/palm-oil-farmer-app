# Part 2 - Menata folder dan memperjelas batas fitur

Ketika hampir semua pekerjaan berada di dalam folder `Gardens`, nama folder itu tidak lagi banyak membantu kita menemukan file. Pencarian lokasi, pengajuan, hasil peninjauan, penyimpanan, dan komponen peta mempunyai alasan perubahan yang berbeda. Kita akan memberi masing-masing tempat yang mudah dikenali.

Pada part ini, kita memindahkan file tanpa mengubah isi Swift. Cara ini membuat perubahan mudah diperiksa: satu file yang berpindah seharusnya tetap mempunyai isi yang sama. Setelah strukturnya jelas, kita akan mulai memisahkan aturan bisnis dan menghubungkan MVVM-C pada part berikutnya.

Perintah di bawah merupakan panduan manual untuk dijalankan satu kelompok demi satu kelompok. Sesudah tutorial dibuat, pengguna mendelegasikan pelaksanaan Part 2 kepada assistant. Pemindahan telah dilakukan pada branch `refactor/02-feature-folders`; hasil aktual tersedia di [catatan Part 2](../refactor/part-02-structure.md). Jangan mengulang perintah pemindahan pada checkout yang sudah selesai.

## Tujuan part ini

Setelah selesai, kamu dapat menemukan file berdasarkan fitur atau tanggung jawabnya, tanpa membuka payung `Features/Gardens` terlebih dahulu. Kamu juga mempunyai checkpoint lokal yang membuktikan bahwa source hanya berpindah lokasi.

Hasil yang ingin kita capai:

- Fitur daftar, registrasi, profil, riwayat, pengajuan, status, rekomendasi, dan panduan area berada sejajar.
- Nilai bisnis, implementasi penyimpanan, komponen UI bersama, dan layar eksperimen mempunyai lokasi tersendiri.
- Nama tipe, nama file Swift, isi file Swift, module, schema, konfigurasi rilis, serta pendekatan penyimpanan dipertahankan.
- Build/test dapat dibandingkan dengan Part 1.
- Checkpoint disimpan dalam commit lokal. Push dan PR tetap ditunda.

## Materi yang akan kita pelajari

1. Menentukan batas folder dan menyiapkan titik kerja.
2. Memindahkan file per kelompok tanggung jawab.
3. Membuktikan perubahan hanya pemindahan dan menyimpan checkpoint.

## Persiapan teknis

Baca [baseline Part 1](../refactor/baseline.md) terlebih dahulu. Commit dokumentasi Part 1 adalah `12820cd`, sedangkan commit kode aplikasi yang diperiksa adalah `43e413f`. Baseline otomatis mencatat 18 test lulus dan 8 warning build. Pemeriksaan UI dan identitas build TestFlight belum lengkap.

Semua perintah dijalankan dari root repository `palm-oil`. Perintah `mv` memindahkan file/folder; kita tidak menggunakan perintah tersebut untuk mengganti nama tipe Swift.

Tutorial ini tidak membutuhkan assistant mengoperasikan UI. Build dan test dapat dijalankan melalui Terminal. Kamu tetap bisa membuka file dengan editor yang biasa kamu gunakan.

---

## Materi 1 - Menentukan batas folder dan menyiapkan titik kerja

Clean Architecture berhubungan dengan arah ketergantungan, sedangkan folder membantu kita melihat pembagian tanggung jawab itu. Kita akan menata tempat file dahulu, lalu memperbaiki ketergantungannya pada part berikutnya.

Untuk presentation, kita memakai pendekatan berdasarkan fitur. Untuk aturan bisnis dan akses data, kita menyediakan `Domain` dan `Data` yang dipecah menurut kebutuhan nyata. Kita belum membuat folder `UseCases`, `ViewModels`, atau `Coordinators` yang kosong.

### Persiapan

Pastikan kamu berada pada repository yang sama dengan Part 1. Source aplikasi belum boleh mempunyai perubahan lain yang akan bercampur dengan pemindahan.

### Langkah-langkah

1. **Periksa branch dan perubahan yang ada.**

   Jalankan:

   ```bash
   git status --short --branch
   ```

   Lalu periksa perubahan aplikasi yang sudah dilacak:

   ```bash
   git diff --stat -- PalmOilFarmer PalmOilFarmerTests PalmOilFarmer.xcodeproj
   ```

   Periksa pula staging:

   ```bash
   git diff --cached --stat
   ```

   Pada titik awal yang diharapkan, tidak ada perubahan aplikasi atau perubahan staged. Dokumen lama `docs/architecture-assessment.md` mungkin masih untracked; file itu bukan bagian dari pemindahan ini.

   Jika ada pekerjaan source lain, pisahkan checkpoint pekerjaan itu sebelum melanjutkan. Jangan menghapus perubahan untuk mengikuti tutorial.

2. **Buat branch untuk pekerjaan pemindahan.**

   Dari branch yang sudah memuat checkpoint Part 1 dan tutorial ini, jalankan:

   ```bash
   git switch -c refactor/02-feature-folders
   ```

   Catat posisi awal branch:

   ```bash
   git log -1 --oneline
   ```

   Branch ini boleh dibuat dari checkpoint lokal sebelumnya karena kita belum push atau membuat PR. Jika namanya sudah ada, periksa dahulu apakah kamu sedang melanjutkan pekerjaan yang sama.

3. **Kenali pembagian target.**

   Gunakan tabel berikut sebagai aturan penempatan:

   | Lokasi | Isi yang ditempatkan |
   | --- | --- |
   | `App` | Entry point, konfigurasi, dan root composition yang sekarang ada |
   | `Domain/Gardens` | Nilai kebun, lokasi, batas, draf, dan riwayat tersimpan |
   | `Domain/Reviews` | Nilai pengajuan/status dan kontrak repository yang sudah ada |
   | `Data/Gardens` | SwiftData model dan GardenStore lama selama masa transisi |
   | `Data/Reviews` | CloudKit repository, DTO, dan adapter record |
   | `Data/Location` | Akses CoreLocation dan pencarian MapKit |
   | `Features/GardenList` | Daftar, kartu, filter, dan ilustrasi khusus daftar |
   | `Features/GardenRegistration` | Guide, lokasi/foto, editor detail registrasi, dan mapping |
   | `Features/GardenProfile` | Profil dan ringkasan kebun |
   | `Features/GardenHistory` | Editor dan tampilan riwayat pupuk/panen |
   | `Features/ReviewRequest` | Informasi program serta form pengajuan |
   | `Features/ReviewStatus` | Layar status milik implementasi tim |
   | `Features/Recommendations` | Hasil, chart, model tampilan, demo, dan mapper hasil |
   | `Features/AreaGuidance` | Peta/pemilihan area, navigasi, dan geometri zona yang dipakai ulang |
   | `Features/MapDownload` | Tampilan download yang sudah ada; layanan download baru tidak dibuat |
   | `SharedUI/Maps` | Tampilan peta yang dipakai beberapa fitur |
   | `SharedUI/Gardens` | Komponen/presentation value bersama yang memahami kebun |
   | `Experiments/FindingWaypoint` | Entry point dan layar eksperimen yang dipertahankan |
   | `DesignSystem` | Token, style, dan komponen visual generik yang sudah ada |
   | `PreviewSupport` | Fixture dan reference screen yang sudah ada |

   Di dalam fitur yang masih kecil, file tetap boleh sejajar. Kita baru menambahkan subfolder ketika kelompoknya memang ada, seperti `Mapping`, `Geometry`, dan `Mappers`.

4. **Bedakan batas tujuan dengan kondisi transisi.**

   Ada beberapa file yang sekarang menggabungkan lebih dari satu peran. Pada Part 2 kita memindahkan file tersebut secara utuh:

   | File | Yang masih bercampur | Perlakuan pada part ini |
   | --- | --- | --- |
   | `GardenStore.swift` | State UI, storage, mapping, dan submit | Taruh di `Data/Gardens`; pemisahan tanggung jawab menyusul |
   | `GardenBoundary.swift` | Geometri dan konversi CoreLocation | Taruh di `Domain/Gardens`; framework dependency belum dihapus |
   | `PlantationReviewModels.swift` | Nilai review dan pembentukan timeline UI | Taruh di `Domain/Reviews`; tidak mengubah timeline tim |
   | `GardenListFilter.swift` | Filter, stage/list item, dan pengaturan developer | Pindahkan utuh ke fitur daftar |
   | `GardenDetailsView.swift` | Editor registrasi yang juga dipanggil profil | Tetap bersama registrasi; pemakaian ulang dicatat untuk part profil |
   | `AreaViews.swift` | Peta, picker, navigasi, dan extension geometri | Pindahkan utuh ke AreaGuidance |
   | `WaypointZoneThumbnail.swift` | Thumbnail, palette, dan preview data eksperimen | Tetap utuh di eksperimen |

   Folder bernama Domain belum berarti semua dependency di dalamnya sudah bersih. Kita tidak akan menyebut Part 2 sebagai penyelesaian Clean Architecture. Kita juga tidak memecah file tim agar folder terlihat lebih rapi.

5. **Kenali file yang tetap di tempatnya.**

   `App`, `DesignSystem`, `PreviewSupport`, assets, entitlements, project/scheme, konfigurasi, dan test target tetap di lokasi sekarang. Kita tidak mengganti nama app/module, mengubah deployment target, atau membuat Swift Package baru.

   File hasil dan status yang dipindahkan tetap mempunyai isi identik. Data demo yang ada tidak dihapus atau diganti pada part ini.

6. **Periksa cara project menemukan source.**

   Buka `PalmOilFarmer.xcodeproj/project.pbxproj` sebagai bacaan, lalu cari `PBXFileSystemSynchronizedRootGroup`. Pada checkout ini, source app disinkronkan dari folder `PalmOilFarmer` dan test dari `PalmOilFarmerTests`.

   Seluruh tujuan pemindahan kita masih berada di bawah root source app yang sama. Karena itu, tidak diperlukan pemindahan file ke target/module lain atau penambahan file reference satu per satu.

   Jangan membuat group/reference duplikat untuk file yang sama. Jika build kemudian tidak menemukan suatu tipe, periksa lokasi dan duplikasi file sebelum mengedit isi project.

### Hasil yang harus terlihat

Kamu mempunyai branch kerja dan dapat menjelaskan mengapa sebuah file ditempatkan pada fitur, Domain, Data, SharedUI, atau eksperimen. Kamu juga mengetahui dependency yang sengaja belum disentuh.

### Cara kerjanya

Kita memakai fitur untuk menjawab “bagian aplikasi mana yang sedang diubah?” dan layer untuk menjawab “siapa yang memiliki aturan atau akses ini?”. Sebuah komponen peta yang dipakai beberapa fitur cocok berada di SharedUI. DTO CloudKit tetap berada di Data, meskipun dipakai untuk menampilkan kebun di Home.

Semua tipe masih berada dalam satu module. Memindahkan file belum mencegah sebuah View memanggil repository konkret. Pemisahan tersebut akan kita kerjakan melalui kontrak dan dependency injection pada part selanjutnya.

> **Tips:** Jangan membuat folder `Common` atau `Utils` untuk menampung file yang membingungkan. Tanyakan lebih dahulu siapa pemiliknya dan siapa yang memakai file tersebut.

---

## Materi 2 - Memindahkan file per kelompok tanggung jawab

Sekarang kita akan menerapkan peta tadi pada file yang sudah ada. Jalankan satu blok, lalu periksa hasilnya sebelum pindah ke blok berikutnya. Kita tidak menyalin file lalu membiarkan versi lama tetap ikut dikompilasi.

### Persiapan

Pastikan branch aktif adalah `refactor/02-feature-folders` dan kamu menjalankan perintah dari root repository. Jika ada editor yang menawarkan penyimpanan perubahan source yang tidak kamu buat, periksa perbedaannya dahulu.

### Langkah-langkah

1. **Buat folder tujuan yang langsung dipakai.**

   Jalankan:

   ```bash
   mkdir -p PalmOilFarmer/Domain/Gardens
   mkdir -p PalmOilFarmer/Data/Gardens
   mkdir -p PalmOilFarmer/Data/Location
   mkdir -p PalmOilFarmer/SharedUI/Maps
   mkdir -p PalmOilFarmer/SharedUI/Gardens
   mkdir -p PalmOilFarmer/Experiments
   mkdir -p PalmOilFarmer/Features/ReviewRequest
   mkdir -p PalmOilFarmer/Features/ReviewStatus
   mkdir -p PalmOilFarmer/Features/AreaGuidance/Geometry
   mkdir -p PalmOilFarmer/Features/MapDownload
   ```

   Folder fitur lain akan terbentuk dengan memindahkan folder asalnya. Secara khusus, jangan membuat `Domain/Reviews` atau `Data/Reviews` dahulu: nanti kedua folder itu menjadi hasil pemindahan folder utuh.

2. **Angkat fitur presentation menjadi fitur sejajar.**

   Jalankan:

   ```bash
   mv PalmOilFarmer/Features/Gardens/List PalmOilFarmer/Features/GardenList
   mv PalmOilFarmer/Features/Gardens/Registration PalmOilFarmer/Features/GardenRegistration
   mv PalmOilFarmer/Features/Gardens/Profile PalmOilFarmer/Features/GardenProfile
   mv PalmOilFarmer/Features/Gardens/History PalmOilFarmer/Features/GardenHistory
   mv PalmOilFarmer/Features/Gardens/Recommendations PalmOilFarmer/Features/Recommendations
   mv PalmOilFarmer/Features/Gardens/Mapping PalmOilFarmer/Features/GardenRegistration/Mapping
   ```

   Buka salah satu file pada lokasi baru, misalnya `Features/GardenProfile/GardenProfileView.swift`. Nama struct dan seluruh isinya tetap sama.

   Mapping menjadi bagian registrasi karena flow produksinya sekarang menyelesaikan pendaftaran kebun. Kita tidak membuat flow mapping baru.

3. **Pisahkan nilai kebun dan review dari folder layar.**

   Jalankan:

   ```bash
   mv PalmOilFarmer/Features/Gardens/Models/Garden.swift PalmOilFarmer/Domain/Gardens/Garden.swift
   mv PalmOilFarmer/Features/Gardens/Models/GardenBoundary.swift PalmOilFarmer/Domain/Gardens/GardenBoundary.swift
   mv PalmOilFarmer/Features/Gardens/Models/GardenDraft.swift PalmOilFarmer/Domain/Gardens/GardenDraft.swift
   mv PalmOilFarmer/Features/Gardens/Models/GardenLocation.swift PalmOilFarmer/Domain/Gardens/GardenLocation.swift
   mv PalmOilFarmer/Features/Gardens/Models/GardenReview.swift PalmOilFarmer/Domain/Gardens/GardenReview.swift
   mv PalmOilFarmer/Features/Gardens/Review/Domain PalmOilFarmer/Domain/Reviews
   mv PalmOilFarmer/Features/Gardens/Review/ReviewContactDetails.swift PalmOilFarmer/Domain/Reviews/ReviewContactDetails.swift
   ```

   `Garden.swift` memuat lebih dari satu tipe. Kita tetap memindahkannya sebagai satu file. Hal yang sama berlaku untuk contact/error review yang sekarang berada dalam satu file.

4. **Pindahkan implementasi data dan akses lokasi.**

   Jalankan:

   ```bash
   mv PalmOilFarmer/Features/Gardens/Data/GardenStore.swift PalmOilFarmer/Data/Gardens/GardenStore.swift
   mv PalmOilFarmer/Features/Gardens/Data/DraftPlantationRequest.swift PalmOilFarmer/Data/Gardens/DraftPlantationRequest.swift
   mv PalmOilFarmer/Features/Gardens/Data/CurrentLocationProvider.swift PalmOilFarmer/Data/Location/CurrentLocationProvider.swift
   mv PalmOilFarmer/Features/Gardens/Data/LocationSearchService.swift PalmOilFarmer/Data/Location/LocationSearchService.swift
   mv PalmOilFarmer/Features/Gardens/Review/Data PalmOilFarmer/Data/Reviews
   ```

   Setelah pemindahan, `Data/Reviews` masih memuat adapter report yang menghasilkan model UI. Pisahkan lokasinya sekarang, dengan isi file tetap:

   ```bash
   mkdir -p PalmOilFarmer/Features/Recommendations/Mappers
   mv PalmOilFarmer/Data/Reviews/ReviewRecommendationAdapter.swift PalmOilFarmer/Features/Recommendations/Mappers/ReviewRecommendationAdapter.swift
   ```

   Adapter CKRecord/DTO tetap di Data. Adapter yang membentuk `FertilizerRecommendationReport` menjadi bagian presentation rekomendasi. Implementasi keduanya belum berubah.

5. **Pisahkan pengajuan dari status dan panduan area.**

   Jalankan:

   ```bash
   mv PalmOilFarmer/Features/Gardens/Review/ReviewRequestView.swift PalmOilFarmer/Features/ReviewRequest/ReviewRequestView.swift
   mv PalmOilFarmer/Features/Gardens/Review/ReviewContactFormView.swift PalmOilFarmer/Features/ReviewRequest/ReviewContactFormView.swift
   mv PalmOilFarmer/Features/Gardens/Review/ReviewStatusView.swift PalmOilFarmer/Features/ReviewStatus/ReviewStatusView.swift
   mv PalmOilFarmer/Features/Recommendations/AreaViews.swift PalmOilFarmer/Features/AreaGuidance/AreaViews.swift
   mv PalmOilFarmer/Features/GardenRegistration/Mapping/MapDownloadView.swift PalmOilFarmer/Features/MapDownload/MapDownloadView.swift
   ```

   Pemisahan `ReviewRequest` dan `ReviewStatus` membantu menunjukkan batas pekerjaanmu dan implementasi tim. `AreaViews.swift` tetap satu file, termasuk extension WaypointZone yang ada di dalamnya.

   Folder MapDownload menampung tampilan lama yang sudah direferensikan kode. Pemindahan ini tidak mengaktifkan download offline atau background service.

6. **Letakkan komponen bersama dan komponen daftar pada pemiliknya.**

   Jalankan:

   ```bash
   mv PalmOilFarmer/Features/Gardens/Components/GardenMapView.swift PalmOilFarmer/SharedUI/Maps/GardenMapView.swift
   mv PalmOilFarmer/Features/Gardens/Components/MapHeroView.swift PalmOilFarmer/SharedUI/Maps/MapHeroView.swift
   mv PalmOilFarmer/Features/GardenRegistration/LocationMapPreview.swift PalmOilFarmer/SharedUI/Maps/LocationMapPreview.swift
   mv PalmOilFarmer/Features/Gardens/Components/GardenAreaIcon.swift PalmOilFarmer/SharedUI/Gardens/GardenAreaIcon.swift
   mv PalmOilFarmer/Features/Gardens/Components/LiveGardenReader.swift PalmOilFarmer/SharedUI/Gardens/LiveGardenReader.swift
   mv PalmOilFarmer/Features/Gardens/Models/GardenDisplayMetrics.swift PalmOilFarmer/SharedUI/Gardens/GardenDisplayMetrics.swift
   mv PalmOilFarmer/Features/Gardens/Components/SeedlingIcon.swift PalmOilFarmer/Features/GardenList/SeedlingIcon.swift
   mv PalmOilFarmer/Features/Gardens/Models/GardenListFilter.swift PalmOilFarmer/Features/GardenList/GardenListFilter.swift
   ```

   DisplayMetrics adalah nilai tampilan yang sudah diformat, sehingga tidak ditempatkan bersama nilai bisnis murni. LiveGardenReader masih membaca store konkret; pemindahan ini belum mengubah dependency tersebut.

   DesignSystem dipertahankan untuk komponen generik. Komponen yang mengetahui Garden tidak dimasukkan ke sana hanya karena dipakai lebih dari satu layar.

7. **Pisahkan entry point eksperimen dari kemampuan yang dipakai produksi.**

   Jalankan:

   ```bash
   mv PalmOilFarmer/Features/FindingWaypoint PalmOilFarmer/Experiments/FindingWaypoint
   mv PalmOilFarmer/Experiments/FindingWaypoint/WaypointLocationSession.swift PalmOilFarmer/Data/Location/WaypointLocationSession.swift
   mv PalmOilFarmer/Experiments/FindingWaypoint/WaypointZoning.swift PalmOilFarmer/Features/AreaGuidance/Geometry/WaypointZoning.swift
   ```

   Folder eksperimen kini tetap menyimpan `FindingWaypointView.swift`, `WaypointMapView.swift`, `WaypointZoneThumbnail.swift`, serta README-nya. Session lokasi dan pembagian zona mempunyai pemakai pada flow hasil sehingga lokasinya tidak lagi berada di bawah entry point eksperimen.

   Jangan mengubah root app menjadi FindingWaypointView atau menghapus preview eksperimen. Semua pemindahan masih berada dalam target app yang sama.

8. **Hapus folder asal yang sudah kosong.**

   Jalankan:

   ```bash
   rmdir PalmOilFarmer/Features/Gardens/Data
   rmdir PalmOilFarmer/Features/Gardens/Models
   rmdir PalmOilFarmer/Features/Gardens/Components
   rmdir PalmOilFarmer/Features/Gardens/Review
   rmdir PalmOilFarmer/Features/Gardens
   ```

   `rmdir` hanya berhasil untuk folder kosong. Jika ada pesan bahwa folder belum kosong, lihat isinya dan cocokkan dengan langkah sebelumnya. Jangan menggantinya dengan penghapusan paksa.

9. **Periksa struktur yang terbentuk.**

   Jalankan:

   ```bash
   rg --files PalmOilFarmer -g '*.swift'
   ```

   Semua source dari folder Gardens lama sudah mempunyai lokasi baru. App, DesignSystem, PreviewSupport, assets, dan test tetap berada di lokasi semula.

   Jalankan juga:

   ```bash
   git status --short
   ```

   Pada tahap ini Git dapat menampilkan file lama sebagai deleted dan folder baru sebagai untracked. Itu belum berarti isi file hilang. Setelah file lama dan baru staged bersama, Git bisa membandingkan kesamaannya sebagai rename.

### Hasil yang harus terlihat

Folder `Features/Gardens` tidak lagi ada. Semua file lama masih tersedia pada tujuan masing-masing, termasuk implementasi status/hasil dan file eksperimen yang tetap utuh.

### Cara kerjanya

Referensi tipe Swift pada project ini menggunakan nama tipe dalam module, bukan path folder. Selama kita mempertahankan module, nama tipe, dan isi source, pemanggilan GardenProfileView atau GardenStore tidak perlu diganti hanya karena file berpindah.

Model SwiftData juga tetap berada dalam app target yang sama, dengan nama dan properti yang sama. Kita tidak mengganti schema atau lokasi store. Build dan test tetap diperlukan sebagai pemeriksaan integrasi; kesamaan folder tidak membuktikan kompatibilitas upgrade TestFlight.

> **Tips:** Jalankan setiap blok sekali dan catat posisi terakhir yang selesai. Jika melanjutkan sesi yang terhenti, periksa source dan tujuan sebelum mengulang `mv`. Memindahkan folder ke tujuan yang sudah ada bisa menghasilkan susunan bersarang yang tidak kamu maksudkan.

---

## Materi 3 - Membuktikan pemindahan dan menyimpan checkpoint lokal

Sekarang kita akan memeriksa dua hal: apakah setiap file masih sama, dan apakah project tetap dapat dibangun. Dokumentasi diperbarui setelah checkpoint pemindahan supaya perbedaan source dan perbedaan penjelasan tetap mudah dibaca.

### Persiapan

Semua langkah pemindahan sudah selesai. Belum ada edit isi Swift, perubahan project settings, atau perubahan test. Jika kamu sempat mengedit source, pisahkan perubahan itu dahulu.

### Langkah-langkah

1. **Stage pemindahan source app.**

   Karena source app sudah diperiksa bersih sebelum memulai, kita dapat men-stage pemindahan dalam root app ini:

   ```bash
   git add -A -- PalmOilFarmer
   ```

   Periksa semua file staged:

   ```bash
   git diff --cached --name-status -M
   ```

   Untuk peta pada tutorial ini, hasilnya seharusnya **60 rename dengan kesamaan 100%**: 59 file Swift dan satu README eksperimen. Barisnya memakai status `R100`, berisi path lama dan path baru. Angka ini berlaku untuk checkout sumber tutorial; jika ada file tambahan pada branch-mu, cocokkan dahulu asalnya.

   Jika muncul `M`, `A`, `D`, atau tingkat kesamaan selain 100%, periksa penyebabnya. Pada checkpoint pemindahan, kita belum menerima perubahan isi file.

2. **Periksa isi dan konfigurasi yang harus tetap.**

   Jalankan:

   ```bash
   git diff --cached --numstat -M
   ```

   Rename murni menunjukkan nol baris ditambah dan nol baris dihapus. Periksa juga:

   ```bash
   git diff --cached --check
   git diff --cached --name-only -- PalmOilFarmer.xcodeproj PalmOilFarmerTests Configurations Developer.xcconfig.example
   ```

   Perintah terakhir seharusnya tidak menampilkan perubahan. `Developer.xcconfig` tetap lokal dan tidak dimasukkan ke staging. Jika kamu menemukan perubahan lain yang tidak dimaksudkan, keluarkan dari staging melalui editor Git sambil mempertahankan file kerjanya.

3. **Jalankan test Debug dari Terminal.**

   Gunakan Xcode yang dipakai baseline:

   ```bash
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
     -project PalmOilFarmer.xcodeproj \
     -scheme PalmOilFarmer \
     -destination 'platform=iOS Simulator,id=BD8D68EA-DE49-4AF3-A283-69D78F6984C3' \
     -derivedDataPath /private/tmp/palm-oil-part2-debug \
     -resultBundlePath /private/tmp/palm-oil-part2-debug-tests.xcresult \
     -parallel-testing-enabled NO
   ```

   Destination tersebut tersedia saat baseline diperiksa. Jika perangkat itu tidak tersedia lagi, lihat daftar simulator lewat `xcrun simctl list devices available` dengan DEVELOPER_DIR yang sama dan pilih simulator iOS 27 yang tersedia.

   Xcode memerlukan nama result bundle yang belum ada. Saat mengulang, gunakan nama baru seperti `palm-oil-part2-debug-tests-02.xcresult`, bukan menghapus bukti sebelumnya.

   Hasil yang diharapkan tetap 18 test lulus. Catat hasil aktual dan warning. Delapan warning baseline bukan alasan untuk memperbaiki source dalam checkpoint rename ini.

4. **Baca ringkasan hasil test.**

   Setelah perintah selesai, jalankan:

   ```bash
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary \
     --path /private/tmp/palm-oil-part2-debug-tests.xcresult
   ```

   Sesuaikan path jika kamu memakai nama result bundle lain. Pastikan angka lulus/gagal berasal dari hasil tersebut. Jika ada kegagalan, cocokkan dengan baseline dan periksa apakah ada file yang belum ikut dipindahkan atau terduplikasi.

5. **Periksa kompilasi Release tanpa menjalankan app Production.**

   Jalankan:

   ```bash
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
     -project PalmOilFarmer.xcodeproj \
     -scheme PalmOilFarmer \
     -configuration Release \
     -destination 'generic/platform=iOS Simulator' \
     -derivedDataPath /private/tmp/palm-oil-part2-release
   ```

   Build ini memeriksa kompilasi Release untuk simulator, termasuk perbedaan kode `#if DEBUG`. Ini bukan Archive/TestFlight, tidak menjalankan pengajuan Production, dan belum membuktikan upgrade data pengguna.

6. **Buat commit yang hanya berisi pemindahan.**

   Setelah pemeriksaan sesuai, lihat sekali lagi daftar staged:

   ```bash
   git diff --cached --summary -M
   ```

   Lalu simpan checkpoint:

   ```bash
   git commit -m "refactor: organize files by feature and responsibility"
   ```

   Periksa commit dengan:

   ```bash
   git show --stat --oneline -M HEAD
   ```

   Source aplikasi pada commit ini seharusnya hanya berpindah. Isi Swift dan implementasi tim tetap sama.

7. **Perbarui petunjuk lokasi pada dokumentasi.**

   Sesudah commit pemindahan, edit dokumentasi sebagai pekerjaan terpisah:

   - Pada README root, perbarui tabel “Where code belongs” sesuai lokasi baru. Sebutkan bahwa folder merupakan struktur transisi menuju Clean Architecture; GardenStore dan beberapa dependency belum dipisahkan.
   - Pada `PalmOilFarmer/Experiments/FindingWaypoint/README.md`, jelaskan bahwa session lokasi berada di `Data/Location` dan zoning di `Features/AreaGuidance/Geometry`. Entry point eksperimen dan kemampuan yang sudah ada tetap sama.
   - Perbarui link file pada tutorial Part 1 agar menuju lokasi baru. Penjelasan snapshot baseline yang menyebut path lama tetap boleh dipertahankan sebagai catatan keadaan awal, dengan keterangan yang jelas.

   Untuk membantu menemukan referensi lama, jalankan:

   ```bash
   rg -n 'Features/Gardens|Features/FindingWaypoint' README.md docs PalmOilFarmer/Experiments
   ```

   Jangan melakukan replace global terhadap seluruh source atau semua catatan historis. Baseline dan langkah pemindahan tutorial ini memang mencatat path lama. Yang perlu diperbaiki adalah petunjuk lokasi aktif dan link yang akan rusak.

8. **Simpan perubahan dokumentasi sebagai commit kedua.**

   Jika hanya tiga file di atas yang diubah, stage secara spesifik:

   ```bash
   git add -- README.md PalmOilFarmer/Experiments/FindingWaypoint/README.md docs/tutorials/part-01-baseline-dan-persiapan-pr.md
   git diff --cached --stat
   git diff --cached --check
   ```

   Pastikan staged diff hanya berisi dokumentasi, lalu commit:

   ```bash
   git commit -m "docs: describe feature ownership and updated file locations"
   ```

   Jika kamu juga mencatat hasil pemeriksaan dalam dokumen baru, tambahkan hanya path dokumen tersebut secara eksplisit setelah memeriksa isinya. Tidak perlu mengulangi seluruh test hanya karena penjelasan Markdown berubah.

9. **Periksa keadaan akhir branch.**

   Jalankan:

   ```bash
   git log -3 --oneline
   git status --short --branch
   ```

   Kamu mempunyai checkpoint pemindahan dan dokumentasi lokal yang terpisah. Tidak ada perintah push atau pembuatan PR pada part ini. Ketika nanti PR diperlukan, kita dapat menentukan base dan mengirim rangkaian commit yang sudah bisa diperiksa.

### Hasil yang harus terlihat

Semua pemindahan source terdeteksi sebagai rename identik, test Debug telah diperiksa, kompilasi Release telah diperiksa, dan catatan lokasi aktif sudah diperbarui. Hasil pemeriksaanmu tercatat sebagai hasil baru, bukan disalin dari Part 1.

### Cara kerjanya

Git menyimpulkan rename dari kesamaan isi. Status `R100` membuat reviewer dapat melihat perpindahan tanpa harus memeriksa ulang implementasi yang sama. Memisahkan commit dokumentasi juga membantu karena perubahan penjelasan memang mengubah isi file, sedangkan checkpoint source mempertahankan isinya.

Folder Domain/Data/Features membantu membaca struktur, tetapi belum menegakkan dependency melalui compiler. Kita masih mempunyai satu module dan sejumlah ketergantungan lama. Pada part berikutnya, kontrak dan pemilik tanggung jawab akan mulai dipisahkan secara bertahap, dengan scope status/hasil tetap dihormati.

> **Tips:** Jika build gagal setelah move-only, periksa source root, target yang sama, file duplikat, dan langkah yang terlewat. Mengubah kode untuk mengatasi salah penempatan akan membuat penyebab masalah lebih sulit dibaca.

---

## Checkpoint akhir Part 2

- [ ] Branch kerja memakai nama `refactor/02-feature-folders`.
- [ ] `Features/Gardens` lama sudah kosong dan tidak dipakai sebagai payung fitur.
- [ ] Pengajuan dan status berada pada fitur yang berbeda.
- [ ] Session lokasi dan geometri yang dipakai produksi terpisah dari entry point eksperimen.
- [ ] File yang memuat beberapa tanggung jawab dipindahkan utuh dan dicatat untuk tahap berikutnya.
- [ ] Pada checkpoint source terdapat 60 rename `R100` sesuai checkout acuan.
- [ ] Isi Swift, test, module, model persistence, konfigurasi, dan kontrak remote tetap sama.
- [ ] Hasil test Debug dibandingkan dengan baseline 18 test.
- [ ] Kompilasi Release simulator diperiksa tanpa diklaim sebagai Archive atau upgrade TestFlight.
- [ ] Dokumentasi lokasi aktif diperbarui dalam commit terpisah.
- [ ] Tidak ada push atau PR.

Belum semua pemeriksaan UI Part 1 selesai. Pada part ini kita tidak menganggap test otomatis sebagai pengganti pemeriksaan UI tersebut. Sebelum mengubah perilaku pada part selanjutnya, skenario yang masih kosong tetap menjadi pekerjaan verifikasi yang terlihat.

Untuk review berikutnya, siapkan output `git show --summary -M` dari commit pemindahan, ringkasan hasil test, dan hasil build Release. Kamu tidak perlu mengirim isi konfigurasi lokal atau data pribadi.

## Berikutnya: Part 3

Kita akan mengenali nilai bisnis, nilai khusus presentation, validasi, dan kontrak repository yang dibutuhkan scope sampai pengajuan. Setelah itu, Data layer serta dependency injection manual dapat diperbaiki sebelum MVVM-C diterapkan pada fitur pilot.
