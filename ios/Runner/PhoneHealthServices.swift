import Flutter
import HealthKit
import UIKit

/// HealthKit deliberately hides read-permission denial. Empty reads stay unknown.
final class PhoneHealthServices {
  private let store = HKHealthStore()
  init(controller: FlutterViewController) {
    FlutterMethodChannel(name: "leon/health", binaryMessenger: controller.binaryMessenger)
      .setMethodCallHandler { [self] call, result in handle(call, result) }
  }
  private func type(_ metric: String) -> HKSampleType? {
    switch metric {
      case "steps": return HKQuantityType.quantityType(forIdentifier: .stepCount)
      case "heartRate": return HKQuantityType.quantityType(forIdentifier: .heartRate)
      case "activeCalories": return HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
      case "sleep": return HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
      default: return nil
    }
  }
  private func finish(_ result: @escaping FlutterResult, _ value: Any?) {
    DispatchQueue.main.async { result(value) }
  }
  private func failure(_ result: @escaping FlutterResult, _ error: Error) {
    finish(result, FlutterError(code: "health_read_failed", message: error.localizedDescription, details: nil))
  }
  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
      case "availability": result(HKHealthStore.isHealthDataAvailable() ? "ready" : "unsupported")
      case "settings":
        // Public Health URL opens Health; permission editing remains inside Health.
        guard let url = URL(string: "x-apple-health://") else { result(false); return }
        UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
      case "authorize":
        guard HKHealthStore.isHealthDataAvailable() else {
          result(FlutterError(code: "health_unavailable", message: "Apple Health is unavailable", details: nil)); return
        }
        let metrics = call.arguments as? [String] ?? []
        let types = Set<HKObjectType>(metrics.compactMap { type($0) })
        if types.isEmpty { result(nil); return }
        store.requestAuthorization(toShare: [], read: types) { [self] _, error in
          if let error = error { failure(result, error) }
          else { finish(result, nil) } // This is not proof of granted read access.
        }
      case "read":
        guard HKHealthStore.isHealthDataAvailable(),
          let args = call.arguments as? [String: Any], let metric = args["metric"] as? String,
          let sampleType = type(metric), let startMs = args["start"] as? NSNumber,
          let endMs = args["end"] as? NSNumber else {
          result(FlutterError(code: "health_unavailable", message: "Health query unavailable", details: nil)); return
        }
        let start = Date(timeIntervalSince1970: startMs.doubleValue / 1000)
        let end = Date(timeIntervalSince1970: endMs.doubleValue / 1000)
        if end <= start { result(["access": "unknown"]); return }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        if metric == "sleep" {
          let query = HKSampleQuery(sampleType: sampleType, predicate: predicate,
            limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [self] _, samples, error in
            if let error = error { failure(result, error); return }
            let asleep = (samples as? [HKCategorySample] ?? []).filter { [1, 3, 4, 5].contains($0.value) }
            let clipped = asleep.compactMap { sample -> [Double]? in
              let from = max(sample.startDate, start), to = min(sample.endDate, end)
              return to > from ? [from.timeIntervalSince1970 * 1000, to.timeIntervalSince1970 * 1000] : nil
            }
            finish(result, ["access": "unknown", "platform": "Apple Health", "intervals": clipped,
              "sources": Array(Set(asleep.map { $0.sourceRevision.source.name })).sorted(),
              "method": "Asleep intervals merged across stages and sources; awake and in-bed time excluded",
              "sampleAt": clipped.map { $0[1] }.max().map { NSNumber(value: $0) as Any } ?? NSNull()])
          }
          store.execute(query)
        } else if metric == "heartRate" {
          let heartPredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate, .strictEndDate])
          let query = HKSampleQuery(sampleType: sampleType, predicate: heartPredicate, limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { [self] _, samples, error in
            if let error = error { failure(result, error); return }
            guard let sample = samples?.first as? HKQuantitySample else { finish(result, ["access": "unknown"]); return }
            let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            finish(result, ["access": "unknown", "platform": "Apple Health", "value": value,
              "sampleAt": sample.endDate.timeIntervalSince1970 * 1000,
              "sources": [sample.sourceRevision.source.name],
              "method": "Latest heart-rate sample today; not a resting-heart-rate baseline"])
          }
          store.execute(query)
        } else if let quantityType = sampleType as? HKQuantityType {
          let unit: HKUnit = metric == "steps" ? .count() : .kilocalorie()
          // Choose one source to avoid adding overlapping phone/watch/app totals.
          let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate,
            options: [.cumulativeSum, .separateBySource]) { [self] _, statistics, error in
            if let error = error { failure(result, error); return }
            let totals = (statistics?.sources ?? []).compactMap { source -> (HKSource, Double)? in
              guard let quantity = statistics?.sumQuantity(for: source) else { return nil }
              return (source, quantity.doubleValue(for: unit))
            }.sorted { $0.1 == $1.1 ? $0.0.bundleIdentifier < $1.0.bundleIdentifier : $0.1 > $1.1 }
            guard let chosen = totals.first else { finish(result, ["access": "unknown"]); return }
            finish(result, ["access": "unknown", "platform": "Apple Health", "value": chosen.1,
              "sources": [chosen.0.name], "method": "One source with the largest daily total; sources are never added"])
          }
          store.execute(query)
        }
      default: result(FlutterMethodNotImplemented)
    }
  }
}
