# Home — Coded HI-FID

Reference inspected through Sketch MCP on 9 November 2026 before implementation. No computer-use tools were used.

Document: `00693CBB-7D99-4FC6-B58D-B562D43CDC78`; page: `07FFBFBD-9CC4-426D-BDD2-1523AA380933`. Main Home frame: `59A416E7-3109-47E6-AC67-5756F7DD4257`.

Inspected the Home screenshot and layer tree, the shared status/schedule card sources, and all nine card-state screenshots: before period, next period, waiting for fertilizer, fertilizer ready, year completed, downloading, ready to download, in review, and profile incomplete.

## Layout and data

- Populated Home places registration in a 44 pt plus button beside Kebun. Empty Home retains its registration CTA.
- Cards use a 200 pt map, 28 pt bold garden name, green metric icons, two metric columns, a separator, and a status row. Status cards follow the reference's 367 pt default height; schedule cards follow its 386 pt height. Content expands for long names and accessibility text.
- Incomplete and ready profiles now show their respective action rows. Review visit text uses the garden's actual visit date when available. Results use download/view wording based on stored status.
- A supplied fertilizer schedule renders in the inset green panel. `GardenListContent.fertilizerSchedules` accepts these labels by garden ID. The current domain/service does not supply a dated fertilizer schedule or review-download progress, so production does not invent the reference's countdowns or 40% progress. Existing map-download cards represent a different operation and retain their current behavior.
- The optional developer filter defaults to off. Previously saved developer preferences remain honored.
- `HomeReferenceMap` is a Sketch export used by visual tests, while production retains live garden maps.

## Verification

Simulator build and the full unit suite pass. The opt-in `GardenHomeVisualTests` audit captures populated Home, dark mode, accessibility text, empty Home, incomplete card, and ready card. Rendered output was compared with Sketch, followed by corrections to card heights and icon sizing.

Enable `HOME_VISUAL_AUDIT=1` in the test runner environment to repeat the audit. Images are kept as XCTest attachments and in the test host's temporary `home-hifid-audit` directory. System status-bar chrome is excluded from these view renders. Native glass and live map imagery can differ from Sketch.
