import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenProfilePresentationTests {
    private func makeModel() -> GardenProfileViewModel {
        let garden = profileGarden()
        return GardenProfileViewModel(garden: garden, source: ProfileSourceSpy(gardens: [garden]))
    }

    @Test func savedHighlightRequiresCurrentProfileEditor() throws {
        let model = makeModel()
        model.open(.details)
        let details = try #require(model.sheet)
        model.profileSaved(details)
        #expect(!model.profileJustSaved)
        #expect(model.isCurrent(details))
        model.closeSheet(details)
        model.sheetDidDismiss()
        model.open(.profile)
        let profile = try #require(model.sheet)
        model.profileSaved(details)
        #expect(!model.profileJustSaved)
        model.profileSaved(profile)
        #expect(model.profileJustSaved && model.sheet == nil)
        model.sheetDidDismiss()
        #expect(model.canDeleteNow)
    }

    @Test func editorSessionRemainsLockedUntilDismissalAndOldIdentityExpires() throws {
        let model = makeModel()
        model.open(.profile)
        let first = try #require(model.sheet)
        model.open(.details)
        #expect(model.sheet?.id == first.id)
        model.sheet = nil
        model.open(.details)
        #expect(model.sheet == nil && !model.isCurrent(first))
        model.sheetDidDismiss()
        model.open(.details)
        let second = try #require(model.sheet)
        #expect(second.id != first.id && second.kind == .details)
        model.closeSheet(first)
        #expect(model.isCurrent(second))
        model.closeSheet(second)
        #expect(model.sheet == nil && !model.canDeleteNow)
        model.sheetDidDismiss()
        #expect(model.canDeleteNow)
    }

    @Test func closingProfileInvalidatesEditorAndPreventsFutureRoutes() throws {
        let model = makeModel()
        model.open(.details)
        let sheet = try #require(model.sheet)
        model.close()
        model.sheetDidDismiss()
        model.open(.details)
        model.requestDelete()
        model.reviewAction(.status)
        model.openResults()
        #expect(model.isFinished && !model.isCurrent(sheet) && model.sheet == nil)
        #expect(!model.showsDeleteConfirmation && !model.showsReviewStatus && !model.showsResults)
    }

    @Test func deleteActionWaitsForEditorAndAcceptsNativeDialogDismissalBeforeCallback() {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        let model = makeProfileTestViewModel(garden: garden, source: source)
        model.open(.profile)
        model.requestDelete()
        #expect(!model.showsDeleteConfirmation && !model.delete())
        model.sheet = nil
        model.sheetDidDismiss()
        model.requestDelete()
        model.showsDeleteConfirmation = false
        #expect(model.delete() && model.isFinished)
        #expect(source.gardens.isEmpty)
    }

    @Test func existingStatusAndResultsNavigationCanReturnBeforeOpeningNewEditor() {
        let model = makeModel()
        model.reviewAction(.status)
        model.open(.details)
        #expect(model.showsReviewStatus && model.sheet == nil)
        model.openResults()
        #expect(model.showsResults)
        model.showsResults = false
        model.open(.details)
        #expect(model.sheet == nil)
        model.showsReviewStatus = false
        model.reviewAction(.request)
        #expect(model.sheet?.kind == .review)
    }

    @Test func summaryNavigatesAsPageAndEditingReturnsToSummary() throws {
        let model = makeModel()
        model.openSummary()
        #expect(model.showsSummary && model.sheet == nil)
        #expect(!model.canDeleteNow)
        model.editSummary()
        let editor = try #require(model.sheet)
        #expect(editor.kind == .profile)
        model.profileSaved(editor)
        model.sheetDidDismiss()
        #expect(model.showsSummary && model.sheet == nil)
        model.closeSummary()
        #expect(!model.showsSummary && model.canDeleteNow)
    }

    @Test func closingProfileCancelsSummaryNavigation() {
        let model = makeModel()
        model.openSummary()
        model.close()
        model.editSummary()
        #expect(model.isFinished && !model.showsSummary && model.sheet == nil)
    }
}
