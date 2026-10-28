# Konfigurasi layanan

Mulai dari [setup akun CloudKit](../Docs/OperatorConnection.md).

| File | Isi | Masuk Git |
| --- | --- | --- |
| `Services.xcconfig` | Default bersama, tanpa Team ID pribadi | Ya |
| `App-Info.plist` | Metadata runtime dari build settings layanan | Ya |
| `Services.local.xcconfig` | Akun, bundle ID, container dan mode developer ini | Tidak |
| `Services.local.xcconfig.example` | Contoh mode native, tanpa API Token | Ya |
| `Services.web.local.xcconfig.example` | Contoh mode Web Services opsional | Ya |
| `CloudKit/Native.entitlements` | Izin native, container dari konfigurasi | Ya |
| `CloudKit/Web.entitlements` | Entitlements kosong untuk mode web | Ya |
| `CloudKit/schema.ckdb` | Schema dan role yang sama untuk app petani/operator | Ya |
| `CloudKit/operator/Developer.local.xcconfig` | Hasil helper untuk source operator | Tidak |

Setup sekali per developer:

```sh
python3 Scripts/setup-services.py init --team YOURTEAMID --bundle-id com.yourname.KropsFarmer
python3 Scripts/setup-services.py check
```

Untuk akun lain helper memakai container `iCloud.<bundle-id>`. Tambahkan
`--container` jika memilih nama lain. `init` mempertahankan file lokal yang sudah
ada; penggantian hanya dilakukan jika kamu menambahkan `--force`.

`operator-config` menghasilkan pengaturan matching untuk disalin ke
`Config/Developer.local.xcconfig` di repository operator. Helper tidak menyalin
sertifikat dan tidak memberikan akses akun Apple.

Bundle ID operator dibuat sebagai `<bundle-id-petani>.Operator`, sehingga tidak
memakai identitas operator bawaan akun lain. Gunakan `operator-config --bundle-id`
jika ingin memilih ID operator lain. Pengaturan ini hanya mengubah identitas app
operator, tidak mengubah ID app kamera atau container data.

`schema-command` menampilkan perintah import schema Development; tidak menjalankan
perubahan ke cloud. Persiapan server tetap dilakukan dari akun pemilik container.

Sebelum menggabungkan perubahan format data kedua app, jalankan:

```sh
python3 Scripts/setup-services.py contract-check --operator-root ../drone-mapping-icloud
```

Helper membandingkan DTO, mapper, adapter record serta field schema agar perubahan
di satu app tidak terlewat pada app pasangannya.
