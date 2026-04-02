import Foundation
import Combine
import SwiftUI

class WorkoutManager: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isTracking = false
    @Published var currentWorkout: Workout?
    @Published var elapsedTime: TimeInterval = 0
    
    private var timer: Timer?
    private let saveKey = "SavedWorkouts"
    
    init() {
        loadWorkouts()
    }
    
    // MARK: - Workout Tracking
    
    func startWorkout(sportType: SportType) {
        currentWorkout = Workout(
            sportType: sportType,
            duration: 0,
            date: Date()
        )
        elapsedTime = 0
        isTracking = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }
    
    func pauseWorkout() {
        isTracking = false
        timer?.invalidate()
        timer = nil
    }
    
    func resumeWorkout() {
        isTracking = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }
    
    func stopWorkout(distance: Double? = nil, calories: Int? = nil, notes: String? = nil) {
        timer?.invalidate()
        timer = nil
        
        if var workout = currentWorkout {
            workout.duration = elapsedTime
            workout.distance = distance
            workout.calories = calories
            workout.notes = notes
            workouts.insert(workout, at: 0)
            saveWorkouts()
        }
        
        currentWorkout = nil
        elapsedTime = 0
        isTracking = false
    }
    
    func cancelWorkout() {
        timer?.invalidate()
        timer = nil
        currentWorkout = nil
        elapsedTime = 0
        isTracking = false
    }
    
    // MARK: - Workout Management
    
    func addWorkout(_ workout: Workout) {
        workouts.insert(workout, at: 0)
        saveWorkouts()
    }
    
    func deleteWorkout(at offsets: IndexSet) {
        workouts.remove(atOffsets: offsets)
        saveWorkouts()
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        saveWorkouts()
    }
    
    // MARK: - Statistics
    
    func totalWorkouts() -> Int {
        return workouts.count
    }
    
    func totalDuration() -> TimeInterval {
        return workouts.reduce(0) { $0 + $1.duration }
    }
    
    func totalDistance() -> Double {
        return workouts.compactMap { $0.distance }.reduce(0, +)
    }
    
    func totalCalories() -> Int {
        return workouts.compactMap { $0.calories }.reduce(0, +)
    }
    
    func workoutsByType() -> [SportType: Int] {
        var counts: [SportType: Int] = [:]
        for workout in workouts {
            counts[workout.sportType, default: 0] += 1
        }
        return counts
    }
    
    func workoutsThisWeek() -> [Workout] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return workouts.filter { $0.date >= weekAgo }
    }
    
    func workoutsThisMonth() -> [Workout] {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return workouts.filter { $0.date >= monthAgo }
    }
    
    // MARK: - Persistence
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadWorkouts() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decoded
        }
    }
}
