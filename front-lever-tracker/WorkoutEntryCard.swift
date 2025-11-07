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

// MARK: - Entry Row Component (for grouped display)

struct EntryRow: View {
    let entry: WorkoutEntry
    let modelContext: ModelContext
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Time (Left)
            Text(entry.date, style: .time)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Duration (Middle)
            Text(timeString(from: entry.timeUnderTension))
                .font(.headline)
                .fontWeight(.bold)
            
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
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditEntrySheet(entry: entry, modelContext: modelContext)
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
            }
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Edit Entry Sheet

struct EditEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: WorkoutEntry
    let modelContext: ModelContext
    
    @State private var editedDate: Date
    @State private var editedTimeUnderTension: TimeInterval
    @State private var blueAngle: Angle
    @State private var greenAngle: Angle
    @State private var purpleAngle: Angle
    @State private var yellowAngle: Angle
    
    // Time picker components
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0
    @State private var selectedMilliseconds: Int = 0
    
    init(entry: WorkoutEntry, modelContext: ModelContext) {
        self.entry = entry
        self.modelContext = modelContext
        
        _editedDate = State(initialValue: entry.date)
        _editedTimeUnderTension = State(initialValue: entry.timeUnderTension)
        
        if entry.jointAngles.count == 4 {
            _blueAngle = State(initialValue: Angle(degrees: Double(entry.jointAngles[0])))
            _greenAngle = State(initialValue: Angle(degrees: Double(entry.jointAngles[1])))
            _purpleAngle = State(initialValue: Angle(degrees: Double(entry.jointAngles[2])))
            _yellowAngle = State(initialValue: Angle(degrees: Double(entry.jointAngles[3])))
        } else {
            _blueAngle = State(initialValue: Angle(degrees: 235.0))
            _greenAngle = State(initialValue: Angle(degrees: -145.0))
            _purpleAngle = State(initialValue: Angle(degrees: -35.0))
            _yellowAngle = State(initialValue: Angle(degrees: 70.0))
        }
        
        // Initialize time picker components from timeUnderTension
        let totalSeconds = Int(entry.timeUnderTension)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let milliseconds = Int((entry.timeUnderTension.truncatingRemainder(dividingBy: 1)) * 1000)
        
        _selectedMinutes = State(initialValue: minutes)
        _selectedSeconds = State(initialValue: seconds)
        _selectedMilliseconds = State(initialValue: milliseconds)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date & Time") {
                    DatePicker("Date and Time", selection: $editedDate)
                }
                
                Section("Duration") {
                    HStack {
                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        
                        Text(":")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Picker("Seconds", selection: $selectedSeconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        
                        Text(".")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Picker("Milliseconds", selection: $selectedMilliseconds) {
                            ForEach(0..<1000) { millisecond in
                                Text(String(format: "%03d", millisecond)).tag(millisecond)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                    }
                    .frame(height: 150)
                }
                
                Section("Joint Angles") {
                    ManipulableLinesView(
                        blueAngle: $blueAngle,
                        greenAngle: $greenAngle,
                        purpleAngle: $purpleAngle,
                        yellowAngle: $yellowAngle
                    )
                    .frame(height: 300)
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        // Update time under tension from picker components
        editedTimeUnderTension = TimeInterval(selectedMinutes * 60 + selectedSeconds) + TimeInterval(selectedMilliseconds) / 1000.0
        
        // Update entry properties
        entry.date = editedDate
        entry.timeUnderTension = editedTimeUnderTension
        entry.jointAngles = [
            Float(blueAngle.degrees),
            Float(greenAngle.degrees),
            Float(purpleAngle.degrees),
            Float(yellowAngle.degrees)
        ]
        
        dismiss()
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

