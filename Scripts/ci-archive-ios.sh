#!/bin/bash
set -euo pipefail
umask 077

: "${RUNNER_TEMP:?Missing RUNNER_TEMP}"
: "${APPLE_TEAM_ID:?Configure APPLE_TEAM_ID}"
bundle_id="${IOS_BUNDLE_ID:?Configure IOS_BUNDLE_ID in this GitHub environment}"
container="${CLOUDKIT_CONTAINER_ID:?Configure CLOUDKIT_CONTAINER_ID in this GitHub environment}"
: "${MARKETING_VERSION:?Missing MARKETING_VERSION}"
: "${IOS_DISTRIBUTION_P12_BASE64:?Configure IOS_DISTRIBUTION_P12_BASE64}"
: "${IOS_DISTRIBUTION_P12_PASSWORD:?Configure IOS_DISTRIBUTION_P12_PASSWORD}"
: "${IOS_PROFILE_BASE64:?Configure IOS_PROFILE_BASE64}"

case "${IOS_ENVIRONMENT:-}" in
    staging) ;;
    production)
        : "${IOS_BUILD_NUMBER_OFFSET:?Set IOS_BUILD_NUMBER_OFFSET above existing production builds}"
        ;;
    *)
        echo "error: Invalid iOS release environment." >&2
        exit 1
        ;;
esac

offset="${IOS_BUILD_NUMBER_OFFSET:-0}"
run="${GITHUB_RUN_NUMBER:?Missing GITHUB_RUN_NUMBER}"
if [[ ! "$offset" =~ ^(0|[1-9][0-9]{0,7})$ || ! "$run" =~ ^[1-9][0-9]{0,7}$ ]]; then
    echo "error: IOS_BUILD_NUMBER_OFFSET and GITHUB_RUN_NUMBER must be decimal integers in the supported range." >&2
    exit 1
fi
index=$((offset + run - 1))
major=$((index / 9900 + 1))
minor=$((index % 9900 / 99))
patch=$((index % 99 + 1))
if (( major > 9999 )); then
    echo "error: CI build number exceeds the CFBundleVersion component range." >&2
    exit 1
fi
build_number="$major.$minor.$patch"

work="$(mktemp -d "$RUNNER_TEMP/palm-oil-signing.XXXXXXXX")"
keychain="$work/signing.keychain-db"
profile_path=""
config_created=""
ipa_path=""
archive_complete=""
old_keychains=()
keychain_entry='^[[:space:]]*"(.+)"[[:space:]]*$'
while IFS= read -r path; do
    if [[ "$path" =~ $keychain_entry ]]; then
        old_keychains+=("${BASH_REMATCH[1]}")
    fi
done < <(security list-keychains -d user)

cleanup() {
    if [[ -f "$keychain" ]]; then
        security list-keychains -d user -s ${old_keychains[@]+"${old_keychains[@]}"} || true
        security delete-keychain "$keychain" || true
    fi
    [[ -z "$profile_path" ]] || rm -f -- "$profile_path"
    [[ -z "$config_created" ]] || rm -f -- Developer.xcconfig
    if [[ -z "$archive_complete" && -n "$ipa_path" ]]; then
        rm -f -- "$ipa_path"
    fi
    rm -rf -- "$work"
}
trap cleanup EXIT

printf '%s' "$IOS_DISTRIBUTION_P12_BASE64" | base64 -D > "$work/distribution.p12"
printf '%s' "$IOS_PROFILE_BASE64" | base64 -D > "$work/app.mobileprovision"
security cms -D -i "$work/app.mobileprovision" -o "$work/profile.plist"
python3 - "$work/profile.plist" "$APPLE_TEAM_ID" "$bundle_id" "$container" > "$work/profile-uuid" <<'PY'
from datetime import datetime, timezone
import plistlib
import sys

path, team, bundle_id, container = sys.argv[1:]
with open(path, "rb") as stream:
    profile = plistlib.load(stream)
entitlements = profile["Entitlements"]
expected_ids = [f"{prefix}.{bundle_id}" for prefix in profile["ApplicationIdentifierPrefix"]]
if team not in profile["TeamIdentifier"] or entitlements.get("application-identifier") not in expected_ids:
    sys.exit(f"error: Profile does not authorize bundle ID {bundle_id} on team {team}")
if not entitlements.get("beta-reports-active") or entitlements.get("get-task-allow"):
    sys.exit("error: Expected an App Store Connect distribution provisioning profile")
if container not in entitlements.get("com.apple.developer.icloud-container-identifiers", []):
    sys.exit(f"error: Profile does not authorize CloudKit container {container}")
if profile["ExpirationDate"].replace(tzinfo=timezone.utc) <= datetime.now(timezone.utc):
    sys.exit("error: Provisioning profile has expired")
print(profile["UUID"])
PY
read -r profile_uuid < "$work/profile-uuid"

keychain_password="$(openssl rand -hex 32)"
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 7200 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$work/distribution.p12" -P "$IOS_DISTRIBUTION_P12_PASSWORD" -T /usr/bin/codesign -t cert -f pkcs12 -k "$keychain"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" ${old_keychains[@]+"${old_keychains[@]}"}
unset IOS_DISTRIBUTION_P12_BASE64 IOS_DISTRIBUTION_P12_PASSWORD IOS_PROFILE_BASE64

profile_dir="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$profile_dir"
profile_destination="$profile_dir/$profile_uuid.mobileprovision"
if [[ ! -e "$profile_destination" ]]; then
    cp "$work/app.mobileprovision" "$profile_destination"
    profile_path="$profile_destination"
elif ! cmp -s "$work/app.mobileprovision" "$profile_destination"; then
    echo "error: The installed provisioning profile for $profile_uuid differs from the CI profile." >&2
    exit 1
fi

if [[ ! -f Developer.xcconfig ]]; then
    cp Developer.xcconfig.example Developer.xcconfig
    config_created=1
fi

xcodebuild -version
xcodebuild archive -project PalmOilFarmer.xcodeproj -scheme PalmOilFarmer \
    -configuration Release -destination 'generic/platform=iOS' \
    -archivePath "$work/PalmOilFarmer.xcarchive" -derivedDataPath "$work/DerivedData" \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Apple Distribution" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" PROVISIONING_PROFILE_SPECIFIER="$profile_uuid" \
    PRODUCT_BUNDLE_IDENTIFIER="$bundle_id" CLOUDKIT_CONTAINER_ID="$container" \
    CLOUDKIT_ENVIRONMENT=Production MARKETING_VERSION="$MARKETING_VERSION" CURRENT_PROJECT_VERSION="$build_number"

python3 - "$work/ExportOptions.plist" "$APPLE_TEAM_ID" "$bundle_id" "$profile_uuid" "$IOS_ENVIRONMENT" <<'PY'
import plistlib
import sys

path, team, bundle_id, profile_uuid, environment = sys.argv[1:]
with open(path, "wb") as stream:
    plistlib.dump({
        "method": "app-store-connect",
        "destination": "export",
        "teamID": team,
        "signingStyle": "manual",
        "signingCertificate": "Apple Distribution",
        "provisioningProfiles": {bundle_id: profile_uuid},
        "iCloudContainerEnvironment": "Production",
        "manageAppVersionAndBuildNumber": False,
        "testFlightInternalTestingOnly": environment == "staging",
    }, stream)
PY

xcodebuild -exportArchive -archivePath "$work/PalmOilFarmer.xcarchive" \
    -exportPath "$work/export" -exportOptionsPlist "$work/ExportOptions.plist"

shopt -s nullglob
ipas=("$work"/export/*.ipa)
if [[ ${#ipas[@]} != 1 ]]; then
    echo "error: Expected exactly one exported IPA." >&2
    exit 1
fi
ditto -x -k "${ipas[0]}" "$work/ipa"
app="$work/ipa/Payload/PalmOilFarmer.app"
codesign --verify --strict --deep "$app"
codesign -d --entitlements - "$app" > "$work/entitlements.plist"
python3 - "$app/Info.plist" "$work/entitlements.plist" "$APPLE_TEAM_ID" "$bundle_id" "$container" "$MARKETING_VERSION" "$build_number" <<'PY'
import plistlib
import sys

info_path, entitlements_path, team, bundle_id, container, version, build = sys.argv[1:]
for path, expected in (
    (info_path, {
        "CFBundleIdentifier": bundle_id, "CFBundleShortVersionString": version,
        "CFBundleVersion": build, "CKContainerIdentifier": container, "CKEnvironment": "Production",
    }),
    (entitlements_path, {
        "com.apple.developer.team-identifier": team,
        "com.apple.developer.icloud-container-identifiers": [container],
        "com.apple.developer.icloud-container-environment": "Production",
    }),
):
    with open(path, "rb") as stream:
        values = plistlib.load(stream)
    for key, value in expected.items():
        if values.get(key) != value:
            sys.exit(f"error: Exported app has {key}={values.get(key)!r}; expected {value!r}")
PY

ipa_path="$RUNNER_TEMP/PalmOilFarmer-${GITHUB_RUN_ID:?Missing GITHUB_RUN_ID}-$build_number.ipa"
mv "${ipas[0]}" "$ipa_path"
{
    echo "ipa=$ipa_path"
    echo "bundle_id=$bundle_id"
    echo "build_number=$build_number"
} >> "${GITHUB_OUTPUT:?Missing GITHUB_OUTPUT}"
archive_complete=1
