//
//  front_lever_trackerApp.swift
//  front-lever-tracker
//
//  Created by Geoffrey Cohen on 11/4/25.
//

import SwiftUI
import SwiftData

// MARK: - Main App

@main
struct front_lever_trackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: WorkoutEntry.self)
    }
}