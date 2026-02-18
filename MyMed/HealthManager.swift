//
//  HealthManager.swift
//  MyMed
//
//  HealthKit-Integration für Apple Watch, Health App und verbundene Geräte.
//

import Foundation
import HealthKit
import SwiftUI

/// Verwaltet HealthKit-Zugriff, Gerätequellen und Gesundheitsdaten.
/// Läuft nur auf echtem Gerät – Simulator zeigt Platzhalter.
@MainActor
@Observable
final class HealthManager {
    private let healthStore = HKHealthStore()

    /// Geräte, die Health-Daten beigetragen haben (Apple Watch, iPhone, Drittanbieter)
    var connectedDevices: [HealthDevice] = []

    /// Aktuelle Gesundheitswerte für die Übersicht
    var stats: HealthStats = .empty

    /// Berechtigung wurde erteilt
    var isAuthorized: Bool = false

    /// Berechtigung wurde explizit verweigert
    var isDenied: Bool = false

    /// Lädt gerade
    var isLoading: Bool = false

    /// Fehlermeldung (z.B. Simulator)
    var errorMessage: String?

    /// HealthKit ist auf diesem Gerät verfügbar (nicht im Simulator)
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private static let authorizedKey = "MyMed.HealthKit.authorized"

    init() {
        if !isHealthKitAvailable {
            errorMessage = "Health-Daten sind nur auf echtem iPhone verfügbar."
        } else {
            isAuthorized = UserDefaults.standard.bool(forKey: Self.authorizedKey)
        }
    }

    // MARK: - Authorization

    /// Fordert Berechtigung an und lädt danach Daten.
    func requestAuthorizationAndLoad() async {
        guard isHealthKitAvailable else { return }

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKWorkoutType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isDenied = false
            isAuthorized = true
            UserDefaults.standard.set(true, forKey: Self.authorizedKey)
            errorMessage = nil
            await loadAll()
        } catch {
            isDenied = true
            isAuthorized = false
            UserDefaults.standard.set(false, forKey: Self.authorizedKey)
            errorMessage = "Zugriff verweigert: \(error.localizedDescription)"
        }
    }

    // MARK: - Load Data

    /// Lädt Geräte, Stats und prüft Autorisierung.
    func loadAll() async {
        guard isHealthKitAvailable else { return }
        isLoading = true
        errorMessage = nil

        async let devicesTask = loadConnectedDevices()
        async let statsTask = loadHealthStats()

        let (devices, newStats) = await (devicesTask, statsTask)
        connectedDevices = devices
        stats = newStats
        isLoading = false
    }

    /// Lädt Geräte, die Health-Daten beigetragen haben.
    private func loadConnectedDevices() async -> [HealthDevice] {
        var deviceMap: [String: HealthDevice] = [:]

        let sampleTypes: [(HKQuantityTypeIdentifier, String)] = [
            (.heartRate, "heartrate"),
            (.stepCount, "steps"),
            (.activeEnergyBurned, "activity")
        ]

        for (identifier, _) in sampleTypes {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-30 * 24 * 3600), end: Date(), options: .strictStartDate)

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 100, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                    for sample in samples ?? [] {
                        let device = sample.device
                        let source = sample.sourceRevision.source
                        let key = Self.uniqueKey(device: device, source: source)
                        let name = Self.deviceDisplayName(device: device, source: source)
                        let model = device?.model ?? source.name
                        let icon = Self.iconForDevice(device: device, source: source)
                        if deviceMap[key] == nil {
                            deviceMap[key] = HealthDevice(
                                id: key,
                                name: name,
                                model: model,
                                icon: icon,
                                lastSync: sample.startDate
                            )
                        } else if let existing = deviceMap[key], sample.startDate > existing.lastSync {
                            deviceMap[key] = HealthDevice(
                                id: key,
                                name: name,
                                model: existing.model,
                                icon: existing.icon,
                                lastSync: sample.startDate
                            )
                        }
                    }
                    Task { @MainActor in
                        continuation.resume()
                    }
                }
                healthStore.execute(query)
            }
        }

        return Array(deviceMap.values).sorted { $0.lastSync > $1.lastSync }
    }

    private static func uniqueKey(device: HKDevice?, source: HKSource) -> String {
        if let d = device {
            let parts = [d.name, d.model, d.manufacturer].compactMap { $0 }.filter { !$0.isEmpty }
            if !parts.isEmpty { return parts.joined(separator: "|") }
        }
        return source.bundleIdentifier
    }

    private static func deviceDisplayName(device: HKDevice?, source: HKSource) -> String {
        if let d = device {
            if let name = d.name, !name.isEmpty { return name }
            if let model = d.model {
                if model.lowercased().contains("watch") { return "Apple Watch" }
                if model.lowercased().contains("iphone") { return "iPhone" }
                return model
            }
        }
        let name = source.name
        if name.lowercased().contains("watch") { return "Apple Watch" }
        if name.lowercased().contains("iphone") { return "iPhone" }
        return name
    }

    private static func iconForDevice(device: HKDevice?, source: HKSource) -> String {
        let model = (device?.model ?? source.name).lowercased()
        if model.contains("watch") { return "applewatch" }
        if model.contains("iphone") { return "iphone" }
        return "waveform.path.ecg"
    }

    /// Lädt aktuelle Gesundheitsstatistiken.
    private func loadHealthStats() async -> HealthStats {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        async let steps = fetchStepCount(from: startOfToday, to: now)
        async let heartRate = fetchLatestHeartRate()
        async let sleep = fetchLastNightSleep()
        async let activeEnergy = fetchActiveEnergy(from: startOfToday, to: now)

        return HealthStats(
            stepsToday: await steps,
            latestHeartRate: await heartRate,
            lastNightSleepHours: await sleep,
            activeEnergyToday: await activeEnergy
        )
    }

    private func fetchStepCount(from start: Date, to end: Date) async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let steps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                Task { @MainActor in continuation.resume(returning: steps) }
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatestHeartRate() async -> Int? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let bpm = samples?.first.flatMap { ($0 as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "count/min")) }.map { Int($0) }
                Task { @MainActor in continuation.resume(returning: bpm) }
            }
            healthStore.execute(query)
        }
    }

    private func fetchLastNightSleep() async -> Double? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: now, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 50, sortDescriptors: [sort]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    Task { @MainActor in continuation.resume(returning: nil) }
                    return
                }
                var total: TimeInterval = 0
                for s in samples where s.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue || s.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue || s.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue || s.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    total += s.endDate.timeIntervalSince(s.startDate)
                }
                let hours = total > 0 ? total / 3600 : nil
                Task { @MainActor in continuation.resume(returning: hours) }
            }
            healthStore.execute(query)
        }
    }

    private func fetchActiveEnergy(from start: Date, to end: Date) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let kcal = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                Task { @MainActor in continuation.resume(returning: kcal) }
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Models

struct HealthDevice: Identifiable {
    let id: String
    let name: String
    let model: String
    let icon: String
    let lastSync: Date
}

struct HealthStats {
    var stepsToday: Int
    var latestHeartRate: Int?
    var lastNightSleepHours: Double?
    var activeEnergyToday: Double

    static let empty = HealthStats(stepsToday: 0, latestHeartRate: nil, lastNightSleepHours: nil, activeEnergyToday: 0)
}

