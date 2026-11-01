import SwiftUI

// MARK: - Onboarding (3 pages, shown once)

struct OnboardingView: View {
    // @Binding: RootTabView owns the "completed" flag; this view flips it to dismiss the cover
    @Binding var hasCompleted: Bool
    // @State: paging state is local to this screen
    @State private var pageIndex = 0
    @State private var movingForward = true
    // @StateObject: this view owns the location manager's lifecycle
    @StateObject private var location = LocationManager()
    // @Environment: custom animations must honour Reduce Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = OnboardingPage.all
    private var page: OnboardingPage { pages[pageIndex] }
    private var isLastPage: Bool { pageIndex == pages.count - 1 }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.asphalt.ignoresSafeArea()
            VStack(spacing: 24) {
                topBar
                RoadIllustration()
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .cardStyle()
                ZStack {
                    pageContent
                }
                .frame(maxWidth: .infinity, minHeight: 190, alignment: .top)
                .clipped()
                Spacer(minLength: 0)
                LanePageIndicator(count: pages.count, current: pageIndex)
                actions
            }
            .padding(16)
        }
        .gesture(swipe)
        .onChange(of: location.authorizationStatus) { _, status in
            // The user answered the system prompt, so the intro is finished.
            if isLastPage, status != .notDetermined { finish() }
        }
    }

    // MARK: Subviews

    private var topBar: some View {
        HStack {
            Spacer()
            if !isLastPage {
                Button("Skip", action: finish)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkMuted)
            }
        }
        .frame(minHeight: 32)
    }

    private var pageContent: some View {
        VStack(spacing: 12) {
            Image(systemName: page.symbol)
                .font(.system(size: 36))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.laneYellow)
                .symbolEffect(.bounce, value: pageIndex)
            Text(page.title)
                .font(.title.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
            Text(page.message)
                .font(.body)
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
            if page.asksForPermission {
                PermissionStatusView(location: location)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .id(pageIndex)
        .transition(reduceMotion ? .opacity : slide)
        .accessibilityElement(children: .contain)
    }

    private var actions: some View {
        VStack(spacing: 8) {
            PrimaryButton(title: primaryTitle, systemImage: isLastPage ? "location.fill" : nil, action: primaryAction)
            if isLastPage, location.authorizationStatus == .notDetermined {
                Button("Not now", action: finish)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }

    // MARK: Paging

    /// Asymmetric: the new page slides in from one side while the old one leaves by the other.
    private var slide: AnyTransition {
        let inEdge: Edge = movingForward ? .trailing : .leading
        let outEdge: Edge = movingForward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: inEdge).combined(with: .opacity),
            removal: .move(edge: outEdge).combined(with: .opacity)
        )
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 30).onEnded { value in
            if value.translation.width < -50 {
                go(to: pageIndex + 1)
            } else if value.translation.width > 50 {
                go(to: pageIndex - 1)
            }
        }
    }

    private func go(to newIndex: Int) {
        guard pages.indices.contains(newIndex), newIndex != pageIndex else { return }
        // A removal transition is the one the outgoing view already had, so the direction is
        // set first and the page change is applied in a follow-up main-actor task.
        movingForward = newIndex > pageIndex
        Task { @MainActor in
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : Motion.smooth) {
                pageIndex = newIndex
            }
        }
    }

    // MARK: Actions

    private var primaryTitle: String {
        guard isLastPage else { return "Next" }
        return location.authorizationStatus == .notDetermined ? "Allow location" : "Get started"
    }

    private func primaryAction() {
        if !isLastPage {
            go(to: pageIndex + 1)
        } else if location.authorizationStatus == .notDetermined {
            location.requestWhenInUse()
        } else {
            finish()
        }
    }

    private func finish() {
        hasCompleted = true
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompleted: .constant(false))
}
