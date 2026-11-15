import SwiftUI

/// Main screen displaying the Nutrient Condition assessment report (Kondisi Hara).
/// Sliced from Sketch: "Hasil Peninjauan / Kondisi Hara / Feed"
@MainActor
public struct NutrientConditionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: NutrientConditionViewModel

    public var onBack: (() -> Void)?
    public var onOpenFertilizerEstimation: (() -> Void)?

    public init(
        viewModel: NutrientConditionViewModel,
        onBack: (() -> Void)? = nil,
        onOpenFertilizerEstimation: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onBack = onBack
        self.onOpenFertilizerEstimation = onOpenFertilizerEstimation
    }

    public init(
        onBack: (() -> Void)? = nil,
        onOpenFertilizerEstimation: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: NutrientConditionViewModel())
        self.onBack = onBack
        self.onOpenFertilizerEstimation = onOpenFertilizerEstimation
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Top Navigation Bar
                navigationBar

                // Hero Header
                heroSection
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                // Main Feed Cards
                if let overview = viewModel.overview {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(overview.nutrients.enumerated()), id: \.element.id) { index, nutrient in
                            NutrientCardView(
                                item: nutrient,
                                showsDivider: index < overview.nutrients.count - 1
                            )
                        }
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Coba Lagi") {
                            Task { await viewModel.load() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.18, green: 0.42, blue: 0.25))
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
            }
        }
        .background(Color(hex: 0xF2F4F7).ignoresSafeArea())
        .task {
            if viewModel.overview == nil {
                await viewModel.load()
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Subviews

    private var navigationBar: some View {
        HStack {
            Button(action: handleBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kembali")

            Spacer()

            if let onOpenFertilizerEstimation {
                Button(action: onOpenFertilizerEstimation) {
                    HStack(spacing: 6) {
                        Text("Biaya Pupuk")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Buka Perkiraan Biaya Pupuk")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.overview?.title ?? "Kondisi Hara")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))

            Text(viewModel.overview?.subtitle ?? "Belum seimbang, dihitung per tahun untuk seluruh kebun")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }
}

// MARK: - Previews

#Preview("Kondisi Hara · Default") {
    NutrientConditionView()
}

#Preview("Kondisi Hara · Dark Mode") {
    NutrientConditionView()
        .preferredColorScheme(.dark)
}

// MARK: - Color Hex Helper

private extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

