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
2. **Entitlements**: Add the "Network Extensions" and "App Groups" capabilities to both the Main App and the Network Extension targets and check the Packet Tunnel option .
3. **Implementation**: Copy the content of [`PacketTunnelProvider.swift`](Sources/network-extension/PacketTunnelProvider.swift) into your extension's main file.
4. **App Group Configuration**:
   - Find the line: `forSecurityApplicationGroupIdentifier: "bundleIdentifierOfNetworkExtension"`
   - Replace it with your actual **App Group ID** (e.g., `group.com.yourcompany.projectName`).

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

- **App Group ID**: Required for communication between the App and the Network Extension.
- **Background Modes**: If your app needs to monitor or maintain the VPN in the background, go to **Signing & Capabilities** -> **Background Modes** and check **Network Authentication**.

---

© 2022-2026 QAIG Pvt. Ltd. All Rights Reserved.
