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

    var body: some Scene {
        WindowGroup {
            ContentView(
                store: dependencies.gardenStore,
                dashboardViewModel: dependencies.dashboardViewModel,
                coordinator: dependencies.coordinator,
                registrationFactory: dependencies.registrationFactory,
                mappingFactory: dependencies.mappingFactory,
                profileFactory: dependencies.profileFactory
            )
                .environment(\.farmerReviewRepository, dependencies.reviewRepository)
                .tint(KropsTheme.primaryText)
        }
        .modelContainer(dependencies.modelContainer)
    }
}
