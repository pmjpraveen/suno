//
//  MeetingDetector.swift
//  suno
//

import Foundation
import Combine

class MeetingDetector: ObservableObject {
    @Published var detectedMeeting: Meeting?
    @Published var shouldPromptRecording: Bool = false
    
    private let appMonitor: AppMonitor
    private let calendarService: CalendarService
    private var cancellables = Set<AnyCancellable>()
    
    private var declinedMeetings: Set<String> = []
    
    init(appMonitor: AppMonitor, calendarService: CalendarService) {
        print("🎯 MeetingDetector INIT started")
        self.appMonitor = appMonitor
        self.calendarService = calendarService
        setupMonitoring()
        print("✅ MeetingDetector monitoring setup complete")
    }
    
    private func setupMonitoring() {
        appMonitor.$runningMeetingApps
            .removeDuplicates()
            .sink { [weak self] apps in
                print("📱 Meeting apps changed: \(apps)")
                self?.handleMeetingAppsChanged(apps)
            }
            .store(in: &cancellables)
    }
    
    private func handleMeetingAppsChanged(_ apps: Set<MeetingApp>) {
        guard !apps.isEmpty else {
            print("❌ No meeting apps detected")
            detectedMeeting = nil
            return
        }
        
        print("✅ Meeting apps detected: \(apps.map { $0.rawValue })")
        
        Task {
            await detectMeetingDetails(from: apps)
        }
    }
    
    private func detectMeetingDetails(from apps: Set<MeetingApp>) async {
        guard let app = apps.first else { return }
        
        print("🔍 Extracting details for: \(app.rawValue)")
        
        let windowTitle = appMonitor.getWindowTitle(for: app)
        print("📝 Window title: \(windowTitle ?? "none")")
        
        let calendarMeetings = try? await calendarService.fetchEventsAround(Date(), windowMinutes: 15)
        let matchedCalendarMeeting = calendarMeetings?.first { $0.isHappening }
        
        if let matched = matchedCalendarMeeting {
            print("📅 Matched with calendar event: \(matched.title)")
        }
        
        let meeting = createMeeting(
            from: app,
            windowTitle: windowTitle,
            calendarMeeting: matchedCalendarMeeting
        )
        
        print("🎉 Created meeting: \(meeting.title)")
        
        await MainActor.run {
            detectedMeeting = meeting
            
            if !declinedMeetings.contains(meeting.id) {
                print("🚀 SHOWING PROMPT for meeting: \(meeting.title)")
                shouldPromptRecording = true
            } else {
                print("⏭️ Meeting was previously declined, not prompting")
            }
        }
    }
    
    private func createMeeting(
        from app: MeetingApp,
        windowTitle: String?,
        calendarMeeting: Meeting?
    ) -> Meeting {
        if let calendarMeeting = calendarMeeting {
            return Meeting(
                id: calendarMeeting.id,
                title: calendarMeeting.title,
                startDate: calendarMeeting.startDate,
                endDate: calendarMeeting.endDate,
                participants: calendarMeeting.participants,
                location: calendarMeeting.location,
                notes: calendarMeeting.notes,
                source: sourceFrom(app: app)
            )
        }
        
        let title = extractMeetingTitle(from: windowTitle, app: app)
        let now = Date()
        
        return Meeting(
            id: UUID().uuidString,
            title: title,
            startDate: now,
            endDate: now.addingTimeInterval(3600),
            participants: [],
            location: nil,
            notes: "Detected from \(app.rawValue)",
            source: sourceFrom(app: app)
        )
    }
    
    private func extractMeetingTitle(from windowTitle: String?, app: MeetingApp) -> String {
        guard let windowTitle = windowTitle else {
            return "\(app.rawValue) Meeting"
        }
        
        switch app {
        case .teams:
            if let meetingName = windowTitle.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces) {
                return meetingName
            }
        case .zoom:
            if let meetingName = windowTitle.components(separatedBy: "-").last?.trimmingCharacters(in: .whitespaces) {
                return meetingName
            }
        case .meet:
            if let meetingName = windowTitle.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespaces) {
                return meetingName
            }
        case .webex:
            return windowTitle
        }
        
        return windowTitle
    }
    
    private func sourceFrom(app: MeetingApp) -> MeetingSource {
        switch app {
        case .teams: return .teams
        case .zoom: return .zoom
        case .meet: return .meet
        case .webex: return .webex
        }
    }
    
    // MARK: - User Actions
    
    func declineMeeting(_ meeting: Meeting) {
        print("❌ User declined meeting: \(meeting.title)")
        declinedMeetings.insert(meeting.id)
        shouldPromptRecording = false
    }
    
    func acceptMeeting() {
        print("✅ User accepted meeting prompt")
        shouldPromptRecording = false
    }
}
