//
//  DailyTensionHeatmap.swift
//  front-lever-tracker
//
//  Created by Geoffrey Cohen on 11/4/25.
//

import SwiftUI
import Charts
import SwiftData

// MARK: - Data Model

struct DailyTensionData: Identifiable {
    let id = UUID()
    let date: Date
    let weekday: Int  // 0 = Sunday, 6 = Saturday
    let week: Int     // Week number (0-based, relative to start date)
    let totalTime: TimeInterval
}

// MARK: - Heatmap View

struct DailyTensionHeatmap: View {
    let entries: [WorkoutEntry]
    
    private var heatmapData: [DailyTensionData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        
        // Create a dictionary to aggregate daily totals
        var dailyTotals: [Date: TimeInterval] = [:]
        
        // Process entries within the 30-day range
        for entry in entries {
            let entryDate = calendar.startOfDay(for: entry.date)
            if entryDate >= startDate && entryDate <= today {
                dailyTotals[entryDate, default: 0] += entry.timeUnderTension
            }
        }
        
        // Create data points for all 30 days
        var data: [DailyTensionData] = []
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let totalTime = dailyTotals[date] ?? 0
            
            // Get weekday (0 = Sunday, 6 = Saturday)
            let weekday = (calendar.component(.weekday, from: date) - 1) % 7
            
            // Calculate week number (0-based, relative to start date)
            let week = dayOffset / 7
            
            data.append(DailyTensionData(
                date: date,
                weekday: weekday,
                week: week,
                totalTime: totalTime
            ))
        }
        
        return data
    }
    
    private var maxDailyTotal: TimeInterval {
        heatmapData.map(\.totalTime).max() ?? 1.0
    }
    
    var body: some View {
        Chart(heatmapData) { data in
            Plot {
                RectangleMark(
                    xStart: .value("Week Start", Double(data.week)),
                    xEnd: .value("Week End", Double(data.week) + 1),
                    yStart: .value("Weekday Start", Double(data.weekday)),
                    yEnd: .value("Weekday End", Double(data.weekday) + 1)
                )
                .foregroundStyle(by: .value("Time", data.totalTime))
            }
            .accessibilityLabel(data.date.formatted(date: .complete, time: .omitted))
            .accessibilityValue("\(formatTime(data.totalTime)) under tension")
        }
        .chartForegroundStyleScale(range: Gradient(colors: [.white.opacity(0.3), .green]))
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 7, roundLowerBound: false, roundUpperBound: false)) { _ in
                AxisGridLine(stroke: .init(lineWidth: 0.5))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5, roundLowerBound: false, roundUpperBound: false)) { _ in
                AxisGridLine(stroke: .init(lineWidth: 0.5))
            }
        }
        .chartYScale(domain: .automatic(reversed: true))
        .chartLegend(.hidden)
        .aspectRatio(5.0/7.0, contentMode: .fit)
        .accessibilityChartDescriptor(self)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        if timeInterval == 0 {
            return "No time"
        }
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Accessibility

extension DailyTensionHeatmap: AXChartDescriptorRepresentable {
    func makeChartDescriptor() -> AXChartDescriptor {
        let data = heatmapData
        _ = maxDailyTotal
        
        // Get ranges for axes
        let weekMin = data.map(\.week).min() ?? 0
        let weekMax = data.map(\.week).max() ?? 0
        let weekdayMin = 0
        let weekdayMax = 6
        
        // Create weekday labels for accessibility
        let weekdayLabels = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        
        let xAxis = AXNumericDataAxisDescriptor(
            title: "Week",
            range: Double(weekMin)...Double(weekMax + 1),
            gridlinePositions: Array(weekMin...weekMax + 1).map { Double($0) }
        ) { value in
            "Week \(Int(value) + 1)"
        }
        
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Day of Week",
            range: Double(weekdayMin)...Double(weekdayMax + 1),
            gridlinePositions: Array(weekdayMin...weekdayMax + 1).map { Double($0) }
        ) { value in
            let weekday = Int(value)
            if weekday >= 0 && weekday < weekdayLabels.count {
                return weekdayLabels[weekday]
            }
            return "Day \(weekday)"
        }
        
        let dataPoints = data.map { point in
            AXDataPoint(
                x: Double(point.week),
                y: Double(point.weekday),
                additionalValues: [.number(Double(point.totalTime))],
                label: point.date.formatted(date: .complete, time: .omitted)
            )
        }
        
        let series = AXDataSeriesDescriptor(
            name: "Daily Time Under Tension",
            isContinuous: false,
            dataPoints: dataPoints
        )
        
        return AXChartDescriptor(
            title: "30-Day Activity Heatmap",
            summary: "Shows daily time under tension for the past 30 days. Darker green indicates more time.",
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    
    // Create dummy entries spread over the past 30 days
    var dummyEntries: [WorkoutEntry] = []
    for dayOffset in 0..<30 {
        if dayOffset % 3 == 0 { // Add entries every 3 days
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let time = Double.random(in: 30...120)
            dummyEntries.append(WorkoutEntry(
                date: date,
                timeUnderTension: time,
                jointAngles: [235.0, -145.0, -35.0, 70.0]
            ))
        }
    }
    
    return List {
        Section("Activity Heatmap") {
            DailyTensionHeatmap(entries: dummyEntries)
                .padding(.vertical)
        }
    }
}

