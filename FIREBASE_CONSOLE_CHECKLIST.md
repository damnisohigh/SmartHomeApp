# Firebase Console checklist

Тема диплома: "Система керування розумним будинком із застосуванням хмарних технологій".

У проєкті є дві різні Firebase-конфігурації, тому важливо відкривати правильну консоль і правильний тип бази даних.

## SmartHomeApp.xcodeproj

Основний демо-проєкт без фізичного ESP32.

- Xcode project: `/Users/damnisohigh/Documents/Codex/2026-05-27/goal-ios-esp32/SmartHomeApp.xcodeproj`
- Firebase project: `smarthomeapp-f65c5`
- Bundle ID: `com.example.SmartHomeApp`
- Database type: Realtime Database
- Database URL: `https://smarthomeapp-f65c5-default-rtdb.europe-west1.firebasedatabase.app`

У Firebase Console треба відкрити:

`Build -> Realtime Database -> Data`

Після запуску застосунку або натискання кнопки `Повторити sync` у вкладці `Хмара` мають з'явитися вузли:

- `app/status`
- `devices`
- `telemetry/current`
- `telemetry/history`
- `commands`

Якщо у вкладці `Хмара` показано `Firebase Auth error: CONFIGURATION_NOT_FOUND`, треба увімкнути:

`Build -> Authentication -> Sign-in method -> Anonymous -> Enable`

Після цього для демо можна використати правила Realtime Database:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

Для короткої демонстрації без Authentication можна тимчасово відкрити тестові правила:

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

Публічні правила не можна залишати для реального застосунку.

## SmartHome.xcodeproj

Старіший Desktop-проєкт.

- Xcode project: `/Users/damnisohigh/Desktop/SmartHome/SmartHome.xcodeproj`
- Firebase project: `smarthome-934b7`
- Bundle ID: `xyz.damnisohigh.SmartHome`
- Database type: Firestore Database

У Firebase Console треба відкрити:

`Build -> Firestore Database -> Data`

Після запуску застосунку мають з'явитися колекції:

- `rooms`
- `events`

Якщо дивитися `Realtime Database` для цього проєкту, даних там не буде, бо цей застосунок використовує Firestore.

## Найчастіші причини порожньої консолі

1. Відкрито не той Firebase project.
2. Відкрито Firestore замість Realtime Database або навпаки.
3. Не увімкнено Anonymous Auth, а правила вимагають `auth != null`.
4. Правила бази даних забороняють запис.
5. Запущено інший Xcode-проєкт, ніж очікувалося.

Для основного дипломного демо рекомендовано запускати `SmartHomeApp.xcodeproj` і дивитися саме `smarthomeapp-f65c5 -> Realtime Database -> Data`.
