# CodedUI3 garden flows and fertilizer contract

Reference: `KROPS` → `CodedUI3` in Sketch. Branch: `ui/codedui3-garden-flows`.

## Scope and ownership

Garden registration, location guidance/search, boundary controls, garden details/profile, history forms, and review request screens follow CodedUI3. The existing status timeline is retained.

`Features/Gardens/Recommendations` and `Features/FindingWaypoint` are excluded: Hasil Peninjauan belongs to another contributor. Global theme tokens and button styles are unchanged. `GardenFlowComponents.swift` scopes the new neutral styling to garden setup.

The fertilizer data contract is updated with the user's authorization to support the current form. Changes are limited to fertilizer values, their persistence/mapping, and backward compatibility. CloudKit record types, field names, permissions, result data, and review lifecycle are unchanged.

## Files to review by feature

| Feature | Main files |
| --- | --- |
| Garden UI components | `Features/Gardens/Components/GardenFlowComponents.swift` |
| Garden list | `Features/Gardens/List/GardenListView.swift`, `GardenOverviewIllustration.swift` |
| Registration and mapping | `Registration/RegistrationIntroView.swift`, `LocationSearchView.swift`, `GardenDetailsView.swift`, `Mapping/GardenBoundaryView.swift`, `BoundaryEditorLayout.swift`, `App/ContentView.swift` |
| Profile and history | `Profile/GardenProfileView.swift`, `GardenProfileGuideView.swift`, `GardenSummaryView.swift`, `Components/MapHeroView.swift`, `History/GardenHistoryEditors.swift`, `FertilizerCompositionFields.swift`, `FertilizerDraft.swift` |
| Fertilizer persistence/payload | `Models/Garden.swift`, `FertilizerComposition.swift`, `Data/DraftPlantationRequest.swift`, `GardenStore.swift`, `Review/Domain/PlantationReviewModels.swift`, `Review/Data/PlantationReviewDTOs.swift`, `PlantationDomainMapper.swift` |
| Review request UI | `Review/ReviewRequestView.swift`, `ReviewContactFormView.swift` |

## Presentation flow

- Location guidance precedes search. A toolbar action opens the camera album; the photo tip can be dismissed.
- Photo locations are confirmed before boundary guidance. Point movement, geometry validation, undo, clear, recenter, and draft saving remain available.
- Confirmation and boundary-guide cards sit 8 pt from the physical bottom edge. Their content can scroll when text does not fit.
- A newly saved garden opens its profile after the map closes. Incomplete profiles offer the profile guide.
- Saving fertilizer history opens harvest history after the fertilizer sheet closes. Back from harvest returns to fertilizer. Each successfully saved step persists independently.
- Completing the profile offers the ready-for-review prompt. Review requests retain contact validation, consent, and async submission.

## Current fertilizer contract

The form collects annual application frequency, fertilizer type, dose per tree, and N/P/K/Mg percentages for NPK. Bag inputs are removed. New records save without fabricated bag values.

- `Garden.fertilizationFrequencyPerYear` persists as an optional SwiftData attribute, and maps to `AgronomicProfile.fertilizationFrequencyPerYear`.
- `FertilizerRecord.composition` is optional for legacy/non-NPK records. New NPK entries require valid percentages. Blank magnesium becomes zero on save.
- Composition values must be finite, individually within 0–100%, and total more than zero but no more than 100%.
- Dose must be finite and positive.
- Legacy bag weight/count are optional. Existing values are preserved when present; new records omit them.
- Both submission paths (GardenStore and the profile fallback) include frequency and composition.

The existing CloudKit `agronomicJSON` string carries the new fields. No new CloudKit fields or record types are introduced. Example JSON for the current approach:

```json
{
  "year": 2012,
  "soil": "Mineral",
  "fertilizationFrequencyPerYear": 2,
  "fertilizers": [
    {
      "id": "<record UUID>",
      "name": "NPK",
      "dosePerTree": 0.5,
      "composition": {
        "nitrogen": 15,
        "phosphorus": 15,
        "potassium": 15,
        "magnesium": 0
      }
    },
    {
      "id": "<record UUID>",
      "name": "Dolomit",
      "dosePerTree": 0.5
    }
  ]
}
```

Consumers of this JSON must accept missing `bagKg`/`bags`, read `fertilizationFrequencyPerYear`, and read the optional `composition` object. Legacy payloads lacking the new keys still decode; their original bag values remain available. The CloudKit adapter continues transporting the same `agronomicJSON` field.

## Compatibility and prior local values

The earlier UI stored frequency/composition separately in UserDefaults. `LocalFertilizerFormStore` remains as a migration reader. Local and remote gardens merge these older device-only values only when their corresponding persisted fields are absent. Existing synchronized values take precedence. Legacy NPK metadata is never applied to a fertilizer whose type has changed away from NPK.

Reopening the editor also loads the earlier values if needed. Successful saves write frequency/composition through GardenStore, then remove the old device-only entry. New edits no longer rely on the separate UserDefaults store. Cancel and failed save leave the old values intact.

The harvest unit remains weight **per harvest**, matching the current HarvestRecord contract. Monthly harvest-weight semantics are outside this change.

## Assets

- `CodedUI3LocationGuide`: 2× export of Sketch layer `2B2A48EB-4C25-45EB-AA5F-AA8E17738AB3`.
- `CodedUI3ReviewDrone`: template vector PDF of layer `D863ECE0-D64C-4898-BB8D-195DC6210019`.

Live maps continue using the existing MapKit coordinates. Grayscale profile/data preview images are existing fixtures.

## Validation

- Xcode build succeeds.
- All 27 Swift Testing tests pass. Coverage includes new records without bags, valid/invalid compositions, local add/update/reload, current JSON keys, CKRecord encode/decode round trip, remote-to-garden mapping, legacy JSON decoding, and prior device-only value migration.
- Payload tests use in-memory CKRecords; they do not submit a live CloudKit review.
- Main form previews and large-text composition layouts were inspected. The new form preview uses records without bag values.
- Hasil Peninjauan/recommendation/waypoint files remain unchanged.
- Full interaction smoke testing remains manual: the device-interaction skill required by the runtime tool was unavailable in this session. Its session was closed without interactions.

Suggested smoke check: register a garden → locate and draw boundary → save details → add NPK and Dolomit without bag data → enter frequency/composition/dose → continue to harvest → reopen history and confirm values. Also check cancel, invalid percentages, and failed-save behavior. Coordinate a real review submission with the backend owner when checking the live server.
