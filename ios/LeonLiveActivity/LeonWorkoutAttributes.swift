import ActivityKit
import Foundation

public struct LeonWorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var remainingSeconds: Int
        public var totalDurationSeconds: Int
        public var exerciseName: String
        public var setNumber: Int
        public var totalSets: Int
        public var targetWeightKg: Double
        public var targetReps: Int
        public var plateBreakdown: String
        public var isResting: Bool
        public var targetEndTime: Date

        public init(
            remainingSeconds: Int,
            totalDurationSeconds: Int,
            exerciseName: String,
            setNumber: Int,
            totalSets: Int,
            targetWeightKg: Double,
            targetReps: Int,
            plateBreakdown: String,
            isResting: Bool,
            targetEndTime: Date
        ) {
            self.remainingSeconds = remainingSeconds
            self.totalDurationSeconds = totalDurationSeconds
            self.exerciseName = exerciseName
            self.setNumber = setNumber
            self.totalSets = totalSets
            self.targetWeightKg = targetWeightKg
            self.targetReps = targetReps
            self.plateBreakdown = plateBreakdown
            self.isResting = isResting
            self.targetEndTime = targetEndTime
        }
    }

    public var workoutTitle: String

    public init(workoutTitle: String) {
        self.workoutTitle = workoutTitle
    }
}
