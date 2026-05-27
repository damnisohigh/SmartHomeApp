import SwiftUI

struct ClimatePanel: View {
    @EnvironmentObject private var store: SmartHomeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Клімат модель", systemImage: "thermometer.variable")
                    .font(.headline)
                Spacer()
                Text(store.isAutoSimulationEnabled ? "AUTO" : "PAUSED")
                    .font(.caption.bold())
                    .foregroundStyle(store.isAutoSimulationEnabled ? .green : .secondary)
            }

            HStack {
                ClimateValue(title: "У кімнаті", value: String(format: "%.1f°C", store.sensor.temperature))
                ClimateValue(title: "На вулиці", value: String(format: "%.1f°C", store.sensor.outsideTemperature))
                ClimateValue(title: "Ціль", value: String(format: "%.0f°C", store.sensor.targetTemperature))
            }

            Slider(value: Binding(
                get: { store.sensor.targetTemperature },
                set: { store.updateTargetTemperature($0) }
            ), in: 16...28, step: 1)

            HStack(spacing: 10) {
                Button {
                    store.setClimateMode(.heater)
                } label: {
                    Label("Heat", systemImage: "flame.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    store.setClimateMode(.airConditioner)
                } label: {
                    Label("Cool", systemImage: "snowflake")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    store.setClimateMode(nil)
                } label: {
                    Label("Off", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Text("Температура автоматично змінюється кожні 2 секунди. Опалення піднімає її, кондиціонер знижує, вентиляція покращує повітря й зменшує вологість.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ClimateValue: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
