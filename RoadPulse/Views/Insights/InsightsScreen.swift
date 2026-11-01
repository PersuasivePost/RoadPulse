import CoreLocation
import MapKit
import SwiftUI

// MARK: - Insights tab

struct InsightsScreen: View {
    // @FetchRequest: every hazard, live; the numbers recompute when reports change
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)], animation: .default)
    private var hazards: FetchedResults<Hazard>
    // @EnvironmentObject: the user's location decides what "near me" means
    @EnvironmentObject private var location: LocationManager
    // @AppStorage: distances follow the Settings unit
    @AppStorage(SettingsKey.units) private var units: UnitSystem = SettingsKey.Default.units

    /// Falls back to the middle of the demo area until a location fix arrives.
    private var origin: CLLocationCoordinate2D {
        location.location?.coordinate ?? MapCamera.mumbaiRegion.center
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let stats = InsightsStats(hazards: Array(hazards), origin: origin)
                VStack(spacing: 16) {
                    statRow(stats)
                    if stats.total == 0 {
                        emptyCard
                    } else {
                        BarChart(data: stats.perArea)
                        SeverityDonut(counts: stats.severityCounts)
                        WorstRoadsList(roads: stats.worstRoads, units: units)
                    }
                }
                .padding(16)
            }
            .background(Color.asphalt.ignoresSafeArea())
            .navigationTitle("Insights")
        }
    }

    private func statRow(_ stats: InsightsStats) -> some View {
        HStack(spacing: 12) {
            StatCard(title: "Reports", value: Double(stats.total), symbol: "list.bullet.rectangle")
            StatCard(title: "Fixed", value: stats.fixedPercent, suffix: "%",
                     symbol: "checkmark.circle", tint: Color.sev1)
            StatCard(title: "Avg severity", value: stats.averageSeverity, decimals: 1,
                     symbol: "exclamationmark.triangle", tint: Color.sev4)
        }
    }

    private var emptyCard: some View {
        Text("Charts appear once you have reported a hazard.")
            .font(.subheadline)
            .foregroundStyle(Color.inkMuted)
            .padding(16)
            .frame(maxWidth: .infinity)
            .cardStyle()
    }
}

// MARK: - Preview

#Preview {
    InsightsScreen()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .environmentObject(LocationManager())
}
