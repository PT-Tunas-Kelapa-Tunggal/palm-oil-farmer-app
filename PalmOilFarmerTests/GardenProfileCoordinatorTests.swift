import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenProfileCoordinatorTests {
    @Test func editorSessionRemainsLockedUntilDismissalAndOldIdentityExpires() throws {
        let coordinator = GardenProfileCoordinator()
        coordinator.open(.profile)
        let first = try #require(coordinator.sheet)
        coordinator.open(.summary)
        #expect(coordinator.sheet?.id == first.id)
        coordinator.sheet = nil
        coordinator.open(.details)
        #expect(coordinator.sheet == nil && !coordinator.isCurrent(first))
        coordinator.sheetDidDismiss()
        coordinator.open(.summary)
        let second = try #require(coordinator.sheet)
        #expect(second.id != first.id && second.kind == .summary)
        coordinator.closeSheet(first)
        #expect(coordinator.isCurrent(second))
        coordinator.closeSheet(second)
        #expect(coordinator.sheet == nil && !coordinator.canDeleteNow)
        coordinator.sheetDidDismiss()
        #expect(coordinator.canDeleteNow)
    }

    @Test func closingProfileInvalidatesEditorAndPreventsFutureRoutes() throws {
        let coordinator = GardenProfileCoordinator()
        coordinator.open(.details)
        let sheet = try #require(coordinator.sheet)
        coordinator.close()
        coordinator.sheetDidDismiss()
        coordinator.open(.summary)
        coordinator.requestDelete()
        coordinator.reviewAction(.status)
        coordinator.openResults()
        #expect(coordinator.isFinished && !coordinator.isCurrent(sheet) && coordinator.sheet == nil)
        #expect(!coordinator.showsDeleteConfirmation && !coordinator.showsReviewStatus && !coordinator.showsResults)
    }

    @Test func deleteActionWaitsForEditorAndAcceptsNativeDialogDismissalBeforeCallback() {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        let flow = makeProfileTestFlow(garden: garden, source: source)
        flow.coordinator.open(.profile)
        flow.coordinator.requestDelete()
        #expect(!flow.coordinator.showsDeleteConfirmation && !flow.viewModel.delete())
        flow.coordinator.sheet = nil
        flow.coordinator.sheetDidDismiss()
        flow.coordinator.requestDelete()
        flow.coordinator.showsDeleteConfirmation = false
        #expect(flow.viewModel.delete() && flow.coordinator.isFinished)
        #expect(source.gardens.isEmpty)
    }

    @Test func existingStatusAndResultsNavigationCanReturnBeforeOpeningNewEditor() {
        let coordinator = GardenProfileCoordinator()
        coordinator.reviewAction(.status)
        coordinator.open(.summary)
        #expect(coordinator.showsReviewStatus && coordinator.sheet == nil)
        coordinator.openResults()
        #expect(coordinator.showsResults)
        coordinator.showsResults = false
        coordinator.open(.details)
        #expect(coordinator.sheet == nil)
        coordinator.showsReviewStatus = false
        coordinator.reviewAction(.request)
        #expect(coordinator.sheet?.kind == .review)
    }

    @Test func closingProfileCancelsPendingSummaryEdit() throws {
        let coordinator = GardenProfileCoordinator()
        coordinator.open(.summary)
        coordinator.editProfile(from: try #require(coordinator.sheet))
        coordinator.close()
        coordinator.sheetDidDismiss()
        #expect(coordinator.isFinished && coordinator.sheet == nil)
    }
}
