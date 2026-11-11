import SwiftUI

// MARK: - Where is what? (GardenProfile)
//
// Open this file's canvas ("Peta Alur Profil") to see every screen of the feature side by side.
// Every view file below also has its own #Preview next to the code.
//
// Domain/                      (1) GardenProfileDataSource, FertilizerCatalogue (pure Foundation)
// Data/
//   Repositories/  GardenProfileRepository (reads/edits through Core/Gardens)
// Presentation/                GardenProfileCoordinator (sheets + pushes), GardenProfileFlow
//   Overview/
//     Screens/     GardenProfileScreen ........... SCREEN "Profil Kebun"
//     Components/  GardenProfileContentView (layout), GardenMetricsView, GardenProfileCompletionCard
//     ViewModels/  GardenProfileViewModel
//   Summary/
//     Screens/     GardenProfileSummaryView ...... PUSH "Riwayat Panen dan Pemupukan"
//     Components/  FertilizerSummaryCard, HarvestSummaryCard (unused)
//   ProfileEditor/
//     Sheets/      GardenProfileEditorView ....... SHEET "Lengkapi / Ubah Profil"
//     Components/  FertilizerInputCard, NPKCompositionInputView, FrequencyStepper, GardenProfileFieldRow
//     ViewModels/  GardenProfileEditorViewModel, FertilizerInputDraft, GardenProfileEditorField
//   ReviewInformation/
//     Sheets/      GardenReviewInformationView ... SHEET "Peninjauan Kebun"
//     ViewModels/  GardenProfileReviewPresentation (review status/report shown on the profile)
//
// Shared with other features (SharedUI/Components): GardenProfileStyle, GardenProfileHeader,
// GardenProfileIconButton, GardenProfileActionButton, GardenProfileSectionHeader, ProfileSummaryRow.
//
// Screens owned by OTHER features that this profile opens (still referenced directly, to be moved
// behind the flow, docs/ARCHITECTURE.md §7.3): GardenDetailsView (GardenRegistration),
// ReviewRequestView (ReviewRequest), ReviewStatusView (ReviewStatus), FertilizerRecommendationView (Recommendations).
//
// Wiring: App/ProfileComposition (production), PreviewSupport/GardenProfileCanvasFixtures (canvas).

#if DEBUG
private struct ProfileFlowFrame<Content: View>: View {
    let title: String
    let file: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title3.bold())
            Text(file).font(.caption.monospaced()).foregroundStyle(.secondary)
            NavigationStack { content() }
                .frame(width: 402, height: 874)
                .clipShape(RoundedRectangle(cornerRadius: 44))
                .overlay { RoundedRectangle(cornerRadius: 44).stroke(Color(uiColor: .separator)) }
        }
    }
}

#Preview("Peta Alur Profil", traits: .fixedLayout(width: 2700, height: 1000)) {
    ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 40) {
            ProfileFlowFrame(title: "1 · Profil belum lengkap", file: "Overview/Components/GardenProfileContentView") {
                GardenProfileCanvasFixtures.content(complete: false)
            }
            ProfileFlowFrame(title: "2 · Lengkapi profil", file: "ProfileEditor/Sheets/GardenProfileEditorView") {
                GardenProfileEditorView(model: GardenProfileCanvasFixtures.makeEditor(filled: false), onClose: {})
            }
            ProfileFlowFrame(title: "3 · Profil siap ditinjau", file: "Overview/Components/GardenProfileContentView") {
                GardenProfileCanvasFixtures.content(complete: true, justSaved: true)
            }
            ProfileFlowFrame(title: "4 · Riwayat", file: "Summary/Screens/GardenProfileSummaryView") {
                GardenProfileSummaryView(garden: GardenProfileCanvasFixtures.completeGarden, onClose: {}, onEdit: {})
            }
            ProfileFlowFrame(title: "5 · Tentang peninjauan", file: "ReviewInformation/Sheets/GardenReviewInformationView") {
                GardenReviewInformationView(onClose: {}, onApply: {})
            }
        }
        .padding(40)
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#endif
