# QSDK: QSleeve iOS SDK Implementation Guide

Welcome to the QSleeve iOS SDK distribution repository. This repository provides the pre-compiled binary versions of the QSleeve SDK, allowing for easy integration into your iOS applications.

---

## Quick Start Flow

Follow these steps in order to set up your project and integrate the SDK successfully.

### 1. Prerequisites

Before starting, ensure you have the following:

- **iOS 26.0+** / **macOS 26.0+**
- **Xcode 15+**
- **App Group ID**: Required for communication between the App and the Network Extension.

### 2. Add Dependencies

The QSleeve solution requires two main components:

1. **QSleeveSDK**: The main core library (distributed as a binary XCFramework).
2. **QSleeveKit**: The tunnel adapter library required by the Network Extension.

#### Add via Swift Package Manager (SPM)

In Xcode, go to **File > Add Package Dependencies** and add:

- **QSleeveSDK**: `https://github.com/Navneet-Gupta-qaig/QSDK.git`
  - **Dependency Rule**: Select **Branch** and enter `main`.
  - **Target**: Choose your **Main App** target when prompted.

- **QSleeveKit** (Required for Network Extension): `https://github.com/Navneet-Gupta-qaig/Qsleeve-sdk-apple.git`
  - **Dependency Rule**: Select **Branch** and enter `main`.
  - **Target**: Choose your **Network Extension** target when prompted.

### 3. Setup Network Extension

The Network Extension is the core of the VPN. It must be added as a separate target in your project.

1. **Create Target**: Add a new "network-extension" target to your Xcode project.
2. **Entitlements Configuration**:
   - **Main App**:
     - `com.apple.developer.networking.networkextension`: `packet-tunnel-provider`
     - `com.apple.developer.networking.vpn.api`: `allow-vpn`
     - `com.apple.security.application-groups`: Your App Group ID (e.g., `group.com.company.app`)
   - **Network Extension**:
     - `com.apple.developer.networking.networkextension`: `packet-tunnel-provider`
     - `com.apple.security.application-groups`: Your App Group ID
3. **Implementation**: Copy the content of [`PacketTunnelProvider.swift`](Sources/network-extension/PacketTunnelProvider.swift) into your extension's main file.
4. **Required Manual Changes**:

| File                         | Line | Key Change         | Implementation Detail                                                                      |
| :--------------------------- | :--- | :----------------- | :----------------------------------------------------------------------------------------- |
| `PacketTunnelProvider.swift` | 29   | App Group ID       | Replace `"group.com.qaig.QSleeve"` with your **Actual App Group ID**.                      |
| `testCode.swift`             | 32   | `authUrl`          | Update this to your server environment.                                                    |
| `testCode.swift`             | 34   | `providerBundleId` | Replace `"bundleIdentifierOfNetworkExtension"` with your **Extension Target's Bundle ID**. |

---

### 4. Implement App Logic

Use the [`testCode.swift`](Sources/testCode.swift) as a reference for your main UI and SDK interaction.

---

### SDK Core APIs

The SDK manages the tunnel state internally, providing 5 main API entry points for simplicity and robustness.

### 1. Initialize

```swift
let qsleeve = QSleeveSDK()

let result = await qsleeve.initialize(
    body: ["username": "your_user", "password": "your_password"],
    authUrl: "https://auth.yourserver.com:8443",
    providerBundleId: "com.yourcompany.app.extension"
)
```

This performs a "Warm Up" of the environment:

- **Authentication**: Performs encrypted login and key exchange.
- **Profile Setup**: Automatically creates and saves the VPN profile in iOS Settings.
- **Returns**: A `Result` containing a configuration dictionary in the `config` key. You should save this dictionary locally (e.g., in `UserDefaults` or a database).

### 2. Connect

```swift
let result = await qsleeve.connect(configJson: savedConfig)
```

Establishes the VPN tunnel using the previously saved `"config"` mapping.

- **Retry Logic**: The SDK will try to start the tunnel repeatedly if the initial attempt fails.
- **Reachability**: It verifies connectivity by pinging the VPN's server address.

### 3. Disconnect

```swift
let result = await qsleeve.disconnect()
```

Safely stops the active VPN tunnel.

### 4. Get Status

```swift
let result = await qsleeve.getStatus()
// Access status via result.success?["status"] as? Bool
```

Asynchronously checks if the VPN tunnel is genuinely connected and reachable.

### 5. Re-Initialize

```swift
let result = await qsleeve.reInitialize(configJson: savedConfig)
```

Automatically re-authenticates and updates configuration using cacehd credentials. This is useful for auto-recovery if the session expires or network conditions change.

---

## ⚠️ Important Considerations

- **App Group ID**: Required for communication and log sharing. Ensure the ID matches exactly in the Main App entitlements, Extension entitlements, and the `PacketTunnelProvider.swift` code.
- **Background Modes**: Go to **Signing & Capabilities** -> **Background Modes** and check **Network Authentication**.

---

## 🛠️ Troubleshooting

### "Permission Denied" (Code 10) on Initialize

If `initialize()` fails with `permission denied`:

1. **Check Entitlements**: Ensure the Main App has the `allow-vpn` and `packet-tunnel-provider` entitlements.
2. **App Group ID**: Verify that the App Group ID in your entitlements matches what you passed to the SDK.
3. **Bundle ID**: Ensure the `providerBundleId` passed to `initialize()` exactly matches the Bundle Identifier of your Network Extension target.
4. **Provisioning**: Ensure you are using a Developer Profile that supports Network Extensions.

---

© 2022-2026 QAIG Pvt. Ltd. All Rights Reserved.
