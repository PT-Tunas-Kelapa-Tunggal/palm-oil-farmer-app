# Part 1 - Mengenali baseline dan menyiapkan PR pertama

Pada project yang sudah masuk TestFlight, tampilan yang berhasil dijalankan bukan satu-satunya hal yang perlu kita pertahankan. Draf kebun harus tetap terbaca, pengajuan harus tetap terhubung ke sistem operator, dan perubahan dari satu PR harus bisa dibedakan dari perubahan PR berikutnya.

Karena itu, kita akan memulai dari aplikasi yang ada. Kita akan mengenali jalur utama, menjalankan pemeriksaan awal, lalu mencatat hasilnya dalam satu dokumen kecil. Dokumen inilah yang akan menjadi pembanding ketika kita mulai memindahkan folder pada Part 2.

Di sepanjang seri ini, kamu yang mengerjakan perubahan secara manual. Tutorial menjelaskan file yang perlu dibuka, alasan perubahan, dan hasil yang perlu diperiksa. Kita akan memperkenalkan konsep Clean Architecture dan MVVM-C ketika konsep tersebut mulai dipakai.

> **Penyesuaian pelaksanaan:** Part 1 sudah didelegasikan ke assistant. Branch yang dipakai adalah `refactor/01-baseline`; checkpoint disimpan lokal. Langkah push/PR pada materi ini ditunda sesuai permintaan pengguna. Hasil aktual tersedia di [baseline](../refactor/baseline.md).

## Tujuan part ini

Setelah menyelesaikan Part 1, kamu mempunyai:

- Commit lokal yang jelas sebagai titik awal refactor.
- Branch kerja terpisah dari branch acuan.
- Pemahaman alur aplikasi sampai pengajuan berhasil.
- Catatan hasil build, test, dan pemeriksaan flow yang benar-benar kamu jalankan.
- Dokumen baseline yang siap direview dalam PR kecil.

Pada part ini, source Swift, struktur folder aplikasi, schema penyimpanan, dan konfigurasi rilis tetap menggunakan implementasi sekarang. Hasil pekerjaanmu adalah dokumen `docs/refactor/baseline.md`.

## Materi yang akan kita pelajari

1. Mengenali titik awal dan membuat branch kerja.
2. Membaca flow serta memeriksa aplikasi sebelum refactor.
3. Menulis baseline dan menyiapkan PR pertama.

> **Lokasi file setelah Part 2:** link source pada materi ini sudah mengarah ke struktur baru. Tabel dan uraian path lama tetap menjadi penjelasan keadaan baseline sebelum pemindahan.

## Persiapan teknis

Siapkan repository yang sudah kamu pull, Xcode, satu iOS Simulator yang didukung project, dan editor Markdown. Kamu bisa memakai editor yang biasa kamu gunakan untuk membaca file ini.

Saat tutorial ini disusun, kondisi checkout adalah:

| Hal | Nilai yang ditemukan |
| --- | --- |
| Project dan scheme | `PalmOilFarmer` |
| Test target | `PalmOilFarmerTests` |
| Branch lokal | `build/testflight-prep` |
| Commit lokal | `43e413f` |
| Deployment target pada project | iOS 27.0 |
| Konfigurasi Run/Test pada scheme | Debug |
| Konfigurasi Archive pada scheme | Release |

Nilai di atas adalah hasil pembacaan checkout, bukan bukti bahwa build TestFlight dibuat dari commit yang sama. Jika kode berubah setelah tutorial ditulis, gunakan hasil pemeriksaanmu dan catat perbedaannya.

`Developer.xcconfig` sudah ditemukan di checkout saat penulisan. File ini diabaikan oleh Git. Kamu tidak perlu membuatnya ulang jika konfigurasi lokalmu sudah bekerja.

---

## Materi 1 - Mengenali titik awal dan membuat branch kerja

Sebuah baseline adalah keadaan aplikasi yang dijadikan pembanding. Dalam refactor ini, baseline memiliki dua bagian: versi kode dan perilaku yang kita amati. Mengetahui salah satunya saja belum cukup untuk menjelaskan apakah perubahan berikutnya menyebabkan masalah baru.

Kita akan mencatat versi kode terlebih dahulu, lalu menyiapkan tempat kerja yang terpisah.

### Persiapan

Buka Terminal pada folder repository. Semua perintah Git dalam tutorial dijalankan dari folder tersebut. Jalankan perintah satu per satu agar kamu bisa membaca hasilnya sebelum melanjutkan.

### Langkah-langkah

1. **Pastikan Terminal berada di project yang benar.**

   Jalankan:

   ```bash
   pwd
   ```

   Pada komputer yang dipakai saat tutorial ditulis, hasilnya adalah `/Users/hatamisg/Learning/Project/palm-oil`. Di Finder atau editor, folder ini seharusnya berisi `PalmOilFarmer.xcodeproj`, `PalmOilFarmer`, dan `PalmOilFarmerTests`.

2. **Periksa perubahan yang belum menjadi commit.**

   Jalankan:

   ```bash
   git status --short --branch
   ```

   Pada checkout awal terdapat `?? docs/`. Tanda `??` berarti file atau folder belum dilacak Git. Folder itu berisi dokumen analisis sebelumnya dan materi tutorial ini.

   Jika kamu melihat file `.swift`, konfigurasi project, atau perubahan lain yang kamu buat sendiri, kenali dahulu perubahan tersebut. Kita perlu dapat membedakan pekerjaan yang sudah ada dari pekerjaan tutorial. Jangan menggunakan perintah reset atau menghapus perubahan untuk membuat status terlihat bersih.

3. **Catat commit kode yang sedang kamu baca.**

   Jalankan:

   ```bash
   git log -1 --oneline
   ```

   Simpan ID commit dan judulnya dalam catatan sementara. Pada saat penulisan, ID-nya `43e413f`, dengan perubahan terakhir mengenai CloudKit sebagai sumber data submitted dan SwiftData untuk draf.

   Jika hasilmu berbeda, gunakan ID dari komputermu. ID `43e413f` bukan nilai yang harus dipaksakan.

4. **Periksa hubungan dengan branch remote.**

   Jalankan:

   ```bash
   git branch -vv
   ```

   Perintah ini menunjukkan branch aktif dan remote-tracking branch yang diikutinya. Remote-tracking branch adalah catatan lokal Git tentang posisi remote terakhir yang diketahui.

   Untuk memperbarui catatan itu, jalankan:

   ```bash
   git fetch origin
   ```

   Lalu periksa kembali:

   ```bash
   git status --short --branch
   ```

   `fetch` tidak menggabungkan kode remote ke source yang sedang kamu buka. Jika muncul `behind`, `ahead`, atau branch acuan ternyata berbeda, catat hasilnya sebelum membuat branch tutorial. Kita perlu memastikan titik awalnya dahulu, bukan langsung menjalankan pull/rebase tanpa membaca keadaan repository.

5. **Buat branch kerja dari baseline yang sudah kamu kenali.**

   Jika branch aktifmu masih `build/testflight-prep` dan tidak ada perbedaan remote yang perlu diselesaikan, jalankan:

   ```bash
   git switch -c refactor/01-baseline
   ```

   Periksa hasilnya:

   ```bash
   git branch --show-current
   ```

   Hasil yang diharapkan adalah `refactor/01-baseline`. Jika branch dengan nama itu sudah ada dari pengerjaan sebelumnya, baca status dan posisi branch tersebut sebelum menggunakannya kembali.

6. **Pisahkan identitas kode lokal dari identitas build TestFlight.**

   Jika informasi TestFlight tersedia, catat versi dan build number yang sedang digunakan tester. Jika kamu memiliki akses ke arsip atau informasi upload, cocokkan informasi itu dengan catatan source yang digunakan saat membuat build.

   Jika commit rilis belum diketahui, tulis **belum terverifikasi**. Selesai melakukan pull menunjukkan keadaan repository lokalmu; itu tidak menentukan commit pembentuk build TestFlight.

### Hasil yang harus terlihat

Kamu berada pada branch kerja, mengetahui commit awalnya, dan mengetahui apakah hubungan commit tersebut dengan build TestFlight sudah terverifikasi atau masih belum diketahui.

### Cara kerjanya

Branch memberi nama pada rangkaian commit. Ketika kamu membuat branch baru, source aplikasi tetap sama sampai kamu mengubahnya. File untracked juga tidak otomatis masuk commit hanya karena kamu berpindah branch.

Kita akan memakai branch ini untuk dokumentasi baseline. Perubahan source akan dimulai dari pekerjaan berikutnya setelah baseline tersebut jelas.

> **Tips:** Simpan ID baseline awal. Setelah kamu membuat commit dokumentasi, `git log -1` akan menunjukkan commit dokumentasi itu, sedangkan commit kode awal masih menjadi pembanding yang kita catat.

---

## Materi 2 - Membaca flow dan memeriksa aplikasi sebelum refactor

Sebelum memisahkan ViewModel dan Coordinator, kita perlu mengenali tanggung jawab yang sekarang masih digabung. Kita juga perlu melihat perilakunya agar tidak menjadikan dugaan dari kode sebagai hasil pengujian.

Pada materi ini, kita menelusuri jalur produksi dari entry point sampai pengajuan. Bagian status dan hasil tetap menggunakan implementasi tim.

### Persiapan

Buka `PalmOilFarmer.xcodeproj` di Xcode. Gunakan scheme `PalmOilFarmer` dan simulator dengan versi iOS yang didukung project.

Gunakan data uji untuk pemeriksaan yang membuat kebun atau pengajuan. Jalur Run pada scheme sekarang memakai Debug/Development. TestFlight memakai jalur Release/Production. Data Development dan Production tidak perlu tampil sama.

### Langkah-langkah

1. **Temukan pemilik aplikasi dan penyimpanannya.**

   Buka [PalmOilFarmerApp.swift](../../PalmOilFarmer/App/PalmOilFarmerApp.swift). Perhatikan bahwa app membuat ModelContainer, lalu memberikan container tersebut ke ContentView.

   Berikutnya buka [AppConfiguration.swift](../../PalmOilFarmer/App/AppConfiguration.swift). Cari tiga hal berikut:

   - Nilai container dan environment dibaca dari konfigurasi build.
   - Lokasi store SwiftData dibedakan menurut container dan environment.
   - ModelContainer memakai `DraftPlantationRequest` dan tidak mengaktifkan sinkronisasi SwiftData CloudKit otomatis.

   Cukup kenali alurnya. Kita belum mengubah konfigurasi ini.

2. **Ikuti flow dari Home sampai profil.**

   Buka [ContentView.swift](../../PalmOilFarmer/App/ContentView.swift). Cari pemanggilan `GardenListView`, `RegistrationIntroView`, `GardenBoundaryView`, dan `GardenProfileView`.

   Perhatikan bahwa ContentView menyimpan state untuk memilih kebun, membuka registrasi, menyimpan lokasi sementara, dan membuka mapping setelah sheet ditutup. Nanti sebagian tanggung jawab ini menjadi pekerjaan Coordinator.

   Gunakan peta berikut untuk menemukan file lain ketika diperlukan:

   | Jalur | File utama saat ini |
   | --- | --- |
   | Home | `Features/Gardens/List/GardenListView.swift` |
   | Guide dan pencarian | `Features/Gardens/Registration/RegistrationIntroView.swift`, `LocationSearchView.swift` |
   | Pemilihan foto | `Features/Gardens/Registration/GardenPhotoPickerView.swift` |
   | Pemetaan | `Features/Gardens/Mapping/GardenBoundaryView.swift` |
   | Detail registrasi/edit | `Features/Gardens/Registration/GardenDetailsView.swift` |
   | Profil dan riwayat | `Features/Gardens/Profile/GardenProfileView.swift`, `History/GardenHistoryEditors.swift` |
   | Pengajuan | `Features/Gardens/Review/ReviewRequestView.swift`, `ReviewContactFormView.swift` |

   Semua path pada tabel berada di dalam folder `PalmOilFarmer`. Tujuan kita saat ini mengetahui hubungan antarbagian, bukan menghafal setiap isi file.

3. **Baca perpindahan data lokal ke remote.**

   Buka [GardenStore.swift](../../PalmOilFarmer/App/State/GardenStore.swift). Temukan `addDraft`, `add`, `update`, `refreshRemote`, dan `submitReview`.

   Kemudian lihat [DraftPlantationRequest.swift](../../PalmOilFarmer/Data/Gardens/DraftPlantationRequest.swift) dan [CloudKitFarmerReviewRepository.swift](../../PalmOilFarmer/Data/Reviews/CloudKitFarmerReviewRepository.swift).

   Catat alur yang dipertahankan sepanjang seri:

   | Keadaan data | Pendekatan sekarang |
   | --- | --- |
   | Lokasi disimpan lewat “Lakukan Nanti” | Draf lokal SwiftData |
   | Kebun selesai dipetakan, belum diajukan | Draf terpetakan lokal SwiftData |
   | Pengajuan berhasil disimpan server | CloudKit menjadi sumber data submitted; draf lokal dibersihkan |
   | Kebun submitted dibaca kembali | Diambil dari CloudKit |

   Refactor ini tidak menambahkan cache submitted. Kita juga mempertahankan nama model, field, dan nilai tersimpan sampai ada pekerjaan migrasi tersendiri.

4. **Periksa konfigurasi lalu jalankan build baseline.**

   Pada scheme `PalmOilFarmer`, lihat pengaturan Run dan pastikan konfigurasi yang digunakan adalah Debug. Pilih simulator, kemudian jalankan **Product > Build** (`⌘B`).

   Catat hasil yang benar-benar muncul. Jika build gagal, tulis pesan error utamanya. Jika runtime berhenti karena konfigurasi belum lengkap, periksa `Developer.xcconfig` lokal berdasarkan contoh repository dan konfigurasi project yang sudah digunakan tim.

   Pertahankan identitas aplikasi dan container yang sudah dipakai. Menyalin nilai contoh `com.example...` ke project aktif akan membuat acuan pengujian berubah.

   Jika ingin melihat versi Xcode, gunakan informasi versi dari aplikasi Xcode. Pada lingkungan penulisan tutorial, command-line developer directory masih menunjuk CommandLineTools; itu sebabnya hasil pemeriksaan terminal sebelumnya belum merupakan hasil build aplikasi.

5. **Jalankan test yang sudah ada.**

   Jalankan **Product > Test** (`⌘U`) dengan simulator yang dipilih. Test yang ada berada di `PalmOilFarmerTests` dan antara lain memeriksa penyimpanan in-memory, konversi model, filter, validasi, serta geometri.

   Catat status dan nama test yang gagal jika ada. Jangan langsung mengubah source supaya baseline terlihat lulus. Kegagalan yang sudah ada perlu dibedakan dari regresi akibat pekerjaan berikutnya.

   Test yang berhasil juga belum membuktikan navigasi modal atau komunikasi dengan operator berhasil; keduanya memerlukan pemeriksaan tersendiri.

6. **Jalankan flow utama menggunakan data uji Development.**

   Jalankan aplikasi (`⌘R`), lalu kerjakan skenario berikut secara berurutan. Isi hasilnya dengan **lulus**, **gagal**, **belum diuji**, atau **terhambat**, disertai catatan singkat.

   | ID | Yang kamu lakukan | Yang perlu diamati |
   | --- | --- | --- |
   | F01 | Buka Home, lalu tarik untuk refresh | Daftar/empty state tampil; catat jika error hanya terlihat di console |
   | F02 | Buka “Daftarkan Kebun”, lanjutkan guide, cari alamat, pilih hasil | Sheet pencarian ditutup dan mapping muncul |
   | F03 | Dari lokasi hasil pencarian, pilih “Lakukan Nanti”; hentikan dan jalankan kembali app | Draf muncul kembali dan bisa dibuka |
   | F04 | Lanjutkan draf, gambar batas valid, lengkapi nama/tanggal tanam/jenis tanah, lalu simpan | Kebun terpetakan tampil dan draf lokasi yang diselesaikan tidak tersisa sebagai kartu kedua |
   | F05 | Hentikan dan jalankan kembali app sebelum mengajukan kebun itu | Kebun lokal yang baru disimpan masih terbaca |
   | F06 | Buka editor profil atau riwayat, ubah nilai, lalu batalkan | Perubahan yang dibatalkan tidak menjadi nilai tersimpan |
   | F07 | Isi dan simpan riwayat pupuk serta panen | Nilai terbaru tampil pada profil; pengajuan tersedia ketika profil lengkap |
   | F08 | Buka pengajuan, baca informasi, setujui, isi kontak dan konfirmasi, lalu kirim | Modal pengajuan selesai dan profil menunjukkan pengajuan; catat error jika terjadi |
   | F09 | Setelah submit berhasil, jalankan kembali app dengan koneksi dan refresh | Kebun submitted dapat dibaca kembali melalui CloudKit |

   Pada F08, gunakan environment Development dengan identitas data yang jelas sebagai data uji. Keberhasilan tombol/layar bukan bukti bahwa aplikasi operator sudah membaca record; catat verifikasi operator secara terpisah jika kamu mengerjakannya.

7. **Periksa cabang flow yang membutuhkan perangkat atau data tambahan.**

   Coba lokasi perangkat, penolakan izin lokasi, dan foto dengan geotag jika perangkat/data mendukung. Pada jalur foto, periksa konfirmasi lokasi serta “Cari Lagi”. Pada mapping yang belum disimpan, periksa konfirmasi keluar setelah titik batas ditambahkan.

   Simulator dan perangkat nyata mempunyai kondisi foto/GPS yang berbeda. Jika skenario belum dapat dijalankan, tulis penyebabnya. Kita perlu tahu apa yang belum teruji, bukan menganggapnya berhasil.

   Pengujian update dari build TestFlight lama ke build baru belum dilakukan pada tahap ini. Catat kebutuhan tersebut sebagai pemeriksaan rilis setelah perubahan source nanti tersedia.

8. **Catat batas kepemilikan yang sudah disepakati.**

   Gunakan batas berikut dalam catatan baseline:

   | Bagian | Perlakuan selama seri |
   | --- | --- |
   | Home, registrasi, mapping, profil, riwayat, dan pengajuan | Refactor tanggung jawab menjadi Clean Architecture + MVVM-C |
   | Status/timeline, hasil, rekomendasi, panduan area, eksperimen | Pemindahan folder saja, dengan implementasi tetap sama |
   | Kontrak data dengan operator | Dipertahankan; kompatibilitas remote tetap menjadi syarat integrasi |
   | Bug yang ditemukan | Dicatat dan ditangani pada PR terpisah |

   Jika kelak pemindahan folder menuntut perubahan di luar batas ini, kita periksa dahulu penyebabnya dan pisahkan pekerjaannya. Kita tidak akan diam-diam merombak implementasi hasil agar cocok dengan struktur baru.

### Hasil yang harus terlihat

Kamu dapat menjelaskan perjalanan satu kebun dari draf hingga pengajuan. Kamu juga memiliki hasil pemeriksaan awal, termasuk bagian yang gagal, belum diuji, atau belum dapat diverifikasi.

### Cara kerjanya

Baseline perilaku membantu kita membandingkan keadaan sebelum dan sesudah refactor. Saat suatu flow berubah, kita bisa memeriksa apakah perubahan tersebut baru muncul setelah PR tertentu.

Pemeriksaan lokal dan remote memiliki batas yang berbeda. Membaca draf setelah restart menguji jalur lokal. Membaca submitted garden setelah refresh menguji pembacaan remote pada kondisi saat itu. Verifikasi di aplikasi operator diperlukan untuk membuktikan sisi operator secara langsung.

Beberapa bagian README masih menggambarkan penyimpanan JSON dan review simulasi. Untuk baseline ini, catat implementasi yang kamu baca dan perilaku yang kamu jalankan; perbedaan dokumentasi masuk daftar temuan.

> **Tips:** Gunakan satu kebun uji dengan nama yang mudah dikenali. Catat nama itu agar hasil pemeriksaan antarlayar tidak tertukar dengan record lain. Screenshot cukup memakai data uji dan jangan menyertakan isi konfigurasi lokal.

---

## Materi 3 - Menulis baseline dan menyiapkan PR pertama

Sekarang kita mempunyai informasi yang diperlukan untuk membuat catatan yang berguna. Dokumen baseline akan menjelaskan titik awal, batas pekerjaan, dan bukti pemeriksaan. Dengan begitu, PR pemindahan folder berikutnya mempunyai pembanding yang konkret.

### Persiapan

Tetap berada di branch `refactor/01-baseline`. Siapkan hasil pemeriksaan dari Materi 1 dan Materi 2.

### Langkah-langkah

1. **Buat dokumen hasil pekerjaanmu.**

   Melalui editor, buat folder `docs/refactor` di root repository, sejajar dengan folder `PalmOilFarmer`. Di dalamnya buat file `baseline.md`.

   Folder ini berisi catatan refactor. Folder `docs/tutorials` berisi panduan yang sedang kamu baca. Menyimpannya di luar folder source aplikasi membuat keduanya mudah dibedakan dari file fitur.

2. **Isi identitas baseline.**

   Tulis judul, tanggal pemeriksaan, branch acuan, ID commit kode awal, branch kerja, versi Xcode, serta simulator/perangkat yang digunakan.

   Tambahkan versi/build TestFlight jika diketahui dan status hubungan commit-nya. Gunakan “belum terverifikasi” untuk informasi yang belum bisa dibuktikan.

3. **Tulis cakupan dan aturan data.**

   Ringkas batas dari Materi 2: perilaku yang kita refactor berhenti sampai pengajuan berhasil; bagian status/hasil hanya dipindahkan foldernya; pendekatan SwiftData untuk draf dan CloudKit untuk submitted dipertahankan.

   Tambahkan bahwa identitas aplikasi, lokasi store, nama model persistence, dan kontrak field remote tetap dipertahankan. Ini menjadi acuan review ketika perubahan mulai menyentuh Data layer.

4. **Masukkan hasil pemeriksaan yang sebenarnya.**

   Salin daftar skenario F01-F09 sebagai tabel catatan dan tambahkan hasilmu. Catat pula hasil build/test serta pemeriksaan foto/GPS.

   Agar mudah dibaca kembali, isi dokumen dapat disusun menjadi enam bagian: Identitas baseline, Cakupan, Aturan data, Hasil pemeriksaan, Temuan awal, dan Belum terverifikasi.

   Pisahkan temuan dari pekerjaan yang dilakukan. Contohnya, jika sudah ditemukan bug sebelum refactor, tuliskan langkah pemicu dan hasilnya. Tidak perlu memasukkan perbaikannya ke PR dokumentasi ini.

5. **Periksa perubahan sebelum staging.**

   Jalankan:

   ```bash
   git status --short
   ```

   Untuk melihat perubahan file yang sudah dilacak, jalankan:

   ```bash
   git diff --stat
   ```

   File baru yang belum dilacak tidak muncul pada diff biasa. Buka kembali `baseline.md` di editor untuk memeriksa isinya. Jika Xcode mengubah file project atau scheme, lihat perbedaannya terlebih dahulu. Tidak semua perubahan yang muncul saat bekerja perlu menjadi bagian PR.

6. **Stage hanya dokumen baseline.**

   Jalankan:

   ```bash
   git add -- docs/refactor/baseline.md
   ```

   Lalu periksa file yang akan masuk commit:

   ```bash
   git diff --cached --name-only
   ```

   Untuk PR ini, hasil yang diharapkan hanya `docs/refactor/baseline.md`. Periksa isinya:

   ```bash
   git diff --cached
   ```

   Dokumen analisis dan tutorial yang masih untracked tidak otomatis ikut. Jika ada file lain yang sudah staged dari pekerjaan sebelumnya, kenali dan keluarkan file tersebut dari staging melalui editor Git sebelum membuat commit ini; file kerjanya tetap dipertahankan.

7. **Buat checkpoint commit.**

   Setelah staged diff sesuai, jalankan:

   ```bash
   git commit -m "docs: record refactor baseline and scope"
   ```

   Periksa commit terbaru:

   ```bash
   git show --stat --oneline HEAD
   ```

   Commit tersebut seharusnya berisi dokumen baseline. Source aplikasi masih menggunakan perilaku awal.

8. **Siapkan PR dengan base branch yang tepat.**

   Branch acuan lokal kita adalah `build/testflight-prep`. Gunakan branch tersebut sebagai calon base PR, lalu pastikan itu memang branch integrasi yang kamu gunakan. Hindari memilih `main` hanya karena antarmuka hosting memilihnya secara default.

   Ketika siap mengirim branch kerja, jalankan:

   ```bash
   git push -u origin refactor/01-baseline
   ```

   Buka PR melalui layanan Git yang kamu gunakan. Judul yang bisa dipakai adalah **“Document baseline and scope for MVVM-C refactor”**.

   Isi deskripsinya dengan alasan baseline dibuat, cakupan perubahan dokumen, hasil pemeriksaan yang kamu jalankan, dan informasi yang belum terverifikasi. Periksa tab perubahan PR: PR pertama ini seharusnya hanya menambahkan dokumen baseline.

   Jika base branch ternyata sudah menerima perubahan baru, periksa perbedaannya dan ulangi pemeriksaan yang terpengaruh sebelum menganggap baseline ini masih berlaku. Kita belum perlu memilih strategi rebase/merge sampai kondisi branch-nya diketahui.

### Hasil yang harus terlihat

Kamu mempunyai satu commit dokumentasi, dengan PR yang mudah diperiksa. Pembaca PR dapat mengetahui kode acuannya, batas refactor, hasil pengujian awal, dan bagian yang belum diverifikasi.

### Cara kerjanya

Staging menentukan perubahan yang akan masuk ke commit berikutnya. Karena itu, kita menggunakan path file yang spesifik dan memeriksa staged diff sebelum commit. Folder `docs` yang berisi beberapa dokumen tidak harus dikirim sekaligus.

Commit adalah checkpoint lokal. Push mengirim branch ke remote. PR membandingkan branch kerja dengan base branch yang dipilih. Memastikan ketiganya sesuai akan membantu kita menjaga ukuran review ketika mulai memindahkan file dan memisahkan tanggung jawab.

> **Tips:** Satu PR sebaiknya memiliki tujuan yang bisa dijelaskan dalam satu kalimat. Pada part ini tujuannya mencatat baseline. Pemindahan folder baru dimulai pada pekerjaan berikutnya.

---

## Checkpoint akhir Part 1

Gunakan daftar ini untuk memeriksa pekerjaanmu:

- [ ] Commit kode awal dan branch acuan sudah dicatat.
- [ ] Hubungan dengan build TestFlight ditandai terverifikasi atau belum terverifikasi.
- [ ] Branch kerja terpisah sudah dibuat.
- [ ] Build baseline berhasil, atau kendala setup-nya tercatat dengan jelas.
- [ ] Hasil test yang tersedia sudah dicatat tanpa mengklaim pengujian yang belum dijalankan.
- [ ] Hasil flow utama dan keterbatasan pemeriksaan perangkat/remote sudah dicatat.
- [ ] Batas pengajuan versus status/hasil sudah tertulis.
- [ ] Pendekatan penyimpanan dan kontrak data sekarang menjadi acuan yang dipertahankan.
- [ ] Commit/PR dokumentasi hanya memuat file yang memang dimaksudkan.

Jika build belum bisa dijalankan, kita selesaikan setup tersebut sebelum mengubah source. Jika ada kegagalan test atau flow pada baseline, kita catat dan tentukan penanganannya secara terpisah. Ketidakjelasan commit TestFlight tetap terlihat sebagai keterbatasan, bukan dianggap selesai oleh pemeriksaan lokal.

Untuk sesi berikutnya, siapkan isi `baseline.md`, hasil build/test, dan pesan error jika ada. Kamu tidak perlu mengirim isi `Developer.xcconfig`, data pribadi, atau seluruh repository.

## Berikutnya: Part 2

Pada Part 2, kita akan menata folder berdasarkan fitur dan tanggung jawab. Tujuannya membuat file mudah ditemukan dengan perubahan yang dapat direview sebagai pemindahan. Pemisahan ViewModel dan Coordinator akan mengikuti setelah struktur dan acuan perilaku ini jelas.
