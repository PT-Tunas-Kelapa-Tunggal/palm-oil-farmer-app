# Palm Oil Farmer

An iOS app for oil palm farmers, built with SwiftUI and organized by feature, with one app target and a Swift Testing target.
The project is being migrated incrementally to Clean Architecture with MVVM-C and SwiftUI NavigationStack. Part 2 organized files; Part 3 separates Foundation-only Domain values/rules from framework and presentation helpers and makes the existing review repository contract injectable into GardenStore. Use cases, full dependency composition, ViewModels, and Coordinators follow in later parts.
Keep the structure small: add folders and abstractions when real code needs them.

## Naming

- Display name: **Palm Oil Farmer**.
- Xcode project, app target, and Swift module: `PalmOilFarmer`.
- Test target: `PalmOilFarmerTests`.
- Repository slug, if needed: `palm-oil-farmer`.
- The existing bundle identifiers are retained to preserve app identity and access to existing saved gardens.

## Developer Setup & Configuration

This project uses a central `Developer.xcconfig` file for developer-specific credentials (gitignored).

1. Copy the configuration template:
   ```bash
   cp Developer.xcconfig.example Developer.xcconfig
   ```
2. Open `Developer.xcconfig` and fill in your individual Apple Developer account details:
   - `DEVELOPMENT_TEAM`: Your 10-character Apple Developer Team ID.
   - `PRODUCT_BUNDLE_IDENTIFIER`: Your app bundle identifier.
   - `CLOUDKIT_CONTAINER_ID`: Your CloudKit container identifier.

> **CloudKit Environment Handling**:
> - **Local Development / Run (`⌘R`)**: Xcode automatically builds in **Debug** mode and uses the CloudKit **`Development`** sandbox.
> - **TestFlight / Archive (`Product → Archive`)**: Xcode automatically builds in **Release** mode and uses the CloudKit **`Production`** environment.
> - All required configuration keys are enforced at runtime via `AppConfiguration`; missing keys trigger an explicit panic (`fatalError`) rather than falling back to hardcoded defaults.


## Where code belongs

| Folder | Responsibility |
| --- | --- |
| `PalmOilFarmer/App` | App entry point, shared store ownership, top-level navigation |
| `PalmOilFarmer/DesignSystem/Tokens` | Shared colors, spacing, typography, corner radii, control dimensions |
| `PalmOilFarmer/DesignSystem/Components` | Reusable UI with no dependency on garden models or services |
| `PalmOilFarmer/DesignSystem/Styles` | Button styles and shared presentation modifiers |
| `PalmOilFarmer/DesignSystem/Catalog` | Light, dark, and accessibility-size component previews |
| `PalmOilFarmer/Domain/Gardens` | Foundation-only garden/history values, required details, validation, and profile readiness |
| `PalmOilFarmer/Domain/Reviews` | Review/contact values, contact validation, request snapshot construction, and repository contract |
| `PalmOilFarmer/Data/Gardens` | SwiftData draft model and the transitional GardenStore |
| `PalmOilFarmer/Data/Reviews` | CloudKit repository, DTOs, domain mapper, and CKRecord adapter |
| `PalmOilFarmer/Data/Location` | Current location, MapKit search, waypoint session, and CoreLocation geometry adapters |
| `PalmOilFarmer/Features/GardenList` | Home list, cards, filters, and list illustration |
| `PalmOilFarmer/Features/GardenRegistration` | Guide, location/photo selection, details, and boundary mapping |
| `PalmOilFarmer/Features/GardenProfile` | Profile, summary, and profile progress |
| `PalmOilFarmer/Features/GardenHistory` | Fertilizer and harvest editors and history UI |
| `PalmOilFarmer/Features/ReviewRequest` | Program information, consent, and contact form |
| `PalmOilFarmer/Features/ReviewStatus` | Existing status/timeline UI; implementation retained |
| `PalmOilFarmer/Features/Recommendations` | Existing reports, charts, demo data, and report presentation mapper |
| `PalmOilFarmer/Features/AreaGuidance` | Existing area map/picker/navigation and shared zoning geometry |
| `PalmOilFarmer/Features/MapDownload` | Existing download presentation; no download service added |
| `PalmOilFarmer/SharedUI/Maps` | Reused map views and map hero UI |
| `PalmOilFarmer/SharedUI/Gardens` | Reused garden UI, display metrics, and transitional LiveGardenReader |
| `PalmOilFarmer/SharedUI/Reviews` | Existing review titles and timeline presentation helpers |
| `PalmOilFarmer/Experiments/FindingWaypoint` | Standalone experimental entry point, map, thumbnail, and preview data |
| `PalmOilFarmer/PreviewSupport` | Debug fixtures and reference-screen compositions |
| `PalmOilFarmerTests` | Swift Testing checks for persistence, validation, and geometry |

This layout is transitional. Domain now compiles independently with Foundation: CoreLocation conversions/measurements live in Data, and titles/timeline formatting live in SharedUI. GardenStore consumes `FarmerReviewRepository` but still combines observable state, SwiftData, mapping, and submission and defaults to the concrete CloudKit implementation. The profile still has a direct CloudKit fallback. Full composition and screen orchestration remain later migration work.

The implementation scope runs from Home through successful review submission. Existing status/results/guidance/experiment files remain unchanged in Part 3; their shared timeline/title helpers were relocated from Domain without changing the helper bodies. See [the baseline](docs/refactor/baseline.md), [Part 2 results](docs/refactor/part-02-structure.md), and [Part 3 verification](docs/refactor/part-03-domain-contracts.md).

## Rules for changes

- Keep transient UI state in the view. `GardenStore` owns saved gardens; profile views receive the latest value from their parent. Editors own local drafts and publish them only after a successful save.
- A profile's `onUpdate` must update the parent's source of truth. Static reference previews intentionally use fixed input; use a stateful parent for interactive editing previews.
- Put calculations and validation in value types. Introduce use cases, ViewModels, and flow Coordinators incrementally; simple controls do not require a ViewModel or Coordinator of their own.
- Keep Domain independent of Data, Features, SharedUI, and Apple UI/location/persistence frameworks. Presentation keeps form drafts and messages; existing input rules live in Domain. Persisted decoding and model fields remain compatible rather than being retroactively rejected by new initializers.
- Keep framework access at the data boundary. `LocationSearchView` accepts a search closure for deterministic results. Existing `initialResults` is a convenience for fixed reference previews.
- Design system components must not depend on `Garden`, `GardenStore`, or preview fixtures. `GardenPickerField` currently has a historical name but takes only generic labels, values, and content.
- Prefer semantic system typography for text. Use shared tokens for repeated visual roles; illustration coordinates and map dimensions can remain local constants.
- Keep small, closely related types together. Extract a type when its name or responsibility deserves a discoverable file.
- Preserve SwiftData model identity, properties, store paths, CloudKit fields, JSON payload keys, and enum raw values. Changing persisted types requires an explicit migration and compatibility checks. Historical JSON decoding coverage does not prove storage migration.
- Put production area guidance under `Features/AreaGuidance`, location access under `Data/Location`, and standalone waypoint experiment screens under `Experiments/FindingWaypoint`.
- Keep move-only commits separate from Swift implementation changes and documentation edits. Fixes to behavior belong in separate work.

## User testing build (branch `user-testing/midfid`)

The app follows the Sketch **MID-FID Flow** page (KROPS file): Daftar Kebun (dari foto / dari pencarian), Profil Kebun, Ajukan Peninjauan, Hasil Peninjauan.

- **Registration:** guide sheet → "Cari alamat" (place search, current location, or a geotagged photo). A photo location is confirmed on the map first ("Ya, Ini kebun saya" / "Cari Lagi").
- **Lakukan Nanti:** saves the location as a local SwiftData draft. The draft card reopens the map to continue mapping.
- **Mode Developer (debug builds):** hold the "Kebun" title for 1.5 s to open it. It erases all garden data and toggles the home filter tabs.
- **Review:** consent → contact form → CloudKit submission through GardenStore. The status UI still has a facilitator long-press action, and "Lihat & unduh hasil" still simulates an 8-second download. These presentation behaviors are retained during the structural migration.
- **Results:** CloudKit results are adapted for presentation; `DemoReviewReport` still provides demo/fallback results. Demo areas (AA–CB) and fertilizer quantities follow the mapped boundary; demo nutrient levels, prices, and rainfall are fixed examples. Tap a nutrient bar for its fertilizer reference; "Buka Map" guides to the selected area with GPS (straight-line distance, not a route). Part 2 does not change result behavior.

## Verification

Open `PalmOilFarmer.xcodeproj` and build the `PalmOilFarmer` scheme. Run its `PalmOilFarmerTests` test target on an iOS simulator with Product > Test. Persistence tests use in-memory SwiftData containers. Terminal build/test instructions are included in the [Part 2 tutorial](docs/tutorials/part-02-struktur-folder-dan-batas-fitur.md).

Open `DesignSystemCatalog.swift` in Canvas to inspect shared controls. Before merging UI changes, check light/dark appearance, long labels, larger Dynamic Type, Reduce Motion, and Reduce Transparency. For navigation or save-flow changes, also exercise registration, editing, cancellation, and deletion in the simulator. Unit tests do not replace these UI checks.

## Data Architecture & Persistence

- **Local Drafts (Offline First)**: Unsubmitted drafts (unmapped locations from "Lakukan Nanti" and mapped gardens awaiting review) are stored locally in **SwiftData** via `DraftPlantationRequest`. The store file is physically partitioned by CloudKit container and environment (`AppConfiguration.swiftDataStoreURL`).
- **CloudKit as Single Source of Truth**: Once a farmer submits a scan request, the record is uploaded to CloudKit Public Database. Upon confirmation, the local draft is evicted from SwiftData.
- **Environment Isolation**: Debug builds connect to CloudKit `Development` and isolate drafts to the `Development` directory; Release / TestFlight builds connect to CloudKit `Production` and isolate drafts to the `Production` directory. Stale Development test data does not leak into Production builds.
- **Server-Side Access Control**: CloudKit's record-type ACL (`schema.ckdb`) grants `READ, WRITE` to `_creator` and `"Drone Operator"`. The farmer app natively only receives the authenticated user's records.

## Apple references

- [Model data and state ownership](https://developer.apple.com/documentation/swiftui/model-data)
- [Managing model data with Observation](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Dynamic text styles](https://developer.apple.com/documentation/swiftui/font/textstyle)
- [Swift Testing](https://developer.apple.com/documentation/testing)

The folder layout is a project convention, not an Apple-mandated architecture.
