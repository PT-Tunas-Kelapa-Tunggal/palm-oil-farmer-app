# Setup CloudKit milik sendiri

App petani sekarang memakai **CloudKit native** sebagai mode utama. Kamu tidak perlu
akun atau API Token teman. Pengaturan lokal sudah disiapkan untuk:

| Pengaturan | Nilai di komputer ini |
| --- | --- |
| Apple Developer Team | `4Z34RN4542` |
| App ID petani | `com.hata.Kropshata` |
| Container | `iCloud.com.hata.Kropshata` |
| Database | Public |
| Record type | `PlantationScanRequest` |

Nilai akun tersimpan di `Config/Services.local.xcconfig` dan diabaikan Git.
Swift membaca nilai yang sama dari Info.plist hasil build. Entitlements mengambil
container dari konfigurasi yang sama, sehingga tidak perlu mengedit banyak file.

## 1. Siapkan akun Apple Developer dan container

Gunakan keanggotaan Apple Developer Program aktif. Akun **Individual berbayar**
bisa memakai CloudKit; keanggotaan organisasi tidak wajib untuk akunmu sendiri.
Akun iCloud pada iPhone dan Mac dipakai sebagai pengguna layanan; ini berbeda
dari akun developer untuk signing, walaupun boleh menggunakan email yang sama.

1. Buka [Apple Developer Account](https://developer.apple.com/account/), login ke
   akunmu, lalu buka Certificates, Identifiers & Profiles.
2. Pada Identifiers, buat atau pilih App ID `com.hata.Kropshata`.
3. Aktifkan iCloud dengan dukungan CloudKit.
4. Buat container `iCloud.com.hata.Kropshata` jika belum ada, lalu hubungkan ke App ID.
   Jika nama itu tidak tersedia untuk akunmu, pilih nama baru yang unik dan ubah
   **hanya** `KROPS_CLOUDKIT_CONTAINER` di file konfigurasi lokal.
   Untuk operator, aktifkan iCloud/CloudKit pada App ID
   `com.hata.Kropshata.Operator` dan hubungkan **container yang sama**.
5. Di Xcode, pilih akunmu pada Settings → Apple Accounts. Proyek membaca Team ID
   dari konfigurasi lokal. Biarkan Automatically manage signing aktif agar Xcode
   membuat/memperbarui provisioning profile dengan izin CloudKit.

Referensi Apple: [mengaktifkan CloudKit](https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app),
[menghubungkan container dengan App ID](https://developer.apple.com/help/account/identifiers/enable-app-capabilities).

## 2. Buat schema Development

Buka [CloudKit Console](https://icloud.developer.apple.com/) dengan akunmu, pilih
container di atas dan environment **Development**. Schema versi proyek berada di
`Config/CloudKit/schema.ckdb`. Siapkan schema sebelum pengujian pengiriman.

Cara yang dapat diulang menggunakan cktool:

1. Buat CloudKit **management token** dari akunmu untuk administrasi schema.
   Token ini hanya untuk tool di Mac, tidak dimasukkan ke app. Ini berbeda dari
   API Token Web Services; app native tidak membutuhkannya.
2. Simpan token melalui prompt aman di Terminal:

   ```sh
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun cktool save-token --type management
   ```

3. Dari root `Krops_coded`, jalankan `python3 Scripts/setup-services.py schema-command`.
   Salin dan jalankan perintah import yang ditampilkan. Helper hanya menampilkan
   perintah; tidak mengubah akun/server secara otomatis.

Alternatifnya, buat record type serta field melalui CloudKit Console sesuai file
schema. Field yang dicari memerlukan indeks:

| Field | Tipe | Indeks |
| --- | --- | --- |
| `gardenID` | String | Queryable |
| `statusCode` | Int64 | Queryable |
| System record ID (`___recordID`) | Reference | Queryable |
| System creation date (`___createTime`) | Timestamp | Queryable, Sortable |
| `farmerName`, `farmerPhone`, `farmerAddress` | String | — |
| `gardenName`, `locationName` | String | — |
| `areaHectares` | Double | — |
| `boundaryJSON`, `agronomicJSON`, `resultJSON` | String | — |
| `submittedAt`, `scheduledFor`, `inReviewAt`, `completedAt` | Timestamp | — |
| `operatorNotes` | String | — |
| `orthomosaicAsset` | Asset | — |

Schema mempertahankan format JSON yang dipakai operator. Jangan mengubah tipe
field atau format JSON secara terpisah di salah satu app.

Referensi Apple: [schema sebagai source code](https://developer.apple.com/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow),
[cktool](https://developer.apple.com/icloud/ck-tool/).

## 3. Berikan izin akun iCloud operator

Schema membuat role `KropsOperator`. Tambahkan **pengguna iCloud yang dipakai pada
Mac operator** ke role ini melalui CloudKit Console. Haknya adalah membaca dan
mengubah pengajuan, termasuk hasil/asset. Pengguna petani mendapat hak membuat
pengajuan dan membaca record miliknya melalui role bawaan.

Team ID signing bukan pengganti role pengguna di database. Saat pengguna operator
belum terlihat pada Console, jalankan app operator dengan iCloud aktif terlebih
dahulu agar identitas pengguna pada container dapat dibuat.

## 4. Hubungkan dan jalankan kedua aplikasi

Konfigurasi source operator `../drone-mapping-icloud` sudah diperbarui agar container
tidak ditanam dalam Swift. Di komputer ini `Config/Developer.local.xcconfig` operator
sudah disiapkan dengan akunmu dan container yang sama.

1. Periksa app petani: `python3 Scripts/setup-services.py check`.
2. Buka `PalmOilFarmer.xcodeproj`, scheme **PalmOilFarmer**, lalu pilih iPhone kamu.
   iCloud native harus memakai container dari `Config/CloudKit/Native.entitlements`.
3. Buka proyek operator dan scheme **ControlDroneMapping**, gunakan mode normal
   (`demo: false`). Build native operator juga harus memiliki izin atas container ini.
   Setup engine pemetaan operator tetap mengikuti panduan repository operator.
4. Login iCloud di Settings iPhone dan System Settings Mac. App native memakai
   sesi iCloud perangkat; tidak ada login web atau API Token untuk mode ini.
5. Daftarkan kebun uji dan ajukan peninjauan. Buka kembali dashboard operator agar
   `syncReviewRequests()` mengambil pengajuan. Pengajuan awal tidak menyiratkan
   pengiriman berhasil jika server atau penyimpanan lokal gagal.
6. Cocokkan nama kebun, kontak, koordinat dan ID request. Kirim hasil dari operator,
   kemudian tarik untuk refresh pada app petani.

Kedua app harus memakai environment yang sama. Pada native CloudKit environment
ditentukan oleh entitlements/provisioning profile Apple. `KROPS_WEB_ENVIRONMENT`
hanya mengatur koneksi Web Services. Untuk TestFlight/App Store, siapkan schema
Production dan periksa kedua app menggunakan Production. Data Development dan
Production terpisah.

## Kolaborasi tanpa konflik pengaturan akun

- Commit source, contoh konfigurasi, dan `schema.ckdb`.
- Jalankan `python3 Scripts/setup-services.py contract-check` sebelum menggabungkan
  perubahan format data untuk memeriksa kecocokan dengan source operator.
- Jangan commit `Services.local.xcconfig`, konfigurasi lokal operator, API Token,
  sertifikat, atau private key.
- Developer baru menjalankan helper `init` dengan Team ID dan bundle ID sendiri;
  default container menjadi `iCloud.<bundle-id>`. Ini sandbox mandiri.
- Untuk uji integrasi bersama, pilih satu backend pemilik. Native build kedua app
  harus ditandatangani dengan akses ke backend tersebut. Akun Individual terpisah
  tidak otomatis mendapat akses native hanya karena source GitHub sama.
- Developer app petani yang perlu backend milikmu dengan signing akun sendiri
  dapat memakai mode Web Services opsional dengan **API Token akunmu**, bukan teman.
  Buat token pada container milikmu dengan callback
  `https://localhost/krops-cloudkit/auth`. Gunakan helper `init --mode web`, lalu isi
  `PalmOilFarmer/Resources/CloudKitWeb.local.plist`. Mode ini memerlukan login iCloud
  web dan environment token yang sesuai. Jangan memasukkan server private key.

Data cloud di container lama tidak dipindahkan otomatis. Bundle ID pengguna ini
tetap `com.hata.Kropshata`, sehingga penyimpanan kebun lokal pada instalasi tersebut
tetap tersedia.

## Status verifikasi

Pada 28 Oktober 2026, 45 test dalam 7 suite lulus. Build Debug native (simulator),
Release native (kompilasi tanpa signing perangkat), dan Debug web opsional berhasil.
Info.plist hasil build dan entitlements simulator sama-sama menunjuk
`iCloud.com.hata.Kropshata`. Konfigurasi build operator menunjuk Team dan container
yang sama; kompilasi bagian repository CloudKit operator juga berhasil diperiksa.
Helper setup diuji untuk akun developer berbeda, perlindungan overwrite, konfigurasi
web tanpa token, dan kesesuaian seluruh 17 field schema dengan adapter operator.

Pengujian build dan respons lokal tidak membuktikan bahwa container, schema, role,
dan provisioning profile sudah dibuat dalam akunmu. Pengiriman nyata dilakukan
setelah langkah akun di atas selesai. Source operator hanya diubah pada konfigurasi
CloudKit; engine, pemetaan, dan pemrosesan fotonya tidak diubah.
