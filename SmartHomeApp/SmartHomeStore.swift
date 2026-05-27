import Foundation

@MainActor
final class SmartHomeStore: ObservableObject {
    @Published var rooms: [Room] = SeedData.rooms
    @Published var devices: [SmartDevice] = SeedData.devices
    @Published var automations: [Automation] = SeedData.automations
    @Published var sensor = SeedData.sensor
    @Published var securityMode: SecurityMode = .home
    @Published var isEsp32Online = true
    @Published var lastPacket = "ESP32-SIM: temp=23.4; hum=48; motion=1; relay=OK"
    @Published var cloudStatus = "Simulation Cloud online"
    @Published var lastCloudSync = ""
    @Published var pendingCommandDeviceID: SmartDevice.ID?
    @Published var cloudMode: CloudMode = .simulated
    @Published var isAutoSimulationEnabled = true
    @Published var commandLog: [CloudCommand] = []
    @Published var firebaseSetup = FirebaseSetupInfo(
        projectID: "unknown",
        databaseURL: "missing DATABASE_URL",
        bundleID: "unknown"
    )

    private let cloudService: CloudService
    private var simulationTimer: Timer?

    init(cloudService: CloudService = MockCloudService()) {
        self.cloudService = cloudService
        self.cloudMode = cloudService.mode
        self.firebaseSetup = Self.loadFirebaseSetup()
        self.lastCloudSync = Self.clockString()
        self.commandLog = [
            CloudCommand(time: Self.clockString(), title: "Simulation cloud ready", route: "iOS -> Mock Cloud DB -> MQTT model -> ESP32-SIM", result: "Демо працює без API ключа", isSuccessful: true)
        ]
        startAutoSimulation()
        syncInitialCloudState()
    }

    deinit {
        simulationTimer?.invalidate()
    }

    var activeDevicesCount: Int {
        devices.filter(\.isOn).count
    }

    var totalDevicesCount: Int {
        devices.count
    }

    func toggleDevice(_ device: SmartDevice) {
        guard let index = devices.firstIndex(of: device) else { return }
        let nextState = !devices[index].isOn
        sendCloudCommand(to: devices[index], turnOn: nextState)
    }

    func sendCloudCommand(to device: SmartDevice, turnOn: Bool) {
        guard let index = devices.firstIndex(of: device) else { return }
        let command = turnOn ? "ON" : "OFF"
        pendingCommandDeviceID = devices[index].id
        cloudStatus = "\(cloudMode.rawValue): queued \(device.name) \(command)"
        appendCommand(
            title: "\(device.name) \(command)",
            route: cloudMode == .simulated ? "iOS -> Mock Cloud DB -> MQTT model -> ESP32-SIM" : "iOS -> HTTPS -> Cloud DB -> MQTT -> ESP32",
            result: "Очікує підтвердження реле",
            isSuccessful: true
        )

        Task { [weak self] in
            let delivery = await self?.cloudService.sendDeviceCommand(device: device, turnOn: turnOn)
            guard let self, let currentIndex = self.devices.firstIndex(where: { $0.id == device.id }) else { return }
            self.devices[currentIndex].isOn = turnOn

            if self.devices[currentIndex].kind == .socket {
                self.devices[currentIndex].value = turnOn ? 120 : 0
            }

            if self.devices[currentIndex].kind == .lock {
                self.devices[currentIndex].value = turnOn ? 1 : 0
            }

            self.pendingCommandDeviceID = nil
            self.cloudStatus = "\(self.cloudMode.rawValue): synced \(device.name) \(command)"
            self.lastCloudSync = Self.clockString()
            self.refreshPacket()
            self.appendCommand(
                title: delivery?.title ?? "Cloud command failed",
                route: delivery?.route ?? "iOS -> Cloud",
                result: delivery?.result ?? "Немає відповіді від сервісу",
                isSuccessful: delivery?.isSuccessful == true
            )
        }
    }

    func updateDeviceValue(_ device: SmartDevice, value: Double) {
        guard let index = devices.firstIndex(of: device) else { return }
        devices[index].value = value
    }

    func updateTargetTemperature(_ value: Double) {
        sensor.targetTemperature = value
        updateDevice(named: "Термостат", value: value)
    }

    func setClimateMode(_ mode: DeviceKind?) {
        guard mode == nil || mode == .heater || mode == .airConditioner else { return }
        setDevice(named: "Опалення", isOn: mode == .heater, value: 900)
        setDevice(named: "Кондиціонер", isOn: mode == .airConditioner, value: sensor.targetTemperature)
        appendCommand(
            title: mode == nil ? "Climate OFF" : "Climate \(mode == .heater ? "HEAT" : "COOL")",
            route: "iOS -> Cloud Function -> ESP32-SIM climate relays",
            result: "Кліматичне реле оновлено",
            isSuccessful: true
        )
    }

    func toggleAutomation(_ automation: Automation) {
        guard let index = automations.firstIndex(of: automation) else { return }
        automations[index].isEnabled.toggle()
    }

    func runAutomation(_ automation: Automation) {
        appendCommand(
            title: "Scenario: \(automation.name)",
            route: "iOS app -> Cloud Function -> ESP32-SIM relays",
            result: "Сценарій виконується",
            isSuccessful: true
        )

        switch automation.name {
        case "Вечірній режим":
            setDevice(named: "Головне світло", isOn: true, value: 65)
            setDevice(named: "Нічне світло", isOn: true, value: 25)
            securityMode = .home
        case "Я йду з дому":
            for index in devices.indices where devices[index].kind == .light || devices[index].kind == .socket || devices[index].kind == .fan {
                devices[index].isOn = false
                if devices[index].kind == .socket { devices[index].value = 0 }
            }
            setDevice(named: "IP-камера", isOn: true, value: 1080)
            setDevice(named: "Вхідний замок", isOn: true, value: 1)
            securityMode = .away
            sensor.motionDetected = false
        case "Провітрювання кухні":
            setDevice(named: "Витяжка", isOn: true, value: 75)
            sensor.airQuality = min(100, sensor.airQuality + 5)
        case "Клімат авто":
            if sensor.temperature < sensor.targetTemperature - 0.5 {
                setClimateMode(.heater)
            } else if sensor.temperature > sensor.targetTemperature + 0.5 {
                setClimateMode(.airConditioner)
            } else {
                setClimateMode(nil)
            }
        default:
            break
        }

        refreshPacket()
        cloudStatus = "Cloud synced scenario: \(automation.name)"
        lastCloudSync = Self.clockString()
        appendCommand(
            title: "Scenario complete",
            route: "ESP32-SIM -> Cloud DB -> iOS app",
            result: "Стан пристроїв оновлено",
            isSuccessful: true
        )
    }

    func simulateEsp32Packet() {
        sensor = EnvironmentSimulator.nextSnapshot(from: sensor, devices: devices)
        isEsp32Online = Int.random(in: 1...10) != 1
        refreshPacket()
        cloudStatus = isEsp32Online ? "Telemetry synced to \(cloudMode.rawValue)" : "Cloud waiting for ESP32 reconnect"
        lastCloudSync = Self.clockString()
        Task { [weak self] in
            guard let self else { return }
            let delivery = await self.cloudService.sendTelemetry(self.sensor)
            self.appendCommand(
                title: delivery.title,
                route: delivery.route,
                result: isEsp32Online ? delivery.result : "Пакет не доставлено",
                isSuccessful: isEsp32Online && delivery.isSuccessful
            )
        }
    }

    func toggleAutoSimulation() {
        isAutoSimulationEnabled.toggle()
    }

    func syncInitialCloudState() {
        cloudStatus = "\(cloudMode.rawValue): syncing initial state"
        Task { [weak self] in
            guard let self else { return }
            let delivery = await self.cloudService.syncInitialState(devices: self.devices, sensor: self.sensor)
            self.cloudStatus = delivery.isSuccessful ? "\(self.cloudMode.rawValue): initial state synced" : "\(self.cloudMode.rawValue): initial sync failed"
            self.lastCloudSync = Self.clockString()
            self.appendCommand(
                title: delivery.title,
                route: delivery.route,
                result: delivery.result,
                isSuccessful: delivery.isSuccessful
            )
        }
    }

    private func setDevice(named name: String, isOn: Bool, value: Double) {
        guard let index = devices.firstIndex(where: { $0.name == name }) else { return }
        devices[index].isOn = isOn
        devices[index].value = value
    }

    private func updateDevice(named name: String, value: Double) {
        guard let index = devices.firstIndex(where: { $0.name == name }) else { return }
        devices[index].value = value
    }

    private func startAutoSimulation() {
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isAutoSimulationEnabled else { return }
                self.applyClimateAutomation()
                self.simulateEsp32Packet()
            }
        }
    }

    private func applyClimateAutomation() {
        let autoEnabled = automations.first(where: { $0.name == "Клімат авто" })?.isEnabled == true
        guard autoEnabled else { return }

        if sensor.temperature < sensor.targetTemperature - 0.6 {
            setDevice(named: "Опалення", isOn: true, value: 900)
            setDevice(named: "Кондиціонер", isOn: false, value: sensor.targetTemperature)
        } else if sensor.temperature > sensor.targetTemperature + 0.6 {
            setDevice(named: "Опалення", isOn: false, value: 900)
            setDevice(named: "Кондиціонер", isOn: true, value: sensor.targetTemperature)
        } else {
            setDevice(named: "Опалення", isOn: false, value: 900)
            setDevice(named: "Кондиціонер", isOn: false, value: sensor.targetTemperature)
        }
    }

    private func refreshPacket() {
        let motion = sensor.motionDetected ? 1 : 0
        let leak = sensor.leakDetected ? 1 : 0
        let relay = isEsp32Online ? "OK" : "LOST"
        lastPacket = "ESP32-SIM: temp=\(sensor.temperature); target=\(Int(sensor.targetTemperature)); hum=\(Int(sensor.humidity)); motion=\(motion); leak=\(leak); relay=\(relay)"
    }

    private func appendCommand(title: String, route: String, result: String, isSuccessful: Bool) {
        commandLog.insert(
            CloudCommand(time: Self.clockString(), title: title, route: route, result: result, isSuccessful: isSuccessful),
            at: 0
        )

        if commandLog.count > 8 {
            commandLog.removeLast()
        }
    }

    private static func clockString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    private static func loadFirebaseSetup() -> FirebaseSetupInfo {
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let values = NSDictionary(contentsOfFile: path)
        else {
            return FirebaseSetupInfo(
                projectID: "missing GoogleService-Info.plist",
                databaseURL: "missing GoogleService-Info.plist",
                bundleID: Bundle.main.bundleIdentifier ?? "unknown"
            )
        }

        let projectID = values["PROJECT_ID"] as? String ?? "missing PROJECT_ID"
        let databaseURL = values["DATABASE_URL"] as? String ?? "missing DATABASE_URL"
        let bundleID = values["BUNDLE_ID"] as? String ?? Bundle.main.bundleIdentifier ?? "unknown"

        return FirebaseSetupInfo(projectID: projectID, databaseURL: databaseURL, bundleID: bundleID)
    }
}
