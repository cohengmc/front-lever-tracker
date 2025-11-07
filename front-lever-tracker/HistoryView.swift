//
//  HistoryView.swift
//  front-lever-tracker
//
//  Created by Geoffrey Cohen on 11/4/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    let entries: [WorkoutEntry]
    
    var todayTotal: TimeInterval {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.filter { Calendar.current.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.timeUnderTension }
    }
    
    var dailyAverage: TimeInterval {
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + $1.timeUnderTension }
        let days = Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
        return total / Double(days)
    }
    
    // Group entries by date
    var groupedEntries: [(date: Date, entries: [WorkoutEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        
        return grouped.map { (date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date } // Most recent first
    }
    
    var body: some View {
        List {
            HStack {
//                Section("Activity Heatmap") {
                    DailyTensionHeatmap(entries: entries)
                        .padding(.vertical, 8)
//                }
                
                VStack{
                    HStack {
                        Text("Today's Total")
                        Spacer()
                        Text(timeString(from: todayTotal))
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Daily Average")
                        Spacer()
                        Text(timeString(from: dailyAverage))
                            .fontWeight(.bold)
                    }
                }
            }
            
            
            ForEach(groupedEntries, id: \.date) { dateGroup in
                Section {
                    ForEach(dateGroup.entries) { entry in
                        EntryRow(entry: entry, modelContext: modelContext)
                    }
                } header: {
                    Text(dateGroup.date, style: .date)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
        }
        .navigationTitle("History")
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    
    // Create dummy entries with varied dates and angles
    let dummyEntries = [
        WorkoutEntry(
            date: now,
            timeUnderTension: 61.0,
            jointAngles: [235.0, -145.0, -35.0, 70.0]
        ),
        WorkoutEntry(
            date: now,
            timeUnderTension: 45.5,
            jointAngles: [220.0, -150.0, -40.0, 65.0]
        ),
        WorkoutEntry(
            date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            timeUnderTension: 78.2,
            jointAngles: [240.0, -140.0, -30.0, 75.0]
        ),
        WorkoutEntry(
            date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
            timeUnderTension: 52.3,
            jointAngles: [230.0, -155.0, -35.0, 68.0]
        ),
        WorkoutEntry(
            date: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
            timeUnderTension: 90.0,
            jointAngles: [225.0, -145.0, -25.0, 72.0]
        )
    ]
    
    return NavigationStack {
        HistoryView(entries: dummyEntries)
    }
}

