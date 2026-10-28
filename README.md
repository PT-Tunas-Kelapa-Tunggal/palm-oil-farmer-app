# Palm Oil Farmer

An iOS app for oil palm farmers, built with SwiftUI and organized by feature, with one app target and a Swift Testing target.
Keep the structure small: add folders and abstractions when real code needs them.

Start with the [screen map](Docs/ScreenMap.md) to find a page, its components, data owner, and navigation. See [architecture](Docs/Architecture.md) for placement rules and the [documentation index](Docs/README.md) for setup and supporting guides.

The app starts at `PalmOilFarmerApp → AppFlow → GardenListScreen`. Screen files name navigation/modal destinations; Flow files connect steps.

## Naming

- Display name: **Palm Oil Farmer**.
- Xcode project, app target, and Swift module: `PalmOilFarmer`.
- Test target: `PalmOilFarmerTests`.
- Repository slug, if needed: `palm-oil-farmer`.
- Per-developer bundle identifiers come from the local service configuration. Local garden data belongs to the selected app identifier.

## Where code belongs

| Folder | Responsibility |
| --- | --- |
| `PalmOilFarmer/App` | App entry point, shared store ownership, top-level navigation |
| `Config` | Shared service defaults, ignored developer settings, entitlements and CloudKit schema |
| `PalmOilFarmer/Services/CloudKit` | Native and optional web connections, with no hardcoded developer account |
| `PalmOilFarmer/Shared/ReviewContract` | DTOs, JSON mapper and CKRecord contract shared with the operator |
| `PalmOilFarmer/Core/DesignSystem/Tokens` | Shared colors, spacing, typography, corner radii, control dimensions |
| `PalmOilFarmer/Core/DesignSystem/Components` | Reusable UI with no dependency on garden models or services |
| `PalmOilFarmer/Core/DesignSystem/Styles` | Button styles and shared presentation modifiers |
| `PalmOilFarmer/Core/DesignSystem/Catalog` | Light, dark, and accessibility-size component previews |
| `PalmOilFarmer/Features/GardenList` | Garden list and cards |
| `PalmOilFarmer/Features/GardenProfile` | Profile screen, content composition, local sections |
| `PalmOilFarmer/Features/GardenDetails` | Shared new/edit garden form |
| `PalmOilFarmer/Features/GardenRegistration` | Location selection, search and photo metadata |
| `PalmOilFarmer/Features/GardenMapping` | Boundary editor, mapping drafts and draft storage |
| `PalmOilFarmer/Features/GardenHistory` | Fertilizer/harvest editors, drafts and cards |
| `PalmOilFarmer/Features/GardenReview` | Review submission, status, models and service |
| `PalmOilFarmer/Features/FertilizerRecommendations` | Recommendation reports and presentation |
| `PalmOilFarmer/Features/MapDownloads` | Reference map download screens and cards |
| `PalmOilFarmer/Shared/Gardens` | Garden values, persistence, location access and shared domain UI |
| `PalmOilFarmer/Features/FindingBlock` | Allocation section and navigation with Models, Data, Views |
| `PalmOilFarmer/Features/FindingWaypoint` | Separate waypoint experiment with Models, Data, Views |
| `PalmOilFarmer/Resources` | Asset catalog; asset names remain unchanged |
| `Docs` | Current guides and archived development records |
| `PalmOilFarmer/PreviewSupport` | Debug fixtures and reference-screen compositions |
| `PalmOilFarmerTests` | Swift Testing checks for persistence, validation, and geometry |

## Rules for changes

- Keep transient UI state in the view. `GardenStore` owns saved gardens; profile views receive the latest value from their parent. Editors own local drafts and publish them only after a successful save.
- A profile's `onUpdate` must update the parent's source of truth. Static reference previews intentionally use fixed input; use a stateful parent for interactive editing previews.
- Put calculations and validation in value types. Add a feature model only when orchestration becomes substantial; there is no mandatory ViewModel per screen.
- Keep framework access at the data boundary. `LocationSearchScreen` accepts a search closure for deterministic results. Existing `initialResults` is a convenience for fixed reference previews.
- Design system components must not depend on `Garden`, `GardenStore`, or preview fixtures. `GardenPickerField` currently has a historical name but takes only generic labels, values, and content.
- Prefer semantic system typography for text. Use shared tokens for repeated visual roles; illustration coordinates and map dimensions can remain local constants.
- Keep small, closely related types together. Extract a type when its name or responsibility deserves a discoverable file.
- Keep JSON keys and enum raw values compatible with existing `gardens.json`. Changing persisted types requires an explicit migration and compatibility tests.
- FindingWaypoint is a separate experimental flow; FindingBlock is embedded in recommendations. Shared garden values and persistence live in Shared/Gardens; review and recommendation contracts stay with their respective features.

## CloudKit services and developer setup

The default connection is **native CloudKit owned by your own Apple Developer
account**. No API Token is needed for this mode. The existing operator record type,
fields, JSON formats and status codes remain compatible.

Start with [CloudKit account setup](Docs/OperatorConnection.md) and
[configuration files](Config/README.md). The current local setup uses
`com.hata.Kropshata` and `iCloud.com.hata.Kropshata`; account-specific values live in
ignored `Config/Services.local.xcconfig`, not in Swift source or project settings.

```text
Config/
  Services.xcconfig                  Shared defaults
  Services.local.xcconfig.example    Per-developer native template
  Services.web.local.xcconfig.example Optional shared-backend web template
  CloudKit/                         Entitlements and versioned database schema
Scripts/setup-services.py           Local setup, validation, operator config helper
PalmOilFarmer/Services/CloudKit/      Native connection and configuration
  WebServices/                      Optional API Token connection
PalmOilFarmer/Shared/ReviewContract/ DTOs, CKRecord adapter and JSON mapper
PalmOilFarmer/Features/GardenReview/ Review UI, domain values and app adapters
```

New developers create their own ignored settings once:

```sh
python3 Scripts/setup-services.py init --team YOURTEAMID --bundle-id com.yourname.KropsFarmer
python3 Scripts/setup-services.py check
```

By default this selects `iCloud.<bundle-id>` and native mode. Each developer creates
that container in their own account for an independent sandbox. Testing two apps
against one shared backend requires the same authorized container and environment;
separate containers do not share records. Optional Web Services mode can connect a
farmer build signed by another developer to the backend owner's API Token.

The operator source `../drone-mapping-icloud` now reads `DRONE_CLOUDKIT_CONTAINER`
from its ignored `Config/Developer.local.xcconfig`. Its Info.plist and entitlements
use that same setting. Run `python3 Scripts/setup-services.py operator-config` to
prepare matching owner-account settings for it.

The CloudKit contract remains `PlantationScanRequest` in the public database.
`gardenID`, `boundaryJSON`, `agronomicJSON`, `resultJSON`, `orthomosaicAsset`, and
status values `0...3` are unchanged. The DTO, mapper and CKRecord adapter match the
operator's source. `Config/CloudKit/schema.ckdb` declares the fields, query indexes
and the `KropsOperator` role needed to read/update requests from other farmers.

Opening a profile fetches the latest request; explicit refresh fetches again.
Responses are saved locally through `GardenStore`, and real operator area IDs such
as `A` are displayed as supplied. Cloud records are not automatically copied from a
previous container. The app bundle identifier remains unchanged for this user's
current install, so local gardens stay available.

## Verification

Open `PalmOilFarmer.xcodeproj` and build the `PalmOilFarmer` scheme. Run its `PalmOilFarmerTests` test target on an iOS simulator with Product > Test. Tests use unique temporary directories, never the user's gardens file.

Open `DesignSystemCatalog.swift` in Canvas to inspect shared controls. Before merging UI changes, check light/dark appearance, long labels, larger Dynamic Type, Reduce Motion, and Reduce Transparency. For navigation or save-flow changes, also exercise registration, editing, cancellation, and deletion in the simulator. Unit tests do not replace these UI checks.

## Deliberate limits

- Persistence is still synchronous and atomic. The extracted `GardenPersistence` isolates the file format, but does not claim a performance improvement. Move I/O off the main actor when measurement warrants it; serialize writes and preserve save-failure behavior when making that change.
- The refactor retains existing layouts and custom glass appearance. Semantic typography is introduced in shared form controls; fixed-size typography elsewhere still needs a dedicated visual/accessibility review.
- Reference layout variants remain supported in the profile. They have not been removed or redesigned.
- No additional local database, dependency-injection framework, or extra production modules are required at this stage. Profile performance before adding caching or changing storage.

## Apple references

- [Model data and state ownership](https://developer.apple.com/documentation/swiftui/model-data)
- [Managing model data with Observation](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Dynamic text styles](https://developer.apple.com/documentation/swiftui/font/textstyle)
- [Swift Testing](https://developer.apple.com/documentation/testing)

The folder layout is a project convention, not an Apple-mandated architecture.

Historical refactor plans and verification reports are collected in [Docs/Archive](Docs/Archive/README.md).
