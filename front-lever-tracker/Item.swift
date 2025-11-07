//
//  Item.swift
//  front-lever-tracker
//
//  Created by Geoffrey Cohen on 11/4/25.
//

import Foundation
import SwiftData

// MARK: - Models

@Model
class WorkoutEntry {
    var date: Date
    var timeUnderTension: TimeInterval
    var jointAngles: [Float]  // [blue, green, purple, yellow] in degrees
    
    init(date: Date, timeUnderTension: TimeInterval, jointAngles: [Float]) {
        self.date = date
        self.timeUnderTension = timeUnderTension
        self.jointAngles = jointAngles
    }
}