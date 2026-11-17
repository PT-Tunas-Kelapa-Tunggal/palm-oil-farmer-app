import Testing
@testable import PalmOilFarmer

struct BoundaryDrawingGuideStateTests {
    @Test func primaryActionsShowBothDemonstrationsBeforeStartingMapping() {
        var guide = BoundaryDrawingGuideState()
        #expect(guide.step == .zoom)
        let advancedToTap = guide.advance()
        #expect(advancedToTap)
        #expect(guide.step == .tap)
        let stayedInGuide = guide.advance()
        #expect(!stayedInGuide)
        #expect(guide.step == .tap)
    }

    @Test func backReturnsToZoomBeforeLeavingForLocationConfirmation() {
        var guide = BoundaryDrawingGuideState()
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
