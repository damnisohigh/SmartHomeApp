import Foundation

protocol CloudService {
    var mode: CloudMode { get }
    func syncInitialState(devices: [SmartDevice], sensor: SensorSnapshot) async -> CloudDeliveryResult
    func sendDeviceCommand(device: SmartDevice, turnOn: Bool) async -> CloudDeliveryResult
    func sendDeviceValue(_ device: SmartDevice) async
    func sendTelemetry(_ sensor: SensorSnapshot) async -> CloudDeliveryResult
}

struct MockCloudService: CloudService {
    let mode: CloudMode = .simulated

    func sendDeviceValue(_ device: SmartDevice) async {}

    func syncInitialState(devices: [SmartDevice], sensor: SensorSnapshot) async -> CloudDeliveryResult {
        try? await Task.sleep(nanoseconds: 220_000_000)
        return CloudDeliveryResult(
            title: "Initial cloud state",
            route: "iOS -> Mock Cloud DB -> app/status + devices + telemetry",
            result: "Початковий стан \(devices.count) пристроїв підготовлено",
            isSuccessful: true
        )
    }

    func sendDeviceCommand(device: SmartDevice, turnOn: Bool) async -> CloudDeliveryResult {
        try? await Task.sleep(nanoseconds: 450_000_000)
        let command = turnOn ? "ON" : "OFF"
        return CloudDeliveryResult(
            title: "ESP32-SIM ack: \(device.name)",
            route: "iOS -> Cloud DB -> MQTT broker -> ESP32-SIM -> relay",
            result: "Реле перемкнулося на \(command)",
            isSuccessful: true
        )
    }

    func sendTelemetry(_ sensor: SensorSnapshot) async -> CloudDeliveryResult {
        try? await Task.sleep(nanoseconds: 180_000_000)
        return CloudDeliveryResult(
            title: "Telemetry synced",
            route: "ESP32-SIM -> MQTT broker -> Cloud DB -> iOS",
            result: "T=\(sensor.temperature)°C, H=\(Int(sensor.humidity))%, AQ=\(sensor.airQuality)%",
            isSuccessful: true
        )
    }
}

struct HTTPCloudService: CloudService {
    let mode: CloudMode = .realHttp
    var endpoint: URL
    var apiKey: String

    func sendDeviceValue(_ device: SmartDevice) async {}

    func syncInitialState(devices: [SmartDevice], sensor: SensorSnapshot) async -> CloudDeliveryResult {
        let payload: [String: Any] = [
            "type": "initial_state",
            "devices": devices.map { device in
                [
                    "id": device.id.uuidString,
                    "name": device.name,
                    "room": device.room,
                    "kind": device.kind.rawValue,
                    "isOn": device.isOn,
                    "value": device.value,
                    "unit": device.unit
                ]
            },
            "telemetry": [
                "temperature": sensor.temperature,
                "humidity": sensor.humidity,
                "airQuality": sensor.airQuality,
                "energyUsage": sensor.energyUsage
            ]
        ]
        return await post(payload: payload, title: "HTTP initial state")
    }

    func sendDeviceCommand(device: SmartDevice, turnOn: Bool) async -> CloudDeliveryResult {
        let payload: [String: Any] = [
            "type": "device_command",
            "device": device.name,
            "room": device.room,
            "command": turnOn ? "ON" : "OFF"
        ]
        return await post(payload: payload, title: "HTTP command: \(device.name)")
    }

    func sendTelemetry(_ sensor: SensorSnapshot) async -> CloudDeliveryResult {
        let payload: [String: Any] = [
            "type": "telemetry",
            "temperature": sensor.temperature,
            "humidity": sensor.humidity,
            "airQuality": sensor.airQuality,
            "energyUsage": sensor.energyUsage
        ]
        return await post(payload: payload, title: "HTTP telemetry")
    }

    private func post(payload: [String: Any], title: String) async -> CloudDeliveryResult {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            return CloudDeliveryResult(
                title: title,
                route: "iOS -> HTTPS endpoint -> Cloud DB/MQTT bridge",
                result: "HTTP status \(code)",
                isSuccessful: (200...299).contains(code)
            )
        } catch {
            return CloudDeliveryResult(
                title: title,
                route: "iOS -> HTTPS endpoint -> Cloud DB/MQTT bridge",
                result: "Network error: \(error.localizedDescription)",
                isSuccessful: false
            )
        }
    }
}
