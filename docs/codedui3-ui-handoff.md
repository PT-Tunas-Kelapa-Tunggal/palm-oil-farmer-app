# CodedUI3 garden UI handoff

Reference: `KROPS` → `CodedUI3` in Sketch. Branch: `ui/codedui3-garden-flows`.

## Scope and ownership

This change updates garden registration, location guidance/search, boundary controls, garden details/profile, history forms, and the review request screens. The existing status timeline already matches the reference and is retained.

`Features/Gardens/Recommendations` and `Features/FindingWaypoint` are excluded: the Hasil Peninjauan flow belongs to another contributor. No shared theme tokens or global button styles were changed. `GardenFlowComponents.swift` holds the neutral actions, surfaces, and history header used by this feature only.

There are no changes to data models, GardenStore, CloudKit repositories, DTOs, domain mapping, entitlements, or backend contracts. Existing save/submit callbacks and their failure handling remain in place. The only new persisted preference is the UI-only photo-tip dismissal key `garden.location.hasSeenPhotoTip`.

## Files to review by feature

| Feature | Main files |
| --- | --- |
| Shared garden UI | `Features/Gardens/Components/GardenFlowComponents.swift` |
| Empty garden list | `Features/Gardens/List/GardenListView.swift`, `GardenOverviewIllustration.swift` |
| Registration and mapping | `Registration/RegistrationIntroView.swift`, `LocationSearchView.swift`, `GardenDetailsView.swift`, `Mapping/GardenBoundaryView.swift`, `BoundaryEditorLayout.swift`, `App/ContentView.swift` |
| Profile and history | `Profile/GardenProfileView.swift`, `GardenProfileGuideView.swift`, `GardenSummaryView.swift`, `Components/MapHeroView.swift`, `History/GardenHistoryEditors.swift`, `GardenHistoryViews.swift` |
| Review request | `Review/ReviewRequestView.swift`, `ReviewContactFormView.swift` |

## Presentation flow

- Registration shows location guidance before search. The search toolbar exposes the camera album and a dismissible photo tip.
- Photo locations are confirmed first. Boundary guidance appears on the map before drawing begins. Existing point movement, validation, undo, clear, recenter, and draft saving remain available.
- Saving a garden opens its profile after the mapping presentation closes. Incomplete profiles offer a guide with “Lengkapi sekarang” and “Lakukan nanti”.
- Saving fertilizer history opens harvest history after the fertilizer sheet closes. The harvest back action returns to fertilizer history. History saves still use the existing callbacks; each successfully saved step is persisted independently.
- Completing a previously incomplete profile offers the ready-for-review prompt. Submitting a review still uses the existing contact validation, consent, and async submission. The information screen leads directly to that contact form.

## Deliberate differences requiring a separate data contract change

The new Sketch fertilizer form includes annual application frequency and N/P/K/Mg composition. `FertilizerRecord` currently only stores name, bag weight, bag count, and dose per tree. Frequency and composition inputs have **not** been added, because their values could not be saved or sent by the existing contract. Bag weight and bag count remain editable and required, including when editing an existing record. No placeholder values are submitted.

The new Sketch harvest label describes monthly weight. The current `HarvestRecord.latestWeightKg` represents weight per harvest. The form and history card therefore retain the explicit label **Rata-rata berat per panen**, without reinterpreting or converting stored data. New forms require an entered positive weight rather than silently saving the former 450 kg default.

Resolve these two contract differences with the backend owner before adding the corresponding design fields or changing units. They are intentionally outside this UI change.

## Assets

Two new assets are scoped to CodedUI3; existing reference-map assets remain untouched:

- `CodedUI3LocationGuide`: exported at 2× from Sketch layer `2B2A48EB-4C25-45EB-AA5F-AA8E17738AB3`.
- `CodedUI3ReviewDrone`: template vector PDF exported from layer `D863ECE0-D64C-4898-BB8D-195DC6210019`.

Other app maps continue to render live coordinates through the existing MapKit views. Existing grayscale images in profile/data previews are preview fixtures, not replacement map data.

## Validation

- Xcode BuildProject succeeds.
- All 18 existing Swift Testing tests pass, including persistence, legacy decoding, invalid fertilizer values, mapping geometry, and review mapping.
- Xcode previews inspected: location guide, photo tip/search, boundary layout, garden details, completed profile, profile guide, fertilizer form, harvest form, and review information. Location guidance and harvest controls were also rendered at Dynamic Type AX 2.
- Backend/data/recommendation/waypoint paths were checked for unintended diffs; none were present.
- Full tap-through smoke testing remains a manual check. The device-interaction tool required a device-interaction skill that was not available in this session; its session was closed without performing interactions.

Suggested smoke check: register a garden → find location → draw and confirm boundary → save details → complete fertilizer and harvest history → open review information → return from contact form → reopen the garden and confirm saved history. Also check cancel, invalid values, and failed-save behavior; do not submit a real review just to verify UI.
