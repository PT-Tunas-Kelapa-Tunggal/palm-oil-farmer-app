import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct ReviewSubmissionFlowTests {
    private func request(in profile: GardenProfileFlow) throws -> ReviewRequestFlow {
        profile.coordinator.reviewAction(.request)
        return profile.makeReviewRequest(try #require(profile.coordinator.sheet))
    }

    @Test func mainFlowRegistersCompletesProfileAndSubmitsWithoutPersistingSubmittedCache() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        let app = reviewTestDependencies(repository: repository)
        app.gardenListViewModel.registerGarden()
        #expect(app.coordinator.registrationSheet == .guide)
        let registration = app.registrationFactory.makeFlow(initialStep: .guide,
            onLocate: app.coordinator.locatedGarden, onCancel: app.coordinator.cancelRegistration)
        registration.coordinator.continueToSearch()
        registration.searchViewModel.selectResult(mappingLocation())
        #expect(app.coordinator.mappingLocation == nil && app.coordinator.registrationSheet == nil)
        app.coordinator.registrationDidDismiss()
        let location = try #require(app.coordinator.mappingLocation)
        let mapping = app.mappingFactory.makeFlow(location: location, onFinish: app.coordinator.mappingFinished)
        mappingPoints().forEach(mapping.viewModel.addPoint)
        mapping.viewModel.confirmBoundary()
        let details = mapping.makeDetailsFlow()
        completeDetails(details.viewModel)
        #expect(details.viewModel.save())
        mapping.coordinator.detailsDidDismiss()
        app.coordinator.mappingDidDismiss()
        let garden = try #require(app.gardenStore.gardens.first)
        app.gardenListViewModel.selectGarden(garden)
        #expect(app.coordinator.path == [.gardenProfile(garden.id)])
        let profile = app.profileFactory.makeFlow(garden: garden)
        profile.coordinator.open(.profile)
        let editor = profile.makeProfileEditor(try #require(profile.coordinator.sheet))
        editor.fertilizers[0].name = "Urea"
        editor.fertilizers[0].doseKgPerTree = 1.5
        editor.harvestFrequency = 3
        editor.monthlyWeightKg = 2250
        editor.fertilizationFrequency = 2
        let fertilizerID = editor.fertilizers[0].id
        #expect(editor.save() && profile.viewModel.isComplete)
        profile.coordinator.sheetDidDismiss()
        #expect(app.gardenListViewModel.presentation(showsFilter: true).gardens.first?.stage == .readyForReview)
        #expect(makeTestGardenStore(in: app.modelContainer).gardens.first?.id == garden.id)
        let review = try request(in: profile)
        let contact = try openReviewContact(review)
        completeReviewContact(contact.viewModel)
        await contact.viewModel.submit()
        let sent = try #require(repository.submissions.first)
        #expect(repository.submissions.count == 1 && sent.garden.id == garden.id && sent.status == .submitted)
        #expect(sent.garden.name == garden.name && sent.boundary == mappingPoints().map { CoordinatePoint(latitude: $0.latitude, longitude: $0.longitude) })
        #expect(sent.agronomy.plantingYear == 2016 && sent.agronomy.plantingMonth == garden.plantingMonth && sent.agronomy.soilType == SoilType.peat.rawValue)
        #expect(sent.agronomy.fertilizerRecords.first?.id == fertilizerID && sent.agronomy.harvestRecord?.latestWeightKg == 750)
        #expect(sent.farmer.name == "Budi" && sent.farmer.address == "Riau" && sent.farmer.phone == "+62 (812)-3456 789")
        #expect(review.coordinator.isFinished && profile.coordinator.sheet == nil && !profile.coordinator.isFinished)
        #expect(profile.reviewPresentation.activeStatus == .submitted && profile.reviewPresentation.action(for: profile.viewModel.garden) == .status)
        #expect(app.gardenStore.gardens.first?.id == garden.id && app.gardenStore.gardens.first?.review?.status == .submitted)
        let reopened = makeTestGardenStore(in: app.modelContainer, repository: repository)
        #expect(reopened.gardens.isEmpty)
        await reopened.refreshRemote()
        #expect(reopened.gardens.first?.id == garden.id && reopened.gardens.first?.review?.status == .submitted)
    }

    @Test func primaryFlowRequiresBothConsentsAndRejectsRetiredContactSession() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        let app = reviewTestDependencies(repository: repository)
        let garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        let profile = app.profileFactory.makeFlow(garden: garden)
        let review = try request(in: profile)
        review.viewModel.continueToContact()
        #expect(review.coordinator.path.isEmpty && review.viewModel.showsConsentError)
        let contact = try openReviewContact(review)
        completeReviewContact(contact.viewModel)
        contact.viewModel.hasConsent = false
        await contact.viewModel.submit()
        #expect(contact.viewModel.errorMessage != nil && repository.submissions.isEmpty)
        contact.viewModel.hasConsent = true
        review.coordinator.path.removeLast()
        await contact.viewModel.submit()
        #expect(repository.submissions.isEmpty && app.gardenStore.gardens.first?.review == nil)
    }

    @Test func profileReadinessIsRecheckedAtSendAndFailedFormCanRetryWithLatestHistory() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        let app = reviewTestDependencies(repository: repository)
        var garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        let profile = app.profileFactory.makeFlow(garden: garden)
        let review = try request(in: profile)
        let contact = try openReviewContact(review)
        completeReviewContact(contact.viewModel)
        garden.harvestRecord = nil
        #expect(app.gardenStore.update(garden))
        await contact.viewModel.submit()
        #expect(contact.viewModel.errorMessage == ReviewSubmissionError.profileIncomplete.localizedDescription)
        #expect(repository.submissions.isEmpty && profile.coordinator.sheet != nil && !review.coordinator.isFinished)
        garden.harvestRecord = HarvestRecord(frequencyPerMonth: 4, latestWeightKg: 900)
        #expect(app.gardenStore.update(garden))
        await contact.viewModel.submit()
        #expect(repository.submissions.first?.agronomy.harvestRecord?.latestWeightKg == 900)
        #expect(review.coordinator.isFinished && contact.viewModel.errorMessage == nil)
    }

    @Test func remoteFailureRetainsDraftAndContactThenSuccessfulRetryClosesOnlyReviewSheet() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        repository.rejectsSubmission = true
        let app = reviewTestDependencies(repository: repository)
        let garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        let profile = app.profileFactory.makeFlow(garden: garden)
        let review = try request(in: profile)
        let contact = try openReviewContact(review)
        completeReviewContact(contact.viewModel)
        await contact.viewModel.submit()
        #expect(contact.viewModel.errorMessage == "Pengiriman gagal. Coba lagi.")
        #expect(contact.viewModel.name == "  Budi \n" && contact.viewModel.hasConsent && !contact.viewModel.hasSubmitted)
        #expect(profile.coordinator.sheet != nil && profile.reviewPresentation.activeStatus == nil)
        #expect(makeTestGardenStore(in: app.modelContainer).gardens.first?.id == garden.id)
        repository.rejectsSubmission = false
        await contact.viewModel.submit()
        #expect(repository.submissions.count == 2 && contact.viewModel.hasSubmitted && review.coordinator.isFinished)
        #expect(profile.coordinator.sheet == nil && !profile.coordinator.isFinished)
        #expect(profile.reviewPresentation.activeStatus == .submitted && makeTestGardenStore(in: app.modelContainer).gardens.isEmpty)
    }

    @Test func closedRequestCannotDismissOrMutateNewSessionButConfirmedSaveStillCommits() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        repository.suspendsSubmission = true
        let app = reviewTestDependencies(repository: repository)
        let garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        let profile = app.profileFactory.makeFlow(garden: garden)
        let oldReview = try request(in: profile)
        let oldContact = try openReviewContact(oldReview)
        completeReviewContact(oldContact.viewModel)
        let pending = Task { await oldContact.viewModel.submit() }
        await repository.waitForSubmission(of: garden.id)
        oldContact.close()
        profile.coordinator.sheetDidDismiss()
        let newReview = try request(in: profile)
        let newSheetID = try #require(profile.coordinator.sheet?.id)
        let newContact = try openReviewContact(newReview)
        completeReviewContact(newContact.viewModel)
        await newContact.viewModel.submit()
        #expect(newContact.viewModel.errorMessage == ReviewSubmissionError.inProgress.localizedDescription)
        #expect(repository.submissions.count == 1)
        repository.finishSubmission(of: garden.id, with: .success(try #require(repository.submissions.first)))
        await pending.value
        #expect(oldContact.viewModel.hasSubmitted && app.gardenStore.gardens.first?.review?.status == .submitted)
        #expect(profile.coordinator.sheet?.id == newSheetID && !newReview.coordinator.isFinished)
        #expect(profile.reviewPresentation.activeStatus == nil && makeTestGardenStore(in: app.modelContainer).gardens.isEmpty)
        await newContact.viewModel.submit()
        #expect(newContact.viewModel.errorMessage == ReviewSubmissionError.alreadySubmitted.localizedDescription)
        #expect(repository.submissions.count == 1 && profile.coordinator.sheet?.id == newSheetID)
    }

    @Test func errorFromClosedRequestIsIgnoredAndDraftRemainsRetryable() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        repository.suspendsSubmission = true
        let app = reviewTestDependencies(repository: repository)
        let garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        let profile = app.profileFactory.makeFlow(garden: garden)
        let oldReview = try request(in: profile)
        let oldContact = try openReviewContact(oldReview)
        completeReviewContact(oldContact.viewModel)
        let pending = Task { await oldContact.viewModel.submit() }
        await repository.waitForSubmission(of: garden.id)
        oldContact.close()
        profile.coordinator.sheetDidDismiss()
        let current = try request(in: profile)
        repository.finishSubmission(of: garden.id, with: .failure(ReviewSubmissionRepositorySpy.Failure.unavailable))
        await pending.value
        #expect(oldContact.viewModel.errorMessage == nil && !oldContact.viewModel.hasSubmitted)
        #expect(!current.coordinator.isFinished && profile.coordinator.sheet != nil && app.gardenStore.gardens.first?.review == nil)
        #expect(makeTestGardenStore(in: app.modelContainer).gardens.first?.id == garden.id)
        repository.suspendsSubmission = false
        let retry = try openReviewContact(current)
        completeReviewContact(retry.viewModel)
        await retry.viewModel.submit()
        #expect(retry.viewModel.hasSubmitted && repository.submissions.count == 2)
    }
}
