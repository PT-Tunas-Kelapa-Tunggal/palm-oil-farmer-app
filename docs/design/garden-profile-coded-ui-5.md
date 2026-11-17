# Garden profile — COdedUI5

Reference inspected on 6 November 2026 in KROPS, page `5AABA032-5113-4A5B-AB55-227297227C21`.
The page now contains the profile flow; the earlier registration reference is recorded separately in `coded-ui-5.md`.

## Screen functions

| Sketch frame | Function | Implementation |
| --- | --- | --- |
| Kebun — `7F672171-CE5B-4CA5-84C5-DEF6F0CDBADE` | Open a saved garden from its satellite card. | Existing GardenList navigation; unsubmitted cards omit the old status pill. Submitted review statuses remain visible. |
| Missing History — `0F4319B7-2B6B-4EB5-A249-B07A220D3D68` | Explain why harvest and fertilizer history are needed; open the combined form. | GardenProfileContent and ProfileCompletionCard. |
| Formulir Profil Kebun — `4E4DAE1D-B571-4EE6-939F-8D18C7DCF602` | Enter monthly harvest frequency and weight, yearly fertilization frequency, fertilizer types, NPK composition and dose per tree. Save the entire draft once. | GardenProfileEditor and GardenProfileEditorViewModel. |
| Fertilizer menu — `A4643EEC-9A1D-4CC8-AA6F-F76730107D42` | Select the fertilizer for an individual card. NPK reveals composition fields. | Native Menu/Picker and ProfileFertilizerCatalogue. Existing names remain selectable. |
| Complete — `F497957A-86D9-4674-AFD3-D402C69A73C5` | Show readiness; open profile summary, inspection information or the existing review request flow. | GardenProfileContent. |
| Profil Kebun — `4CFCFDC4-61B7-4B34-806E-E7FB64725ADF` | Read saved harvest and fertilizer history; pencil reopens the combined editor. | GardenProfileSummaryScreen. |
| Information sheet — `C8AB1376-9EC3-432B-A269-BB447F07A5AB` | Explain field inspection, drone imaging and recommendations. Its CTA hands off to the existing review flow, which retains its consent step. | ProfileReviewInformation. |

All seven screen frames were inspected as layer trees and screenshots before implementation. The separate title/header frame describes the flow, not an app screen.

## Ownership and maintenance

- All former `Features/GardenHistory` files now live in `Features/GardenProfile/History`; the old folder was removed. Existing editor APIs remain for compatibility with reference previews and existing callers/tests. Production profile actions use the combined editor.
- GardenProfileComponents contains the shared header, icon button, primary action, field row, frequency control and section heading. GardenProfileStyle centralizes semantic surface colors.
- GardenProfileContent shares the detail layout between the production coordinator and the callback-based legacy entry point.
- The summary and information sheets queue edit/review actions until their dismissal completes, avoiding overlapping presentations.
- GardenProfileFlow creates the combined editor with the current sheet identity; a dismissed or wrong sheet cannot save.
- GardenProfileEditorViewModel validates every filled fertilizer card before one persistence call. Untouched extra cards are ignored; partly filled cards block saving. Failed writes retain the draft for retry.
- GardenProfileSketchPreviews uses the production views and isolated fixtures. ProfileReferenceSatellite is a map-only Sketch export for reference previews; production uses the garden's live coordinates.

## Data compatibility

- The new form asks for monthly harvest weight. `averageMonthlyWeightKg` stores that value; the existing `latestWeightKg` keeps the per-harvest equivalent for older consumers. Older records without monthly weight display `latestWeightKg × frequencyPerMonth`.
- `fertilizationFrequencyPerYear` is optional for old gardens and is persisted through SwiftData, local Garden Codable storage and review DTO mapping.
- NPK percentages are persisted in FertilizerComposition and carried through the review DTO round trip. Values must be finite, in 0–100%, and total at most 100%.
- New entries do not invent bag weight/count, because the new form does not ask for them. Those fields are optional; old values are preserved and shown in the summary when available.
- Existing `NPK 15-15-15` names are understood by the editor without dropping their old bag metadata.
- Editing garden details preserves the new profile fields.

## Adaptive behavior and verification

- Text uses semantic fonts without a Dynamic Type cap. Accessibility sizes stack field labels/controls and metric tiles, and show nutrient fields in one column.
- Long garden names expand the map header instead of overlapping metric tiles. Editors, summary, information and detail content can scroll.
- Surfaces and action tints use system semantic colors. Light/Dark appearance and Increased Contrast remain system-driven. White map labels and a dark scrim are intentional for satellite readability. Navigation glyph sizes stay bounded inside 44/48 pt touch targets.
- Native Liquid Glass buttons and menus follow the installed OS. Semantic surfaces deliberately replace the static Sketch colors, in line with the requested adaptive appearance. Live satellite images and data differ from reference fixtures.
- Xcode build succeeds. All 167 unit tests pass, including five new GardenProfileDesignTests covering atomic save, retry/validation, expired sessions, legacy metadata and SwiftData/review DTO round trips.
- Rendered and visually inspected the missing-history detail, complete detail, form, summary and information views, plus Dark Mode/AX5/Increased Contrast and landscape samples. Native menu interaction and a full device-driven end-to-end run were not performed; the menu uses the standard SwiftUI Picker/Menu implementation.
