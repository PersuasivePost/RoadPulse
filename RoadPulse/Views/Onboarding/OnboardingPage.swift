import Foundation

// MARK: - Onboarding content

struct OnboardingPage: Identifiable, Equatable {
    let id: Int
    let symbol: String
    let title: String
    let message: String
    /// The last page asks for location access.
    let asksForPermission: Bool

    static let all: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            symbol: "camera.viewfinder",
            title: "Spot the hazard",
            message: "Photograph a pothole or crack on your commute. It takes about ten seconds.",
            asksForPermission: false
        ),
        OnboardingPage(
            id: 1,
            symbol: "cpu",
            title: "Checked on your phone",
            message: "An AI model on your device confirms the hazard. Your photos never leave your phone.",
            asksForPermission: false
        ),
        OnboardingPage(
            id: 2,
            symbol: "location.fill",
            title: "Pin it on the map",
            message: "Allow location so reports are geotagged and you can see hazards nearby. "
                + "Camera and motion access are requested when you first use them.",
            asksForPermission: true
        ),
    ]
}
