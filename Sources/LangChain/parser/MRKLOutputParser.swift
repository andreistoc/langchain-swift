//
//  File.swift
//  
//
//  Created by 顾艳华 on 2023/6/21.
//

import Foundation

public struct MRKLOutputParser: BaseOutputParser {
    public init() {}
    public func parse(text: String) -> Parsed {
        print("🔍 MRKLOutputParser: Parsing text (length: \(text.count))")
        print("🔍 MRKLOutputParser: First 300 chars: '\(String(text.prefix(300)))'")
        if text.count > 300 {
            print("🔍 MRKLOutputParser: Last 200 chars: '\(String(text.suffix(200)))'")
        }
        
        // Try multiple variations of "Final Answer" to be more flexible
        let finalAnswerVariations = [
            "FINAL ANSWER:",
            "Final Answer:",
            "final answer:",
            "FINAL_ANSWER:",
            "Final_Answer:",
            "final_answer:"
        ]
        
        let textUpper = text.uppercased()
        
        // Check for any variation of final answer
        for variation in finalAnswerVariations {
            let searchPattern = variation.uppercased()
            if let finalAnswerRange = textUpper.range(of: searchPattern) {
                let answer = text[finalAnswerRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                print("✅ MRKLOutputParser: Found final answer using pattern '\(variation)'")
                return Parsed.finish(AgentFinish(final: answer))
            }
        }
        
        // If no final answer found, look for action pattern
        let pattern = "Action\\s*:[\\s]*(.*?)\\s*Action\\s*Input\\s*:[\\s]*(.*)"
        // Adding NSRegularExpression.Options.dotMatchesLineSeparators to allow . to match newlines for the input part
        // Adding NSRegularExpression.Options.caseInsensitive for "Action" and "Action Input"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        
        if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            var actionString: String?
            if let actionRange = Range(match.range(at: 1), in: text) {
                actionString = String(text[actionRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            var inputString: String?
            if let inputRange = Range(match.range(at: 2), in: text) {
                inputString = String(text[inputRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if let action = actionString, let input = inputString, !action.isEmpty {
                print("✅ MRKLOutputParser: Found action pattern - Action: '\(action)', Input: '\(String(input.prefix(50)))...'")
                return Parsed.action(AgentAction(action: action, input: input, log: text))
            } else {
                print("❌ MRKLOutputParser: Regex matched but failed to extract valid action/input.")
                return Parsed.error
            }
        }
        
        // Enhanced fallback logic: if the text seems like a direct answer (no action pattern and no final answer marker)
        // but contains substantial content, treat it as a final answer
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 MRKLOutputParser: Checking fallback patterns for text length: \(trimmedText.count)")
        
        if trimmedText.count > 10 && !trimmedText.lowercased().contains("action:") {
            let lowerText = trimmedText.lowercased()
            
            // MOST AGGRESSIVE: Check for the exact Smart Search response pattern we just saw
            if trimmedText.hasPrefix("## 📅 Activity Timeline") || 
               trimmedText.hasPrefix("## 📅 ACTIVITY TIMELINE") {
                print("✅ MRKLOutputParser: EXACT SMART SEARCH MATCH - treating as final answer due to activity timeline header")
                return Parsed.finish(AgentFinish(final: trimmedText))
            }
            
            // VERY AGGRESSIVE: Check for ANY ## markdown header with emoji
            if trimmedText.hasPrefix("## 📅") || trimmedText.hasPrefix("## 🌅") || 
               trimmedText.hasPrefix("## 🌞") || trimmedText.hasPrefix("## 🌆") ||
               trimmedText.hasPrefix("## 📊") || trimmedText.hasPrefix("## 🔍") {
                print("✅ MRKLOutputParser: EMOJI HEADER MATCH - treating as final answer due to emoji markdown header")
                return Parsed.finish(AgentFinish(final: trimmedText))
            }
            
            // FIRST: Check for direct ## header pattern (most specific for Smart Search responses)
            if trimmedText.hasPrefix("##") || trimmedText.hasPrefix("# ") {
                print("✅ MRKLOutputParser: DIRECT HEADER MATCH - treating as final answer due to ## header prefix")
                return Parsed.finish(AgentFinish(final: trimmedText))
            }
            
            // Enhanced markdown/structured formatting patterns (like Smart Search responses)
            let markdownPatterns = [
                "## 📅", "###", "####",  // Markdown headers with emojis
                "📅", "🌅", "🌞", "🌆", "📊", "🔍", "🤔", "▶️", "💬", "🚀", "🧠",  // Emojis
                "activity timeline", "summary", "data sources used", "main projects",
                "morning", "afternoon", "evening", "timeline"
            ]
            
            // Digital twin specific response patterns
            let structuredPatterns = [
                "you worked on", "you were", "you accessed", "you focused on", 
                "key documents", "websites visited", "applications used",
                "main projects", "main themes", "total activities"
            ]
            
            // General thoughtful content patterns
            let thoughtPatterns = [
                "based on", "according to", "the data shows", "i found", "looking at", 
                "analysis", "result", "during", "focused on", "primarily", "indicating"
            ]
            
            // Check for markdown/structured formatting patterns first (most specific)
            for pattern in markdownPatterns {
                if lowerText.contains(pattern) {
                    print("✅ MRKLOutputParser: MARKDOWN MATCH - treating as final answer due to markdown pattern '\(pattern)'")
                    return Parsed.finish(AgentFinish(final: trimmedText))
                }
            }
            
            // Check for structured response patterns (digital twin responses)
            for pattern in structuredPatterns {
                if lowerText.contains(pattern) {
                    print("✅ MRKLOutputParser: STRUCTURED MATCH - treating as final answer due to structured pattern '\(pattern)'")
                    return Parsed.finish(AgentFinish(final: trimmedText))
                }
            }
            
            // Check for thoughtful content patterns
            for pattern in thoughtPatterns {
                if lowerText.contains(pattern) {
                    print("✅ MRKLOutputParser: CONTENT MATCH - treating as final answer due to content pattern '\(pattern)'")
                    return Parsed.finish(AgentFinish(final: trimmedText))
                }
            }
            
            // If the text is substantial and well-formed (contains multiple sentences), treat it as a final answer
            if trimmedText.count > 100 {
                let sentences = trimmedText.components(separatedBy: ". ")
                if sentences.count >= 3 {
                    print("✅ MRKLOutputParser: SUBSTANTIAL MATCH - treating as final answer due to substantial multi-sentence content (\(sentences.count) sentences)")
                    return Parsed.finish(AgentFinish(final: trimmedText))
                }
            }
            
            // Additional check for responses that start with common response patterns
            let responseStarters = [
                "##", "###", "based on your", "looking at your", "here is", "here are",
                "the following", "your activity", "you have", "i can see"
            ]
            
            for starter in responseStarters {
                if lowerText.hasPrefix(starter) {
                    print("✅ MRKLOutputParser: STARTER MATCH - treating as final answer due to response starter '\(starter)'")
                    return Parsed.finish(AgentFinish(final: trimmedText))
                }
            }
            
            // SPECIAL: Look for the exact pattern we see in logs - if it contains comprehensive activity data
            if lowerText.contains("timeline") && lowerText.contains("summary") && trimmedText.count > 200 {
                print("✅ MRKLOutputParser: TIMELINE+SUMMARY MATCH - treating as final answer due to timeline + summary pattern")
                return Parsed.finish(AgentFinish(final: trimmedText))
            }
            
            // ULTRA FALLBACK: If it contains any detailed structured information and is substantial
            if (lowerText.contains("you ") || lowerText.contains("your ")) && 
               (lowerText.contains("activity") || lowerText.contains("work") || lowerText.contains("project")) &&
               trimmedText.count > 200 {
                print("✅ MRKLOutputParser: ULTRA FALLBACK - treating as final answer due to substantial user-focused content")
                return Parsed.finish(AgentFinish(final: trimmedText))
            }
        }
        
        // If no "Final Answer" and no "Action: Action Input:" pattern is found.
        print("❌ MRKLOutputParser: NO MATCH FOUND. Detailed analysis:")
        print("  - Length: \(text.count)")
        print("  - Contains 'action:': \(text.lowercased().contains("action:"))")
        print("  - Starts with ##: \(text.hasPrefix("##"))")
        print("  - Contains timeline: \(text.lowercased().contains("timeline"))")
        print("  - Contains summary: \(text.lowercased().contains("summary"))")
        print("  - Contains emoji 📅: \(text.contains("📅"))")
        print("  - First 200 chars: '\(String(text.prefix(200)))'")
        if text.count > 200 {
            print("  - Last 200 chars: '\(String(text.suffix(200)))'")
        }
        return Parsed.error
    }
}
