//
//  ContentView.swift
//  Qsleeve-sdk-test
//
//  Created by Qaig on 12/02/26.
//

import SwiftUI
import NetworkExtension
import QSleeveSDK

struct ContentView: View {
    
    // MARK: - State
    @State private var vpnConfig: [String: Any]?
    @State private var clientPublicKey: String?
    @State private var vpnStatus: NEVPNStatus = .disconnected
    
    @State private var isInitializing = false
    @State private var isConnecting = false
    @State private var isReinitializing = false
    @State private var isPinging = false
    @State private var errorMessage: String?
    
    // Auto-Start Toggle
    @State private var autoStartEnabled: Bool = false
    
    // Diagnostic Logs (visible on-screen)
    @State private var logs: [String] = ["📝 App launched. Ready."]
    
    // MARK: - Config
    let authUrl = "http://115.245.211.54:9001"
    let privateIp = "http://172.16.20.103:8080/tm-api/company/ping"
    let providerBundleIdentifier = "com.QAIG.QTesting.network-testing"
    
    private let qsleeve = QSleeveSDK()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // --- Status Header ---
                VStack(spacing: 6) {
                    Image(systemName: vpnStatus == .connected ? "shield.checkered.fill" : "lock.shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(statusColor)
                    
                    Text(vpnStatus.asText.uppercased())
                        .font(.headline.bold())
                        .foregroundColor(statusColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                
                // --- Main Content ---
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // Info Dashboard
                        infoDashboard
                        
                        // Error Alerts
                        if let error = errorMessage {
                            Text("❌ \(error)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                        
                        // User preferences (Auto Start toggle example)
                        Toggle("On-Demand / Auto Connect", isOn: $autoStartEnabled)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                        
                        // --- Buttons ---
                        VStack(spacing: 10) {
                            
                            // 1. Initialize SDK
                            actionButton(
                                title: "Initialize SDK",
                                icon: "sparkles",
                                color: .blue,
                                isLoading: isInitializing
                            ) { initializeSDK() }
                            .disabled(isInitializing)
                            
                            // 2. Connect VPN
                            actionButton(
                                title: "Connect VPN",
                                icon: "play.fill",
                                color: .green,
                                isLoading: isConnecting
                            ) { connectVPN() }
                            .disabled(vpnConfig == nil || isConnecting || vpnStatus == .connected)
                            
                            // 3. Re-Initialize VPN
                            actionButton(
                                title: "Re-Initialize VPN",
                                icon: "arrow.triangle.2.circlepath",
                                color: .indigo,
                                isLoading: isReinitializing
                            ) { reInitializeSDK() }
                            .disabled(isReinitializing || isInitializing)

                            // 4. Disconnect VPN
                            actionButton(
                                title: "Disconnect VPN",
                                icon: "stop.fill",
                                color: .red
                            ) { disconnectVPN() }
                            .disabled(vpnStatus == .disconnected && vpnStatus != .connecting)
                            
                            HStack(spacing: 10) {
                                // 5. Check Ping
                                actionButton(
                                    title: "Ping Internal API",
                                    icon: "bolt.horizontal.fill",
                                    color: .orange,
                                    isLoading: isPinging
                                ) { checkPing() }
                                .disabled(vpnStatus != .connected)
                                
                                // 6. Get VPN Status
                                actionButton(
                                    title: "Poll Status",
                                    icon: "info.circle.fill",
                                    color: .purple
                                ) { getStatus() }
                            }
                            
                            // Reset UI
                            Button("🧹 Reset UI State") { resetAll() }
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // --- Live Log Viewer ---
                        logViewer
                    }
                    .padding()
                }
            }
            .navigationTitle("QSleeve Reference App")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            log("👀 View appeared. Setting up status observer...")
            // Debug logging can be enabled here if the SDK exposes an API.
            log("🔧 Debug logging hook not configured (no QSleeveLogger in scope)")
            
            qsleeve.onStatusUpdate = { status in
                log("📡 STATUS CHANGE: \(status.asText.uppercased()) (rawValue: \(status.rawValue))")
                DispatchQueue.main.async {
                    self.vpnStatus = status
                }
            }
            log("✅ Status observer bound.")
        }
    }
    
    // MARK: - Views
    
    private var statusColor: Color {
        switch vpnStatus {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnecting: return .yellow
        case .invalid: return .red
        default: return .primary
        }
    }
    
    private var infoDashboard: some View {
        VStack(alignment: .leading, spacing: 6) {
            infoRow("Bundle ID", providerBundleIdentifier)
            infoRow("Auth URL", authUrl)
            infoRow("Ping URL", privateIp)
            infoRow("Config", vpnConfig == nil ? "⚠️ Not loaded" : "✅ \(vpnConfig!.keys.count) keys")
            infoRow("PublicKey", clientPublicKey == nil ? "⚠️ Not received" : "✅ Received")
            infoRow("VPN Status", "\(vpnStatus.asText) (raw: \(vpnStatus.rawValue))")
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var logViewer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("LIVE LOGS")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(logs.count) entries")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Button("Clear") { logs = [] }
                    .font(.caption2)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(logs.enumerated()), id: \.offset) { index, entry in
                            Text(entry)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(logColor(entry))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                    }
                }
                .frame(height: 250)
                .background(Color.black.opacity(0.03))
                .border(Color.gray.opacity(0.2))
                .onChange(of: logs.count) { _ in
                    if let last = logs.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let ts = formatter.string(from: Date())
        let entry = "[\(ts)] \(message)"
        print(entry)
        DispatchQueue.main.async {
            self.logs.append(entry)
        }
    }
    
    // 1. INITIALIZE
    private func initializeSDK() {
        log("🚀 === INITIALIZE BEGIN ===")
        log("   AuthURL: \(authUrl)")
        log("   BundleID: \(providerBundleIdentifier)")
        
        let credentials: [String: Any] = ["username": "admin", "password": "Troop#345", "ldap_sso": 0]
        isInitializing = true
        errorMessage = nil
        log("initialize body:// \(credentials) , \(authUrl), \(providerBundleIdentifier )")
        Task {
            let result = await qsleeve.initialize(
                body: credentials,
                authUrl: authUrl,
                providerBundleId: providerBundleIdentifier
            )
 
            await MainActor.run {
                isInitializing = false
                switch result {
                case .success(let data):
                    log("✅ initialize() returned SUCCESS")
                    if let config = data["config"] as? [String: Any] {
                        self.vpnConfig = config
                        log("📦 Config correctly loaded into memory cache.")
                    } else {
                        log("⚠️ No 'config' key mapped in response.")
                    }
                    
                case .failure(let error):
                    log("❌ initialize() FAILED: \(error.localizedDescription) (code: \((error as NSError).code))")
                    self.errorMessage = "\((error as NSError).code): \(error.localizedDescription)"
                }
            }
        }
    }
    
    // 2. CONNECT
    private func connectVPN() {
        // Appending 'autoStart' from UI Settings seamlessly allows developers to pass extra parameters defined under Auto-Start
        var currentConfig = vpnConfig
        
        guard currentConfig != nil else {
            log("❌ Cannot connect: no config loaded. Initialize first.")
            return
        }
        
        // Set On-Demand connection dynamically.
        currentConfig!["autoStart"] = autoStartEnabled
        
        log("🚀 === CONNECT BEGIN (AutoStart: \(autoStartEnabled)) ===")
        isConnecting = true
        errorMessage = nil
        
        Task {
            let result = await qsleeve.connect(configJson: currentConfig!)
            
            await MainActor.run {
                isConnecting = false
                switch result {
                case .success(let response):
                    log("✅ connect() returned SUCCESS")
                    log("   status: \(response["status"] ?? "?")")
                    
                case .failure(let error):
                    log("❌ connect() FAILED: \(error.localizedDescription) (code: \((error as NSError).code))")
                    self.errorMessage = "\((error as NSError).code): \(error.localizedDescription)"
                }
            }
        }
    }

    // 3. RE-INITIALIZE
    private func reInitializeSDK() {
        log("🔄 === RE-INITIALIZE BEGIN ===")
        isReinitializing = true
        errorMessage = nil
        
        Task {
            log("📡 Calling qsleeve.reInitialize(configJson:)...")
            // Passing `vpnConfig` or `nil` prompts SDK to use previous initialization context logically
            let result = await qsleeve.reInitialize(configJson: vpnConfig)
            
            await MainActor.run {
                isReinitializing = false
                switch result {
                case .success(let data):
                    let code = data["code"] as? String ?? ""
                    log("✅ reInitialize() completed: Code = \(code)")
                    
                    if code == "REINIT_1006" {
                        log("⚠️ Peer Not Found on Server. Client needs to fully 'Initialize' again.")
                        self.errorMessage = "Peer Not Found. Please completely Re-Register."
                    } else if let config = data["config"] as? [String: Any] {
                        self.vpnConfig = config
                        log("📦 Refreshed configuration successfully mapped! Ready for Connect.")
                    }
                    
                case .failure(let error):
                    log("❌ reInitialize() FAILED: \(error.localizedDescription) (code: \((error as NSError).code))")
                    self.errorMessage = "\((error as NSError).code): \(error.localizedDescription)"
                }
            }
        }
    }
    
    // 4. DISCONNECT
    private func disconnectVPN() {
        log("🛑 === DISCONNECT ===")
        Task {
            let result = await qsleeve.disconnect()
            switch result {
            case .success(let data):
                log("✅ Disconnected. \(data["status"] ?? "")")
            case .failure(let err):
                log("❌ Disconnect error: \(err.localizedDescription) (code: \((err as NSError).code))")
            }
        }
    }
    
    // 5. PING
    private func checkPing() {
        log("🏓 === PING TEST ===")
        log("   Target URL: \(privateIp)")
        isPinging = true
        
        Task {
            do {
                guard let url = URL(string: privateIp) else { return }
                var request = URLRequest(url: url)
                request.timeoutInterval = 10.0
                let startTime = Date()
                let (_, response) = try await URLSession.shared.data(for: request)
                let elapsed = Date().timeIntervalSince(startTime) * 1000
                if let http = response as? HTTPURLResponse {
                    log("🏓 Ping response: HTTP \(http.statusCode) in \(Int(elapsed))ms")
                    if (200...399).contains(http.statusCode) {
                        log("✅ Ping SUCCESS - Internal Private network routed successfully!")
                    }
                }
            } catch {
                log("❌ Ping FAILED: \(error.localizedDescription)")
            }
            await MainActor.run { isPinging = false }
        }
    }
    
    // 6. GET STATUS
    private func getStatus() {
        log("📊 === SDK STATUS POLL ===")
        
        Task {
            let result = await qsleeve.getStatus()
            switch result {
            case .success(let data):
                log("   Tunnel Up & Reachable: \(data["status"] ?? false)")
                log("   Result Code: \(data["code"] ?? "")")
            case .failure(let err):
                log("❌ getStatus() error: \(err.localizedDescription) (code: \((err as NSError).code))")
            }
        }
    }
    
    // RESET
    private func resetAll() {
        log("🧹 Cleaning Interface State...")
        vpnConfig = nil
        clientPublicKey = nil
        errorMessage = nil
        isInitializing = false
        isConnecting = false
        isPinging = false
    }
    
    // MARK: - UI Configuration Variables
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundColor(.secondary).font(.caption2).frame(width: 70, alignment: .leading)
            Text(value).font(.system(size: 10, weight: .medium, design: .monospaced)).lineLimit(2)
        }
    }
    
    private func logColor(_ entry: String) -> Color {
        if entry.contains("❌") || entry.contains("FAILED") { return .red }
        if entry.contains("✅") || entry.contains("SUCCESS") { return .green }
        if entry.contains("⚠️") { return .orange }
        if entry.contains("🔄") || entry.contains("📡") { return .blue }
        return .primary
    }
    
    private func actionButton(title: String, icon: String, color: Color, isLoading: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if isLoading { ProgressView().padding(.trailing, 4) } else { Image(systemName: icon) }
                Text(title).bold()
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(color.opacity(isLoading ? 0.5 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

// MARK: - App Status Standard Format Extension
extension NEVPNStatus {
    var asText: String {
        switch self {
        case .invalid: return "invalid"
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .reasserting: return "reasserting"
        case .disconnecting: return "disconnecting"
        @unknown default: return "unknown"
        }
    }
}

