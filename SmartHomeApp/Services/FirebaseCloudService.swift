import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase

struct FirebaseCloudService: CloudService {
    let mode: CloudMode = .realHttp

    private var database: DatabaseReference {
        if let configuredURL = FirebaseApp.app()?.options.databaseURL {
            return Database.database(url: configuredURL).reference()
        }

        if let projectID = FirebaseApp.app()?.options.projectID {
            return Database.database(url: "https://\(projectID)-default-rtdb.firebaseio.com").reference()
        }

        return Database.database().reference()
    }

    func syncInitialState(devices: [SmartDevice], sensor: SensorSnapshot) async -> CloudDeliveryResult {
        var updates: [String: Any] = [
            "app/status": [
                "name": "SmartHomeApp",
                "mode": "ESP32 simulation",
                "source": "iOS",
                "lastStartupAt": ServerValue.timestamp(),
                "deviceCount": devices.count
            ],
            "telemetry/current": telemetryPayload(from: sensor)
        ]

        for device in devices {
            let devicePath = "devices/\(device.id.uuidString)"
            updates["\(devicePath)/name"] = device.name
            updates["\(devicePath)/room"] = device.room
            updates["\(devicePath)/kind"] = device.kind.rawValue
            updates["\(devicePath)/isOn"] = device.isOn
            updates["\(devicePath)/value"] = device.value
            updates["\(devicePath)/unit"] = device.unit
            updates["\(devicePath)/updatedAt"] = ServerValue.timestamp()
        }

        let result = await updateChildren(updates)
        return CloudDeliveryResult(
            title: "Firebase initial state",
            route: "iOS -> Firebase Realtime Database -> app/status + devices + telemetry/current",
            result: result.message(success: "Початковий стан записано у Firebase"),
            isSuccessful: result.isSuccessful
        )
    }

    func sendDeviceCommand(device: SmartDevice, turnOn: Bool) async -> CloudDeliveryResult {
        let command = turnOn ? "ON" : "OFF"
        let commandID = UUID().uuidString
        let payload: [String: Any] = [
            "id": commandID,
            "deviceName": device.name,
            "room": device.room,
            "kind": device.kind.rawValue,
            "command": command,
            "source": "iOS",
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ]

        let commandPath = "commands/\(commandID)"
        let devicePath = "devices/\(device.id.uuidString)"
        let updates: [String: Any] = [
            commandPath: payload,
            "\(devicePath)/name": device.name,
            "\(devicePath)/room": device.room,
            "\(devicePath)/kind": device.kind.rawValue,
            "\(devicePath)/isOn": turnOn,
            "\(devicePath)/updatedAt": ServerValue.timestamp()
        ]

        let result = await updateChildren(updates)
        return CloudDeliveryResult(
            title: "Firebase command: \(device.name)",
            route: "iOS -> Firebase Realtime Database -> commands/\(commandID)",
            result: result.message(success: "Команду \(command) записано у Firebase"),
            isSuccessful: result.isSuccessful
        )
    }

    func sendTelemetry(_ sensor: SensorSnapshot) async -> CloudDeliveryResult {
        let telemetry = telemetryPayload(from: sensor)

        let result = await updateChildren([
            "telemetry/current": telemetry,
            "telemetry/history/\(UUID().uuidString)": telemetry
        ])

        return CloudDeliveryResult(
            title: "Firebase telemetry",
            route: "ESP32-SIM -> Firebase Realtime Database -> telemetry/current",
            result: result.message(success: "Показники записано у Firebase"),
            isSuccessful: result.isSuccessful
        )
    }

    private func telemetryPayload(from sensor: SensorSnapshot) -> [String: Any] {
        [
            "temperature": sensor.temperature,
            "targetTemperature": sensor.targetTemperature,
            "outsideTemperature": sensor.outsideTemperature,
            "humidity": sensor.humidity,
            "airQuality": sensor.airQuality,
            "energyUsage": sensor.energyUsage,
            "motionDetected": sensor.motionDetected,
            "leakDetected": sensor.leakDetected,
            "updatedAt": ServerValue.timestamp()
        ]
    }

    private func updateChildren(_ values: [String: Any]) async -> FirebaseWriteResult {
        let authWarning = await authenticateIfAvailable()

        return await withCheckedContinuation { (continuation: CheckedContinuation<FirebaseWriteResult, Never>) in
            database.updateChildValues(values) { error, _ in
                if let error {
                    let details = [authWarning, "Firebase write error: \(error.localizedDescription)"]
                        .compactMap { $0 }
                        .joined(separator: " | ")
                    continuation.resume(returning: .failure(details))
                } else {
                    continuation.resume(returning: .success)
                }
            }
        }
    }

    private func authenticateIfAvailable() async -> String? {
        if Auth.auth().currentUser != nil {
            return nil
        }

        return await withCheckedContinuation { (continuation: CheckedContinuation<FirebaseWriteResult, Never>) in
            Auth.auth().signInAnonymously { _, error in
                if let error {
                    continuation.resume(returning: .failure("Firebase Auth error: \(error.localizedDescription)"))
                } else {
                    continuation.resume(returning: .success)
                }
            }
        }.errorMessage
    }
}

private enum FirebaseWriteResult: Equatable {
    case success
    case failure(String)

    var isSuccessful: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case let .failure(message) = self {
            return message
        }
        return nil
    }

    func message(success: String) -> String {
        switch self {
        case .success:
            return success
        case let .failure(message):
            return message
        }
    }
}
