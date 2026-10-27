import SwiftUI

struct ReviewTimelineRow: View {
    let entry: ReviewTimelineEntry
    var isLast = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Rectangle()
                .fill(.clear)
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .padding(.top, entry.date == nil ? 12 : 34)
                .overlay(alignment: .top) {
                    Circle()
                        .fill(entry.isReached ? Color.primary : Color.secondary)
                        .frame(width: entry.isReached ? 20 : 12, height: entry.isReached ? 20 : 12)
                        .offset(y: entry.date == nil ? 7 : 24)
                }
                .frame(width: 20)
                .padding(.bottom, isLast ? 0 : -24)

            VStack(alignment: .leading, spacing: 4) {
                if let date = entry.date {
                    Text(date).font(.footnote).foregroundStyle(.secondary)
                }
                Text(entry.title)
                    .font(entry.isReached ? .title2.weight(.semibold) : .headline)
                    .foregroundStyle(entry.isReached ? .primary : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(entry.message)
                    .font(entry.isReached ? .body : .subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
