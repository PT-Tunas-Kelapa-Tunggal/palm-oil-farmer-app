import SwiftUI

struct AssessmentStatusView: View {
    let viewModel: AssessmentStatusViewModel
    let onAdvance: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var dark: Bool { colorScheme == .dark }
    private var palette: AssessmentPalette { .init(isDark: dark) }
    private var track: Color {
        dark ? Color(red: 56 / 255, green: 56 / 255, blue: 58 / 255)
            : Color(red: 198 / 255, green: 198 / 255, blue: 200 / 255)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.steps) { step in
                        row(step)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 12)
        .foregroundStyle(palette.primary)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(viewModel.sheetHeight), .large])
        .presentationDragIndicator(dark ? .visible : .hidden)
        .presentationCornerRadius(38)
        .presentationBackground {
            if dark { palette.card } else { Rectangle().fill(.regularMaterial) }
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: dark ? "checkmark" : "xmark")
                    .font(dark ? .title3 : .headline)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tutup status peninjauan")

            Text("Status Peninjauan")
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityAddTraits(.isHeader)
                #if DEBUG
                .onLongPressGesture(minimumDuration: 1.5, perform: onAdvance)
                .accessibilityAction(named: Text("Majukan status pratinjau"), onAdvance)
                #endif

            Color.clear.frame(width: 44, height: 1)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
    }

    private func row(_ step: AssessmentStatusViewModel.Step) -> some View {
        HStack(alignment: .top, spacing: 16) {
            marker(for: step.phase)
                .frame(width: 24)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                if let date = step.date {
                    Text(date)
                        .font(.footnote)
                        .foregroundStyle(palette.secondary)
                }
                Text(step.title)
                    .font(step.phase == .current ? .title3.weight(.semibold) : .headline)
                    .foregroundStyle(step.phase == .upcoming ? palette.secondary : palette.primary)
                Text(step.message)
                    .font(.subheadline)
                    .foregroundStyle(step.phase == .upcoming ? palette.tertiary : palette.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, step.id == .completed ? 0 : 24)
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay(alignment: .topLeading) {
            if step.id != .completed || !dark {
                Rectangle()
                    .fill(!dark && step.phase == .finished ? AssessmentPalette.graphite : track)
                    .frame(width: 2)
                    .padding(.top, 32)
                    .padding(.bottom, 2)
                    .padding(.leading, 11)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(step.phase == .current ? .isSelected : [])
    }

    @ViewBuilder
    private func marker(for phase: AssessmentStatusViewModel.Step.Phase) -> some View {
        switch phase {
        case .finished:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: dark ? 20 : 17, weight: dark ? .regular : .semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 24, height: 24)
        case .current:
            Circle()
                .fill(AssessmentPalette.graphite)
                .overlay { if dark { Circle().strokeBorder(track, lineWidth: 4) } }
                .frame(width: dark ? 24 : 16, height: dark ? 24 : 16)
                .frame(width: 24, height: 24)
        case .upcoming:
            Circle()
                .fill(dark ? palette.card : palette.background)
                .overlay { Circle().strokeBorder(dark ? palette.secondary : track, lineWidth: 2) }
                .frame(width: 12, height: 12)
                .frame(width: 24, height: 24)
        }
    }
}

#if DEBUG
private struct AssessmentStatusPreview: View {
    @State private var showsStatus = true
    @State private var review = GardenReview(
        contact: ReviewContactDetails(
            name: "Hendrawan Nugroho",
            phone: "0812 3456 7890",
            address: "Jalan Kebun"
        )
    )

    var body: some View {
        ScrollView {
            AssessmentReviewStatusCard(status: .inReview(contactName: review.contact.name)) { showsStatus = true }
                .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showsStatus) {
            AssessmentStatusView(viewModel: AssessmentStatusViewModel(review: review)) {
                review.advance()
            }
        }
    }
}

#Preview("Status Peninjauan · Light") {
    AssessmentStatusPreview()
        .preferredColorScheme(.light)
}

#Preview("Status Peninjauan · Accessibility") {
    AssessmentStatusPreview()
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
