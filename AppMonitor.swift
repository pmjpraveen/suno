//
//  AppMonitor.swift
//  suno
//

import Foundation
import AppKit
import Combine

class AppMonitor: ObservableObject {
    @Published var runningMeetingApps: Set<MeetingApp> = []
    @Published var hasAccessibilityPermission: Bool = false
    
    private var timer: Timer?
    private let workspace = NSWorkspace.shared
    
    init() {
        checkAccessibilityPermission()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Permission
    
    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options)
        hasAccessibilityPermission = trusted
        return trusted
    }
    
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkRunningApps()
        }
        checkRunningApps()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkRunningApps() {
        let runningApps = workspace.runningApplications
        var detected: Set<MeetingApp> = []
        
        for app in runningApps {
            if let bundleID = app.bundleIdentifier,
               let meetingApp = MeetingApp.from(bundleID: bundleID) {
                detected.insert(meetingApp)
            }
        }
        
        if detected != runningMeetingApps {
            runningMeetingApps = detected
        }
    }
    
    // MARK: - Window Title Extraction
    
    func getWindowTitle(for app: MeetingApp) -> String? {
        guard hasAccessibilityPermission else { return nil }
        
        for bundleID in app.bundleIdentifiers {
            if let runningApp = workspace.runningApplications.first(where: { $0.bundleIdentifier == bundleID }),
               let pid = runningApp.processIdentifier as pid_t? {
                let appElement = AXUIElementCreateApplication(pid)
                var windows: CFTypeRef?
                
                if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows) == .success,
                   let windowList = windows as? [AXUIElement],
                   let firstWindow = windowList.first {
                    var title: CFTypeRef?
                    if AXUIElementCopyAttributeValue(firstWindow, kAXTitleAttribute as CFString, &title) == .success,
                       let titleString = title as? String {
                        return titleString
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Meeting App Enum

enum MeetingApp: String, CaseIterable, Hashable {
    case teams = "Microsoft Teams"
    case zoom = "Zoom"
    case meet = "Google Meet"
    case webex = "Webex"
    
    var bundleIdentifiers: [String] {
        switch self {
        case .teams:
            return ["com.microsoft.teams", "com.microsoft.teams2"]
        case .zoom:
            return ["us.zoom.xos"]
        case .meet:
            return []
        case .webex:
            return ["com.cisco.webexmeetingsapp", "Cisco-Systems.Spark"]
        }
    }
    
    static func from(bundleID: String) -> MeetingApp? {
        for app in MeetingApp.allCases {
            if app.bundleIdentifiers.contains(bundleID) {
                return app
            }
        }
        return nil
    }
}
