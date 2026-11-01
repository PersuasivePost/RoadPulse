import SwiftUI

// MARK: - Shown instead of the app when the database can't open

struct StoreErrorView: View {
    let error: PersistenceError

    var body: some View {
        ZStack {
            Color.asphalt.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Severity.severe.color)
                Text("Can't open your reports")
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.ink)
                Text(error.errorDescription ?? "")
                    .font(.body)
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }
}

// MARK: - Preview

#Preview {
    StoreErrorView(error: .storeUnavailable("preview"))
}
