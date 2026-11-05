package com.example.leon

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.widget.ScrollView
import android.widget.TextView
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.*
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.time.Instant

class HealthReader(private val activity: MainActivity) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var pending: MethodChannel.Result? = null
    private val launcher = activity.registerForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { pending?.success(null); pending = null }

    private fun permission(metric: String): String = when(metric) {
        "steps" -> HealthPermission.getReadPermission(StepsRecord::class)
        "heartRate" -> HealthPermission.getReadPermission(HeartRateRecord::class)
        "sleep" -> HealthPermission.getReadPermission(SleepSessionRecord::class)
        "activeCalories" -> HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class)
        else -> throw IllegalArgumentException("Unknown health metric")
    }
    private fun status(): Int = if (Build.VERSION.SDK_INT < 28)
        HealthConnectClient.SDK_UNAVAILABLE else HealthConnectClient.getSdkStatus(activity)

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when(call.method) {
                "availability" -> result.success(when(status()) {
                    HealthConnectClient.SDK_AVAILABLE -> "ready"
                    HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> "installRequired"
                    else -> "unsupported"
                })
                "settings" -> {
                    val intent = if(status() == HealthConnectClient.SDK_AVAILABLE)
                        Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS)
                    else Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata"))
                    activity.startActivity(intent); result.success(null)
                }
                "authorize" -> {
                    check(status() == HealthConnectClient.SDK_AVAILABLE) { "Health Connect is unavailable" }
                    check(pending == null) { "Permission request already open" }
                    val permissions = (call.arguments as List<*>).map { permission(it as String) }.toSet()
                    if (permissions.isEmpty()) result.success(null)
                    else { pending = result; launcher.launch(permissions) }
                }
                "read" -> scope.launch {
                    try {
                        check(status() == HealthConnectClient.SDK_AVAILABLE) { "Health Connect is unavailable" }
                        val metric = call.argument<String>("metric")!!
                        val start = Instant.ofEpochMilli(call.argument<Number>("start")!!.toLong())
                        val end = Instant.ofEpochMilli(call.argument<Number>("end")!!.toLong())
                        val client = HealthConnectClient.getOrCreate(activity)
                        if (!client.permissionController.getGrantedPermissions().contains(permission(metric))) {
                            result.success(mapOf("access" to "denied")); return@launch
                        }
                        if(!end.isAfter(start)) {
                            result.success(mapOf("access" to "granted")); return@launch
                        }
                        result.success(read(client, metric, start, end))
                    } catch(e: SecurityException) {
                        result.success(mapOf("access" to "denied"))
                    } catch(e: Exception) { result.error("health_read_failed", e.message, null) }
                }
                else -> result.notImplemented()
            }
        } catch(e: Exception) { pending = null; result.error("health_error", e.message, null) }
    }

    private suspend fun read(client: HealthConnectClient, metric: String, start: Instant, end: Instant): Map<String, Any?> {
        val filter = TimeRangeFilter.between(start, end)
        val output = mutableMapOf<String, Any?>("access" to "granted", "platform" to "Health Connect")
        val origins = mutableSetOf<String>()
        when(metric) {
            "steps" -> {
                // Platform priority/deduplication, never add the phone sensor total.
                val aggregate = client.aggregate(AggregateRequest(setOf(StepsRecord.COUNT_TOTAL), filter))
                output["value"] = aggregate[StepsRecord.COUNT_TOTAL]
                origins.addAll(aggregate.dataOrigins.map { it.packageName })
                output["method"] = "Health Connect daily aggregate"
            }
            "activeCalories" -> {
                // Use one source: calories are not priority-deduplicated by all
                // Health Connect versions. Never sum overlapping watch/app feeds.
                val records = mutableListOf<ActiveCaloriesBurnedRecord>()
                var token: String? = null
                do {
                    val page = client.readRecords(ReadRecordsRequest(ActiveCaloriesBurnedRecord::class,
                        filter, pageToken = token))
                    records.addAll(page.records); token = page.pageToken
                } while(token != null)
                var largest: Pair<String, Double>? = null
                for(source in records.map { it.metadata.dataOrigin.packageName }.toSortedSet()) {
                    val aggregate = client.aggregate(AggregateRequest(
                        setOf(ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL), filter,
                        setOf(androidx.health.connect.client.records.metadata.DataOrigin(source))))
                    val total = aggregate[ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL]?.inKilocalories
                    if(total != null && (largest == null || total > largest!!.second)) largest = source to total
                }
                largest?.let { output["value"] = it.second; origins.add(it.first) }
                output["method"] = "One source with the largest daily active total; sources are never added"
            }
            "heartRate" -> {
                var token: String? = null
                var latest: Pair<HeartRateRecord, HeartRateRecord.Sample>? = null
                do {
                    val page = client.readRecords(ReadRecordsRequest(HeartRateRecord::class, filter, pageToken = token))
                    for(record in page.records) for(sample in record.samples) {
                        if(sample.time >= start && sample.time <= end && (latest == null || sample.time > latest!!.second.time))
                            latest = record to sample
                    }
                    token = page.pageToken
                } while(token != null)
                latest?.let {
                    output["value"] = it.second.beatsPerMinute
                    output["sampleAt"] = it.second.time.toEpochMilli()
                    origins.add(it.first.metadata.dataOrigin.packageName)
                }
                output["method"] = "Latest heart-rate sample today; not a resting-heart-rate baseline"
            }
            "sleep" -> {
                val intervals = mutableListOf<Pair<Instant, Instant>>()
                var token: String? = null
                var estimated = false
                do {
                    val page = client.readRecords(ReadRecordsRequest(SleepSessionRecord::class, filter, pageToken = token))
                    for(record in page.records) {
                        val sleeping = record.stages.filter { it.stage in setOf(
                            SleepSessionRecord.STAGE_TYPE_SLEEPING, SleepSessionRecord.STAGE_TYPE_LIGHT,
                            SleepSessionRecord.STAGE_TYPE_DEEP, SleepSessionRecord.STAGE_TYPE_REM) }
                        val pieces = if(record.stages.isEmpty()) {
                            estimated = true; listOf(record.startTime to record.endTime)
                        } else sleeping.map { it.startTime to it.endTime }
                        val clipped = pieces.map { maxOf(it.first, start) to minOf(it.second, end) }
                            .filter { it.second > it.first }
                        if(clipped.isNotEmpty()) origins.add(record.metadata.dataOrigin.packageName)
                        intervals.addAll(clipped)
                    }
                    token = page.pageToken
                } while(token != null)
                if(intervals.isNotEmpty()) {
                    output["intervals"] = intervals.map { listOf(it.first.toEpochMilli(), it.second.toEpochMilli()) }
                    output["sampleAt"] = intervals.maxOf { it.second }.toEpochMilli()
                }
                output["method"] = if(estimated) "Sleep session duration; awake time may be included when stages are missing"
                    else "Asleep intervals merged across stages and sources; awake and in-bed time excluded"
            }
        }
        output["sources"] = origins.sorted().map { name ->
            try { activity.packageManager.getApplicationLabel(activity.packageManager.getApplicationInfo(name, 0)).toString() }
            catch(_: Exception) { name }
        }
        return output
    }
    fun close() { scope.cancel(); pending?.error("health_cancelled", "Activity closed", null); pending = null }
}

/** Health Connect's mandatory permission rationale is a real in-app screen. */
class HealthPrivacyActivity: Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val text = TextView(this).apply {
            textSize = 16f; setTextColor(0xFFE2E8F0.toInt()); setPadding(40, 48, 40, 48)
            text = "Health data privacy\n\nAEON reads only the metrics you choose: steps, heart rate, sleep and active calories. Reads happen while using the phone app.\n\nHealth data stays on this device and is not sent to a server, included in backups, or used for advertising. Imported values can fill Home and Recovery; manual sleep and calorie entries take precedence. Step sources are never added together.\n\nTurn each import off in Health & Measurements, or revoke access in Health Connect settings. Turning import off immediately removes imported values from the app.\n\nNo health records are written or deleted."
        }
        val scroll = ScrollView(this).apply { setBackgroundColor(0xFF161A23.toInt()); addView(text) }
        setContentView(scroll)
    }
}
