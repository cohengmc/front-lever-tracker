//
//  WorkoutEntryCard.swift
//  front-lever-tracker
//
//  Created by Geoffrey Cohen on 11/4/25.
//

import SwiftUI
import SwiftData

struct WorkoutEntryCard: View {
    let entry: WorkoutEntry
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Date and Time (Left)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
//            Spacer()
            
            // Duration (Middle)
            Text(timeString(from: entry.timeUnderTension))
                .font(.headline)
                .fontWeight(.bold)
            
//            Spacer()
            
            // Visual representation (Right)
            if entry.jointAngles.count == 4 {
                StaticLinesView(
                    blueAngle: entry.jointAngles[0],
                    greenAngle: entry.jointAngles[1],
                    purpleAngle: entry.jointAngles[2],
                    yellowAngle: entry.jointAngles[3],
                    scale: 0.6
                )
                .frame(width: 120, height: 120)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    let sampleEntry = WorkoutEntry(
        date: Date(),
        timeUnderTension: 16.2,
        jointAngles: [235.0, -145.0, -35.0, 70.0]
    )
    
    return List {
        WorkoutEntryCard(entry: sampleEntry)
    }
}

