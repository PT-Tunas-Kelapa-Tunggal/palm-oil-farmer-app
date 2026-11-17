import SwiftUI

#if DEBUG
private struct ProfileScreenFrame<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title3.bold())
            NavigationStack { content() }
                .frame(width: 402, height: 874)
                .clipShape(RoundedRectangle(cornerRadius: 44))
                .overlay { RoundedRectangle(cornerRadius: 44).stroke(KropsTheme.separatorOpaque) }
        }
    }
}

#Preview("Peta Alur Profil", traits: .fixedLayout(width: 2700, height: 1000)) {
    ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 40) {
            ProfileScreenFrame(title: "1 · Profil belum lengkap") {
                GardenProfileCanvasFixtures.content(complete: false)
            }
            ProfileScreenFrame(title: "2 · Lengkapi profil") {
                GardenProfileEditorView(viewModel: GardenProfileCanvasFixtures.makeEditor(filled: false), onClose: {})
            }
            ProfileScreenFrame(title: "3 · Profil siap ditinjau") {
                GardenProfileCanvasFixtures.content(complete: true, justSaved: true)
            }
            ProfileScreenFrame(title: "4 · Riwayat") {
                GardenProfileSummaryView(garden: GardenProfileCanvasFixtures.completeGarden, onClose: {}, onEdit: {})
            }
            ProfileScreenFrame(title: "5 · Tentang peninjauan") {
                GardenReviewInformationView(onClose: {}, onApply: {})
            }
        }
        .padding(40)
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#endif
