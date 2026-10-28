#!/usr/bin/env python3
"""Prepare per-developer settings without changing CloudKit or signing into accounts."""
import argparse
from pathlib import Path
import re
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "Config/Services.local.xcconfig"


def validate(team, bundle, container):
    if team == "YOURTEAMID" or not re.fullmatch(r"[A-Z0-9]{10}", team):
        raise ValueError("Team ID harus 10 karakter huruf besar/angka.")
    if not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle):
        raise ValueError("Bundle ID harus berformat reverse-domain, misalnya com.namakamu.KropsFarmer.")
    if not re.fullmatch(r"iCloud\.[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", container):
        raise ValueError("Container harus berformat iCloud.com.namakamu.KropsFarmer.")


def settings():
    values = {}
    for path in [ROOT / "Config/Services.xcconfig", CONFIG]:
        if path.exists():
            for line in path.read_text().splitlines():
                match = re.fullmatch(r"\s*(KROPS_[A-Z_]+)\s*=\s*(.*?)\s*", line.partition("//")[0])
                if match:
                    values[match[1]] = match[2]
    return values


def check():
    values = settings()
    validate(values.get("KROPS_DEVELOPMENT_TEAM", ""), values.get("KROPS_BUNDLE_IDENTIFIER", ""),
             values.get("KROPS_CLOUDKIT_CONTAINER", ""))
    mode = values.get("KROPS_REVIEW_TRANSPORT")
    expected = {"native": "Config/CloudKit/Native.entitlements", "web": "Config/CloudKit/Web.entitlements"}
    if mode not in expected or values.get("KROPS_SERVICE_ENTITLEMENTS") != expected[mode]:
        raise ValueError("Mode dan entitlements tidak cocok. Jalankan ulang init dengan --force.")
    if values.get("KROPS_WEB_ENVIRONMENT") not in ("development", "production"):
        raise ValueError("Environment harus development atau production.")
    for key in ("KROPS_DEVELOPMENT_TEAM", "KROPS_BUNDLE_IDENTIFIER", "KROPS_CLOUDKIT_CONTAINER", "KROPS_REVIEW_TRANSPORT"):
        print(f"{key} = {values[key]}")
    if mode == "native":
        print("Native: API Token tidak diperlukan. Environment mengikuti provisioning profile Apple.")
    else:
        import plistlib
        token_path = ROOT / "PalmOilFarmer/Resources/CloudKitWeb.local.plist"
        token = plistlib.loads(token_path.read_bytes()).get("apiToken", "") if token_path.exists() else ""
        if not token.strip() or "REPLACE_" in token:
            raise ValueError(f"Isi API Token milik container pilihanmu di {token_path}.")
        print("Web: file API Token tersedia (nilai token tidak ditampilkan).")
    print("Konfigurasi lokal valid. Kepemilikan container/schema tetap harus dicek di akun Apple.")
    return values


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    init = commands.add_parser("init", help="Buat konfigurasi akun lokal, tanpa mengubah akun Apple.")
    init.add_argument("--team", required=True)
    init.add_argument("--bundle-id", required=True)
    init.add_argument("--container", help="Default: iCloud.<bundle-id>")
    init.add_argument("--mode", choices=["native", "web"], default="native")
    init.add_argument("--environment", choices=["development", "production"], default="development")
    init.add_argument("--force", action="store_true", help="Izinkan mengganti file konfigurasi lokal yang sudah ada.")
    commands.add_parser("check", help="Periksa konfigurasi lokal; tidak menampilkan token.")
    operator_config = commands.add_parser("operator-config", help="Siapkan file lokal yang bisa disalin ke repository operator.")
    operator_config.add_argument("--bundle-id", help="Default: <bundle-id-petani>.Operator")
    commands.add_parser("schema-command", help="Tampilkan perintah import schema; tidak menjalankannya.")
    contract = commands.add_parser("contract-check", help="Cocokkan kontrak data dengan source operator.")
    contract.add_argument("--operator-root", type=Path, default=ROOT.parent / "drone-mapping-icloud")
    args = parser.parse_args()
    if args.command == "init":
        container = args.container or "iCloud." + args.bundle_id
        validate(args.team, args.bundle_id, container)
        if CONFIG.exists() and not args.force:
            raise ValueError(f"{CONFIG} sudah ada; dipertahankan. Gunakan --force jika ingin menggantinya.")
        entitlement = "Native" if args.mode == "native" else "Web"
        CONFIG.write_text("// Personal settings. Ignored by Git.\n" + "\n".join([
            f"KROPS_DEVELOPMENT_TEAM = {args.team}", f"KROPS_BUNDLE_IDENTIFIER = {args.bundle_id}",
            f"KROPS_CLOUDKIT_CONTAINER = {container}", f"KROPS_REVIEW_TRANSPORT = {args.mode}",
            f"KROPS_WEB_ENVIRONMENT = {args.environment}",
            f"KROPS_SERVICE_ENTITLEMENTS = Config/CloudKit/{entitlement}.entitlements", ""]))
        if args.mode == "web":
            target = ROOT / "PalmOilFarmer/Resources/CloudKitWeb.local.plist"
            if not target.exists():
                shutil.copyfile(ROOT / "PalmOilFarmer/Resources/CloudKitWeb.example.plist", target)
        print(f"Dibuat: {CONFIG}")
        if args.mode == "native":
            check()
        else:
            print("Isi file CloudKitWeb.local.plist, lalu jalankan check.")
    elif args.command == "contract-check":
        shared = ROOT / "PalmOilFarmer/Shared/ReviewContract"
        operator = args.operator_root / "ControlDroneMapping/Data/ReviewRequest"
        for name in ["PlantationReviewDTOs.swift", "PlantationDomainMapper.swift", "PlantationRecordCKAdapter.swift"]:
            if (shared / name).read_bytes() != (operator / name).read_bytes():
                raise ValueError(f"Kontrak berbeda: {name}. Cocokkan perubahan di kedua aplikasi sebelum integrasi.")
            print(f"Identik: {name}")
        adapter = (shared / "PlantationRecordCKAdapter.swift").read_text()
        field_block = adapter.split("public enum Field {", 1)[1].split("    }", 1)[0]
        fields = set(re.findall(r'public static let \w+ = "([^"]+)"', field_block))
        schema = (ROOT / "Config/CloudKit/schema.ckdb").read_text()
        schema_fields = set(re.findall(r"^\s+(\w+) (?:STRING|DOUBLE|INT64|TIMESTAMP|ASSET)[,\s]", schema, re.M))
        if fields != schema_fields:
            raise ValueError("Field schema tidak cocok dengan CKRecord adapter.")
        print(f"Schema cocok: {len(fields)} field.")
    elif args.command == "check":
        check()
    elif args.command == "operator-config":
        values = check()
        output = ROOT / "Config/CloudKit/operator/Developer.local.xcconfig"
        output.parent.mkdir(parents=True, exist_ok=True)
        prefix = values["KROPS_BUNDLE_IDENTIFIER"].rsplit(".", 1)[0]
        operator_bundle = args.bundle_id or values["KROPS_BUNDLE_IDENTIFIER"] + ".Operator"
        validate(values["KROPS_DEVELOPMENT_TEAM"], operator_bundle, values["KROPS_CLOUDKIT_CONTAINER"])
        output.write_text("// Local operator configuration for the same backend. Ignored by Git.\n" +
                          f"DRONE_DEVELOPMENT_TEAM = {values['KROPS_DEVELOPMENT_TEAM']}\n" +
                          f"DRONE_BUNDLE_PREFIX = {prefix}\n" +
                          f"DRONE_OPERATOR_BUNDLE_IDENTIFIER = {operator_bundle}\n" +
                          f"DRONE_CLOUDKIT_CONTAINER = {values['KROPS_CLOUDKIT_CONTAINER']}\n")
        print(f"Dibuat: {output}\nSalin ke Config/Developer.local.xcconfig pada source operator yang sudah memakai container configurable.")
    else:
        values = check()
        print("Jalankan setelah menyimpan management token cktool dari akunmu sendiri:")
        import shlex
        print(shlex.join(["env", "DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer", "xcrun", "cktool",
                          "import-schema", "--validate", "--team-id", values["KROPS_DEVELOPMENT_TEAM"],
                          "--container-id", values["KROPS_CLOUDKIT_CONTAINER"], "--environment", "development",
                          "--file", "Config/CloudKit/schema.ckdb"]))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
