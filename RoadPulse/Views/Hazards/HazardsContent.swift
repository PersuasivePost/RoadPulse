import CoreData
import SwiftUI

// MARK: - Hazards list / gallery

/// Rebuilt by `HazardsScreen` whenever the filters or search change, which gives its
/// `SectionedFetchRequest` a new predicate; Core Data does the filtering, so results are instant.
struct HazardsContent: View {
    // @SectionedFetchRequest: live hazards grouped into one section per Area
    @SectionedFetchRequest private var sections: SectionedFetchResults<String, Hazard>
    // @ObservedObject: the screen owns the view model; this view only calls its actions
    @ObservedObject var viewModel: HazardsViewModel
    let layout: HazardsLayout
    let namespace: Namespace.ID
    let detailID: UUID?
    let isUnfiltered: Bool
    // @Binding: the screen shows the delete confirmation
    @Binding var pendingDeleteID: UUID?
    let onSelect: (UUID) -> Void
    let onReport: () -> Void
    let onClearFilters: () -> Void

    // @State: whether the first row is on screen decides if the jump-to-top button shows
    @State private var isAtTop = true
    // @Environment: scrolling animations are skipped when Reduce Motion is on
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(query: HazardQuery,
         viewModel: HazardsViewModel,
         layout: HazardsLayout,
         namespace: Namespace.ID,
         detailID: UUID?,
         pendingDeleteID: Binding<UUID?>,
         onSelect: @escaping (UUID) -> Void,
         onReport: @escaping () -> Void,
         onClearFilters: @escaping () -> Void) {
        _sections = SectionedFetchRequest(fetchRequest: query.groupedByAreaRequest(),
                                          sectionIdentifier: \.areaSectionName,
                                          animation: .default)
        self.viewModel = viewModel
        self.layout = layout
        self.namespace = namespace
        self.detailID = detailID
        isUnfiltered = query.predicate == nil
        _pendingDeleteID = pendingDeleteID
        self.onSelect = onSelect
        self.onReport = onReport
        self.onClearFilters = onClearFilters
    }

    private var flat: [Hazard] { sections.flatMap { $0 } }

    // MARK: Body

    var body: some View {
        Group {
            if sections.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if layout == .list { list } else { grid }
                        }
                        .safeAreaPadding(.trailing, 28) // room for the index strip
                        overlays(proxy: proxy)
                    }
                }
            }
        }
        .background(Color.asphalt.ignoresSafeArea())
    }

    // MARK: List

    private var list: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section) { hazard in
                        HazardRow(hazard: hazard, namespace: namespace,
                                  isHeroSource: detailID != hazard.id) { onSelect(hazard.id) }
                            .reportsTop(hazard.id == flat.first?.id, $isAtTop)
                            .listRowBackground(Color.surface)
                            .listRowSeparatorTint(Color.inkMuted.opacity(0.12))
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button { resolve(hazard) } label: {
                                    Label(hazard.isFixed ? "Reopen" : "Resolve",
                                          systemImage: hazard.isFixed ? "arrow.uturn.backward" : "checkmark.circle.fill")
                                }
                                .tint(hazard.isFixed ? Color.laneYellow : Color.sev1)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { pendingDeleteID = hazard.id } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu { menu(for: hazard) } preview: { HazardPreviewCard(hazard: hazard) }
                    }
                } header: {
                    sectionHeader(section.id, count: section.count)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.refresh() }
    }

    // MARK: Grid

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
                      spacing: 12, pinnedViews: [.sectionHeaders]) {
                ForEach(sections) { section in
                    Section {
                        ForEach(section) { hazard in
                            HazardGridCell(hazard: hazard, namespace: namespace,
                                           isHeroSource: detailID != hazard.id) { onSelect(hazard.id) }
                                .reportsTop(hazard.id == flat.first?.id, $isAtTop)
                                .contextMenu { menu(for: hazard) } preview: { HazardPreviewCard(hazard: hazard) }
                        }
                    } header: {
                        sectionHeader(section.id, count: section.count)
                            .padding(.vertical, 8)
                            .background(Color.asphalt)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .refreshable { await viewModel.refresh() }
    }

    // MARK: Pieces

    private func sectionHeader(_ name: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            Text("\(count)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.laneYellow.opacity(0.25)))
            Spacer()
        }
        .textCase(nil)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func menu(for hazard: Hazard) -> some View {
        Button { resolve(hazard) } label: {
            Label(hazard.isFixed ? "Reopen" : "Mark fixed",
                  systemImage: hazard.isFixed ? "arrow.uturn.backward" : "checkmark.circle")
        }
        Button {
            DirectionsLauncher.openInMaps(to: hazard.coordinate, name: hazard.displayTitle)
        } label: {
            Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
        }
        ShareLink(item: hazard.shareSummary) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        Button(role: .destructive) { pendingDeleteID = hazard.id } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func overlays(proxy: ScrollViewProxy) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if flat.count >= 5 {
                SeverityIndexStrip(available: Set(flat.map(\.severityLevel))) { severity in
                    Haptics.tap()
                    if let id = SeverityIndex.firstHazardID(with: severity, in: flat) {
                        scroll(proxy, to: id)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 4)
            }
            if !isAtTop, let firstID = flat.first?.id {
                Button {
                    Haptics.tap()
                    scroll(proxy, to: firstID)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.headline)
                        .foregroundStyle(Color.ink)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.laneYellow))
                        .environment(\.colorScheme, .light) // dark ink on yellow in both appearances
                        .shadow(color: Color.black.opacity(0.2), radius: 6, y: 2)
                }
                .buttonStyle(PressScaleButtonStyle())
                .padding(16)
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                .accessibilityLabel("Back to top")
            }
        }
        .animation(reduceMotion ? nil : Motion.snappy, value: isAtTop)
    }

    @ViewBuilder
    private var emptyState: some View {
        if isUnfiltered {
            EmptyState(title: "No reports yet",
                       message: "Photograph a pothole and it will be listed here.",
                       actionTitle: "Report a hazard", action: onReport)
        } else {
            EmptyState(title: "No matches",
                       message: "Try a different search, or clear the filters.",
                       actionTitle: "Clear filters", action: onClearFilters)
        }
    }

    // MARK: Actions

    private func resolve(_ hazard: Hazard) {
        if !hazard.isFixed { Haptics.success() }
        viewModel.toggleFixed(hazard)
    }

    private func scroll(_ proxy: ScrollViewProxy, to id: UUID) {
        withAnimation(reduceMotion ? nil : Motion.smooth) {
            proxy.scrollTo(id, anchor: .top)
        }
    }
}

// MARK: - Top-of-list tracking

private extension View {
    /// Keeps `isAtTop` true while the first row is on screen (lazy rows appear/disappear as they scroll).
    func reportsTop(_ isFirst: Bool, _ isAtTop: Binding<Bool>) -> some View {
        onAppear { if isFirst { isAtTop.wrappedValue = true } }
            .onDisappear { if isFirst { isAtTop.wrappedValue = false } }
    }
}
