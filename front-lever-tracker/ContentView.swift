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
                TimerView(
                    onSave: saveEntry,
                    onCancel: { showingTimer = true },
                    initialAngles: getMostRecentAngles()
                )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingTimer = false }) {
                                Label("History", systemImage: "clock.arrow.circlepath")
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
    
    private func saveEntry(time: TimeInterval, jointAngles: [Float]) {
        let entry = WorkoutEntry(date: Date(), timeUnderTension: time, jointAngles: jointAngles)
        modelContext.insert(entry)
        showingTimer = true
    }
    
    private func getMostRecentAngles() -> [Float]? {
        guard let mostRecent = entries.first, mostRecent.jointAngles.count == 4 else {
            return nil
        }
        return mostRecent.jointAngles
    }
}

// MARK: - Timer View

struct TimerView: View {
    @State private var timerState: TimerState = .ready
    @State private var countdown = 3
    @State private var elapsedTime: TimeInterval = 0
    @State private var displayTime: TimeInterval = 0
    @State private var timer: Timer?
    
    // Joint angles state - initialized from most recent entry or defaults
    @State private var blueAngle: Angle
    @State private var greenAngle: Angle
    @State private var purpleAngle: Angle
    @State private var yellowAngle: Angle
    
    // Continuous adjustment state
    @State private var adjustmentTimer: Timer?
    @State private var isAdjusting = false
    
    let onSave: (TimeInterval, [Float]) -> Void
    let onCancel: () -> Void
    
    init(onSave: @escaping (TimeInterval, [Float]) -> Void, onCancel: @escaping () -> Void, initialAngles: [Float]? = nil) {
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Use initial angles if provided, otherwise use defaults
        if let angles = initialAngles, angles.count == 4 {
            _blueAngle = State(initialValue: Angle(degrees: Double(angles[0])))
            _greenAngle = State(initialValue: Angle(degrees: Double(angles[1])))
            _purpleAngle = State(initialValue: Angle(degrees: Double(angles[2])))
            _yellowAngle = State(initialValue: Angle(degrees: Double(angles[3])))
        } else {
            _blueAngle = State(initialValue: Angle(degrees: 235.0))
            _greenAngle = State(initialValue: Angle(degrees: -145.0))
            _purpleAngle = State(initialValue: Angle(degrees: -35.0))
            _yellowAngle = State(initialValue: Angle(degrees: 70.0))
        }
    }
    
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
            
            //Spacer()
            
            // Control Buttons
            if timerState == .stopped {
                adjustmentButtons
                
                Text("Adjust Positioning")
                    .font(.title2)
                    .fontWeight(.bold)
                
                ManipulableLinesView(
                    blueAngle: $blueAngle,
                    greenAngle: $greenAngle,
                    purpleAngle: $purpleAngle,
                    yellowAngle: $yellowAngle
                )
                .frame(height: 200)
                
                Spacer()
                
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
            
            controlButtons
            
            Spacer()
        }
        .padding()
    }
    
    private var adjustmentButtons: some View {
        HStack(spacing:24) {
            ContinuousAdjustButton(
                action: { adjustTime(-0.1) },
                icon: "minus.circle.fill",
                color: .red,
                onPressStart: { startContinuousAdjustment(-0.1) },
                onPressEnd: { stopContinuousAdjustment() }
            )
            
            Text("Adjust Time")
                .font(.title2)
                .fontWeight(.bold)
            
            ContinuousAdjustButton(
                action: { adjustTime(0.1) },
                icon: "plus.circle.fill",
                color: .green,
                onPressStart: { startContinuousAdjustment(0.1) },
                onPressEnd: { stopContinuousAdjustment() }
            )
        }
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
    
    private func startContinuousAdjustment(_ amount: TimeInterval) {
        // Start repeating timer for continuous adjustment
        // Note: Initial adjustment is already done by the button's action
        adjustmentTimer?.invalidate()
        adjustmentTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            adjustTime(amount)
        }
        isAdjusting = true
    }
    
    private func stopContinuousAdjustment() {
        adjustmentTimer?.invalidate()
        adjustmentTimer = nil
        isAdjusting = false
    }
    
    private func saveWorkout() {
        let jointAngles: [Float] = [
            Float(blueAngle.degrees),
            Float(greenAngle.degrees),
            Float(purpleAngle.degrees),
            Float(yellowAngle.degrees)
        ]
        onSave(displayTime, jointAngles)
        resetTimer()
    }
    
    private func resetTimer() {
        stopContinuousAdjustment()
        timerState = .ready
        elapsedTime = 0
        displayTime = 0
        countdown = 3
        // Reset angles to default values
        blueAngle = Angle(degrees: 235.0)
        greenAngle = Angle(degrees: -145.0)
        purpleAngle = Angle(degrees: -35.0)
        yellowAngle = Angle(degrees: 70.0)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
    }
}

// MARK: - Continuous Adjust Button

struct ContinuousAdjustButton: View {
    let action: () -> Void
    let icon: String
    let color: Color
    let onPressStart: () -> Void
    let onPressEnd: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 45))
            .foregroundColor(color)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            action() // Initial tap
                            onPressStart() // Start continuous adjustment
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onPressEnd()
                    }
            )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WorkoutEntry.self, inMemory: true)
}
