import SwiftUI

// MARK: - Location permission status

/// One line that shows the current location permission and updates live.
struct PermissionStatusView: View {
    // @ObservedObject: OnboardingView owns the manager (@StateObject); this subview only watches it
    @ObservedObject var location: LocationManager

    var body: some View {
        Label(LocationManager.describe(location.authorizationStatus),
              systemImage: LocationManager.symbol(for: location.authorizationStatus))
            .font(.subheadline)
            .foregroundStyle(location.isAuthorized ? Color.sev1 : Color.inkMuted)
            .symbolRenderingMode(.hierarchical)
            .animation(Motion.snappy, value: location.authorizationStatus)
    }
}

// MARK: - Preview

#Preview {
    PermissionStatusView(location: LocationManager())
        .padding()
        .background(Color.asphalt)
}
