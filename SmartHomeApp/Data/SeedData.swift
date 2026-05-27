import Foundation

enum SeedData {
    static let rooms: [Room] = [
        Room(name: "Вітальня", subtitle: "Світло, камера, розетка", symbol: "sofa.fill"),
        Room(name: "Кухня", subtitle: "Датчик протікання, вентиляція", symbol: "fork.knife"),
        Room(name: "Спальня", subtitle: "Термостат, нічне світло", symbol: "bed.double.fill"),
        Room(name: "Передпокій", subtitle: "Замок, рух, сигналізація", symbol: "door.left.hand.open")
    ]

    static let devices: [SmartDevice] = [
        SmartDevice(name: "Головне світло", room: "Вітальня", kind: .light, isOn: true, value: 80, unit: "%"),
        SmartDevice(name: "IP-камера", room: "Вітальня", kind: .camera, isOn: true, value: 1080, unit: "p"),
        SmartDevice(name: "Розумна розетка", room: "Вітальня", kind: .socket, isOn: false, value: 0, unit: "Вт"),
        SmartDevice(name: "Витяжка", room: "Кухня", kind: .fan, isOn: false, value: 35, unit: "%"),
        SmartDevice(name: "Опалення", room: "Спальня", kind: .heater, isOn: false, value: 900, unit: "Вт"),
        SmartDevice(name: "Кондиціонер", room: "Спальня", kind: .airConditioner, isOn: false, value: 18, unit: "°C"),
        SmartDevice(name: "Термостат", room: "Спальня", kind: .thermostat, isOn: true, value: 22, unit: "°C"),
        SmartDevice(name: "Нічне світло", room: "Спальня", kind: .light, isOn: false, value: 30, unit: "%"),
        SmartDevice(name: "Вхідний замок", room: "Передпокій", kind: .lock, isOn: true, value: 1, unit: "")
    ]

    static let automations: [Automation] = [
        Automation(name: "Вечірній режим", description: "Вмикає світло у вітальні та зменшує яскравість у спальні.", symbol: "moon.stars.fill", isEnabled: true),
        Automation(name: "Я йду з дому", description: "Вимикає розетки, блокує замок, активує камеру.", symbol: "figure.walk.departure", isEnabled: true),
        Automation(name: "Провітрювання кухні", description: "Запускає вентиляцію, якщо вологість або якість повітря погіршується.", symbol: "wind", isEnabled: true),
        Automation(name: "Клімат авто", description: "Підігріває або охолоджує кімнату до цільової температури.", symbol: "thermometer.variable", isEnabled: true)
    ]

    static let sensor = SensorSnapshot(
        temperature: 23.4,
        humidity: 48,
        motionDetected: true,
        airQuality: 91,
        energyUsage: 1.8,
        leakDetected: false,
        outsideTemperature: 11.0,
        targetTemperature: 22.0
    )
}
