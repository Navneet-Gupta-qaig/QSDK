//
//  PacketTunnelProvider.swift
//  Created by Navneet Gupta on 23/09/2025.
//  Copyright (C) 2022-2026 QAIG Pvt. Ltd. All Rights Reserved.

import NetworkExtension
import QSleeveKit
enum PacketTunnelProviderError: String, Error {
    case invalidProtocolConfiguration
    case cantParseQSleeveConfig
}

class PacketTunnelProvider: NEPacketTunnelProvider {

    override init() {
        super.init()
        log("PacketTunnelProvider initialized")
    }

    private lazy var adapter: QSleeveAdapter = {
        return QSleeveAdapter(with: self) { [weak self] logLevel, message in
            self?.log("\(logLevel): \(message)")
        }
    }()

    func log(_ message: String) {
        NSLog("QSleeve Tunnel: %@\n", message)
        
        // Placeholder for user: Replace with actual App Group identifier
        let appGroupID = "bundleIdentifierOfNetworkExtension"
        
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let fileURL = containerURL.appendingPathComponent("vpn_crash_logs.txt")
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let ts = formatter.string(from: Date())
            let line = "[\(ts)] EXT: \(message)\n"
            if let data = line.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                        if #available(iOS 13.4, *) {
                            try? fileHandle.seekToEnd()
                        } else {
                            fileHandle.seekToEndOfFile()
                        }
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: fileURL)
                }
            }
        }
    }

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        log("Starting tunnel")
        
        var parsedQSleeveConfig: String? = nil
        
        // Casing is WgQuickConfig to match MOBILECONFIG.md and SDK's providerConfiguration
        if let options = options {
            if let wgData = options["WgQuickConfig"] as? Data {
                parsedQSleeveConfig = String(data: wgData, encoding: .utf8)
            } else if let wgString = options["WgQuickConfig"] as? String {
                parsedQSleeveConfig = wgString
            }
        }
        
        if parsedQSleeveConfig == nil {
            if let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol,
               let providerConfiguration = protocolConfiguration.providerConfiguration,
               let fallbackConfig = providerConfiguration["WgQuickConfig"] as? String {
                parsedQSleeveConfig = fallbackConfig
            }
        }
        
        guard let qsConfig = parsedQSleeveConfig else {
            log("Invalid provider configuration: missing WgQuickConfig")
            completionHandler(PacketTunnelProviderError.invalidProtocolConfiguration)
            return
        }

        let tunnelConfiguration: TunnelConfiguration
        do {
            tunnelConfiguration = try TunnelConfiguration(fromQSleeveConfig: qsConfig)
        } catch {
            log("QSleeve config not parseable. Error: \(error)")
            completionHandler(PacketTunnelProviderError.cantParseQSleeveConfig)
            return
        }

        adapter.start(tunnelConfiguration: tunnelConfiguration) { [weak self] adapterError in
            guard let self = self else { return }
            if let adapterError = adapterError {
                self.log("QSleeve adapter error: \(adapterError.localizedDescription)")
            } else {
                let interfaceName = self.adapter.interfaceName ?? "unknown"
                self.log("Tunnel interface is \(interfaceName)")
            }
            completionHandler(adapterError)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        log("Stopping tunnel")
        adapter.stop { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.log("Failed to stop QSleeve adapter: \(error.localizedDescription)")
            }
            completionHandler()

            #if os(macOS)
            // HACK: We have to kill the tunnel process ourselves because of a macOS bug
            exit(0)
            #endif
        }
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }

    override func wake() {
        // Add code here to wake up.
    }
}
