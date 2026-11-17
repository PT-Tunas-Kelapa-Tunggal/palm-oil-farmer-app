import SwiftUI

struct ReviewContactFormView: View {
    @State private var model: ReviewContactFormViewModel
    private let onClose: () -> Void
    private let dismissOnClose: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: ReviewContactField?

    init(flow: ReviewContactFlow) {
        _model = State(initialValue: flow.viewModel)
        onClose = flow.close
        dismissOnClose = flow.dismissOnClose
    }

    var body: some View {
        Group {
            if model.hasSubmitted {
                submittedConfirmationContent
            } else if model.isEditingContact {
                contactEditorContent
            } else {
                reviewSummaryContent
            }
        }
        .background(KropsTheme.surfaceBackground)
        .alert("Pengajuan belum dikirim", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("Mengerti", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Screen 1: Form Narahubung

    private var contactEditorContent: some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            GardenProfileHeader(title: "Ajukan Peninjauan", onBack: handleEditorBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GardenProfileSectionHeader(
                        title: "Narahubung",
                        message: "Petugas menghubungi orang ini untuk menjadwalkan kunjungan ke kebun."
                    )

                    VStack(alignment: .leading, spacing: 18) {
                        contactField(
                            title: "Nama lengkap",
                            symbol: "person",
                            placeholder: "Contoh: Hendrawan Nugroho",
                            text: $model.name,
                            field: .name,
                            contentType: .name,
                            keyboard: .default
                        )

                        contactField(
                            title: "Nomor HP",
                            symbol: "phone",
                            placeholder: "Contoh: 0812 3456 7890",
                            text: $model.phone,
                            field: .phone,
                            contentType: .telephoneNumber,
                            keyboard: .phonePad
                        )

                        addressField(text: $model.address)
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(KropsTheme.surfaceCard)
                            .onTapGesture { focusedField = nil }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { focusedField = nil }
                }
            }
            .scrollBounceBehavior(.always)
            .scrollDismissesKeyboard(.immediately)
            .background {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { focusedField = nil }
            }
        }
        .background {
            KropsTheme.surfaceBackground
                .ignoresSafeArea()
                .onTapGesture { focusedField = nil }
        }
        .safeAreaInset(edge: .bottom) {
            if focusedField == nil {
                GardenProfileActionButton(title: "Simpan Narahubung") {
                    focusedField = nil
                    withAnimation(reduceMotion ? nil : .snappy) {
                        _ = model.saveContact()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .background(KropsTheme.surfaceBackground)
            }
        }
    }

    private func contactField(
        title: String,
        symbol: String,
        placeholder: String,
        text: Binding<String>,
        field: ReviewContactField,
        contentType: UITextContentType,
        keyboard: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)
                TextField(placeholder, text: text)
                    .font(.body)
                    .keyboardType(keyboard)
                    .textContentType(contentType)
                    .submitLabel(field.next != nil ? .next : .done)
                    .focused($focusedField, equals: field)
                    .onSubmit { focusedField = field.next }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(KropsTheme.surfaceCardRaised, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .onTapGesture { focusedField = field }
        }
    }

    private func addressField(text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alamat lengkap")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "house")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                    .padding(.top, 3)
                    .accessibilityHidden(true)
                TextField("Nama jalan, desa atau dusun, dan kecamatan", text: text, axis: .vertical)
                    .font(.body)
                    .lineLimit(3...5)
                    .textContentType(.fullStreetAddress)
                    .focused($focusedField, equals: .address)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(minHeight: 96, alignment: .topLeading)
            .background(KropsTheme.surfaceCardRaised, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .address }
        }
    }

    // MARK: - Screen 2: Saved Contact & Anggaran Pupuk

    private var reviewSummaryContent: some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            GardenProfileHeader(title: "Ajukan Peninjauan", onBack: close)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        GardenProfileSectionHeader(
                            title: "Narahubung",
                            message: "Petugas menghubungi orang ini untuk menjadwalkan kunjungan."
                        )

                        ForEach(Array(model.savedContacts.enumerated()), id: \.offset) { index, contact in
                            savedContactCard(contact, isSelected: index == model.selectedContactIndex) {
                                model.selectContact(at: index)
                            }
                        }

                        Button {
                            focusedField = nil
                            withAnimation(reduceMotion ? nil : .snappy) {
                                model.startAddingAnotherContact()
                            }
                        } label: {
                            Label("Tambah narahubung lain", systemImage: "plus")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .foregroundStyle(KropsTheme.accentPrimary)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        GardenProfileSectionHeader(
                            title: "Anggaran Pupuk",
                            message: "Batas dana pupuk yang bisa Anda siapkan per hektar per tahun."
                        )

                        fertilizerBudgetCard(budget: $model.fertilizerBudgetPerHectare)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 14) {
                ConsentCheckbox(
                    isChecked: $model.hasConsent,
                    text: "Saya memastikan data narahubung dan anggaran pupuk sudah benar."
                )

                GardenProfileActionButton(title: model.isSubmitting ? "Mengirim…" : "Kirim Pengajuan") {
                    guard !model.isSubmitting else { return }
                    focusedField = nil
                    Task {
                        await model.submit(closesImmediately: false)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .background(KropsTheme.surfaceBackground)
        }
    }

    private func savedContactCard(
        _ contact: ReviewContactDetails,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? KropsTheme.accentHero : KropsTheme.labelSecondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(contact.phone)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(contact.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func fertilizerBudgetCard(budget: Binding<Double>) -> some View {
        VStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(model.formattedBudgetPerHectare)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Text("per hektar per tahun")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                Slider(
                    value: budget,
                    in: ReviewContactFormViewModel.budgetRange,
                    step: ReviewContactFormViewModel.budgetStep
                )
                .tint(KropsTheme.surfaceInverseRaised)
                .accessibilityLabel("Anggaran pupuk per hektar per tahun")
                .accessibilityValue(model.formattedBudgetPerHectare)

                HStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { index in
                        Circle()
                            .fill(KropsTheme.fillBlack12)
                            .frame(width: 4, height: 4)
                        if index < 9 {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .accessibilityHidden(true)

                HStack {
                    Text("Rp1 jt")
                    Spacer()
                    Text("Rp10 jt")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Text("Total untuk kebun \(model.formattedArea)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(model.formattedTotalBudget)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
        }
        .padding(16)
        .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Screen 3: Pengajuan Terkirim

    private var submittedConfirmationContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image("PengajuanIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Pengajuan Terkirim")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Pengajuan peninjauan untuk \(model.gardenName) sudah kami terima.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()

            GardenProfileActionButton(title: "Kembali ke Detail Kebun", action: close)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Navigation Actions

    private func handleEditorBack() {
        focusedField = nil
        withAnimation(reduceMotion ? nil : .snappy) {
            if !model.cancelEditingContact() {
                close()
            }
        }
    }

    private func close() {
        focusedField = nil
        onClose()
        if dismissOnClose { dismiss() }
    }
}

#if DEBUG
#Preview("1 · Form Narahubung") {
    ReviewContactFormView(onSubmit: { _ in })
        .environment(\.locale, Locale(identifier: "id_ID"))
}

#Preview("2 · Ajukan Peninjauan") {
    ReviewContactFormView(
        gardenName: "Belakang Rumah",
        areaHectares: 1.7,
        savedContacts: [
            ReviewContactDetails(
                name: "Hendrawan Nugroho",
                phone: "0812 7745 3021",
                address: "Jl. Raya Gunung Kijang Km 25, Malang Rapat, Gunung Kijang, Bintan"
            )
        ],
        onSubmit: { _ in }
    )
    .environment(\.locale, Locale(identifier: "id_ID"))
}

#Preview("3 · Pengajuan Terkirim") {
    ReviewContactFormView(
        flow: ReviewContactFlow(
            viewModel: ReviewContactFormViewModel(
                gardenName: "Belakang Rumah",
                areaHectares: 1.7,
                hasSubmitted: true,
                isActive: { true },
                onSubmit: { _ in },
                onSubmitted: {}
            ),
            close: {}
        )
    )
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#endif
