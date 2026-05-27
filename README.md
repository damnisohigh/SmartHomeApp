# Smart Home iOS Demo

SwiftUI demo app for the coursework topic: "Система керування розумним будинком із застосуванням розумних технологій".

The project is intentionally built without physical ESP32 hardware. The `ESP32` tab simulates telemetry packets that would normally be sent by a microcontroller: temperature, humidity, motion, leak state, relay status, and energy usage.

## Features

- Dashboard with home status, sensors, active devices, and alerts.
- Room view with controllable lights, thermostat, socket, lock, camera, and fan.
- Automation scenarios for evening mode, leaving home, and kitchen ventilation.
- Security mode selector.
- Cloud control screen that demonstrates a Firebase/Cloud DB + MQTT style route.
- Command log: `iOS app -> Cloud DB -> MQTT broker -> ESP32-SIM -> relay`.
- ESP32 simulation screen with generated telemetry packet and relay acknowledgements.

## Cloud Technology Simulation

The app shows how cloud technologies would be used in the real system:

1. The iOS app sends an ON/OFF command to the cloud database.
2. A cloud function or MQTT broker forwards the command to ESP32.
3. ESP32 switches a relay for a light, fan, socket, camera, or lock.
4. ESP32 sends an acknowledgement and telemetry back to the cloud.
5. The iOS app receives the updated device state.

The app is configured for Firebase Realtime Database through `GoogleService-Info.plist`, `FirebaseCore`, and `FirebaseDatabase`. iOS writes device commands and telemetry to Firebase; ESP32 is still simulated locally unless a physical controller is added.

For this Firebase project the Realtime Database instance is in Europe, so the app uses:

`https://smarthomeapp-f65c5-default-rtdb.europe-west1.firebasedatabase.app`

After running the app, open Firebase Console -> Realtime Database -> Data and check these nodes:

- `telemetry/current` - updated automatically every 2 seconds by the ESP32 simulator.
- `telemetry/history` - one generated telemetry packet per simulation tick.
- `commands` - commands created when a device is toggled in the app.
- `devices` - last known state for controlled devices.

The app tries Anonymous Auth before writing. If the Cloud tab shows `Firebase Auth error: CONFIGURATION_NOT_FOUND`, enable Firebase Console -> Authentication -> Sign-in method -> Anonymous. If it shows `Firebase write error: Permission denied`, set Realtime Database rules to allow authenticated demo users, for example:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

For a short classroom/demo run without Authentication, temporary public test rules also make the simulator visible immediately:

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

Do not leave public rules enabled for a real deployed app.

The architecture still has a real integration point:

- `CloudService` protocol describes command and telemetry delivery.
- `FirebaseCloudService` writes commands and telemetry to Firebase Realtime Database.
- `MockCloudService` simulates cloud delivery for offline demonstration.
- `HTTPCloudService` is ready for a real HTTPS endpoint and API key.
- `EnvironmentSimulator` generates sensor data every 2 seconds.
- Heating increases temperature, air conditioner decreases temperature, and ventilation improves air quality/reduces humidity.

## Project Structure

- `Models.swift` - domain models.
- `Data/SeedData.swift` - initial rooms, devices, automations, sensors.
- `Services/CloudService.swift` - cloud abstraction, mock cloud, real HTTP client.
- `Services/FirebaseCloudService.swift` - real Firebase Realtime Database integration.
- `Services/EnvironmentSimulator.swift` - sensor/physics simulation.
- `Services/NumberFormatting.swift` - shared numeric helpers.
- `SmartHomeStore.swift` - app state, commands, automations.
- `Views/Dashboard/ClimatePanel.swift` - climate simulation UI.
- `ContentView.swift` - main screens and navigation.

## Run

Open `SmartHomeApp.xcodeproj` in Xcode and run the `SmartHomeApp` scheme on an iPhone Simulator.
