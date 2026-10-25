import SwiftUI

/// Stand-in for screens belonging to later milestones. Clearly labeled
/// so nothing reads as finished or silently succeeds.
struct DevelopmentPlaceholderView: View {
    let title: String
    let milestone: String

    var body: some View {
        VStack(spacing: Theme.Spacing.cardGap) {
            Spacer()
            Image(systemName: "hammer")
                .font(.largeTitle)
                .foregroundStyle(Color.caSecondary)
            Text(title)
                .font(.headline)
            Text("Development placeholder — \(milestone)")
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.caBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
