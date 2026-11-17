# Garden profile — Coded HI-FID

Implemented against the open Sketch document on 9 November 2026, through Sketch MCP only. No computer-use tools were used.

Reference document: `00693CBB-7D99-4FC6-B58D-B562D43CDC78`; page: `07FFBFBD-9CC4-426D-BDD2-1523AA380933` (`Coded HI-FID `).

## Reference screens

| State | Sketch frame |
| --- | --- |
| Missing history | `A77DB2AE-1376-472E-813D-6A101C69AD97` |
| Filled editor | `9B977A12-8C09-4EE3-9078-02F6CB69A7BD` |
| Fertilizer picker | `7A196FA5-87C1-4485-857B-522350D5CDB9` |
| Profile saved | `3CDEA465-F836-4FA5-8A47-AB878B9AABEF` |
| Complete | `F729E35F-D263-48B8-86DB-587F9CC6ADD3` |
| Summary | `004B389C-ABE8-4DF5-BE1C-F5A214C0DF04` |
| Review explanation | `77EDDDC3-F3BC-4F82-B395-07CDAFBDC64C` |

## Implementation

- Shared map header, visible overflow menu, combined metrics card, green actions, completion explanation and Data Kebun rows follow the current reference.
- The editor groups harvest fields, annual fertilization frequency, fertilizer selection, composition, and dosage into the reference's cards. The native picker preserves unfamiliar existing fertilizer selections.
- The summary is a pushed NavigationStack page, with Back returning to garden detail. Its edit sheet belongs to that page, so saving or cancelling leaves the summary visible.
- The summary contains four metric tiles, fertilizer composition badges, dose rows, and a last-updated subtitle. Legacy bag metadata remains visible when present.
- `profileUpdatedAt` is optional for older records. Successful local profile edits persist the timestamp through Garden Codable and SwiftData; details edits preserve it. Remote review records that do not supply a profile-edit timestamp omit that date.
- Only the current profile editor can trigger the saved highlight. Failed saves and unrelated sheets do not trigger it.
- The review introduction uses illustrations exported from Sketch. “Jangan tampilkan lagi” is persisted on the device and skips the introduction on subsequent application actions; the information link still opens it.
- The seedling icon is a template PDF exported from Sketch. `ProfileHiFiMap` is used only by isolated preview fixtures; production maps still show the actual garden boundary.

## Verification

- Simulator build succeeds.
- 188 Swift Testing tests pass, including the saved-state guard and profile timestamp persistence checks.
- An opt-in XCTest render audit captures missing history, complete, saved, editor, summary, information, dark detail, and accessibility-size editor states. Repeated captures were inspected after corrections to spacing, column widths, typography, icons, and dark contrast.
- Audit images use 402 pt width and full reference content heights. The audit renders production SwiftUI views in a hosting controller without computer UI automation. It excludes system status-bar chrome; long screens scroll on a physical-size viewport.
- Native picker opening, sheet gestures, and a device-driven end-to-end interaction were not exercised. Native glass, font rasterization, live map imagery, and system chrome can differ from static Sketch exports; this is not a claim of zero pixel difference.

To repeat the visual audit, enable `PROFILE_VISUAL_AUDIT=1` in the test runner environment and run `GardenProfileVisualTests`. Captures are retained as XCTest attachments and written to the test host's temporary `profile-hifid-audit` directory. Without that variable, the visual audit skips itself.
