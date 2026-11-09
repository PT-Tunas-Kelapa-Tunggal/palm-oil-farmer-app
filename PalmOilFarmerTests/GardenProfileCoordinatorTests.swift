import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenProfileCoordinatorTests {
    @Test func savedHighlightRequiresCurrentProfileEditor() throws {
        let coordinator = GardenProfileCoordinator()
        coordinator.open(.details)
        let details = try #require(coordinator.sheet)
        coordinator.profileSaved(details)
        #expect(!coordinator.profileJustSaved)
        #expect(coordinator.isCurrent(details))
        coordinator.closeSheet(details)
        coordinator.sheetDidDismiss()
        coordinator.open(.profile)
        let profile = try #require(coordinator.sheet)
        coordinator.profileSaved(details)
        #expect(!coordinator.profileJustSaved)
        coordinator.profileSaved(profile)
        #expect(coordinator.profileJustSaved && coordinator.sheet == nil)
        coordinator.sheetDidDismiss()
        #expect(coordinator.canDeleteNow)
    }

    @Test func editorSessionRemainsLockedUntilDismissalAndOldIdentityExpires() throws {
        let coordinator = GardenProfileCoordinator()
        coordinator.open(.profile)
        let first = try #require(coordinator.sheet)
        coordinator.open(.details)
        #expect(coordinator.sheet?.id == first.id)
        coordinator.sheet = nil
        coordinator.open(.details)
        #expect(coordinator.sheet == nil && !coordinator.isCurrent(first))
        coordinator.sheetDidDismiss()
        coordinator.open(.details)
        let second = try #require(coordinator.sheet)
        #expect(second.id != first.id && second.kind == .details)
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
        coordinator.open(.details)
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
        coordinator.open(.details)
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

    @Test func summaryNavigatesAsPageAndEditingReturnsToSummary() throws {
        let coordinator = GardenProfileCoordinator()
        coordinator.openSummary()
        #expect(coordinator.showsSummary && coordinator.sheet == nil)
        #expect(!coordinator.canDeleteNow)
        coordinator.editSummary()
        let editor = try #require(coordinator.sheet)
        #expect(editor.kind == .profile)
        coordinator.profileSaved(editor)
        coordinator.sheetDidDismiss()
        #expect(coordinator.showsSummary && coordinator.sheet == nil)
        coordinator.closeSummary()
        #expect(!coordinator.showsSummary && coordinator.canDeleteNow)
    }

    @Test func closingProfileCancelsSummaryNavigation() {
        let coordinator = GardenProfileCoordinator()
        coordinator.openSummary()
        coordinator.close()
        coordinator.editSummary()
        #expect(coordinator.isFinished && !coordinator.showsSummary && coordinator.sheet == nil)
    }
}
