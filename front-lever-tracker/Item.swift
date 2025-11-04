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
    var poseIndex: Int
    
    init(date: Date, timeUnderTension: TimeInterval, poseIndex: Int) {
        self.date = date
        self.timeUnderTension = timeUnderTension
        self.poseIndex = poseIndex
    }
}