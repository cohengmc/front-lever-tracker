//
//  ContentView.swift
//  front-lever-tracker
//
//  Created by Geoffrey Cohen on 11/4/25.
//

import SwiftUI
import SwiftData

// MARK: - Content View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var entries: [WorkoutEntry]
    @State private var showingTimer = true
    
    var body: some View {
        NavigationStack {
            if showingTimer {
                TimerView(onSave: saveEntry, onCancel: { showingTimer = true })
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingTimer = false }) {
                                Label("History", systemImage: "clock")
                            }
                        }
                    }
            } else {
                HistoryView(entries: entries)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showingTimer = true }) {
                                Label("Timer", systemImage: "timer")
                            }
                        }
                    }
            }
        }
    }
    
    private func saveEntry(time: TimeInterval, poseIndex: Int) {
        let entry = WorkoutEntry(date: Date(), timeUnderTension: time, poseIndex: poseIndex)
        modelContext.insert(entry)
        showingTimer = true
    }
}

// MARK: - Timer View

struct TimerView: View {
    @State private var timerState: TimerState = .ready
    @State private var countdown = 3
    @State private var elapsedTime: TimeInterval = 0
    @State private var displayTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var selectedPoseIndex = 0
    @State private var showPoseSelection = false
    
    let onSave: (TimeInterval, Int) -> Void
    let onCancel: () -> Void
    
    enum TimerState {
        case ready, countdown, running, stopped
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Front Lever Timer")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            // Timer Display
            if timerState == .countdown {
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(.orange)
            } else {
                Text(timeString(from: timerState == .stopped ? displayTime : elapsedTime))
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .foregroundColor(timerState == .running ? .green : .primary)
            }
            
            Spacer()
            
            // Control Buttons
            if timerState == .stopped {
                adjustmentButtons
                
                if showPoseSelection {
                    poseSelectionView
                }
            }
            
            controlButtons
            
            Spacer()
        }
        .padding()
    }
    
    private var adjustmentButtons: some View {
        HStack(spacing: 40) {
            Button(action: { adjustTime(-0.1) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
            }
            
            Text("Adjust Time")
                .font(.headline)
            
            Button(action: { adjustTime(0.1) }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
    
    private var poseSelectionView: some View {
        VStack(spacing: 20) {
            Text("Select Pose")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Magnified selected pose
            PoseImageView(index: selectedPoseIndex, size: 200)
            
            // Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(0..<6) { index in
                        PoseImageView(index: index, size: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedPoseIndex == index ? Color.blue : Color.clear, lineWidth: 3)
                            )
                            .onTapGesture {
                                withAnimation {
                                    selectedPoseIndex = index
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 100)
            
            Button(action: saveWorkout) {
                Text("Save Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding()
    }
    
    private var controlButtons: some View {
        HStack(spacing: 20) {
            if timerState == .ready {
                Button(action: startCountdown) {
                    Text("Start")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(Color.green)
                        .cornerRadius(15)
                }
            } else if timerState == .running {
                Button(action: stopTimer) {
                    Text("Stop")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(Color.red)
                        .cornerRadius(15)
                }
            } else if timerState == .stopped && !showPoseSelection {
                Button(action: { showPoseSelection = true }) {
                    Text("Next")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(Color.blue)
                        .cornerRadius(15)
                }
            }
        }
    }
    
    private func startCountdown() {
        timerState = .countdown
        countdown = 3
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer?.invalidate()
                startTimer()
            }
        }
    }
    
    private func startTimer() {
        timerState = .running
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timerState = .stopped
        displayTime = elapsedTime
    }
    
    private func adjustTime(_ amount: TimeInterval) {
        displayTime = max(0, displayTime + amount)
    }
    
    private func saveWorkout() {
        onSave(displayTime, selectedPoseIndex)
        resetTimer()
    }
    
    private func resetTimer() {
        timerState = .ready
        elapsedTime = 0
        displayTime = 0
        countdown = 3
        showPoseSelection = false
        selectedPoseIndex = 0
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
    }
}

// MARK: - Pose Image View

struct PoseImageView: View {
    let index: Int
    let size: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.2))
            
            VStack {
                Image(systemName: poseIcon(for: index))
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.blue)
                
                Text(poseName(for: index))
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .frame(width: size, height: size)
    }
    
    private func poseIcon(for index: Int) -> String {
        let icons = ["figure.stand", "figure.arms.open", "figure.flexibility", 
                     "figure.core.training", "figure.mind.and.body", "figure.strengthtraining.traditional"]
        return icons[index]
    }
    
    private func poseName(for index: Int) -> String {
        ["Tuck", "Advanced Tuck", "Straddle", "Half Lay", "Full Lay", "One Arm"][index]
    }
}

// MARK: - History View

struct HistoryView: View {
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
    
    var body: some View {
        List {
            Section("Statistics") {
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
            
            Section("Workout History") {
                ForEach(entries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.date, style: .date)
                                .font(.headline)
                            Text(entry.date, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(timeString(from: entry.timeUnderTension))
                                .font(.headline)
                            Text(poseName(for: entry.poseIndex))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
    
    private func poseName(for index: Int) -> String {
        ["Tuck", "Advanced Tuck", "Straddle", "Half Lay", "Full Lay", "One Arm"][index]
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WorkoutEntry.self, inMemory: true)
}