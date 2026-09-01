//
//  CalendarService.swift
//  suno
//

import Foundation
import EventKit
import Combine

class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var hasPermission = false
    
    init() {
        checkPermission()
    }
    
    func checkPermission() {
        if #available(macOS 14.0, *) {
            hasPermission = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            hasPermission = EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }
    
    func requestPermission() async throws -> Bool {
        if #available(macOS 14.0, *) {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run { hasPermission = granted }
            return granted
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    Task { @MainActor in self.hasPermission = granted }
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    func fetchTodaysEvents() async throws -> [Meeting] {
        guard hasPermission else { throw CalendarError.permissionDenied }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return await withCheckedContinuation { continuation in
            let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
            let events = eventStore.events(matching: predicate)
            let meetings = events.compactMap { convertToMeeting($0) }
            continuation.resume(returning: meetings)
        }
    }
    
    func fetchEventsAround(_ date: Date, windowMinutes: Int = 30) async throws -> [Meeting] {
        guard hasPermission else { throw CalendarError.permissionDenied }
        
        let start = date.addingTimeInterval(TimeInterval(-windowMinutes * 60))
        let end = date.addingTimeInterval(TimeInterval(windowMinutes * 60))
        
        return await withCheckedContinuation { continuation in
            let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
            let events = eventStore.events(matching: predicate)
            let meetings = events.compactMap { convertToMeeting($0) }
            continuation.resume(returning: meetings)
        }
    }
    
    func fetchEvent(withID eventID: String) -> Meeting? {
        guard hasPermission, let event = eventStore.event(withIdentifier: eventID) else { return nil }
        return convertToMeeting(event)
    }
    
    private func convertToMeeting(_ event: EKEvent) -> Meeting? {
        guard !event.isAllDay else { return nil }
        
        let participants = event.attendees?.compactMap { attendee -> String? in
            // Return name if available
            if let name = attendee.name, !name.isEmpty {
                return name
            }
            // Extract email from URL (URL is not optional)
            let url = attendee.url
            if url.scheme == "mailto" {
                return url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
            }
            return nil
        } ?? []
        
        return Meeting(
            id: event.eventIdentifier,
            title: event.title ?? "Untitled",
            startDate: event.startDate,
            endDate: event.endDate,
            participants: participants,
            location: event.location,
            notes: event.notes,
            source: .calendar
        )
    }
}

enum CalendarError: LocalizedError {
    case permissionDenied
    
    var errorDescription: String? {
        "Calendar permission required"
    }
}
