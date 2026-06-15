//
//  WorkoutStore.swift
//  TRunD
//

//

import Foundation
import SwiftUI
import Combine

@MainActor
class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] = []

    func addWorkout(_ workout: Workout) {
        workouts.insert(workout, at: 0)
    }
}
