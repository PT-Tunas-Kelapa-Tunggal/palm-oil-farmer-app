import SwiftUI

/// Sheet composition; the presenting profile owns its route and submission lifetime.
struct ReviewSubmissionView: View {
    @Binding var showsReviewForm: Bool
    let onSubmit: (ReviewContactDetails) async throws -> Void

    var body: some View {
        NavigationStack {
            ReviewRequestScreen { showsReviewForm = true }
                .navigationDestination(isPresented: $showsReviewForm) {
                    ReviewContactFormScreen(onSubmit: onSubmit)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }
}
