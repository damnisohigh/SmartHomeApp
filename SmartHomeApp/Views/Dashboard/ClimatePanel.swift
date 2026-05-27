import SwiftUI

struct ClimatePanel: View {
    @EnvironmentObject private var store: SmartHomeStore

    private var heaterOn: Bool { store.devices.first { $0.kind == .heater }?.isOn == true }
    private var acOn: Bool { store.devices.first { $0.kind == .airConditioner }?.isOn == true }
    private var fan: SmartDevice? { store.devices.first { $0.kind == .fan } }

    private var fanSpeed: Int {
        guard let f = fan, f.isOn else { return 0 }
        return max(1, min(5, Int((f.value / 100.0 * 5).rounded())))
    }

    private var modeColor: Color {
        heaterOn ? .orange : (acOn ? .blue : .green)
    }

    private var modeLabel: String {
        heaterOn ? "Опалення" : (acOn ? "Охолодження" : "Комфорт")
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Клімат")
                    .font(.headline)
                Spacer()
                Text(modeLabel)
                    .font(.caption.bold())
                    .foregroundStyle(modeColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(modeColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Two dials + center display
            HStack(alignment: .center, spacing: 0) {
                TempDial(
                    value: store.sensor.targetTemperature,
                    tint: modeColor,
                    onDecrement: { store.updateTargetTemperature(max(16, store.sensor.targetTemperature - 1)) },
                    onIncrement: { store.updateTargetTemperature(min(28, store.sensor.targetTemperature + 1)) }
                )

                VStack(spacing: 6) {
                    Text(String(format: "%.1f°", store.sensor.temperature))
                        .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(modeColor)
                        .contentTransition(.numericText())
                    Text("у кімнаті")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f° ззовні", store.sensor.outsideTemperature))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)

                FanDial(
                    speed: fanSpeed,
                    onDecrement: { adjustFan(-1) },
                    onIncrement: { adjustFan(+1) }
                )
            }

            // Auto climate toggle
            HStack(spacing: 12) {
                Image(systemName: store.isClimateAutoEnabled ? "thermometer.variable" : "power")
                    .font(.title3)
                    .foregroundStyle(store.isClimateAutoEnabled ? modeColor : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Авто-клімат")
                        .font(.subheadline.bold())
                    Text(store.isClimateAutoEnabled ? modeLabel : "Система вимкнена")
                        .font(.caption)
                        .foregroundStyle(store.isClimateAutoEnabled ? modeColor : .secondary)
                        .animation(.easeInOut, value: modeLabel)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { store.isClimateAutoEnabled },
                    set: { _ in store.toggleClimateAuto() }
                ))
                .labelsHidden()
                .tint(modeColor)
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func adjustFan(_ delta: Int) {
        guard let f = fan else { return }
        let newSpeed = max(0, min(5, fanSpeed + delta))
        store.updateDeviceValue(f, value: Double(newSpeed) / 5.0 * 100.0)
        let shouldBeOn = newSpeed > 0
        if shouldBeOn != f.isOn {
            store.sendCloudCommand(to: f, turnOn: shouldBeOn)
        }
    }
}

// MARK: - Temperature dial

private struct TempDial: View {
    let value: Double
    let tint: Color
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    private var progress: Double { (value - 16) / (28 - 16) }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Background arc: starts at 7:30 (225°), sweeps 270° clockwise
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.gray.opacity(0.15),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(225))

                // Filled arc
                Circle()
                    .trim(from: 0, to: 0.75 * progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(225))
                    .animation(.easeInOut(duration: 0.25), value: progress)

                VStack(spacing: 1) {
                    Text("\(Int(value))°")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(tint)
                        .contentTransition(.numericText())
                    Text("ЦІЛЬ")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 90, height: 90)

            DialButtons(onDecrement: onDecrement, onIncrement: onIncrement)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Fan speed dial

private struct FanDial: View {
    let speed: Int   // 0–5
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    private let levels = 5
    private let radius = 34.0

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.gray.opacity(0.15),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(225))

                // Speed dots placed along the arc
                ForEach(1...levels, id: \.self) { level in
                    let θ = (225.0 + Double(level - 1) * 270.0 / Double(levels - 1)) * Double.pi / 180
                    let x = CGFloat(radius * sin(θ))
                    let y = CGFloat(-radius * cos(θ))
                    let active = level <= speed
                    Circle()
                        .fill(active ? Color.cyan : Color.gray.opacity(0.25))
                        .frame(width: active ? 10 : 6, height: active ? 10 : 6)
                        .offset(x: x, y: y)
                        .animation(.easeInOut(duration: 0.15), value: active)
                }

                // Center
                VStack(spacing: 1) {
                    Image(systemName: "wind")
                        .font(.subheadline.bold())
                        .foregroundStyle(speed > 0 ? Color.cyan : .secondary)
                    Text(speed == 0 ? "ВИМК" : "\(speed)/\(levels)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(speed > 0 ? Color.cyan : .secondary)
                }
            }
            .frame(width: 90, height: 90)

            DialButtons(onDecrement: onDecrement, onIncrement: onIncrement)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared

private struct DialButtons: View {
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(.caption.bold())
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.caption.bold())
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

