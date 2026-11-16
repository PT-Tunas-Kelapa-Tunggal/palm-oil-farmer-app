import SwiftUI

/// Main screen displaying the Fertilizer Cost Estimation report (Perkiraan Biaya Pupuk).
/// Sliced from Sketch: "Hasil Peninjauan / Perkiraan Biaya Pupuk / Default"
@MainActor
public struct FertilizerEstimationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FertilizerEstimationViewModel
    @State private var npkPillFrame: CGRect = .zero

    public var onBack: (() -> Void)?

    public init(
        viewModel: FertilizerEstimationViewModel,
        onBack: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onBack = onBack
    }

    public init(onBack: (() -> Void)? = nil) {
        _viewModel = State(initialValue: FertilizerEstimationViewModel())
        self.onBack = onBack
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Top Navigation Bar
                    navigationBar

                    // Hero Header
                    heroSection
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                    // Main Content
                    if let overview = viewModel.overview {
                        VStack(alignment: .leading, spacing: 24) {
                            // Total Cost Summary Card
                            FertilizerTotalCostCard(
                                totalCost: overview.formattedTotalCost,
                                fertilizerCount: overview.fertilizers.count,
                                budgetLimit: overview.formattedBudgetLimit,
                                remainingBudget: overview.formattedRemainingBudget,
                                budgetProgress: overview.budgetProgress
                            )

                            // Shopping List Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Daftar Belanja")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))
                                    .padding(.horizontal, 4)

                                FertilizerShoppingTableView(
                                    fertilizers: overview.fertilizers,
                                    totalCost: overview.formattedTotalCost,
                                    onSelectNPK: {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                            viewModel.isNPKPickerPresented.toggle()
                                        }
                                    }
                                )

                                if viewModel.isSaveCompositionVisible {
                                    SaveCompositionButton {
                                        viewModel.saveComposition()
                                    }
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity
                                    ))
                                }
                            }
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isSaveCompositionVisible)

                            // Footnote Disclaimer
                            Text(overview.footnote)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 32)
                        }
                        .padding(.horizontal, 16)
                    } else if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 250)
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
                        .frame(maxWidth: .infinity, minHeight: 250)
                    }
                }
            }
            .coordinateSpace(name: "FertilizerScreenSpace")
            .onPreferenceChange(NPKPillAnchorPreferenceKey.self) { rect in
                if rect != .zero {
                    npkPillFrame = rect
                }
            }

            // Floating NPK Menu Overlay (In-place dropdown matching Sketch)
            if viewModel.isNPKPickerPresented, let overview = viewModel.overview {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            viewModel.isNPKPickerPresented = false
                        }
                    }

                NPKPickerMenuView(
                    options: overview.npkOptions,
                    selectedOptionId: overview.selectedNPKId,
                    onSelect: { option in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            viewModel.isNPKPickerPresented = false
                        }
                        Task {
                            await viewModel.selectNPK(option: option)
                        }
                    }
                )
                .offset(
                    x: max(16, npkPillFrame.minX - 8),
                    y: npkPillFrame.maxY + 6
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.94, anchor: .topLeading)),
                    removal: .opacity
                ))
                .zIndex(999)
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
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Perkiraan Biaya Pupuk")
                .font(.largeTitle.bold())
                .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))

            Text("\(viewModel.overview?.gardenName ?? "Kebun"), \(viewModel.overview?.periodDescription ?? "untuk kebutuhan 1 tahun")")
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

// MARK: - Previews

#Preview("Perkiraan Biaya Pupuk · Default") {
    FertilizerEstimationView()
}

#Preview("Perkiraan Biaya Pupuk · Fertilizer Changed") {
    let repo = DummyFertilizerEstimationRepository()
    let vm = FertilizerEstimationViewModel(repository: repo)
    FertilizerEstimationView(viewModel: vm)
        .task {
            await vm.load()
            if let option = vm.overview?.npkOptions.first(where: { $0.id == "npk-12" }) {
                await vm.selectNPK(option: option)
            }
        }
}

#Preview("Perkiraan Biaya Pupuk · Dark Mode") {
    FertilizerEstimationView()
        .preferredColorScheme(.dark)
}

