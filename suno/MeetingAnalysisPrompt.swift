//
//  MeetingAnalysisPrompt.swift
//  suno
//

import Foundation

struct MeetingAnalysisPrompt {
    
    // MARK: - System Prompt
    
    static let systemPrompt = """
You are an expert meeting analyst. Your role is to analyze meeting transcripts and extract structured insights.

## Your Responsibilities:

1. **Summarize Accurately**: Create a concise overview that captures the meeting's essence
2. **Preserve Context**: Maintain important details and nuances
3. **Distinguish Discussion from Decisions**: Clearly separate what was discussed from what was decided
4. **Extract Explicit Action Items**: Only include action items that were explicitly stated
5. **Identify Assignees**: Only when clearly stated in the transcript (never fabricate)
6. **Identify Due Dates**: Only when explicitly mentioned (never assume)
7. **Never Fabricate**: If information is unclear or missing, leave it empty
8. **Avoid Generic Filler**: Be specific and useful
9. **Concise Language**: Use clear, professional language
10. **Preserve Uncertainty**: When the transcript is ambiguous, reflect that in your analysis

## Rules:

- DO NOT invent assignees or due dates
- DO NOT add generic statements like "team agreed to follow up"
- DO extract specific, actionable items
- DO preserve timestamps when available
- DO distinguish between "discussed" and "decided"
- DO note when information is unavailable rather than guessing

## Output Format:

You must respond with valid JSON matching this exact schema:

{
  "overview": "Brief 2-3 sentence summary of the meeting",
  "keyPoints": [
    "First key discussion point",
    "Second key discussion point"
  ],
  "decisions": [
    {
      "text": "Specific decision that was made",
      "timestamp": 123.45  // Optional: seconds from start
    }
  ],
  "actionItems": [
    {
      "task": "Specific action to be taken",
      "assignee": "Person's name",  // Optional: only if explicitly stated
      "dueDate": "2024-03-15",  // Optional: only if explicitly stated, ISO8601
      "timestamp": 456.78  // Optional: seconds from start
    }
  ],
  "mom": "Formal minutes of meeting document"
}

## Minutes of Meeting (MOM) Format:

The MOM should be a well-structured document with these sections (omit sections if information is unavailable):

**Meeting: [Title]**
**Date: [Date]**
**Participants: [Names]**

**Purpose/Agenda:**
[Brief description of meeting purpose]

**Discussion Summary:**
[Paragraph summarizing key discussions]

**Key Decisions:**
1. [Decision 1]
2. [Decision 2]

**Action Items:**
1. [Task] - [Assignee if known] - [Due date if known]
2. [Task] - [Assignee if known] - [Due date if known]

**Open Questions/Follow-ups:**
[Any unresolved items or topics for future discussion]

If a section has no information, mark it as "Not specified" or omit it entirely.
"""
    
    // MARK: - User Prompt Generator
    
    static func createUserPrompt(
        transcript: Transcript,
        meeting: Meeting?
    ) -> String {
        var prompt = "Please analyze this meeting transcript:\n\n"
        
        // Add meeting context if available
        if let meeting = meeting, !meeting.isUnscheduled {
            prompt += "## Meeting Context:\n"
            prompt += "- Title: \(meeting.title)\n"
            prompt += "- Date: \(formatDate(meeting.startDate))\n"
            
            if !meeting.participants.isEmpty {
                prompt += "- Participants: \(meeting.participants.joined(separator: ", "))\n"
            }
            
            if let location = meeting.location {
                prompt += "- Location: \(location)\n"
            }
            
            prompt += "\n"
        }
        
        // Add transcript
        prompt += "## Transcript:\n\n"
        
        if !transcript.segments.isEmpty {
            // Use segmented transcript with timestamps
            for segment in transcript.segments {
                prompt += "[\(segment.formattedTime)] \(segment.text)\n"
            }
        } else {
            // Fall back to full text
            prompt += transcript.fullText
        }
        
        prompt += "\n\n"
        prompt += "Please provide your analysis as a JSON object following the specified schema."
        
        return prompt
    }
    
    // MARK: - JSON Schema
    
    static let jsonSchema = """
{
  "type": "object",
  "required": ["overview", "keyPoints", "decisions", "actionItems", "mom"],
  "properties": {
    "overview": {
      "type": "string",
      "description": "2-3 sentence summary of the meeting"
    },
    "keyPoints": {
      "type": "array",
      "description": "Main discussion points",
      "items": {
        "type": "string"
      }
    },
    "decisions": {
      "type": "array",
      "description": "Decisions that were made",
      "items": {
        "type": "object",
        "required": ["text"],
        "properties": {
          "text": {
            "type": "string"
          },
          "timestamp": {
            "type": "number",
            "description": "Timestamp in seconds from recording start"
          }
        }
      }
    },
    "actionItems": {
      "type": "array",
      "description": "Action items extracted from the meeting",
      "items": {
        "type": "object",
        "required": ["task"],
        "properties": {
          "task": {
            "type": "string"
          },
          "assignee": {
            "type": "string",
            "description": "Only if explicitly mentioned"
          },
          "dueDate": {
            "type": "string",
            "description": "ISO8601 date, only if explicitly mentioned"
          },
          "timestamp": {
            "type": "number",
            "description": "Timestamp in seconds from recording start"
          }
        }
      }
    },
    "mom": {
      "type": "string",
      "description": "Formal minutes of meeting document"
    }
  }
}
"""
    
    // MARK: - Helpers
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
