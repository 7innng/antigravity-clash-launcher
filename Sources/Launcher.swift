import AppKit
import Darwin

final class Launcher: NSObject, NSApplicationDelegate {
    private let targetBundleID = "com.google.antigravity"
    private let defaultPort: UInt16 = 7897
    private let portPreference = "ProxyPort"
    private let proxyHost = "127.0.0.1"

    func applicationDidFinishLaunching(_ notification: Notification) {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: targetBundleID).first
        let editing = NSEvent.modifierFlags.contains(.option) || CommandLine.arguments.contains("--configure")

        if let running, !editing {
            running.activate(options: [])
            NSApp.terminate(nil)
            return
        }

        guard let appURL = locateAntigravity() else {
            finishWithAlert(text("install.title"), text("install.detail"))
            return
        }

        let savedPort = UInt16(exactly: UserDefaults.standard.integer(forKey: portPreference)) ?? 0
        var port = savedPort == 0 ? defaultPort : savedPort
        let listening = portIsListening(port)

        if editing || !listening {
            let prompt = listening ? text("port.prompt") : formatted("port.unreachable", String(port))
            guard let confirmedPort = chooseProxyPort(port, prompt: prompt) else {
                NSApp.terminate(nil)
                return
            }
            port = confirmedPort
            UserDefaults.standard.set(Int(port), forKey: portPreference)

            if running != nil {
                finishWithAlert(text("port.saved.title"), text("port.saved.detail"))
                return
            }
        }

        openAntigravity(at: appURL, port: port)
    }

    private func locateAntigravity() -> URL? {
        let systemApplications = URL(fileURLWithPath: "/Applications", isDirectory: true)
        let userApplications = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)

        return [systemApplications, userApplications]
            .map { $0.appendingPathComponent("Antigravity.app", isDirectory: true) }
            .first { Bundle(url: $0)?.bundleIdentifier == targetBundleID }
    }

    private func openAntigravity(at url: URL, port: UInt16) {
        let proxy = "http://\(proxyHost):\(port)"
        let loopback = "localhost,127.0.0.1,::1"
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.environment = [
            "HTTP_PROXY": proxy, "HTTPS_PROXY": proxy,
            "http_proxy": proxy, "https_proxy": proxy,
            "NO_PROXY": loopback, "no_proxy": loopback,
        ]
        configuration.arguments = ["--proxy-server=\(proxy)"]
        configuration.allowsRunningApplicationSubstitution = false

        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
            DispatchQueue.main.async {
                if let error {
                    self.finishWithAlert(self.text("launch.failed"), error.localizedDescription)
                } else {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    private func chooseProxyPort(_ current: UInt16, prompt: String) -> UInt16? {
        NSApp.activate(ignoringOtherApps: true)

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.stringValue = String(current)
        field.setAccessibilityLabel(text("port.field"))

        let alert = NSAlert()
        alert.messageText = text("port.title")
        alert.informativeText = prompt
        alert.accessoryView = field
        alert.addButton(withTitle: text("port.save"))
        alert.addButton(withTitle: text("cancel"))
        alert.window.initialFirstResponder = field

        while alert.runModal() == .alertFirstButtonReturn {
            let input = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let port = UInt16(input), port > 0 else {
                alert.informativeText = text("port.invalid")
                continue
            }
            guard portIsListening(port) else {
                alert.informativeText = formatted("port.unreachable", String(port))
                continue
            }
            return port
        }
        return nil
    }

    private func portIsListening(_ port: UInt16) -> Bool {
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            return false
        }
        defer { close(socketFD) }

        let length = socklen_t(MemoryLayout<sockaddr_in>.size)
        var address = sockaddr_in()
        address.sin_len = UInt8(length)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr.s_addr = inet_addr(proxyHost)

        return withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { address in
                connect(socketFD, address, length) == 0
            }
        }
    }

    private func finishWithAlert(_ title: String, _ detail: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: text("ok"))
        alert.runModal()
        NSApp.terminate(nil)
    }

    private func text(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }

    private func formatted(_ key: String, _ value: String) -> String {
        String(format: text(key), value)
    }
}

let application = NSApplication.shared
let launcher = Launcher()
application.delegate = launcher
application.run()
