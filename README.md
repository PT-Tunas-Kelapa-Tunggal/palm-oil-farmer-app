# Palm Oil Farmer

An iOS app for oil palm farmers, built with SwiftUI and organized by feature, with one app target and a Swift Testing target.
Keep the structure small: add folders and abstractions when real code needs them.

## Naming

- Display name: **Palm Oil Farmer**.
- Xcode project, app target, and Swift module: `PalmOilFarmer`.
- Test target: `PalmOilFarmerTests`.
- Repository slug, if needed: `palm-oil-farmer`.
- The existing bundle identifiers are retained to preserve app identity and access to existing saved gardens.

## Where code belongs

| Folder | Responsibility |
| --- | --- |
| `PalmOilFarmer/App` | App entry point, shared store ownership, top-level navigation |
| `PalmOilFarmer/DesignSystem/Tokens` | Shared colors, spacing, typography, corner radii, control dimensions |
| `PalmOilFarmer/DesignSystem/Components` | Reusable UI with no dependency on garden models or services |
| `PalmOilFarmer/DesignSystem/Styles` | Button styles and shared presentation modifiers |
| `PalmOilFarmer/DesignSystem/Catalog` | Light, dark, and accessibility-size component previews |
| `PalmOilFarmer/Features/Gardens/Models` | Shared garden values, boundary geometry, display metrics |
| `PalmOilFarmer/Features/Gardens/Data` | Store, JSON persistence, location access, MapKit search, photo metadata |
| `PalmOilFarmer/Features/Gardens/Components` | Shared UI that understands gardens or maps |
| Other Gardens subfolders | Screens and helpers for List, Registration, Mapping, Profile, History, Review, Recommendations |
| `PalmOilFarmer/PreviewSupport` | Debug fixtures and reference-screen compositions |
| `PalmOilFarmerTests` | Swift Testing checks for persistence, validation, and geometry |

## Rules for changes

- Keep transient UI state in the view. `GardenStore` owns saved gardens; profile views receive the latest value from their parent. Editors own local drafts and publish them only after a successful save.
- A profile's `onUpdate` must update the parent's source of truth. Static reference previews intentionally use fixed input; use a stateful parent for interactive editing previews.
- Put calculations and validation in value types. Add a feature model only when orchestration becomes substantial; there is no mandatory ViewModel per screen.
- Keep framework access at the data boundary. `LocationSearchView` accepts a search closure for deterministic results. Existing `initialResults` is a convenience for fixed reference previews.
- Design system components must not depend on `Garden`, `GardenStore`, or preview fixtures. `GardenPickerField` currently has a historical name but takes only generic labels, values, and content.
- Prefer semantic system typography for text. Use shared tokens for repeated visual roles; illustration coordinates and map dimensions can remain local constants.
- Keep small, closely related types together. Extract a type when its name or responsibility deserves a discoverable file.
- Keep JSON keys and enum raw values compatible with existing `gardens.json`. Changing persisted types requires an explicit migration and compatibility tests.
- Add waypoint work under Mapping while it is garden-specific. Promote it to a separate feature only when it gains independent workflows.

## Verification

Open `PalmOilFarmer.xcodeproj` and build the `PalmOilFarmer` scheme. Run its `PalmOilFarmerTests` test target on an iOS simulator with Product > Test. Tests use unique temporary directories, never the user's gardens file.

Open `DesignSystemCatalog.swift` in Canvas to inspect shared controls. Before merging UI changes, check light/dark appearance, long labels, larger Dynamic Type, Reduce Motion, and Reduce Transparency. For navigation or save-flow changes, also exercise registration, editing, cancellation, and deletion in the simulator. Unit tests do not replace these UI checks.

## Deliberate limits

- Persistence is still synchronous and atomic. The extracted `GardenPersistence` isolates the file format, but does not claim a performance improvement. Move I/O off the main actor when measurement warrants it; serialize writes and preserve save-failure behavior when making that change.
- The refactor retains existing layouts and custom glass appearance. Semantic typography is introduced in shared form controls; fixed-size typography elsewhere still needs a dedicated visual/accessibility review.
- Reference layout variants remain supported in the profile. They have not been removed or redesigned.
- No database, dependency-injection framework, or extra production modules are required at this stage. Profile performance before adding caching or changing storage.

## Apple references

- [Model data and state ownership](https://developer.apple.com/documentation/swiftui/model-data)
- [Managing model data with Observation](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Dynamic text styles](https://developer.apple.com/documentation/swiftui/font/textstyle)
- [Swift Testing](https://developer.apple.com/documentation/testing)

The folder layout is a project convention, not an Apple-mandated architecture.
