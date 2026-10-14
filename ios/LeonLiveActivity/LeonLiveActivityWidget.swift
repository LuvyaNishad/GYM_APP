import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct LeonLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LeonWorkoutAttributes.self) { context in
            // Lock Screen & StandBy Live Activity View
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island View
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .foregroundColor(Color(red: 0.0, green: 0.898, blue: 1.0)) // Cyan
                        Text("SET \(context.state.setNumber)/\(context.state.totalSets)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.targetEndTime, countsDown: true)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.0, green: 0.898, blue: 1.0))
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.exerciseName.uppercased())
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.white)
                        HStack {
                            Text("\(String(format: "%.1f", context.state.targetWeightKg)) KG × \(context.state.targetReps) REPS")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(red: 0.72, green: 0.74, blue: 0.77))
                            Spacer()
                            if !context.state.plateBreakdown.isEmpty {
                                Text(context.state.plateBreakdown)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 1.0, green: 0.702, blue: 0.0)) // Amber
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                HStack(spacing: 2) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(Color(red: 0.0, green: 0.898, blue: 1.0))
                        .font(.system(size: 10))
                }
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.targetEndTime, countsDown: true)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 0.898, blue: 1.0))
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(Color(red: 0.0, green: 0.898, blue: 1.0))
            }
        }
    }
}

@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<LeonWorkoutAttributes>

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.07, blue: 0.11) // Onyx base
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.0, green: 0.898, blue: 1.0))
                            .frame(width: 8, height: 8)
                        Text(context.attributes.workoutTitle.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.72, green: 0.74, blue: 0.77))
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .foregroundColor(Color(red: 0.0, green: 0.898, blue: 1.0))
                            .font(.system(size: 12))
                        Text(timerInterval: Date()...context.state.targetEndTime, countsDown: true)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 0.898, blue: 1.0))
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.exerciseName)
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(.white)
                        Text("Set \(context.state.setNumber) of \(context.state.totalSets) • \(String(format: "%.1f", context.state.targetWeightKg)) kg × \(context.state.targetReps) reps")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.72, green: 0.74, blue: 0.77))
                    }
                    Spacer()
                    if !context.state.plateBreakdown.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("PLATES PER SLEEVE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                            Text(context.state.plateBreakdown)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 1.0, green: 0.702, blue: 0.0))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.14, green: 0.15, blue: 0.19))
                        .cornerRadius(6)
                    }
                }
            }
            .padding(14)
        }
    }
}
