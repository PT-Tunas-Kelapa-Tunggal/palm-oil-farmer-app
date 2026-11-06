# GardenProfile

The interactive app and FindingWaypoint use `GardenProfileScreen` with a flow created by `GardenProfileFactory` in `App/ProfileComposition.swift`.

- `GardenProfileContentView` renders the main page and emits actions. It does not present sheets.
- `GardenProfileCoordinator` owns sheet identity, pending transitions, and navigation. A replacement sheet opens after the previous sheet finishes dismissing. Closing the profile invalidates pending transitions.
- `GardenProfileViewModel` writes against the latest garden in the shared source. The combined editor saves harvest, fertilization frequency, and fertilizer records in one update.
- `Editor/` owns editable drafts, typed keyboard focus, validation messages, and form components.
- `Summary/` renders saved records, without editor state.
- `Review/` owns review information and fetched review presentation. A new submission invalidates older pending fetches.
- `Components/` contains shared profile visuals and semantic surface colors.

## Custom NPK

`FertilizerType.npk` identifies the selection independently of its display label. The catalogue keeps persisted names separate from labels. Records continue using the existing Codable format; no destructive migration is performed.

`NPKCompositionInputView` owns the four percentage inputs. It uses four columns normally and one column at accessibility text sizes. Layout changes belong here, not in persistence or the coordinator.

N, P, and K must be explicitly entered. Magnesium is optional and saves as zero when omitted. All values must be finite and between 0 and 100, with a total greater than zero and at most 100. Dose must be finite and greater than zero.

`FertilizerInputDraft` preserves record identity and hidden bag metadata. It recognizes numeric legacy names such as `NPK 15-15-15` and `NPK 15-15-15-2`; existing structured composition takes precedence. Unrecognized names and their existing composition remain intact.

## Historical compatibility

`GardenProfileReferenceView` and the older chart, metrics, and progress layouts live in `PreviewSupport/ReferenceScreens/GardenProfileReferences`. Their names end in `ReferenceView`, and the files are compiled only in DEBUG.

The separate fertilizer/harvest editors, their route cases, factories, and `App/LegacyProfile` have been removed. The reference gallery and integration tests use the combined profile editor. Legacy persisted records are still supported by `FertilizerInputDraft`; keeping data compatibility does not require keeping the old UI.

## Changing the design

- Card appearance: `FertilizerInputCard` and the shared style.
- Nutrient arrangement: `NPKCompositionInputView`.
- Form arrangement: `GardenProfileEditorView`, keeping its single view model and draft state.
- Sheet versus navigation presentation: the screen and coordinator.
- Domain data or nutrient additions: update the domain, draft, mappings, and round-trip tests together.

The profile readiness rule intentionally remains compatible with existing saved gardens. Stricter input validation applies when saving the combined form.

## Names and canvas previews

- `Screen` owns navigation and presentation; `ContentView` owns page layout.
- `EditorView` is an editable form; `InputCard` / `InputView` accept bindings.
- `SummaryView` / `SummaryCard` / `SummaryRow` render saved data.
- Each reusable component has a matching filename. There is no catch-all components file.
- Each of the 18 production SwiftUI view files in GardenProfile includes its own `#Preview`; there are 26 preview configurations.
- `GardenProfileScreen.swift` provides two interactive canvases: an incomplete garden and a complete garden. Use these to exercise the editor, summary, and review transitions.
- `GardenProfileCanvasFixtures` uses an in-memory SwiftData container and an in-memory review repository. Canvas actions never touch saved gardens or CloudKit.
- Drafts, view models, validation, styles, flow, and coordinator have no standalone visual canvas. Unit and integration tests cover their behavior.
