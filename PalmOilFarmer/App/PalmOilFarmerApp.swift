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
    private let modelContainer = AppConfiguration.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(modelContainer: modelContainer)
                .tint(KropsTheme.primaryText)
        }
        .modelContainer(modelContainer)
    }
}
