import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Огляд", systemImage: "house.fill")
                }

            RoomsView()
                .tabItem {
                    Label("Кімнати", systemImage: "square.grid.2x2.fill")
                }

            AutomationsView()
                .tabItem {
                    Label("Сценарії", systemImage: "sparkles")
                }

            CloudView()
                .tabItem {
                    Label("Хмара", systemImage: "icloud.fill")
                }

            Esp32SimulatorView()
                .tabItem {
                    Label("Контролер", systemImage: "cpu.fill")
                }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: SmartHomeStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HeaderCard()

                    CloudSyncCard()

                    ClimatePanel()

                    SectionTitle("Швидке керування")
                    QuickControlGrid()

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "Температура", value: String(format: "%.1f°C", store.sensor.temperature), symbol: "thermometer.sun.fill", tint: .red)
                        MetricCard(title: "Вологість", value: "\(Int(store.sensor.humidity))%", symbol: "humidity.fill", tint: .cyan)
                        MetricCard(title: "Енергія", value: String(format: "%.1f кВт", store.sensor.energyUsage), symbol: "bolt.fill", tint: .yellow)
                        MetricCard(title: "Повітря", value: "\(store.sensor.airQuality)%", symbol: "leaf.fill", tint: .green)
                    }

                    AlertStrip()

                    SectionTitle("Активні пристрої")

                    ForEach(store.devices.filter(\.isOn).prefix(4)) { device in
                        DeviceRow(device: device)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Розумний будинок")
        }
    }
}

struct HeaderCard: View {
    @EnvironmentObject private var store: SmartHomeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Розумний будинок")
                        .font(.title2.bold())
                    Text("Керування пристроями та моніторинг")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: store.isEsp32Online ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(store.isEsp32Online ? .green : .orange)
            }

            HStack {
                StatusPill(title: "\(store.activeDevicesCount)/\(store.totalDevicesCount)", subtitle: "увімкнено")
                StatusPill(title: store.securityMode.rawValue, subtitle: "охорона")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CloudSyncCard: View {
    @EnvironmentObject private var store: SmartHomeStore

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "icloud.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("Хмарна синхронізація")
                    .font(.headline)
                Text(store.cloudStatus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(store.lastCloudSync)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct AlertStrip: View {
    @EnvironmentObject private var store: SmartHomeStore

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: store.sensor.leakDetected ? "drop.triangle.fill" : "shield.lefthalf.filled")
                .font(.title3)
                .foregroundStyle(store.sensor.leakDetected ? .red : .green)

            VStack(alignment: .leading, spacing: 3) {
                Text(store.sensor.leakDetected ? "Увага: можливе протікання" : "Стан будинку нормальний")
                    .font(.headline)
                Text(store.sensor.motionDetected ? "Рух зафіксовано у передпокої" : "Рух не зафіксовано")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct RoomsView: View {
    @EnvironmentObject private var store: SmartHomeStore
    @State private var selectedRoom = "Вітальня"

    var roomDevices: [SmartDevice] {
        store.devices.filter { $0.room == selectedRoom }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.rooms) { room in
                            RoomChip(room: room, isSelected: selectedRoom == room.name) {
                                selectedRoom = room.name
                            }
                        }
                    }
                    .padding()
                }

                List {
                    ForEach(roomDevices) { device in
                        DeviceControlRow(device: device)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Кімнати")
        }
    }
}

struct AutomationsView: View {
    @EnvironmentObject private var store: SmartHomeStore

    var body: some View {
        NavigationStack {
            List {
                Section("Сценарії") {
                    ForEach(store.automations) { automation in
                        AutomationRow(automation: automation)
                    }
                }

                Section("Режим охорони") {
                    Picker("Режим", selection: $store.securityMode) {
                        ForEach(SecurityMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Автоматизація")
        }
    }
}

struct CloudView: View {
    @EnvironmentObject private var store: SmartHomeStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Хмарне керування")
                                    .font(.title2.bold())
                                Text("Firebase Realtime Database")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        CloudRouteView()

                        HStack {
                            Label(store.cloudMode.rawValue, systemImage: store.lastFirebaseError == nil ? "checkmark.seal.fill" : "xmark.seal.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(store.lastFirebaseError == nil ? .blue : .red)
                            Spacer()
                            Text(store.lastFirebaseError == nil ? "підключено" : "помилка з'єднання")
                                .font(.caption.bold())
                                .foregroundStyle(store.lastFirebaseError == nil ? Color.secondary : Color.red)
                        }

                        Text("Команди та телеметрія записуються у Firebase Realtime Database в реальному часі.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    FirebaseSetupCard()

                    SectionTitle("Команди з хмари")

                    ForEach(store.commandLog) { command in
                        CloudCommandRow(command: command)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Хмара")
        }
    }
}

struct FirebaseSetupCard: View {
    @EnvironmentObject private var store: SmartHomeStore

    private var isConnected: Bool { store.lastFirebaseError == nil && store.commandLog.first?.isSuccessful == true }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Firebase Console", systemImage: "checklist")
                    .font(.headline)
                Spacer()
                Image(systemName: isConnected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(isConnected ? .green : .orange)
            }

            if let error = store.lastFirebaseError {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Помилка запису")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption.monospaced())
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Як виправити:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("1. Firebase Console → Authentication → Sign-in method → увімкни Anonymous")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("2. Realtime Database → Rules → { \".read\": true, \".write\": true }")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            FirebaseInfoRow(title: "Project", value: store.firebaseSetup.projectID)
            FirebaseInfoRow(title: "Database", value: store.firebaseSetup.databaseURL)
            FirebaseInfoRow(title: "Bundle", value: store.firebaseSetup.bundleID)

            Divider()

            FirebaseInfoRow(title: "Nodes", value: "telemetry/current, telemetry/history, commands, devices")

            Button {
                store.lastFirebaseError = nil
                store.syncInitialCloudState()
            } label: {
                Label("Повторити sync", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct FirebaseInfoRow: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct Esp32SimulatorView: View {
    @EnvironmentObject private var store: SmartHomeStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "cpu.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("ESP32 Simulation")
                                    .font(.title2.bold())
                                Text(store.isEsp32Online ? "Віртуальний контролер онлайн" : "Зв'язок тимчасово втрачено")
                                    .font(.subheadline)
                                    .foregroundStyle(store.isEsp32Online ? .green : .orange)
                            }
                        }

                        Text("Контролер збирає дані з датчиків температури, вологості та руху і керує реле через хмарну базу даних.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Button {
                            store.simulateEsp32Packet()
                        } label: {
                            Label("Згенерувати пакет", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    SectionTitle("Останній пакет")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        SensorTile(title: "Температура", value: String(format: "%.1f°C", store.sensor.temperature), symbol: "thermometer.medium", tint: .red)
                        SensorTile(title: "Вологість", value: "\(Int(store.sensor.humidity))%", symbol: "humidity.fill", tint: .cyan)
                        SensorTile(title: "Рух", value: store.sensor.motionDetected ? "Виявлено" : "Немає", symbol: "figure.walk", tint: store.sensor.motionDetected ? .orange : .secondary)
                        SensorTile(title: "Контролер", value: store.isEsp32Online ? "Онлайн" : "Офлайн", symbol: "cpu.fill", tint: store.isEsp32Online ? .green : .orange)
                    }

                    SectionTitle("Модель підключення")
                    VStack(alignment: .leading, spacing: 10) {
                        ConnectionStep(number: "1", title: "Датчики", detail: "DHT22, PIR, датчик протікання")
                        ConnectionStep(number: "2", title: "ESP32", detail: "Обробка показників і керування реле")
                        ConnectionStep(number: "3", title: "Хмара", detail: "MQTT broker, Cloud DB, push/status sync")
                        ConnectionStep(number: "4", title: "iOS", detail: "Панель керування, сценарії, сповіщення")
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Контролер")
        }
    }
}

struct QuickControlGrid: View {
    @EnvironmentObject private var store: SmartHomeStore

    private var highlightedDevices: [SmartDevice] {
        ["Головне світло", "Опалення", "Кондиціонер", "Витяжка"].compactMap { name in
            store.devices.first { $0.name == name }
        }
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(highlightedDevices) { device in
                Button {
                    store.toggleDevice(device)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: device.kind.symbol)
                                .foregroundStyle(device.isOn ? device.kind.tint : .secondary)
                            Spacer()
                            Text(store.pendingCommandDeviceID == device.id ? "SYNC" : (device.isOn ? "ON" : "OFF"))
                                .font(.caption.bold())
                                .foregroundStyle(device.isOn ? .green : .secondary)
                        }

                        Text(device.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(device.room)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
                    .padding()
                    .background(device.isOn ? device.kind.tint.opacity(0.16) : Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(device.isOn ? device.kind.tint.opacity(0.55) : Color.clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct StatusPill: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.top, 4)
    }
}

struct DeviceRow: View {
    let device: SmartDevice

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.kind.symbol)
                .frame(width: 34, height: 34)
                .foregroundStyle(device.kind.tint)
                .background(device.kind.tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)
                    .font(.headline)
                Text(device.room)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(device.kind == .lock ? (device.isOn ? "Замкнено" : "Відкрито") : (device.unit.isEmpty ? "ON" : "\(Int(device.value))\(device.unit)"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(device.kind == .lock ? (device.isOn ? .green : .orange) : .secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct RoomChip: View {
    let room: Room
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: room.symbol)
                VStack(alignment: .leading, spacing: 2) {
                    Text(room.name)
                        .font(.subheadline.bold())
                    Text(room.subtitle)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct DeviceControlRow: View {
    @EnvironmentObject private var store: SmartHomeStore
    let device: SmartDevice

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: device.kind.symbol)
                    .foregroundStyle(device.kind.tint)
                    .frame(width: 30)

                VStack(alignment: .leading) {
                    Text(device.name)
                        .font(.headline)
                    Text(device.kind.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(store.pendingCommandDeviceID == device.id ? "SYNC" : deviceStatusLabel(device))
                    .font(.caption.bold())
                    .foregroundStyle(deviceStatusColor(device))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())

                Toggle("", isOn: Binding(
                    get: { device.isOn },
                    set: { _ in store.toggleDevice(device) }
                ))
                .labelsHidden()
            }

            if device.kind == .light || device.kind == .fan || device.kind == .thermostat {
                Slider(
                    value: Binding(
                        get: { device.value },
                        set: { store.updateDeviceValue(device, value: $0) }
                    ),
                    in: device.kind == .thermostat ? 16...28 : 0...100
                )

                Text(sliderLabel(for: device))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: device.isOn)
    }

    private func deviceStatusLabel(_ device: SmartDevice) -> String {
        switch device.kind {
        case .lock: return device.isOn ? "Замкнено" : "Відкрито"
        default: return device.isOn ? "ON" : "OFF"
        }
    }

    private func deviceStatusColor(_ device: SmartDevice) -> Color {
        switch device.kind {
        case .lock: return device.isOn ? .green : .orange
        default: return device.isOn ? .green : .secondary
        }
    }

    private func sliderLabel(for device: SmartDevice) -> String {
        switch device.kind {
        case .thermostat: return "Ціль: \(String(format: "%.0f", device.value))°C"
        case .fan: return "Швидкість: \(String(format: "%.0f", device.value))%"
        case .light: return "Яскравість: \(String(format: "%.0f", device.value))%"
        default: return "\(String(format: "%.0f", device.value))\(device.unit)"
        }
    }
}

struct CloudRouteView: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                CloudRouteNode(symbol: "iphone", title: "iOS")
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                CloudRouteNode(symbol: "icloud.fill", title: "Cloud")
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                CloudRouteNode(symbol: "cpu.fill", title: "ESP32")
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                CloudRouteNode(symbol: "switch.2", title: "Relay")
            }

            Text("Команди від застосунку надходять у хмару та виконуються контролером у реальному часі.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct CloudRouteNode: View {
    let symbol: String
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.headline)
            Text(title)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CloudCommandRow: View {
    let command: CloudCommand

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: command.isSuccessful ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(command.isSuccessful ? .green : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(command.title)
                    .font(.headline)
                Text(command.result)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(command.time)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct AutomationRow: View {
    @EnvironmentObject private var store: SmartHomeStore
    let automation: Automation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: automation.symbol)
                    .foregroundStyle(.blue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(automation.name)
                        .font(.headline)
                    Text(automation.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { automation.isEnabled },
                    set: { _ in store.toggleAutomation(automation) }
                ))
                .labelsHidden()
            }

            Button {
                store.runAutomation(automation)
            } label: {
                Label("Запустити", systemImage: "play.fill")
            }
            .buttonStyle(.bordered)
            .disabled(!automation.isEnabled)
        }
        .padding(.vertical, 6)
    }
}

struct SensorTile: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ConnectionStep: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    ContentView()
        .environmentObject(SmartHomeStore())
}
