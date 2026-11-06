# COdedUI5 implementation map

Reference: Sketch document KROPS, page `COdedUI5` (`5AABA032-5113-4A5B-AB55-227297227C21`).

The page contains 17 screen frames and one section heading. Each screen was inspected through its layer tree and screenshot. Production uses live MapKit imagery and the user's photo library. Sketch satellite images in the preview catalog are comparison fixtures; the heatmap illustration and discovery photograph are production artwork exported from Sketch.

| Preview | Sketch frame | Frame ID | Production presentation |
| --- | --- | --- | --- |
| 01 | Kebun / Empty | 4449FFAD-D08D-44D1-AE5C-3B5C4D4CCC06 | GardenRegistrationEmptyState, GardenListContent |
| 02 | Panduan Temukan Lokasi | 8BC03258-A838-4291-A76C-EF831F2B3B61 | LocationDiscoveryGuide |
| 03 | Cari Alamat / Filled | 8C57D0CA-45BF-44BE-98A1-FBF43C22B270 | LocationSearchContent with results |
| 04 | Cari Alamat / GPS | 483BFEA8-5B8D-4E06-AD9A-FFAEF0CA90A2 | LocationSearchContent, current-location action |
| 05 | Cari Alamat / Foto | 140B0576-59A9-4E67-A900-F2333A628480 | LocationSearchContent, photo action |
| 06 | Pilih Foto Galeri / Default | FB488051-9D90-4BA5-A3D7-0CF589366E9E | GardenPhotoPickerView gallery |
| 07 | Pilih Foto Galeri / Selected | 44E24E29-83EF-453A-B061-740A14CE1DDE | PhotoSelectionContent, PhotoLocationCard |
| 08 | Konfirmasi Lokasi / Search | 4E34B34A-7D9A-46EF-B539-D555AD04AF30 | LocationConfirmationPanel |
| 09 | Konfirmasi Lokasi / GPS | C0397031-A78D-455B-919F-67B8CAD2906D | LocationConfirmationPanel, UserAnnotation |
| 10 | Konfirmasi Lokasi / Photo | C8EB8CAC-3813-4897-BA1F-490D7784BA61 | LocationConfirmationPanel, PhotoLocationMarker |
| 11 | Panduan Petakan Batas | 27A0E665-D589-4200-9896-48BFA3175522 | BoundaryMappingGuide, BoundaryMappingGuideOverlay |
| 12 | Buat Batas / Default | 80C5AB56-014F-4104-852A-D89FD1DF3753 | BoundaryEditorLayout, empty boundary |
| 13 | Buat Batas / Drawing | 21794455-0800-41B2-9E76-4BEC8E286E76 | BoundaryEditorLayout, partial boundary |
| 14 | Buat Batas / Closed | 3024F941-0DB3-447F-94D6-1A333ED9E35A | BoundaryEditorLayout, valid boundary |
| 15 | Data Kebun | 9515AE45-8816-4FDC-822E-8FAA5FC235FD | GardenDetailsView, RegistrationFormField |
| 16 | Pilih Tahun Tanam | 0E72C00A-ACC6-46D4-9E96-C304F67DADF4 | PlantingDatePickerView |
| 17 | Pilih Jenis Tanah | 5F6F860D-F857-449E-A1ED-C53EEC48E889 | GardenDetailsView soil Menu |

## Where to change the design

- `Features/GardenRegistration/RegistrationDesign.swift`: background/surface/action color roles, radii, 48 pt icon controls, 72 pt headers, action buttons, search rows, and floating map panels.
- `RegistrationIntroView.swift`: location-discovery content and illustration layout.
- `LocationSearchView.swift`: search field, results, alternative methods. `LocationSearchContent` has no service work, allowing deterministic previews.
- `Mapping/LocationConfirmationPanel.swift`: location details, mapping instructions, instructional overlay and boundary markers.
- `Mapping/BoundaryEditorLayout.swift`: top measurements and bottom editing controls.
- `GardenDetailsView.swift`: map, metrics and grouped fields. Soil selection uses a native Menu; the supplied Sketch frame shows its closed state.
- `PreviewSupport/ReferenceScreens/CodedUI5Previews.swift`: the 17 comparison states. Keep future references here separate from the older CodedUIFrameCatalog.

## Behavior and accessibility

New registrations follow discovery → search/GPS/photo → confirm location → boundary guide → map editing → details → save. Existing saved drafts open map editing directly. Photo selection shows the image and resolved location before its confirmation action. Returning to search from a drawn boundary requires an explicit discard action.

Typography uses semantic SwiftUI fonts. Search results and form fields grow vertically. Metric rows stack at accessibility sizes; floating map panels scroll at accessibility sizes. The planting-date wheels become menu controls at accessibility sizes. System keyboard, permissions, menu rendering, and Liquid Glass rendering are supplied by the current OS; map labels and imagery depend on the actual location.

## Verification

Use Xcode's BuildProject and RunAllTests. Render the 17 previews at their baseline dimensions, then the discovery, search, map controls, details and planting-date states at AX5. Baseline visual fidelity is checked visually at the frame dimensions; accessibility sizes intentionally reflow.

Verified on 2026-11-06 with the iPhone 18 Pro / iOS 27.0 simulator:

- BuildProject succeeded with no errors.
- RunAllTests: 162 passed, zero failures.
- The three RegistrationDesignFlowTests passed again after the final photo-preview cancellation changes.
- All 17 baseline preview states rendered. The discovery, search, mapping controls, details, and planting-date controls also rendered at AX5.
- AX5 follow-up fixes keep header symbols within their touch targets, remove decorative action icons where they crowd text, and stack the planting-date actions.
- git diff --check passed.

Native Liquid Glass, keyboard, wheel selection backgrounds, and map content may differ from the static Sketch artwork across OS releases and live data. The implementation preserves native interactions and Dynamic Type reflow.

Backgrounds now use semantic systemGroupedBackground and secondarySystemGroupedBackground rather than matching the literal Sketch #F4F5F6 color. These system roles take precedence over exact color matching.

## Adaptive appearance follow-up

Registration actions and neutral map markers now use the semantic label/systemBackground color pair. Panels and map headers inherit the user's appearance instead of overriding colorScheme. The map header uses system material so its text remains legible in both appearances.

Location rows scale their icon containers with ScaledMetric and stack their content at accessibility sizes. Discovery-guide icons follow the same policy. Map panels measure their content and cap their scroll viewport at 45 percent of the nearest container's available height instead of fixing it to 300 points. In landscape at accessibility sizes, measurements move into the scrollable action panel to preserve visible map space. The repeated map-name label is omitted at accessibility sizes; the full name remains in the panel and VoiceOver label.

Validated with BuildProject and rendered light/dark, AX5, Increased Contrast, and landscape previews. This follow-up changes presentation only; navigation and persistence behavior are unchanged. Fixed decorative geometry and touch-target dimensions remain intentional design values.
