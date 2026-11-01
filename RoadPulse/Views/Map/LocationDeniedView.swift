import SwiftUI

// MARK: - Location denied

/// Shown over the map when location access is denied or restricted. The map still works;
/// only "near me" features need location.
struct LocationDeniedView: View {
    let isRestricted: Bool

    // @Environment: opens the app's page in the Settings app
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Severity.high.color)
            VStack(alignment: .leading, spacing: 8) {
                Text(isRestricted ? "Location is restricted" : "Location is off")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.ink)
                Text(isRestricted
                     ? "This device doesn't allow location access, so we can't show where you are."
                     : "Turn on location to see where you are and to geotag your reports.")
                    .font(.footnote)
                    .foregroundStyle(Color.inkMuted)
                if !isRestricted {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .tint(Color.laneYellow)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .cardStyle()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        LocationDeniedView(isRestricted: false)
        LocationDeniedView(isRestricted: true)
    }
    .padding()
    .background(Color.asphalt)
}
