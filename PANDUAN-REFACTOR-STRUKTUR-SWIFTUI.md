# Refactor PalmOilFarmer: struktur, peta halaman, dan Git

## 1. Hasil yang diinginkan pengguna

Rapikan proyek SwiftUI agar pengguna yang sedang belajar bisa menjawab:

1. File mana yang menjadi satu halaman aplikasi?
2. Apa saja komponen yang membentuk halaman itu dan di mana filenya?
3. Komponen mana yang khusus halaman, bersama dalam fitur, atau bagian design system?
4. Dari mana data halaman berasal dan siapa yang mengatur perpindahan halamannya?
5. Perubahan task ini ada di branch dan commit mana?

Gunakan pola screenshot pengguna: **App, Core, Features, Resources**, dengan kode per fitur dikelompokkan menurut tanggung jawab. Folder yang terlihat rapi saja belum memenuhi tujuan; hubungan halaman dan komponen harus bisa ditelusuri melalui nama, lokasi, dan dokumentasi.

Dokumen ini adalah panduan implementasi untuk coding agent, bukan bukti bahwa refactor sudah dilakukan. Proyek yang diperiksa berada di `/Users/hatamisg/Learning/krops_coded`, dengan `PalmOilFarmer.xcodeproj`, sumber `PalmOilFarmer`, dan pengujian `PalmOilFarmerTests`. Path ini membantu menemukan proyek; jangan hardcode path mesin tersebut dalam kode atau dokumentasi repo.

Saat pengguna meminta menjalankan seluruh panduan, inventarisasi seluruh aplikasi dan terapkan bertahap mulai dari Gardens/List, lalu area Gardens lain dan fitur lainnya. Jika pengguna membatasi task, misalnya hanya Gardens/List, patuhi batas itu; jangan memindahkan seluruh Core atau resource dalam task yang sempit. Saat pengguna hanya meminta audit atau revisi panduan, jangan menjalankan refactor aplikasi atau operasi Git.

## 2. Fakta awal yang harus diverifikasi ulang

Catatan berikut berasal dari pembacaan source pada 27 Oktober 2026. Baca ulang kode dan instruksi repo sebelum bekerja; kondisi ini bisa berubah.

| Temuan | Implikasi untuk refactor |
| --- | --- |
| Entry point saat ini `PalmOilFarmerApp → ContentView → GardenListView`. | Telusuri dari entry point aktual, bukan hanya screenshot atau README lama. |
| `ContentView` memiliki `GardenStore` dan `MappingDraftStore`, serta navigasi profil, pendaftaran, dan pemetaan. | Ini penghubung aplikasi dan alur; jangan menganggap semua isi `ContentView` adalah halaman daftar. |
| `GardenListView` menyusun empty state, draf pemetaan, kartu kebun, kartu unduhan opsional, dan tombol pendaftaran. | Peta halaman harus mencakup semua cabang, bukan hanya `GardenCard`. |
| `LocationMapPreview` berada di Registration tetapi juga dipakai List dan Mapping. | Kandidat komponen bersama dalam Gardens, bukan komponen khusus Registration. |
| `MapDownloadView.swift` memuat model/state, progress view, halaman, dan `MapDownloadCard`; card itu dipakai List. | Klasifikasikan per tipe dan pemakaiannya; memindahkan file utuh belum tentu memperjelas batas. |
| `GardenProfileView` berisi komposisi tampilan, varian layout, beberapa sheet, dan tujuan navigasi. `GardenDetailsView` digunakan untuk pendaftaran dan edit dari profil. | Dokumentasikan mode, penggunaan bersama, dan kepemilikan state sebelum memecah file. |
| `RegistrationIntroView` memilih langkah melalui state; `GardenBoundaryView` dapat mengganti isi dengan konfirmasi lokasi foto. | Satu file atau satu presentasi dapat berisi beberapa tahap. Bedakan flow, screen, dan state. |
| `FindingBlockView` ditanam dalam `FertilizerRecommendationView`; ia juga membuka picker dan peta. | Nama feature atau akhiran `View` tidak otomatis berarti halaman penuh. |
| `FindingWaypointView` merupakan entry point eksperimen terpisah. | Tandai sebagai eksperimen; jangan mengaktifkannya sebagai root app demi merapikan struktur. |
| Preview reference memakai jalur dan varian yang tidak selalu tersedia dari entry point utama, termasuk layar unduhan. | Bedakan aktif, eksperimen, dan reference/preview. Jangan menghapus hanya karena tidak ditemukan dalam navigasi utama. |
| `EmptyStateView` generik, tetapi preview-nya memakai `SeedlingIcon` dari Gardens. `GardenPickerField` bernama spesifik tetapi API-nya generik. | Periksa dependensi runtime dan preview secara terpisah; jangan klasifikasikan berdasarkan nama saja. |
| Proyek memakai `PBXFileSystemSynchronizedRootGroup`, satu app target dan satu test target. Info.plist dihasilkan dari build settings. | Jangan menambahkan referensi file manual atau Info.plist baru tanpa kebutuhan yang ditemukan. |
| README menetapkan state UI tetap di view, penyimpanan melalui store, tanpa ViewModel wajib. | Pertahankan arsitektur perilaku ini; screenshot bukan alasan untuk migrasi MVVM. |

**Kondisi Git saat audit:** branch `main` memiliki 26 file tracked yang berubah dan sejumlah file/direktori untracked, termasuk FindingBlock serta model, layanan, dan test baru. Perubahan entry point ke `ContentView` juga belum di-commit. Snapshot `HEAD` tidak sama dengan aplikasi yang sedang dibaca. Kondisi ini harus diselesaikan sebagai baseline sebelum menghasilkan commit refactor yang bersih; lihat bagian Git.

## 3. Struktur tujuan dan aturan penempatan

Berikut konvensi tujuan untuk refactor penuh. Isinya diisi berdasarkan source aktual; jangan membuat folder kosong atau menduplikasi lokasi lama dan baru.

```text
PalmOilFarmer/
├── App/                          # Entry point, pemilik store, alur tingkat app
├── Core/
│   └── DesignSystem/
│       ├── Tokens/
│       ├── Components/           # UI generik tanpa model/layanan fitur
│       ├── Styles/
│       └── Catalog/              # Preview komponen generik
├── Features/
│   ├── Gardens/
│   │   ├── Models/
│   │   ├── Data/                 # Store, persistence, akses framework/layanan
│   │   └── Views/
│   │       ├── List/
│   │       │   ├── GardenListScreen.swift
│   │       │   └── Components/
│   │       │       └── GardenCard.swift
│   │       ├── Profile/
│   │       ├── Registration/
│   │       ├── Mapping/
│   │       ├── History/
│   │       ├── Review/
│   │       ├── Recommendations/
│   │       └── Components/       # UI yang digunakan lintas area Gardens
│   ├── FindingBlock/
│   └── FindingWaypoint/
├── Resources/
│   └── Assets.xcassets/
└── PreviewSupport/               # Fixtures dan komposisi reference/eksperimen

PalmOilFarmerTests/               # Tetap menjadi target test tersendiri
Docs/
├── Architecture.md
└── ScreenMap.md
```

- `Core/DesignSystem` menggantikan lokasi top-level `DesignSystem` dalam refactor penuh. Jangan membuat `Core/Common/Views` sebagai tempat kedua untuk komponen generik yang sama.
- Tambahkan `Core/Services`, `Core/Extensions`, atau `Core/Models` hanya jika ada tanggung jawab bersama yang nyata dan sudah ditelusuri. Hindari `Utils` sebagai tempat serba guna. Jangan memindahkan semua model domain ke Core hanya karena dipakai dua fitur; catat penggunaan lintas fitur dan pilih perubahan terkecil yang memperjelas kepemilikannya.
- Di fitur, gunakan `Models` dan `Data` untuk kebutuhan non-UI, serta `Views` untuk UI. Untuk fitur kecil, isi `Views` boleh datar. Buat subarea/Components ketika membantu pencarian, bukan untuk mengejar keseragaman jumlah folder.
- Pindahkan asset catalog ke Resources sebagai satu kesatuan pada task yang mencakup resource. Pertahankan nama aset, konfigurasi target, dan lookup-nya. PreviewSupport berisi kode Swift pendukung, sehingga tetap terpisah dari resource statis.
- Jangan menambahkan wrapper `iOS`, Controllers, Repository, Fonts, atau ViewModels tanpa kebutuhan. Bila sudah ada pola lokal yang relevan, jelaskan pemetaannya.
- Ikuti struktur tujuan ini secara konsisten pada area yang dikerjakan. Bila fakta kode memerlukan penyimpangan, tulis alasan spesifik dalam Architecture.md; jangan memakai alasan umum “sesuaikan kebutuhan” untuk membiarkan batas tetap kabur.

### Penamaan dan batas UI

| Peran | Konvensi pada area yang direfactor | Bukti untuk menentukan peran |
| --- | --- | --- |
| Halaman | `…Screen.swift`, tipe sesuai nama file | Mengisi konten utama suatu tujuan navigasi, tab, atau modal; langkah flow juga bisa menjadi screen. |
| Pengatur alur | `…Flow.swift` jika tanggung jawab utamanya memilih/menghubungkan langkah | Memilih screen berdasarkan state atau menghubungkan langkah. Tidak wajib membuat coordinator/router baru. |
| Bagian halaman | Nama konkret seperti `GardenCard`, `…Header`, `…Section`, atau `…View` | Dipasang sebagai bagian halaman; tidak menjadi halaman hanya karena memiliki state atau membuka modal. |
| State kosong/loading/error | Cabang atau komponen di screen yang sama | Biasanya variasi satu halaman, bukan halaman baru. |
| Model/store/service | Nama domain dan tanggung jawabnya | Tidak menggambar tampilan. |

Ubah `GardenListView` menjadi `GardenListScreen` pada task daftar agar perannya terlihat dari nama. Terapkan penamaan halaman secara bertahap pada area berikutnya setelah memastikan perannya. Perbarui semua referensi runtime, test, eksperimen, dan preview dalam perubahan yang sama. Jangan membuat wrapper Screen yang hanya meneruskan ke View lama semata-mata untuk memenuhi nama.

Komponen umum harus menerima nilai, binding, content, atau callback yang sesuai; jangan memindahkan aturan penyimpanan/navigasi bisnis ke design system. State bukan pembeda tunggal: komponen boleh memiliki state lokal yang memang miliknya.

## 4. Peta halaman yang wajib dihasilkan

Buat `Docs/Architecture.md` untuk konvensi dan alasan penempatan, serta `Docs/ScreenMap.md` untuk penelusuran halaman. Tautkan keduanya dari README dan perbarui tabel folder lama; jangan meninggalkan panduan lama yang bertentangan. Simpan dokumentasi di root repo agar tidak ikut menjadi resource app secara tidak sengaja.

Untuk setiap screen/flow dalam cakupan task, tuliskan:

- Nama yang terlihat oleh pengguna, simbol, dan path file relatif repo yang dapat diklik.
- Status: aktif dari root app, eksperimen, reference/preview, atau belum terkonfirmasi.
- Dari mana ia dibuka dan cara presentasinya: push, sheet, full screen, tab, atau pergantian isi dalam flow.
- Komponen penting dan lokasinya; sebutkan bagian inline/computed property yang masih berada di file halaman.
- Pemilik state/data, input/output callback, dan siapa yang benar-benar menyimpan perubahan.
- State/varian dan modal anak yang relevan; jangan menganggap setiap preview sebagai halaman produksi.

Pisahkan **pohon komposisi UI** dari **alur navigasi**. Tujuan navigasi tidak selalu merupakan komponen yang terlihat di halaman induk.

Contoh baseline daftar yang perlu diverifikasi dan diperbarui setelah refactor:

```text
Komposisi GardenListView (kelak GardenListScreen)
├── Judul: Text inline
├── Bila semua daftar kosong: EmptyStateView → SeedlingIcon
├── Draf: card inline → LocationMapPreview
├── Kebun tersimpan: GardenCard → GardenMapView + GardenAreaIcon
├── Unduhan opsional: MapDownloadCard → MapDownloadProgressView
│   └── Gambar referensi atau LocationMapPreview
└── PrimaryActionButton

Data: GardenStore.gardens + MappingDraftStore.drafts
      → ContentView → halaman daftar
Navigasi: pilih kebun → callback → ContentView → GardenProfileView
          daftar kebun → callback → ContentView → RegistrationIntroView
          lanjutkan draf → callback → ContentView → GardenBoundaryView
```

Daftar unduhan didukung API halaman dan reference previews, tetapi `ContentView` saat audit tidak memberikan data unduhan. Tandai perbedaan ini secara eksplisit. Dokumentasi final harus memakai nama/path setelah refactor, bukan membiarkan contoh baseline sebagai hasil akhir.

## 5. Urutan pengerjaan

1. **Baseline dan inventaris.** Baca instruksi proyek, status Git, konfigurasi Xcode, entry point, dan seluruh pemanggil simbol yang akan berubah. Tentukan scope task dan baseline yang dapat dipertanggungjawabkan. Catat struktur dan pemeriksaan awal.
2. **Rencana perpindahan konkret.** Tulis tabel singkat path/simbol asal → tujuan → alasan → pemanggil terdampak. Untuk file campuran, petakan per tipe. Lanjutkan keputusan rutin tanpa meminta persetujuan ulang; tanyakan hanya keputusan yang belum terotorisasi dan mengubah scope/perilaku atau penanganan pekerjaan lama.
3. **Struktur dahulu.** Pindahkan file dan lakukan rename per area yang saling terkait. Pertahankan implementasi dan signature selain rename yang diperlukan. Jangan sekaligus menstandarkan semua ukuran, warna, atau perilaku UI.
4. **Perjelas komposisi.** Setelah perpindahan stabil, ekstrak bagian yang memang mengaburkan halaman. Contoh kandidat: kartu draf inline, `MapDownloadCard` dalam file campuran, dan section profil yang besar. Tidak perlu satu file per Text/HStack atau batas jumlah baris yang kaku.
5. **Design system.** Pisahkan UI generik dari domain dan dependensi preview fitur. Misalnya preview `EmptyStateView` dapat memakai ilustrasi generik, sementara komposisi dengan SeedlingIcon tetap ditunjukkan di preview fitur. Jangan memindahkan SeedlingIcon ke Core hanya untuk membenarkan dependensi preview. Konsolidasi komponen/tokens hanya bila semantik dan semua state-nya cocok; jika mengubah visual, jadikan task terpisah.
6. **Verifikasi dan dokumentasi.** Perbarui peta setiap area yang selesai. Periksa perubahan dan buat commit sesuai otorisasi task. Lanjutkan area lain jika masih termasuk scope; jangan melaporkan seluruh refactor selesai setelah satu contoh halaman.

Pertahankan ownership `@State`, `@Binding`, observable store, environment, dan callback. Ekstraksi tidak boleh membuat store baru per komponen, mereset draft, mengubah identitas view secara tidak sengaja, atau memicu `.task`/GPS/network dengan siklus hidup berbeda. Saat memisahkan tipe, periksa akses `private`/`fileprivate`; jangan menjadikan semuanya public agar build lolos.

Tetap pertahankan bundle identifier, target/module, deployment target, key JSON, raw value enum, lokasi `gardens.json` dan `mapping-drafts.json`, identitas data, dan perilaku gagal-simpan. Migrasi penyimpanan, perubahan algoritme pemetaan, pengaktifan eksperimen, atau redesain UI bukan bagian task struktur ini. Catat masalah di luar scope sebagai tindak lanjut.

## 6. Git: baseline, commit, dan push yang bisa dipercaya

**Satu task yang bisa direview = satu branch; satu perubahan logis = satu commit.** Jangan membuat branch baru setiap memindahkan file. Gunakan branch task yang sudah sesuai atau buat branch baru dari baseline yang benar saat implementasi diotorisasi, misalnya `refactor/gardens-structure`. Jangan otomatis mengambil main terbaru dan kehilangan konteks kode kerja.

### Sebelum mengubah file yang sudah berubah

- Catat branch, HEAD, status tracked/untracked/staged, upstream, dan remote. Jangan reset, clean, stash, commit, atau menghapus pekerjaan lama untuk “membersihkan” repo tanpa otorisasi.
- Menjalankan `git switch -c` hanya membuat branch; itu tidak memisahkan perubahan lama dari perubahan baru. Worktree baru dari HEAD juga tidak membawa perubahan yang belum di-commit.
- Untuk kondisi repo saat audit, diperlukan baseline yang mencakup versi kerja yang pengguna ingin refactor. Jika belum ada instruksi penanganannya, selesaikan inventaris/rencana dulu, lalu minta keputusan konkret: pengguna menyelesaikan commit pekerjaan lama, atau mengizinkan agent membuat commit baseline terpisah atas file yang telah dirinci. Jangan memakai izin “commit task refactor” sebagai izin menyertakan seluruh pekerjaan lama.
- Jika baseline sudah disediakan atau penanganannya sudah diotorisasi, lanjut tanpa meminta izin yang sama lagi. Task yang tidak menyentuh pekerjaan lama boleh diteruskan jika commit dan dependensinya benar-benar dapat dipisahkan.
- Memindahkan file yang dirty dapat memasukkan perubahan lama sebagai bagian file baru. Jangan menganggap stage path secara selektif otomatis menyelesaikan masalah ini.

### Commit

- Periksa diff biasa dan staged. Stage hanya perubahan yang termasuk task; hindari `git add .` atau `git add -A` tanpa peninjauan setiap file.
- Semua pemanggil rename dan file baru yang diperlukan harus berada di commit yang sama atau commit sebelumnya. Build yang sukses pada working tree yang masih memakai file untracked bukan bukti commit mandiri dapat dibangun.
- Usahakan setiap commit bisa dibangun dari snapshot commit-nya sendiri. Pisahkan perpindahan/rename, ekstraksi implementasi, dan perubahan perilaku; perubahan perilaku di luar scope harus menjadi task lain. Gabungkan perubahan yang memang saling bergantung.
- Ikuti gaya pesan repo bila ada. Bila belum konsisten, gunakan pesan seperti `refactor: clarify garden list screen and components` atau `docs: map garden screens and navigation`. Tidak wajib mengubah riwayat lama agar mengikuti format baru.
- Jangan sertakan build output, cache, kredensial, atau file pribadi. Jangan amend commit pengguna, rebase riwayat bersama, atau force-push tanpa instruksi eksplisit.

### Otorisasi pengiriman

Bila instruksi task sudah meminta commit dan push, lakukan setelah verifikasi tanpa meminta konfirmasi ulang. Bila task hanya meminta audit, dokumen, atau edit lokal, jangan menganggap push/PR/merge otomatis diotorisasi. Push branch task ke remote yang telah diverifikasi; jangan push langsung ke main atau melakukan merge. Periksa seluruh commit yang akan terkirim terhadap branch dasar, bukan hanya commit terakhir, agar riwayat lain tidak ikut tanpa sengaja. Jika diminta PR, buat deskripsi dari hasil akhir dan laporkan URL-nya.

Bila pemeriksaan terhalang lingkungan, laporkan secara konkret. Jangan menyebut branch “terverifikasi” hanya karena berhasil di-push. Hindari menyatakan commit siap digabung jika snapshot-nya belum dapat dibangun.

## 7. Verifikasi yang sesuai perubahan

Gunakan scheme `PalmOilFarmer` dan target `PalmOilFarmerTests` setelah mengonfirmasi keduanya pada konfigurasi aktual. Cari simulator/SDK yang terpasang; jangan menurunkan deployment target atau mengubah signing untuk memaksa build. Simpan output build di lokasi sementara, bukan file yang ikut commit.

- Jalankan baseline build/test yang relevan pada snapshot awal yang disepakati; bedakan kegagalan lama dan regresi.
- Untuk perpindahan file/rename: build Debug, periksa semua referensi termasuk eksperimen/preview, lalu cek Release pada struktur akhir agar dependensi fixtures yang hanya tersedia saat DEBUG tidak bocor. Tidak perlu menjalankan ulang semua pemeriksaan tanpa perubahan baru.
- Untuk perubahan store/model atau pemecahan kode yang menyentuh kontraknya: gunakan pengujian persistence, failure state, dan kompatibilitas lama dalam `PalmOilFarmerTests` serta `GardenStressTests`.
- Untuk draf dan alur review: gunakan `CodedUI2FlowTests`. Untuk area/block yang terdampak: gunakan `FindingBlockTests`. Nama “FlowTests” tidak berarti ada pengujian interaksi UI; file tersebut berisi Swift Testing untuk perilaku/data.
- Gunakan file data sementara untuk pengujian, bukan data kebun pengguna. Tambahkan test hanya untuk risiko perilaku yang belum dilindungi; jangan membuat test yang sekadar memeriksa nama folder.
- Bila UI diekstrak, bandingkan sebelum/sesudah pada input, ukuran layar, dan state yang sama: empty/populated/draft, dark/light, teks panjang dan Dynamic Type besar sesuai area yang berubah. Pertahankan juga perilaku Reduce Motion/Transparency yang relevan.
- Coba alur terkait di simulator: daftar → profil → edit/batal/simpan, atau pendaftaran → pemetaan → simpan/lanjutkan draf. Jika ekstraksi menyentuh modal, cek tutup/kembali dan kegagalan save. Preview statis bukan pengganti pemeriksaan interaksi.
- Pastikan aset ditemukan, tidak ada sumber terkompilasi ganda, target membership benar, dan dokumentasi mengarah ke file/simbol final. Karena root disinkronkan dengan filesystem, jangan menambah entri PBX manual jika perpindahan sudah ditangani sinkronisasi.

Jika toolchain, simulator, atau akses UI tidak tersedia, selesaikan pemeriksaan statis yang mungkin, jelaskan persis pemeriksaan yang belum dilakukan, dan jangan mengarang hasil atau memperbaiki konfigurasi di luar scope.

## 8. Kriteria selesai dan laporan

Task baru selesai dalam scope yang ditetapkan jika:

- [ ] Pengguna dapat menemukan titik masuk halaman dari konvensi Screen, komponen lokal, dan komponen bersama tanpa menebak dari nama folder lama.
- [ ] ScreenMap mencakup seluruh halaman/flow dalam scope, komposisi dan navigasi dipisahkan, path valid, dan status aktif/reference/eksperimen jelas.
- [ ] Struktur final konsisten dengan tujuan; penyimpangan memiliki alasan konkret; tidak ada dua lokasi bersaing untuk tanggung jawab yang sama.
- [ ] Semua pemanggil, preview, test, README, dan referensi resource terkait sudah diperbarui.
- [ ] Tidak ada perubahan UI, data, state ownership, atau navigasi yang tidak disengaja; verifikasi dan keterbatasannya dicatat.
- [ ] Perubahan pengguna tetap utuh; commit task tidak diam-diam menyertakan atau bergantung pada perubahan lama yang tidak tercakup baseline.
- [ ] Jika commit/push diotorisasi, branch, commit, dan tujuan pengiriman telah diverifikasi dan hasilnya dilaporkan.

Laporan akhir dalam bahasa Indonesia: masalah dan perubahan utama, tree ringkas setelah refactor, tautan peta halaman, satu contoh cara menelusuri layar, hasil pemeriksaan yang benar-benar dijalankan, batasan/area tersisa, serta branch/commit/push/PR bila dilakukan. Jangan mengklaim seluruh aplikasi selesai jika hanya Gardens/List yang tercakup.
