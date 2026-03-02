# QSleeve iOS SDK

Welcome to the QSleeve iOS SDK distribution repository. This repository provides the pre-compiled binary versions of the QSleeve SDK, allowing for easy integration into your iOS applications.

## Integration via Swift Package Manager

The preferred way to integrate the QSleeve SDK is via Swift Package Manager (SPM).

1. In Xcode, go to **File > Add Package Dependencies...**
2. Enter the URL of this repository: `[https://github.com/QSleeve/QSleeve_IOS_SDK](https://github.com/Navneet-Gupta-qaig/QSleeve_IOS_SDK.git)`
3. Select the branch and add main .

### Manual Integration

Alternatively, you can download the `QSleeveSDK.xcframework.zip` from the latest release, unzip it, and add the contained `.xcframework` files to your Xcode project's **Frameworks, Libraries, and Embedded Content** section.

## Requirements

- **iOS 15.0** or later
- **Xcode 15.0** or later
- **Swift 5.9** or later

## 🛠 Prerequisites & Developer Settings

Before integrating the SDK into your project, ensure that your Apple Developer Account and Xcode Project are configured correctly.

### 1. App Identifiers & Certificates

- Your Apple Developer Account must have the **Network Extension** entitlement enabled for your App ID.
- You must create a secondary App ID for your **Packet Tunnel Provider** network extension.
- Provisioning Profiles for both the Main App and the Extension must include the Network Extension features.

### 2. Xcode Project Capabilities

You must add the following capabilities to **BOTH** your Main App Target and your Network Extension Target:

1. **Network Extensions**:
   - Check the box for **Packet Tunnel**.
2. **App Groups**:
   - Create a shared App Group (e.g., `group.com.yourcompany.qsleeve`).
   - Enable this App Group on both the app and the extension so they can share configuration data.

### 3. Entitlements Configuration

Ensure your `.entitlements` files contain the required specific keys:

- **Main App `Entitlements`**:
  - `com.apple.developer.networking.vpn.api` -> `allow-vpn` (Array)
  - `com.apple.developer.networking.networkextension` -> `packet-tunnel-provider` (Array)
- **Network Extension `Entitlements`**:
  - `com.apple.developer.networking.networkextension` -> `packet-tunnel-provider` (Array)

### 4. Background Modes (Main App)

If your app needs to monitor or maintain the VPN in the background:

- Go to **Signing & Capabilities** -> **Background Modes**.
- Check **Network Authentication**.

## Post-Installation Steps

After successfully adding the package to your project, ensure you follow these steps:

### 1. Packet Tunnel Implementation

You need to provide the implementation for your Network Extension. This repository includes the required template files in the `NetworkExtension` directory. **Copy** the following files into your **Network Extension Target**:

- `PacketTunnelProvider.swift`
- `String+ArrayConversion.swift`
- `TunnelConfiguration+WqQuickConfig.swift`

**Important:**

- Ensure these files are targeted **ONLY** to your Network Extension.
- Update the `applicationGroupIdentifier` in `PacketTunnelProvider.swift` (line 28) to match your shared App Group.

### 2. Basic Setup

In your `AppDelegate` or SwiftUI `App` struct, initialize the logger to see SDK activity:

```swift
import QSleeveSDK

// Initialize Logger
QSleeveLogger.enableLogs(level: .info)
```

### 3. Sample SwiftUI Implementation

For a complete reference on how to use the SDK (Initialize, Connect, Disconnect, Status, etc.), you can refer to the sample code provided in the `QSleeveSDK` documentation or follow the structure in our reference application.

A minimal connection flow looks like this:

```swift
let qsleeve = QSleeveSDK()

// 1. Initialize with your credentials
let authPayload: [String: Any] = ["username": "admin", "password": "password123"]
let initResult = await qsleeve.initialize(
    body: authPayload,
    authUrl: "https://your-auth-server.com",
    providerBundleId: "com.yourcompany.app.extension"
)

if case .success(let data) = initResult, let config = data["config"] as? [String: Any] {
    // 2. Connect using the returned configuration
    let connectResult = await qsleeve.connect(configJson: config)
    if case .success = connectResult {
        print("VPN Connected successfully!")
    }
}
```

## 🚀 Unified SDK Core APIs

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
