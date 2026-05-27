import Foundation

enum EnvironmentSimulator {
    static func nextSnapshot(from current: SensorSnapshot, devices: [SmartDevice]) -> SensorSnapshot {
        var snapshot = current
        let heaterOn = devices.contains { $0.kind == .heater && $0.isOn }
        let conditionerOn = devices.contains { $0.kind == .airConditioner && $0.isOn }
        let fanDevice = devices.first { $0.kind == .fan && $0.isOn }
        let fanSpeed = fanDevice.map { $0.value / 100.0 } ?? 0  // 0.0–1.0
        let activeLights = devices.filter { $0.kind == .light && $0.isOn }
        let socketLoad = devices.filter { $0.kind == .socket && $0.isOn }.reduce(0) { $0 + $1.value }

        // Temperature: outside drift + heater/AC effect
        let outsideDrift = (snapshot.outsideTemperature - snapshot.temperature) * 0.015
        let heaterEffect = heaterOn ? 0.28 : 0
        let coolingEffect = conditionerOn ? -0.32 : 0
        let randomNoise = Double.random(in: -0.08...0.08)
        snapshot.temperature = (snapshot.temperature + outsideDrift + heaterEffect + coolingEffect + randomNoise)
            .clamped(to: 15...31).rounded(toPlaces: 1)

        // Humidity: fan dries faster at higher speed
        let humidityDrift = fanSpeed > 0 ? -(fanSpeed * 2.0) : Double.random(in: -0.4...0.7)
        snapshot.humidity = (snapshot.humidity + humidityDrift).clamped(to: 30...75).rounded(toPlaces: 0)

        // Air quality: fan speed matters (higher speed = faster improvement)
        let airChange = fanSpeed > 0 ? Int((fanSpeed * 5).rounded()) : Int.random(in: -1...1)
        snapshot.airQuality = (snapshot.airQuality + airChange).clamped(to: 55...100)

        // Energy: sum of actual loads
        let hvacLoad = (heaterOn ? 0.9 : 0) + (conditionerOn ? 1.1 : 0)
        let lightingLoad = activeLights.reduce(0) { $0 + ($1.value / 100.0) * 0.1 }  // brightness-proportional
        let fanLoad = fanSpeed * 0.15
        snapshot.energyUsage = (0.2 + hvacLoad + lightingLoad + fanLoad + socketLoad / 1000).rounded(toPlaces: 1)

        snapshot.motionDetected = Int.random(in: 1...5) == 1
        snapshot.leakDetected = snapshot.leakDetected ? Int.random(in: 1...3) != 1 : Int.random(in: 1...45) == 1
        return snapshot
    }
}
