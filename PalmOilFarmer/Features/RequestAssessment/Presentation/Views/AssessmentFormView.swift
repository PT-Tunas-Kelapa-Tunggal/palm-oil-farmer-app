import SwiftUI

struct AssessmentFormView: View {
    @State private var viewModel: AssessmentFormViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: Field?

    @ScaledMetric(relativeTo: .body) private var bodySize = 17.0
    @ScaledMetric(relativeTo: .title3) private var inputSize = 20.0
    @ScaledMetric(relativeTo: .subheadline) private var descriptionSize = 15.0
    @ScaledMetric(relativeTo: .subheadline) private var descriptionHeight = 40.0
    @ScaledMetric(relativeTo: .title2) private var iconWidth = 26.0
    @ScaledMetric(relativeTo: .title2) private var addressIconWidth = 31.0
    @ScaledMetric(relativeTo: .title2) private var iconSize = 22.0
    @ScaledMetric(relativeTo: .footnote) private var errorSize = 13.0
    @ScaledMetric(relativeTo: .body) private var labelHeight = 22.0
    @ScaledMetric(relativeTo: .title3) private var titleHeight = 25.0
    @ScaledMetric(relativeTo: .body) private var inputHeight = 52.0
    @ScaledMetric(relativeTo: .body) private var addressHeight = 112.0

    private let onSave: (String, String, String) -> Void
    private enum Field: Hashable { case name, phone, address }

    init(
        viewModel: AssessmentFormViewModel,
        onSave: @escaping (String, String, String) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSave = onSave
    }

    private var dark: Bool { colorScheme == .dark }

    private var inputFill: Color {
        KropsTheme.surfaceCard
    }

    var body: some View {
        @Bindable var model = viewModel

        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Narahubung")
                            .font(.system(size: inputSize, weight: .semibold))
                            .frame(minHeight: titleHeight)
                        Text("Petugas menghubungi orang ini untuk menjadwalkan kunjungan ke kebun.")
                            .font(.system(size: descriptionSize))
                            .frame(minHeight: descriptionHeight, alignment: .topLeading)
                            .foregroundStyle(KropsTheme.labelSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                    VStack(alignment: .leading, spacing: 0) {
                        field(title: "Nama lengkap", icon: "person", error: model.nameError) {
                            TextField("Nama lengkap", text: $model.name, prompt: Text("Contoh: Hendrawan Nugroho").foregroundStyle(KropsTheme.labelTertiary))
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                                .focused($focusedField, equals: .name)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .phone }
                        }
                        field(title: "Nomor HP", icon: "phone", error: model.phoneError) {
                            TextField("Nomor HP", text: $model.phone, prompt: Text("Contoh: 0812 3456 7890").foregroundStyle(KropsTheme.labelTertiary))
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                                .focused($focusedField, equals: .phone)
                        }
                        field(title: "Alamat lengkap", icon: "house", error: model.addressError, multiline: true) {
                            TextField("Alamat lengkap", text: $model.address, prompt: Text("Nama jalan, desa atau dusun, dan kecamatan").foregroundStyle(KropsTheme.labelTertiary), axis: .vertical)
                                .fixedSize(horizontal: false, vertical: true)
                                .textContentType(.fullStreetAddress)
                                .textInputAutocapitalization(.sentences)
                                .focused($focusedField, equals: .address)
                        }
                    }
                    .padding(.horizontal, dark ? 16 : 0)
                    .padding(.vertical, dark ? 8 : 0)
                    .background(.clear, in: RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(KropsTheme.labelPrimary)
        .background(KropsTheme.surfaceBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Button {
                if viewModel.save(onSave: onSave) {
                    focusedField = nil
                } else if viewModel.nameError != nil {
                    focusedField = .name
                } else if viewModel.phoneError != nil {
                    focusedField = .phone
                } else {
                    focusedField = .address
                }
            } label: {
                Text("Simpan Narahubung")
                    .font(.system(size: bodySize, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: inputHeight)
            }
            .buttonStyle(.plain)
            .foregroundStyle(KropsTheme.labelInversePrimary)
            .glassEffect(.regular.tint(KropsTheme.surfaceInverse), in: Capsule())
            .padding(.horizontal, 16)
            .background(KropsTheme.surfaceBackground)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: bodySize, weight: .medium))
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kembali")

            Text("Ajukan Peninjauan")
                .font(.system(size: bodySize, weight: .semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)

            Color.clear.frame(width: 44, height: 1)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
    }

    private func field<Content: View>(
        title: String,
        icon: String,
        error: String?,
        multiline: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: bodySize, weight: .semibold))
                .foregroundStyle(KropsTheme.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: labelHeight)
                .padding(.leading, !dark && !multiline ? 8 : 0)
            HStack(alignment: multiline ? .top : .center, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .frame(width: multiline ? addressIconWidth : iconWidth)
                    .foregroundStyle(KropsTheme.labelSecondary)
                    .accessibilityHidden(true)
                content()
                    .font(.system(size: inputSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(title)
            }
            .padding(12)
            .frame(minHeight: multiline ? addressHeight : inputHeight, alignment: multiline ? .topLeading : .leading)
            .background(inputFill, in: RoundedRectangle(cornerRadius: 12))
            if viewModel.showsValidation, let error {
                Text(error)
                    .font(.system(size: errorSize))
                    .foregroundStyle(KropsTheme.statusCritical)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview("Assessment Form · Light") {
    NavigationStack {
        AssessmentFormView(viewModel: AssessmentFormViewModel()) { _, _, _ in }
    }
    .preferredColorScheme(.light)
}

#Preview("Assessment Form – Accessibility") {
    NavigationStack {
        AssessmentFormView(viewModel: AssessmentFormViewModel()) { _, _, _ in }
    }
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility3)
}
