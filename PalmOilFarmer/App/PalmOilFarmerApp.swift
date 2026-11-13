//
//  PalmOilFarmerApp.swift
//  PalmOilFarmer
//
//  Created by Hatami Sugandi on 19/10/26.
//

import SwiftUI
import SwiftData

@main
struct PalmOilFarmerApp: App {
    private let dependencies = AppDependencies.live()

    /// true = buka eksperimen FindingWaypoint + Semprot pupuk (ESP32).
    /// Release build selalu membuka app normal.
    #if DEBUG
    private static let runsExperiment = true
    #else
    private static let runsExperiment = false
    #endif

    var body: some Scene {
        WindowGroup {
            Group {
                if Self.runsExperiment {
                    FindingWaypointView()
                } else {
                    ContentView(
                        store: dependencies.gardenStore,
                        dashboardViewModel: dependencies.dashboardViewModel,
                        coordinator: dependencies.coordinator,
                        registrationFactory: dependencies.registrationFactory,
                        mappingFactory: dependencies.mappingFactory,
                        profileFactory: dependencies.profileFactory
                    )
                }
            }
            .environment(\.farmerReviewRepository, dependencies.reviewRepository)
            .tint(KropsTheme.primaryText)
        }
        .modelContainer(dependencies.modelContainer)
    }
}
