import ActivityKit
import Foundation

@available(iOS 16.1, *)
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
        public var weightUnit: String

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
            targetEndTime: Date,
            weightUnit: String = "kg"
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
            self.weightUnit = weightUnit
        }
    }

    public var workoutTitle: String
    public var workoutId: String

    public init(workoutTitle: String,workoutId:String) {
        self.workoutTitle = workoutTitle
        self.workoutId = workoutId
    }
}
