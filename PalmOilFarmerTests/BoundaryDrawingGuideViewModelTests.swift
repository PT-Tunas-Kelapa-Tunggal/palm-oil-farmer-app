import Testing
@testable import PalmOilFarmer

@MainActor
struct BoundaryDrawingGuideViewModelTests {
    @Test func primaryActionsShowBothDemonstrationsBeforeStartingMapping() {
        let guide = BoundaryDrawingGuideViewModel()
        #expect(guide.step == .zoom)
        let advancedToTap = guide.advance()
        #expect(advancedToTap)
        #expect(guide.step == .tap)
        let stayedInGuide = guide.advance()
        #expect(!stayedInGuide)
        #expect(guide.step == .tap)
    }

    @Test func backReturnsToZoomBeforeLeavingForLocationConfirmation() {
        let guide = BoundaryDrawingGuideViewModel()
        let stayedOnFirstPage = guide.goBack()
        #expect(!stayedOnFirstPage)
        let advancedToTap = guide.advance()
        #expect(advancedToTap)
        let returnedToZoom = guide.goBack()
        #expect(returnedToZoom)
        #expect(guide.step == .zoom)
        let stayedInGuide = guide.goBack()
        #expect(!stayedInGuide)
        let advancedAgain = guide.advance()
        #expect(advancedAgain)
        #expect(guide.step == .tap)
    }
}
