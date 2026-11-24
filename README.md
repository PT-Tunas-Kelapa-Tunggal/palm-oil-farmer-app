# Palm Oil Farmer

An iOS app for oil palm farmers, built with SwiftUI and organized by feature, with one app target and a Swift Testing target.
The production flow from Home through successful review submission now uses Clean Architecture boundaries with manual MVVM-C and SwiftUI NavigationStack. Parts 2–4 organized files, separated Foundation-only Domain values/rules, and composed data dependencies manually. Parts 5–8 introduced the home, registration, mapping, profile, and history flows. Part 9 completes consent/contact/submission and integration checks. Existing status/results/guidance and reference/experiment implementations retain their compatibility entry points.
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


## GitHub Actions and TestFlight

PRs into `develop` and `main` build the unsigned iOS app and run the CloudKit
contract tests. Pushes to `develop` compare staging Development and pushes to
`main` compare production Production. Release tags verify the partition before
signing.

| Tag example | Branch | CloudKit target | Distribution |
| --- | --- | --- | --- |
| `beta-v11.15.119-1` | `develop` | Staging / Production | TestFlight Internal Only on the staging app record |
| `release-v11.15.119-1` | `main` | Production / Production | Processed upload for manual selection for external TestFlight or App Review |

Use `-2`, `-3`, and so on to create more candidates for the same marketing
version. The workflow validates all three version components and checks that
the tag points to a commit on the indicated branch.

Apple restricts beta builds exported as **TestFlight Internal Only** to internal
tester groups. CI verifies the **Internal Only** audience in App Store Connect
before assigning the build to the staging group.

### Repository-level Actions variable

In the iOS repository, open **Settings → Secrets and variables → Actions →
Variables** and add the shared Team ID.

- **`APPLE_TEAM_ID`**. Sign in to your Apple Developer account, open
  **Membership details**, and copy the 10-character Team ID. Both builds
  and CloudKit checks share this value. [Apple Team ID](https://developer.apple.com/help/glossary/team-id)

### GitHub environments and allowed refs

Under **Settings → Environments**, create `staging` and `production`. Open
each environment, choose **Selected branches and tags** under **Deployment
branches and tags**, and click **Add deployment branch or tag rule**. Add
one rule with **Ref type → Branch** and one with **Ref type → Tag** using
the patterns below. These rules control which refs can use the
environment’s credentials. [GitHub environment setup](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments#creating-an-environment)

| Environment | Branch rule | Tag rule |
| --- | --- | --- |
| `staging` | `develop` | `beta-v*` |
| `production` | `main` | `release-v*` |

Branch pushes use the selected environment for the live CloudKit schema check.
Release tags use that same environment for the schema check and, after it
passes, for signing and uploading.

### Environment variables

Open **Settings → Environments → staging** or **production**, then add the
applicable entries under **Environment variables**.

- **`CLOUDKIT_CONTAINER_ID`**. In **Apple Developer → Certificates, Identifiers
  & Profiles → Identifiers → iCloud Containers**, copy the full `iCloud.` ID
  assigned to the PalmOilFarmer App ID for that environment. Use distinct
  containers for staging and production. The schema check and signed build use
  this value from the same environment. [Create an iCloud container](https://developer.apple.com/help/account/identifiers/create-an-icloud-container), [Assign an iCloud container](https://developer.apple.com/help/account/identifiers/enable-app-capabilities#Enable-iCloud)
- **`IOS_BUNDLE_ID`**. In **App Store Connect → Apps**, open the app record for
  that environment and copy the **Bundle ID** under **General → App Information**.
  Use separate app records and bundle IDs for staging and production. To create
  a staging record, first register its explicit App ID in Apple Developer.
  [Register an App ID](https://developer.apple.com/help/account/identifiers/register-an-app-id/), [Create an app record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
- **`IOS_BUILD_NUMBER_OFFSET`**. Set separately in both environments. Use
  `0` for a fresh App Store Connect record. For an existing record, find its
  highest build number under **TestFlight**. To start at the next major build
  number, multiply the first component of the highest build by `9900`.
  For a highest build of `45` or `45.8.2`, enter `445500`. At workflow run
  `1` that yields `46.0.1`. Keep each environment’s offset stable across
  retries and later tags.
- **`TESTFLIGHT_INTERNAL_GROUP`**. Set in `staging` only. Open the staging
  app in **App Store Connect → TestFlight → Internal Testing**, create an
  internal group if needed, and copy its exact name. [Apple internal testing setup](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/)

If you already configured separate repository variables for the staging and
production IDs, copy those values into the corresponding environment entries
and remove the four old repository variables once the updated workflow is live.

### Environment secrets

Add each secret under **Environment secrets** in both `staging` and
`production`. For a name ending in `_BASE64`, replace `/path/to/file` with the
credential file’s path, run the command, then paste into the matching secret.

```sh
openssl base64 -A -in "/path/to/file" | pbcopy
```

- **`CLOUDKIT_MANAGEMENT_TOKEN`**. Open **CloudKit Console → Settings** for
  your account and generate a **Management Token**. Copy the token as issued
  into the environment for the container it can export. You can use the same
  value in both environments if it can export both containers. [Apple cktool setup](https://developer.apple.com/icloud/ck-tool/)
- **`IOS_DISTRIBUTION_P12_BASE64`**. In **Xcode → Settings → Accounts →
  [your team] → Manage Certificates**, select the **Apple Distribution**
  identity and export it as a password-protected `.p12`. Encode that file
  with the command above. The identity must match the certificate chosen
  for that environment’s provisioning profile. Reuse the same file if both
  profiles use the same identity. [Export a signing identity](https://developer.apple.com/documentation/xcode/sharing-your-teams-signing-certificates)
- **`IOS_DISTRIBUTION_P12_PASSWORD`**. Enter the password you chose when
  exporting that environment’s `.p12`. Use the same password in both
  environments if you reuse the file. [Export a signing identity](https://developer.apple.com/documentation/xcode/sharing-your-teams-signing-certificates)
- **`IOS_PROFILE_BASE64`**. Associate each App ID with its corresponding
  CloudKit container in Apple Developer. Then go to **Certificates,
  Identifiers & Profiles → Profiles → +** and create an **App Store Connect**
  distribution profile using that environment’s App ID and the certificate
  from its `.p12`. Download the `.mobileprovision` and encode it with the
  command above. Create a separate profile for each app. [Enable iCloud](https://developer.apple.com/help/account/identifiers/enable-app-capabilities#Enable-iCloud), [Create an App Store Connect profile](https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile/)
- **`ASC_KEY_ID`**. Go to **App Store Connect → Users and Access →
  Integrations → App Store Connect API → Team Keys**. Create an **App Manager**
  team key for `staging` and a **Developer** team key for `production`.
  Copy the **Key ID** from the corresponding row. Team keys have access
  across apps according to their assigned roles. [Create a team API key](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)
- **`ASC_ISSUER_ID`**. On the same **Integrations** page, copy the
  **Issuer ID** near the top. Use that value in both environments when both
  keys belong to the same App Store Connect team. [Find the Issuer ID](https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests)
- **`ASC_KEY_P8_BASE64`**. In **Team Keys**, download the `.p8` from the
  row for that environment’s `ASC_KEY_ID`. Apple offers the download once.
  Encode the downloaded file with the command above. [Download a team private key](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)

### Protect `develop` and `main`

Create one branch ruleset that requires a pull request and passing CI for
changes to either branch. Before configuring it, get a successful
**Build and test PalmOilFarmer** run on a PR into `develop` or `main`.
GitHub requires a successful run in this repository within the past
seven days for a check to be eligible. [Troubleshoot required checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks)

1. Open **Settings → Rules → Rulesets → New ruleset → New branch ruleset**.
   Name it **Require iOS PR checks** and set **Enforcement status** to **Active**.
2. Under **Target branches → Add a target → Include by pattern**, add
   `develop` and `main` as two separate entries.
3. Leave the **Bypass list** empty to apply the merge requirements to
   everyone, including repository admins.
4. Enable the following rules under **Branch protections**, then click
   **Create**. [Create a GitHub branch ruleset](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository#creating-a-branch-or-tag-ruleset)

| Rule | How to configure it and what it does |
| --- | --- |
| **Require a pull request before merging** | Makes changes go through a PR. Start with **Required approvals** set to `0` for a solo maintainer. Set it to `1` if another reviewer with write access should approve each PR. |
| **Require status checks to pass before merging** | Click **Add checks** and select **Build and test PalmOilFarmer** from the **CI** workflow. Choose **GitHub Actions** as the source if prompted. GitHub waits for the unsigned app build and CloudKit contract tests to pass before allowing a merge. |
| **Block force pushes** | Prevents force pushes from rewriting either protected branch’s history. |
| **Restrict deletions** | Prevents deletion of either protected branch. |

Select only **Build and test PalmOilFarmer** as the required PR check. The
live CloudKit schema job runs on branch pushes and release tags. To
require CI against the latest changes on the target branch, also enable
**Require branches to be up to date before merging** under the status-check
rule. This can require a branch update and another CI run as the target
branch advances. [GitHub rules and check options](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#require-status-checks-to-pass-before-merging)

### Protect iOS release tags

1. Open **Settings → Rules → Rulesets → New ruleset → New tag ruleset**.
   Name it **Restrict iOS release tags** and set **Enforcement status** to
   **Active**.
2. Under **Target tags → Add a target → Include by pattern**, add
   `beta-v*` and `release-v*` as two separate entries.
3. Under **Bypass list → Add bypass**, select the team or role authorized
   to publish releases. Choose **Always allow** for that actor so they can
   push release tags. If repository admins are the intended release
   maintainers, select the **Repository admin** role.
4. Enable the following rules under **Tag protections**, then click
   **Create**. [Create a GitHub tag ruleset](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository#creating-a-branch-or-tag-ruleset)

| Rule | What it does |
| --- | --- |
| **Restrict creations** | Only an actor on the bypass list can create a matching release tag. |
| **Restrict updates** | Only an actor on the bypass list can move an existing release tag to another commit. |
| **Restrict deletions** | Only an actor on the bypass list can delete an existing release tag. |

Use a new candidate suffix when releasing another build for the same
version. The release workflow validates the full tag and checks that the
commit belongs to `develop` for a beta tag or `main` for a release tag.

### CloudKit schema verification

CI compares the selected CloudKit partition with
[`PalmOilFarmer/CloudKitContract/schema.ckdb`](PalmOilFarmer/CloudKitContract/schema.ckdb).
If CI reports drift and the live schema is correct, export that partition
with `cktool export-schema`, review the export, and update the snapshot on
the affected branch. If a release partition is behind, deploy the reviewed
schema from Development to Production in the same container through
CloudKit Console, then rerun the check. [Export a CloudKit schema](https://developer.apple.com/icloud/ck-tool/), [Deploy a CloudKit schema](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema)

For the first release, verify the schema checks and install the staging
build through TestFlight to confirm it can load and submit staging data.

## Where code belongs

| Folder | Responsibility |
| --- | --- |
| `PalmOilFarmer/App` | Entry point, manual dependency composition, top-level navigation, and legacy composition bridges |
| `PalmOilFarmer/App/Navigation` | AppCoordinator, typed root routes, and registration-to-map presentation transitions |
| `PalmOilFarmer/App/State` | Transitional observable GardenStore; consumes Domain contracts without SwiftData or CloudKit types |
| `PalmOilFarmer/DesignSystem/Tokens` | Shared colors, spacing, typography, corner radii, control dimensions |
| `PalmOilFarmer/DesignSystem/Components` | Reusable UI with no dependency on garden models or services |
| `PalmOilFarmer/DesignSystem/Styles` | Button styles and shared presentation modifiers |
| `PalmOilFarmer/DesignSystem/Catalog` | Light, dark, and accessibility-size component previews |
| `PalmOilFarmer/Domain/Gardens` | Foundation-only garden/history values, validation, review projection, and draft/location/photo/authorization contracts |
| `PalmOilFarmer/Domain/Reviews` | Review/contact values, validation, request snapshots, repository/gateway contracts, and SubmitGardenReview use case |
| `PalmOilFarmer/Data/Gardens` | Existing SwiftData draft model and SwiftDataGardenDraftRepository |
| `PalmOilFarmer/Data/Reviews` | CloudKit repository, DTOs, domain mapper, and CKRecord adapter |
| `PalmOilFarmer/Data/Location` | Location authorization, current location, MapKit search, waypoint session, and CoreLocation geometry adapters |
| `PalmOilFarmer/Data/Photos` | Photos authorization, eligible asset lookup, and cancellable thumbnail requests |
| `PalmOilFarmer/Features/GardenList` | Production screen/ViewModel, list data-source contract, presentation values, shared layout, cards, filters, and list illustration |
| `PalmOilFarmer/Features/GardenRegistration` | Guide/location/photo, boundary map and details form ViewModels (no coordinators), and registration write contract |
| `PalmOilFarmer/Features/GardenProfile` | Production profile ViewModel (no coordinator), shared layout, legacy callback entry, summary/progress, and review ViewModel |
| `PalmOilFarmer/Features/GardenHistory` | Fertilizer/harvest ViewModels and editor Coordinator, form drafts, focus identifiers, and history controls/cards |
| `PalmOilFarmer/Features/ReviewRequest` | Program consent and contact ViewModels, typed request Coordinator, and form UI |
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

Domain compiles independently with Foundation. GardenStore consumes `GardenDraftRepository` and `FarmerReviewRepository`; SwiftData fetches and writes belong to Data. `AppDependencies` creates the shared store, review repository, submission use case, and feature factories explicitly. Data does not read AppConfiguration, and the production profile does not name CloudKit's concrete repository. The request-to-Garden projection is a Domain conversion; DTO/CKRecord mapping remains in Data.

The production home uses `GardenListScreen` with `GardenListViewModel`. The ViewModel reads the shared store through the feature's `GardenListDataSource` contract, owns the selected filter, derives the list presentation, and forwards user navigation events. AppCoordinator receives those events and owns the typed NavigationStack path and root modal transitions. ContentView renders the destinations and binds SwiftUI's Back/dismiss behavior to the coordinator. AppDependencies assembles the store, ViewModel, and coordinator without a DI framework. The existing `GardenListView` value/callback API remains for reference screens and the experiment; both entry points use the same layout and presentation rules.

Registration receives a fresh `RegistrationIntroViewModel` from `GardenRegistrationFactory`. LocationSearchViewModel handles the 350 ms search debounce, trimmed queries, stale responses, GPS request state, and existing messages. GardenPhotoPickerViewModel reads Foundation-only photo values; Photos assets and authorization stay in Data. RegistrationIntroViewModel owns guide/search progress, gallery presentation, and the search/photo ViewModels, forwarding the selected location to AppCoordinator only after the gallery closes. AppCoordinator then waits for the registration sheet to close before presenting the map. Thumbnail requests retain the existing 240×240 aspect-fill/opportunistic/network settings, stream encoded PNG updates, and cancel when their consumer terminates.

`GardenMappingFactory` supplies `GardenBoundaryViewModel`, which also owns the details-sheet session, exit dialog, and map outcome, and builds a fresh details ViewModel for each details session. Boundary points, duplicate checks, photo confirmation, validity checks, and location-draft saves belong to the ViewModel. Camera position, marker hit testing, drag offsets, annotation layout, and focus remain in the View. GardenDetailsViewModel validates and builds the existing Garden payload and owns the planting-date sheet. A successful save closes the details sheet before the map closes, and cancelled/replaced editors cannot write through old callbacks. Main registration writes use `GardenRegistrationSaving`, implemented by GardenStore in App, so draft completion, list updates, error policy, and storage remain on the existing path.

`GardenProfileFactory` supplies the production `GardenProfileScreen`. Its ViewModel reads the shared store through `GardenProfileDataSource`, merges each editor's changes into the latest garden, and delegates update/delete to the existing store. The same ViewModel owns editor sessions, deletion confirmation, and handoff to review/status/results screens. History editors keep drafts locally, validate with the existing Domain rules, and publish only after a successful save. Cancelled/replaced sessions reject old writes; duplicate successful saves do not publish twice. `GardenProfileContent` shares the unchanged layout with the existing callback-based GardenProfileView. `GardenProfileReviewViewModel` retains the existing timeline/report/fallback behavior.

`ReviewRequestFactory` builds program-consent and contact ViewModels with a request Coordinator. Each contact route has its own session identity; Back, sheet dismissal, or replacement prevents retired callbacks from changing a new presentation. `SubmitGardenReview` reads the latest garden through `ReviewSubmissionGateway`, requires a complete unsubmitted profile, and blocks simultaneous submissions for the same garden within the shared app instance. GardenStore implements the gateway using its existing submit/promotion/draft-cleanup operation. Confirmed remote success still commits when the caller is cancelled or its screen has closed; only current sessions receive UI completion. Failed requests retain the form and local draft for retry. This guard does not add persistent server idempotency or resolve ambiguous network timeouts.

`App/LegacyComposition.swift` retains the no-argument GardenStore initializer and default review repository. `App/LegacyRegistrationComposition.swift` retains registration/search/photo initializers and fixed-result/search-closure APIs. `App/LegacyMappingComposition.swift`, `App/LegacyHistoryComposition.swift`, and `App/LegacyReviewComposition.swift` retain editor/request callback initializers. The original GardenProfileView callback entry and review wiring remain for reference screens and the team-owned experiment; production uses GardenProfileScreen. Compatibility defaults still use live services where they did before. The main app injects dependencies explicitly; its root preview uses in-memory storage and registration/review/authorization stubs. GardenStore still coordinates shared state and submission side effects. There is still one app module; folder and protocol boundaries are not separate package/target enforcement.

The implementation scope runs from Home through successful review submission. Existing status/results/guidance/experiment implementations remain unchanged. See [the baseline](docs/refactor/baseline.md), [Part 2 results](docs/refactor/part-02-structure.md), [Part 3 verification](docs/refactor/part-03-domain-contracts.md), [Part 4 verification](docs/refactor/part-04-data-composition.md), [Part 5 verification](docs/refactor/part-05-mvvm-coordinator.md), [Part 6 verification](docs/refactor/part-06-location-photo-registration.md), [Part 7 verification](docs/refactor/part-07-mapping-details-drafts.md), [Part 8 verification](docs/refactor/part-08-profile-history.md), and [Part 9 verification](docs/refactor/part-09-review-submission.md). Implementation completion does not replace manual UI, signed Archive, or upgrade testing against the installed TestFlight build.

## Rules for changes

- Keep transient UI state in the view. `GardenStore` owns saved gardens; profile views receive the latest value from their parent. Editors own local drafts and publish them only after a successful save.
- The production list ViewModel owns filter state and emits navigation events; AppCoordinator owns root routes and modal sequencing. Read current shared garden values rather than copying them into another cache. Registration/mapping/details/profile/history/request Coordinators own their feature transitions. Editor writes merge with the latest garden so one editor does not overwrite changes to other fields. Submission uses the shared use case and current route/session guards; keep network completion separate from UI lifetime.
- A profile's `onUpdate` must update the parent's source of truth. Static reference previews intentionally use fixed input; use a stateful parent for interactive editing previews.
- Put calculations and validation in value types. Introduce use cases, ViewModels, and flow Coordinators incrementally; simple controls do not require a ViewModel or Coordinator of their own.
- Keep Domain independent of Data, Features, SharedUI, and Apple UI/location/persistence frameworks. Presentation keeps form drafts and messages; existing input rules live in Domain. Persisted decoding and model fields remain compatible rather than being retroactively rejected by new initializers.
- Assemble live data dependencies in AppDependencies. Tests inject review stubs and use explicit in-memory or temporary-disk containers; they do not select CloudKit defaults. Keep new feature work off the legacy composition bridges.
- Keep location and photo framework access at the data boundary. Views receive flow/ViewModel dependencies; cancellation follows their SwiftUI task lifecycle. Legacy `LocationSearchView` initializers still accept a search closure or fixed `initialResults` for existing reference screens. Inject repository stubs directly for new tests.
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

Open `PalmOilFarmer.xcodeproj` and build the `PalmOilFarmer` scheme. Run its `PalmOilFarmerTests` test target on an iOS simulator with Product > Test. Persistence tests use in-memory and temporary-disk SwiftData containers. Terminal build/test instructions are included in the [Part 2 tutorial](docs/tutorials/part-02-struktur-folder-dan-batas-fitur.md).

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
