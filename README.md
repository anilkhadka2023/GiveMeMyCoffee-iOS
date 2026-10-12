# Give Me My Coffee — iOS

SwiftUI port of the Android app in `../app`. It uses the same backend, the same Google Places
search and the same screens and behaviour.

## Requirements

- Xcode 16 or later (the project uses folder-synchronised groups)
- iOS 17.0+ (uses the Observation framework)

## Setup

1. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` and set `PLACES_API_KEY`.
   This replaces `PLACES_API_KEY` in the Android `local.properties`. The file is git-ignored.
2. Open `GiveMeMyCoffee.xcodeproj`, pick your signing team, and run.
   If the project won't open, regenerate it with XcodeGen: `brew install xcodegen && xcodegen generate`.
3. Backend: `APIConfig.baseURL` is `http://127.0.0.1:55812`. The Simulator reaches a backend on
   the Mac directly, so it doesn't need anything like `adb reverse`. On a physical device, use the
   Mac's LAN IP. Plain HTTP is only allowed for local addresses (`NSAllowsLocalNetworking`).

## How the Android pieces map

| Android | iOS |
| --- | --- |
| Activities + `CoffeeBottomBar` | `TabView` (Home, Cafes, Orders, Profile); the Orders tab pushes menu → order details → status |
| `LoginActivity` auth gate | `RootView` switches on `AppSession.isLoggedIn` |
| `AndroidViewModel` + `StateFlow` | `@Observable` view models, `async`/`await` |
| `EncryptedSharedPreferences` (`TokenStore`) | Keychain |
| `SharedPreferences` (`ProfileRepository`) | `UserDefaults` |
| `Mutex` around token refresh | `actor AuthRepository` with a shared in-flight refresh task |
| `HttpURLConnection` + `org.json` | `URLSession` + `JSONSerialization` |
| Fused location client | `CLLocationManager` (`LocationProvider`) |
| `Toast` | `ToastCenter` overlay |
| Navigation drawer | Toolbar menu on Home |
| `DatePickerDialog` / `TimePickerDialog` | Picker sheets |
| `RangeSlider`, `FlowRow`, `FilterChip` | `RangeSlider`, `FlowLayout`, `Chip` in `Components/` |
| Google Maps directions link | Apple Maps link |
| "Google Pay" button (places the order, no payment) | Black Pay button with the Apple logo (places the order, no payment) |

The cafés list was duplicated in `MainActivity` and `CafesActivity`. Here both tabs share
`CafesViewModel` and `CafeListSection`. The Cafes tab still re-queries Places when you apply
filters, and Home still only filters the results it already has, same as before.
