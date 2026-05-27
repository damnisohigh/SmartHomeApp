import Foundation

enum EnvironmentSimulator {
    static func nextSnapshot(from current: SensorSnapshot, devices: [SmartDevice]) -> SensorSnapshot {
        var snapshot = current
        let heaterOn = devices.contains { $0.kind == .heater && $0.isOn }
        let conditionerOn = devices.contains { $0.kind == .airConditioner && $0.isOn }
        let fanOn = devices.contains { $0.kind == .fan && $0.isOn }
        let lightCount = devices.filter { $0.kind == .light && $0.isOn }.count
        let socketLoad = devices.first(where: { $0.kind == .socket })?.value ?? 0

        let outsideDrift = (snapshot.outsideTemperature - snapshot.temperature) * 0.015
        let heaterEffect = heaterOn ? 0.28 : 0
        let coolingEffect = conditionerOn ? -0.32 : 0
        let randomNoise = Double.random(in: -0.08...0.08)
        snapshot.temperature = (snapshot.temperature + outsideDrift + heaterEffect + coolingEffect + randomNoise).clamped(to: 15...31).rounded(toPlaces: 1)

        let humidityDrift = fanOn ? -1.4 : Double.random(in: -0.4...0.7)
        snapshot.humidity = (snapshot.humidity + humidityDrift).clamped(to: 30...75).rounded(toPlaces: 0)

        let airChange = fanOn ? 3 : Int.random(in: -1...1)
        snapshot.airQuality = (snapshot.airQuality + airChange).clamped(to: 55...100)

        let hvacLoad = (heaterOn ? 0.9 : 0) + (conditionerOn ? 1.1 : 0)
        let lightingLoad = Double(lightCount) * 0.08
        snapshot.energyUsage = (0.35 + hvacLoad + lightingLoad + socketLoad / 1000).rounded(toPlaces: 1)

        snapshot.motionDetected = Int.random(in: 1...5) == 1
        snapshot.leakDetected = snapshot.leakDetected ? Int.random(in: 1...3) != 1 : Int.random(in: 1...45) == 1
        return snapshot
    }
}
