//
//  PacketTunnelProvider.swift
//  Created by Navneet Gupta on 23/09/2025.
//  Copyright (C) 2022-2026 QAIG Pvt. Ltd. All Rights Reserved.

import NetworkExtension
import QSleeveKit
enum PacketTunnelProviderError: String, Error {
    case invalidProtocolConfiguration
    case cantParseWgQuickConfig
}

class PacketTunnelProvider: NEPacketTunnelProvider {

    override init() {
        super.init()
        log("PacketTunnelProvider initialized")
    }

    private lazy var adapter: QSleeveAdapter = {
        return QSleeveAdapter(with: self) { [weak self] _, message in
            self?.log(message)
        }
    }()

    func log(_ message: String) {
        NSLog("WireGuard Tunnel: %@\n", message)
Add Bundle Idenstifer of Network can find in the general tab of the target
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "bundleIdentifierOfNetworkExtension") {
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
        
        var parsedWgQuickConfig: String? = nil
        
        if let options = options {
            if let wgData = options["WgQuickConfig"] as? Data {
                parsedWgQuickConfig = String(data: wgData, encoding: .utf8)
            } else if let wgString = options["WgQuickConfig"] as? String {
                parsedWgQuickConfig = wgString
            }
        }
        
        if parsedWgQuickConfig == nil {
            if let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol,
               let providerConfiguration = protocolConfiguration.providerConfiguration,
               let fallbackConfig = providerConfiguration["WgQuickConfig"] as? String {
                parsedWgQuickConfig = fallbackConfig
            }
        }
        
        guard let WgQuickConfig = parsedWgQuickConfig else {
            log("Invalid provider configuration: missing WgQuickConfig")
            completionHandler(PacketTunnelProviderError.invalidProtocolConfiguration)
            return
        }

        let tunnelConfiguration: TunnelConfiguration
        do {
            tunnelConfiguration = try TunnelConfiguration(fromWgQuickConfig: WgQuickConfig)
        } catch {
            log("wg-quick config not parseable. Error: \(error)")
            completionHandler(PacketTunnelProviderError.cantParseWgQuickConfig)
            return
        }

        adapter.start(tunnelConfiguration: tunnelConfiguration) { [weak self] adapterError in
            guard let self = self else { return }
            if let adapterError = adapterError {
                self.log("WireGuard adapter error: \(adapterError.localizedDescription)")
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
                self.log("Failed to stop WireGuard adapter: \(error.localizedDescription)")
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
