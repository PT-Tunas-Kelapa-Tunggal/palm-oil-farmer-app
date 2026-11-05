import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenProfileCoordinatorTests {
    @Test func editorSessionRemainsLockedUntilDismissalAndOldIdentityExpires() throws {
        let coordinator = GardenProfileCoordinator()
        coordinator.open(.fertilizer)
        let first = try #require(coordinator.sheet)
        coordinator.open(.harvest)
        #expect(coordinator.sheet?.id == first.id)
        coordinator.sheet = nil
        coordinator.open(.details)
        #expect(coordinator.sheet == nil && !coordinator.isCurrent(first))
        coordinator.sheetDidDismiss()
        coordinator.open(.harvest)
        let second = try #require(coordinator.sheet)
        #expect(second.id != first.id && second.kind == .harvest)
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
        coordinator.open(.harvest)
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
        flow.coordinator.open(.fertilizer)
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
        coordinator.open(.harvest)
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

    @Test func historyTypeSelectionUsesNativeBackAndClosePreventsReopening() {
        let coordinator = GardenHistoryEditorCoordinator()
        let id = UUID()
        coordinator.selectType(for: id)
        #expect(coordinator.selectedDraftID == id)
        coordinator.selectedDraftID = nil
        coordinator.selectType(for: id)
        coordinator.close()
        coordinator.selectedDraftID = nil
        coordinator.selectType(for: UUID())
        #expect(coordinator.isFinished && coordinator.selectedDraftID == nil)
    }
}
