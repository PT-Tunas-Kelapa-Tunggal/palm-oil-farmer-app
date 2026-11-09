import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct ReviewRequestViewModelTests {
    @Test func programConsentIsRequiredAndClosingPreventsFurtherNavigation() {
        var closes = 0
        let coordinator = ReviewRequestCoordinator(onClose: { closes += 1 })
        let model = ReviewRequestViewModel(isActive: { !coordinator.isFinished }, onContinue: coordinator.showContact)
        model.continueToContact()
        #expect(model.showsConsentError && coordinator.path.isEmpty)
        model.hasConsent = true
        model.continueToContact()
        model.continueToContact()
        #expect(!model.showsConsentError && coordinator.path.count == 1)
        coordinator.close()
        coordinator.close()
        model.continueToContact()
        #expect(closes == 1 && coordinator.path.count == 1)
    }

    @Test func invalidContactOrUnconfirmedDetailsCannotReachSubmission() async {
        var calls = 0
        let model = ReviewContactFormViewModel(isActive: { true }, onSubmit: { _ in calls += 1 }, onSubmitted: {})
        for missing in 0...3 {
            completeReviewContact(model)
            switch missing {
            case 0: model.name = " \n"
            case 1: model.phone = "08123"
            case 2: model.address = " "
            default: model.hasConsent = false
            }
            await model.submit()
            #expect(model.errorMessage == "Lengkapi nama, nomor telepon, alamat rumah, dan persetujuan terlebih dahulu.")
        }
        #expect(calls == 0 && !model.isSubmitting && !model.hasSubmitted)
    }

    @Test func successfulContactUsesExistingNormalizationAndFinishesOnlyOnce() async {
        var contacts: [ReviewContactDetails] = []
        var finishes = 0
        let model = ReviewContactFormViewModel(isActive: { true }, onSubmit: { contacts.append($0) }, onSubmitted: { finishes += 1 })
        completeReviewContact(model)
        await model.submit()
        await model.submit()
        #expect(contacts.count == 1 && contacts.first?.name == "Budi" && contacts.first?.address == "Riau")
        #expect(contacts.first?.phone == "+62 (812)-3456 789" && finishes == 1 && model.hasSubmitted)
        #expect(!model.isSubmitting && model.errorMessage == nil)
        #expect(ReviewContactField.name.next == .phone && ReviewContactField.phone.next == .address && ReviewContactField.address.next == nil)
    }

    @Test func failurePreservesFieldsAndRetryCanSucceed() async {
        var rejects = true, calls = 0, finishes = 0
        let model = ReviewContactFormViewModel(isActive: { true }, onSubmit: { _ in
            calls += 1
            if rejects { throw ReviewSubmissionRepositorySpy.Failure.unavailable }
        }, onSubmitted: { finishes += 1 })
        completeReviewContact(model)
        await model.submit()
        #expect(!model.isSubmitting && !model.hasSubmitted && finishes == 0)
        #expect(model.errorMessage == "Pengiriman gagal. Coba lagi." && model.phone == "+62 (812)-3456 789")
        rejects = false
        await model.submit()
        #expect(model.hasSubmitted && model.errorMessage == nil && calls == 2 && finishes == 1)
    }

    @Test func repeatedTapWhileSendingDoesNotCreateSecondRequest() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        repository.suspendsSubmission = true
        let app = reviewTestDependencies(repository: repository)
        let garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        let model = ReviewContactFormViewModel(isActive: { true }, onSubmit: { contact in
            _ = try await app.submitGardenReview.execute(gardenID: garden.id, contact: contact)
        }, onSubmitted: {})
        completeReviewContact(model)
        let pending = Task { await model.submit() }
        await repository.waitForSubmission(of: garden.id)
        #expect(model.isSubmitting)
        await model.submit()
        #expect(repository.submissions.count == 1)
        repository.finishSubmission(of: garden.id, with: .success(try #require(repository.submissions.first)))
        await pending.value
        #expect(model.hasSubmitted && !model.isSubmitting)
    }

    @Test func inactiveFormDoesNotStartWriteAndCancellationErrorIsSilent() async {
        var active = false, calls = 0
        let model = ReviewContactFormViewModel(isActive: { active }, onSubmit: { _ in
            calls += 1
            throw CancellationError()
        }, onSubmitted: {})
        completeReviewContact(model)
        await model.submit()
        #expect(calls == 0 && model.errorMessage == nil)
        active = true
        await model.submit()
        #expect(calls == 1 && model.errorMessage == nil && !model.hasSubmitted && !model.isSubmitting)
    }

    @Test func callerCancellationAfterSendSuppressesUICompletionButPreservesCommittedData() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        repository.suspendsSubmission = true
        let app = reviewTestDependencies(repository: repository)
        let garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        var finishes = 0
        let model = ReviewContactFormViewModel(isActive: { true }, onSubmit: { contact in
            _ = try await app.submitGardenReview.execute(gardenID: garden.id, contact: contact)
        }, onSubmitted: { finishes += 1 })
        completeReviewContact(model)
        let pending = Task { await model.submit() }
        await repository.waitForSubmission(of: garden.id)
        pending.cancel()
        repository.finishSubmission(of: garden.id, with: .success(try #require(repository.submissions.first)))
        await pending.value
        #expect(model.hasSubmitted && finishes == 0 && model.errorMessage == nil)
        #expect(app.gardenStore.gardens.first?.review?.status == .submitted)
    }

    @Test func nativeBackInvalidatesOldContactSessionAndNextPageHasFreshDraft() throws {
        let repository = ReviewSubmissionRepositorySpy()
        let app = reviewTestDependencies(repository: repository)
        let flow = app.reviewRequestFactory.makeFlow(gardenID: UUID(), isActive: { true }, onSubmitted: { _ in }, onClose: {})
        let first = try openReviewContact(flow)
        let oldID = try #require(flow.coordinator.currentContactID)
        completeReviewContact(first.viewModel)
        flow.coordinator.path.removeLast()
        #expect(!flow.coordinator.isCurrentContact(oldID))
        flow.viewModel.continueToContact()
        let newID = try #require(flow.coordinator.currentContactID)
        let second = flow.makeContactFlow(newID)
        #expect(newID != oldID && second.viewModel.name.isEmpty && !second.viewModel.hasConsent)
    }

    @Test func savingMultipleContactsBudgetCalculationAndConfirmationStepWorkTogether() async {
        var submitted: [ReviewContactDetails] = []
        var finishes = 0
        let model = ReviewContactFormViewModel(
            gardenName: "Belakang Rumah",
            areaHectares: 1.7,
            isActive: { true },
            onSubmit: { submitted.append($0) },
            onSubmitted: { finishes += 1 }
        )
        #expect(model.isEditingContact && model.savedContacts.isEmpty)
        #expect(!model.cancelEditingContact())

        model.name = "  Hendrawan Nugroho "
        model.phone = "0812 7745 3021"
        model.address = "  Jl. Raya Gunung Kijang Km 25, Malang Rapat, Gunung Kijang, Bintan "
        #expect(model.saveContact())
        #expect(!model.isEditingContact && model.savedContacts.count == 1 && model.selectedContactIndex == 0)

        model.startAddingAnotherContact()
        #expect(model.isEditingContact && model.name.isEmpty && model.phone.isEmpty && model.address.isEmpty)
        #expect(model.cancelEditingContact())
        #expect(!model.isEditingContact && model.name == "Hendrawan Nugroho")

        model.startAddingAnotherContact()
        model.name = "Pak Budi"
        model.phone = "0813 9988 7766"
        model.address = "Desa Toapaya, Bintan"
        #expect(model.saveContact())
        #expect(model.savedContacts.count == 2 && model.selectedContactIndex == 1 && model.name == "Pak Budi")

        model.selectContact(at: 0)
        #expect(model.selectedContactIndex == 0 && model.name == "Hendrawan Nugroho")

        #expect(model.formattedBudgetPerHectare == "Rp5.500.000")
        #expect(model.formattedArea == "1,7 ha")
        #expect(model.formattedTotalBudget == "Rp9.350.000")

        model.hasConsent = true
        await model.submit(closesImmediately: false)
        #expect(model.hasSubmitted && finishes == 0 && submitted.count == 1)
        #expect(submitted.first?.name == "Hendrawan Nugroho")
    }
}
