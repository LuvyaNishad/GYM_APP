import Flutter
import UIKit
#if canImport(ActivityKit)
import ActivityKit
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var liveActivityChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      liveActivityChannel = FlutterMethodChannel(
        name: "leon/live_activity",
        binaryMessenger: controller.binaryMessenger
      )

      liveActivityChannel?.setMethodCallHandler { [weak self] (call, result) in
        self?.handleLiveActivityCall(call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleLiveActivityCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    #if canImport(ActivityKit)
    if #available(iOS 16.1, *) {
      switch call.method {
      case "areActivitiesEnabled":
        result(ActivityAuthorizationInfo().areActivitiesEnabled)

      case "startLiveActivity":
        guard let args = call.arguments as? [String: Any],
              let workoutTitle = args["workoutTitle"] as? String,
              let exerciseName = args["exerciseName"] as? String,
              let setNumber = args["setNumber"] as? Int,
              let totalSets = args["totalSets"] as? Int,
              let remainingSeconds = args["remainingSeconds"] as? Int,
              let totalDurationSeconds = args["totalDurationSeconds"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required fields", details: nil))
          return
        }

        let targetWeightKg = args["targetWeightKg"] as? Double ?? 0.0
        let targetReps = args["targetReps"] as? Int ?? 0
        let plateBreakdown = args["plateBreakdown"] as? String ?? ""
        let isResting = args["isResting"] as? Bool ?? true
        let targetEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        let attributes = LeonWorkoutAttributes(workoutTitle: workoutTitle)
        let initialContentState = LeonWorkoutAttributes.ContentState(
          remainingSeconds: remainingSeconds,
          totalDurationSeconds: totalDurationSeconds,
          exerciseName: exerciseName,
          setNumber: setNumber,
          totalSets: totalSets,
          targetWeightKg: targetWeightKg,
          targetReps: targetReps,
          plateBreakdown: plateBreakdown,
          isResting: isResting,
          targetEndTime: targetEndTime
        )

        do {
          let activity = try Activity.request(
            attributes: attributes,
            content: .init(state: initialContentState, staleDate: nil)
          )
          result(activity.id)
        } catch {
          result(FlutterError(code: "ACTIVITY_START_FAILED", message: error.localizedDescription, details: nil))
        }

      case "updateLiveActivity":
        guard let args = call.arguments as? [String: Any],
              let remainingSeconds = args["remainingSeconds"] as? Int,
              let totalDurationSeconds = args["totalDurationSeconds"] as? Int,
              let exerciseName = args["exerciseName"] as? String,
              let setNumber = args["setNumber"] as? Int,
              let totalSets = args["totalSets"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required fields", details: nil))
          return
        }

        let targetWeightKg = args["targetWeightKg"] as? Double ?? 0.0
        let targetReps = args["targetReps"] as? Int ?? 0
        let plateBreakdown = args["plateBreakdown"] as? String ?? ""
        let isResting = args["isResting"] as? Bool ?? true
        let targetEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        let updatedContentState = LeonWorkoutAttributes.ContentState(
          remainingSeconds: remainingSeconds,
          totalDurationSeconds: totalDurationSeconds,
          exerciseName: exerciseName,
          setNumber: setNumber,
          totalSets: totalSets,
          targetWeightKg: targetWeightKg,
          targetReps: targetReps,
          plateBreakdown: plateBreakdown,
          isResting: isResting,
          targetEndTime: targetEndTime
        )

        Task {
          for activity in Activity<LeonWorkoutAttributes>.activities {
            await activity.update(.init(state: updatedContentState, staleDate: nil))
          }
          result(true)
        }

      case "stopLiveActivity":
        Task {
          for activity in Activity<LeonWorkoutAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
          }
          result(true)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
      return
    }
    #endif

    // Fallback for unsupported platforms / older iOS versions
    result(false)
  }
}
