import Foundation
import SwiftUI

enum DeviceKind: String, CaseIterable, Identifiable {
    case light = "Освітлення"
    case thermostat = "Термостат"
    case lock = "Замок"
    case camera = "Камера"
    case fan = "Вентиляція"
    case socket = "Розетка"
    case heater = "Опалення"
    case airConditioner = "Кондиціонер"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .light: "lightbulb.fill"
        case .thermostat: "thermometer.medium"
        case .lock: "lock.fill"
        case .camera: "video.fill"
        case .fan: "fan.fill"
        case .socket: "powerplug.fill"
        case .heater: "flame.fill"
        case .airConditioner: "snowflake"
        }
    }

    var tint: Color {
        switch self {
        case .light: .yellow
        case .thermostat: .red
        case .lock: .blue
        case .camera: .purple
        case .fan: .teal
        case .socket: .green
        case .heater: .orange
        case .airConditioner: .blue
        }
    }
}

struct SmartDevice: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var room: String
    var kind: DeviceKind
    var isOn: Bool
    var value: Double
    var unit: String
}

struct SensorSnapshot: Equatable {
    var temperature: Double
    var humidity: Double
    var motionDetected: Bool
    var airQuality: Int
    var energyUsage: Double
    var leakDetected: Bool
    var outsideTemperature: Double
    var targetTemperature: Double
}

struct Room: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var subtitle: String
    var symbol: String
}

struct Automation: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var description: String
    var symbol: String
    var isEnabled: Bool
}

struct CloudCommand: Identifiable, Equatable {
    let id = UUID()
    var time: String
    var title: String
    var route: String
    var result: String
    var isSuccessful: Bool
}

enum CloudMode: String, CaseIterable, Identifiable {
    case simulated = "Simulation Cloud"
    case realHttp = "Firebase Cloud"

    var id: String { rawValue }
}

struct CloudDeliveryResult: Equatable {
    var title: String
    var route: String
    var result: String
    var isSuccessful: Bool
}

struct FirebaseSetupInfo: Equatable {
    var projectID: String
    var databaseURL: String
    var bundleID: String
}

enum SecurityMode: String, CaseIterable, Identifiable {
    case home = "Вдома"
    case away = "Нікого немає"
    case night = "Ніч"

    var id: String { rawValue }
}
