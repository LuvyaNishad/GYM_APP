import Flutter
import UIKit
import UserNotifications
#if canImport(ActivityKit)
import ActivityKit
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var nativeServices: WorkoutNativeServices?
  private var healthServices: PhoneHealthServices?
  override func application(_ application:UIApplication,
    didFinishLaunchingWithOptions launchOptions:[UIApplication.LaunchOptionsKey:Any]?) -> Bool {
    GeneratedPluginRegistrant.register(with:self)
    if let controller=window?.rootViewController as? FlutterViewController {
      nativeServices=WorkoutNativeServices(controller:controller)
      healthServices=PhoneHealthServices(controller:controller)
      FlutterMethodChannel(name:"leon/live_activity",binaryMessenger:controller.binaryMessenger)
        .setMethodCallHandler { [weak self] call,result in self?.live(call,result) }
    }
    return super.application(application,didFinishLaunchingWithOptions:launchOptions)
  }
  private func live(_ call:FlutterMethodCall,_ result:@escaping FlutterResult) {
    #if canImport(ActivityKit)
    if #available(iOS 16.1, *) {
      if call.method == "areActivitiesEnabled" {result(ActivityAuthorizationInfo().areActivitiesEnabled);return}
      let args=call.arguments as? [String:Any] ?? [:]
      let id=args["activityId"] as? String
      let workoutId=args["workoutId"] as? String
      let matches=Activity<LeonWorkoutAttributes>.activities.filter {
        (id != nil && $0.id == id) || (workoutId != nil && $0.attributes.workoutId == workoutId)
      }
      if call.method == "cleanupStaleActivities" {
        Task {
          for activity in Activity<LeonWorkoutAttributes>.activities where activity.attributes.workoutId != workoutId || activity.contentState.targetEndTime <= Date() {
            if #available(iOS 16.2, *) {await activity.end(nil,dismissalPolicy:.immediate)}
            else {await activity.end(using:nil,dismissalPolicy:.immediate)}
          }
          await MainActor.run {result(true)}
        };return
      }
      if call.method == "stopLiveActivity" {
        Task {
          for activity in matches {
            if #available(iOS 16.2, *) {await activity.end(nil,dismissalPolicy:.immediate)}
            else {await activity.end(using:nil,dismissalPolicy:.immediate)}
          }
          await MainActor.run {result(true)}
        };return
      }
      guard let workoutId=workoutId,
        let deadline=args["targetEndTime"] as? NSNumber,
        let exercise=args["exerciseName"] as? String,
        let set=args["setNumber"] as? Int,let total=args["totalSets"] as? Int else {
        result(FlutterError(code:"invalid_activity",message:"Missing workout identity or absolute deadline",details:nil));return
      }
      let end=Date(timeIntervalSince1970:deadline.doubleValue/1000)
      guard end > Date() else {result(nil);return}
      let state=LeonWorkoutAttributes.ContentState(
        remainingSeconds:args["remainingSeconds"] as? Int ?? 0,
        totalDurationSeconds:args["totalDurationSeconds"] as? Int ?? 0,
        exerciseName:exercise,setNumber:set,totalSets:total,
        targetWeightKg:args["targetWeightKg"] as? Double ?? 0,
        targetReps:args["targetReps"] as? Int ?? 0,
        plateBreakdown:args["plateBreakdown"] as? String ?? "",
        isResting:args["isResting"] as? Bool ?? true,targetEndTime:end,
        weightUnit:args["weightUnit"] as? String ?? "kg")
      if call.method == "updateLiveActivity" || !matches.isEmpty {
        Task {
          for activity in matches {
            if #available(iOS 16.2, *) {await activity.update(ActivityContent(state:state,staleDate:end))}
            else {await activity.update(using:state)}
          }
          await MainActor.run {result(matches.first?.id)}
        };return
      }
      if call.method == "startLiveActivity" {
        guard ActivityAuthorizationInfo().areActivitiesEnabled,UIApplication.shared.applicationState == .active else {result(nil);return}
        do {
          let attributes=LeonWorkoutAttributes(workoutTitle:args["workoutTitle"] as? String ?? "Workout",workoutId:workoutId)
          let activity:Activity<LeonWorkoutAttributes>
          if #available(iOS 16.2, *) {activity=try Activity.request(attributes:attributes,content:ActivityContent(state:state,staleDate:end),pushType:nil)}
          else {activity=try Activity.request(attributes:attributes,contentState:state,pushType:nil)}
          result(activity.id)
        } catch {result(FlutterError(code:"activity_error",message:error.localizedDescription,details:nil))}
      } else {result(FlutterMethodNotImplemented)}
      return
    }
    #endif
    result(call.method == "areActivitiesEnabled" ? false : nil)
  }
  override func userNotificationCenter(_ center:UNUserNotificationCenter,
    willPresent notification:UNNotification,
    withCompletionHandler completionHandler:@escaping (UNNotificationPresentationOptions) -> Void) {
    if notification.request.identifier == "leon_rest_completion" {
      completionHandler([])
    } else {
      super.userNotificationCenter(center,willPresent:notification,withCompletionHandler:completionHandler)
    }
  }
}
