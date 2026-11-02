import Flutter
import UIKit
import AVFoundation
import UserNotifications

final class WorkoutNativeServices: NSObject, UIDocumentPickerDelegate, AVAudioPlayerDelegate {
  weak var controller: UIViewController?
  private var fileResult: FlutterResult?
  private var exporting = false
  private var players: [AVAudioPlayer] = []
  private var focusRelease: DispatchWorkItem?
  private var cueChannel: FlutterMethodChannel?
  private var visible = true
  private let timerKey = "leon_native_rest_v1"
  private let notificationId = "leon_rest_completion"

  init(controller: FlutterViewController) {
    super.init()
    expireAbsentTimer()
    self.controller = controller
    FlutterMethodChannel(name:"leon/files", binaryMessenger:controller.binaryMessenger)
      .setMethodCallHandler { [weak self] call,result in self?.files(call,result) }
    FlutterMethodChannel(name:"leon/rest", binaryMessenger:controller.binaryMessenger)
      .setMethodCallHandler { [weak self] call,result in self?.rest(call,result) }
    cueChannel = FlutterMethodChannel(name:"leon/cues", binaryMessenger:controller.binaryMessenger)
    cueChannel?.setMethodCallHandler { [weak self] call,result in self?.cue(call,result) }
    NotificationCenter.default.addObserver(self,selector:#selector(interrupted),
      name:AVAudioSession.interruptionNotification,object:nil)
    NotificationCenter.default.addObserver(self,selector:#selector(routeChanged(_:)),
      name:AVAudioSession.routeChangeNotification,object:nil)
    NotificationCenter.default.addObserver(self,selector:#selector(background),
      name:UIApplication.didEnterBackgroundNotification,object:nil)
    NotificationCenter.default.addObserver(self,selector:#selector(foreground),
      name:UIApplication.didBecomeActiveNotification,object:nil)
  }
  deinit {NotificationCenter.default.removeObserver(self)}
  @objc private func background() {visible=false;stopAudio()}
  @objc private func foreground() {if !visible {expireAbsentTimer()};visible=true}
  @objc private func interrupted() {stopAudio();cueChannel?.invokeMethod("interrupted",arguments:nil)}
  @objc private func routeChanged(_ note: Notification) {
    if note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {interrupted()}
  }

  private func temporary(_ name: String, _ data: Data) throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("exports",isDirectory:true)
    try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
    for url in (try? FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:[.contentModificationDateKey])) ?? [] {
      if let modified = try? url.resourceValues(forKeys:[.contentModificationDateKey]).contentModificationDate,
         Date().timeIntervalSince(modified) > 86400 {try? FileManager.default.removeItem(at:url)}
    }
    let url = directory.appendingPathComponent(URL(fileURLWithPath:name).lastPathComponent)
    try data.write(to:url,options:.atomic)
    return url
  }
  private func files(_ call: FlutterMethodCall,_ result: @escaping FlutterResult) {
    guard fileResult == nil,let controller=controller else {
      result(FlutterError(code:"busy",message:"A document picker is already open",details:nil));return
    }
    do {
      if call.method == "pickBackup" {
        fileResult=result;exporting=false
        let picker=UIDocumentPickerViewController(documentTypes:["public.json","public.data"],in:.import)
        picker.delegate=self;controller.present(picker,animated:true);return
      }
      guard let args=call.arguments as? [String:Any],let bytes=args["bytes"] as? FlutterStandardTypedData,
        let name=args["name"] as? String else {throw NSError(domain:"Missing file bytes",code:1)}
      let url=try temporary(name,bytes.data)
      if call.method == "save" {
        fileResult=result;exporting=true
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {picker=UIDocumentPickerViewController(forExporting:[url],asCopy:true)}
        else {picker=UIDocumentPickerViewController(url:url,in:.exportToService)}
        picker.delegate=self;controller.present(picker,animated:true)
      } else if call.method == "share" {
        let share=UIActivityViewController(activityItems:[url],applicationActivities:nil)
        share.popoverPresentationController?.sourceView=controller.view
        share.popoverPresentationController?.sourceRect=CGRect(x:controller.view.bounds.midX,y:controller.view.bounds.midY,width:1,height:1)
        share.completionWithItemsHandler={_,completed,_,error in
          if let error=error {result(FlutterError(code:"share_error",message:error.localizedDescription,details:nil))}
          else {result(completed)}
        }
        controller.present(share,animated:true)
      } else {result(FlutterMethodNotImplemented)}
    } catch {fileResult=nil;result(FlutterError(code:"file_error",message:error.localizedDescription,details:nil))}
  }
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {fileResult?(nil);fileResult=nil}
  func documentPicker(_ controller: UIDocumentPickerViewController,didPickDocumentsAt urls:[URL]) {
    guard let result=fileResult else {return};fileResult=nil
    guard let url=urls.first else {result(nil);return}
    if exporting {result(url.absoluteString);return}
    let access=url.startAccessingSecurityScopedResource();defer {if access {url.stopAccessingSecurityScopedResource()}}
    do {
      let size=try url.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0
      guard size <= 50*1024*1024 else {throw NSError(domain:"Backup exceeds 50 MB",code:1)}
      let data=try Data(contentsOf:url)
      guard data.count <= 50*1024*1024 else {throw NSError(domain:"Backup exceeds 50 MB",code:1)}
      result(FlutterStandardTypedData(bytes:data))
    } catch {result(FlutterError(code:"file_error",message:error.localizedDescription,details:nil))}
  }

  private func stopAudio() {
    focusRelease?.cancel();players.forEach {$0.stop()};players.removeAll()
    try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation)
  }
  private func cue(_ call: FlutterMethodCall,_ result: @escaping FlutterResult) {
    if call.method == "stop" {stopAudio();result(nil);return}
    guard call.method == "play",let args=call.arguments as? [String:Any] else {result(FlutterMethodNotImplemented);return}
    guard visible else {result(nil);return}
    do {
      if args["sound"] as? Bool == true {
        let session=AVAudioSession.sharedInstance()
        try session.setCategory(.playback,mode:.default,options:[.duckOthers])
        try session.setActive(true)
        let name=args["cue"] as? String ?? "metronome"
        let key=FlutterDartProject.lookupKey(forAsset:"assets/audio/\(name).wav")
        guard let path=Bundle.main.path(forResource:key,ofType:nil) else {throw NSError(domain:"Cue asset missing",code:1)}
        let player=try AVAudioPlayer(contentsOf:URL(fileURLWithPath:path));player.volume=0.65;player.delegate=self
        players=players.filter {$0.isPlaying};players.append(player);player.play()
        focusRelease?.cancel()
        let release=DispatchWorkItem {[weak self] in self?.stopAudio()};focusRelease=release
        DispatchQueue.main.asyncAfter(deadline:.now()+1.0,execute:release)
      }
      if args["vibrate"] as? Bool == true {
        if args["cue"] as? String == "complete" {UINotificationFeedbackGenerator().notificationOccurred(.success)}
        else {UIImpactFeedbackGenerator(style:.light).impactOccurred()}
      }
      result(nil)
    } catch {result(FlutterError(code:"cue_error",message:error.localizedDescription,details:nil))}
  }

  private func readTimer() -> [String:Any]? {UserDefaults.standard.dictionary(forKey:timerKey)}
  private func expireAbsentTimer() {
    guard var timer=readTimer(),let deadline=timer["deadline"] as? NSNumber,
      deadline.doubleValue/1000 <= Date().timeIntervalSince1970 else {return}
    timer["phase"]="completed";timer["delivered"]=true
    UserDefaults.standard.set(timer,forKey:timerKey)
  }
  private func clearNotification() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:[notificationId])
    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers:[notificationId])
  }
  private func rest(_ call: FlutterMethodCall,_ result: @escaping FlutterResult) {
    switch call.method {
    case "schedule":
      guard var timer=call.arguments as? [String:Any],let deadline=timer["deadline"] as? NSNumber,
        timer["timerId"] is String,timer["workoutId"] is String else {
        result(FlutterError(code:"invalid_timer",message:"Missing timer identity/deadline",details:nil));return
      }
      timer["phase"]="running";timer["delivered"]=false
      UserDefaults.standard.set(timer,forKey:timerKey)
      clearNotification()
      let content=UNMutableNotificationContent()
      content.title="Rest complete"
      content.body="Next: \(timer["exerciseName"] as? String ?? "Exercise") · Set \(timer["setNumber"] as? Int ?? 1)"
      if timer["sound"] as? Bool == true {content.sound=UNNotificationSound(named:UNNotificationSoundName("complete.wav"))}
      content.userInfo=["timerId":timer["timerId"]!,"workoutId":timer["workoutId"]!]
      let delay=max(0.1,deadline.doubleValue/1000-Date().timeIntervalSince1970)
      let request=UNNotificationRequest(identifier:notificationId,content:content,trigger:UNTimeIntervalNotificationTrigger(timeInterval:delay,repeats:false))
      UNUserNotificationCenter.current().add(request) {error in DispatchQueue.main.async {
        if let error=error {result(FlutterError(code:"rest_error",message:error.localizedDescription,details:nil))}
        else {result(nil)}
      }}
    case "read":
      guard var timer=readTimer() else {result(nil);return}
      if !visible,let deadline=timer["deadline"] as? NSNumber,deadline.doubleValue/1000 <= Date().timeIntervalSince1970 {
        // The OS owns delivery while the app is absent. Never replay an expired
        // alert on resume, including denied permissions or DND suppression.
        timer["phase"]="completed";timer["delivered"]=true
        UserDefaults.standard.set(timer,forKey:timerKey)
      }
      result(timer)
    case "visible":
      if !visible && call.arguments as? Bool == true {expireAbsentTimer()}
      visible=call.arguments as? Bool ?? true
      if visible {UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers:[notificationId])}
      result(nil)
    case "complete":
      guard let args=call.arguments as? [String:Any],var timer=readTimer(),
        timer["timerId"] as? String == args["timerId"] as? String,
        timer["phase"] as? String == "running",
        let deadline=timer["deadline"] as? NSNumber,
        deadline.doubleValue/1000 <= Date().timeIntervalSince1970 + 0.1,
        timer["delivered"] as? Bool != true else {result(false);return}
      if args["background"] as? Bool == true {result(false);return}
      timer["phase"]="completed";timer["delivered"]=true
      UserDefaults.standard.set(timer,forKey:timerKey);clearNotification();result(true)
    case "cancel":
      if let id=call.arguments as? String,readTimer()?["timerId"] as? String != id {result(nil);return}
      UserDefaults.standard.removeObject(forKey:timerKey);clearNotification();result(nil)
    case "exactAvailable": result(true)
    case "requestExact": result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }
}
