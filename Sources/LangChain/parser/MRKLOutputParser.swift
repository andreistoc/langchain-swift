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
        print("MRKLOutputParser: Parsing text: \(text.prefix(200))...") // For debugging
        
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
                print("MRKLOutputParser: Found final answer using pattern '\(variation)'")
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
                print("MRKLOutputParser: Found action pattern - Action: '\(action)', Input: '\(input.prefix(50))...'")
                return Parsed.action(AgentAction(action: action, input: input, log: text))
            } else {
                print("MRKLOutputParser: Regex matched but failed to extract valid action/input.")
                return Parsed.error
            }
        }
        
        // Final fallback: if the text seems like a direct answer (no action pattern and no final answer marker)
        // but contains substantial content, treat it as a final answer
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.count > 10 && !trimmedText.lowercased().contains("action:") {
            // Check if it looks like a thoughtful response rather than an error
            let thoughtPatterns = ["based on", "according to", "the data shows", "i found", "looking at", "analysis", "result"]
            let lowerText = trimmedText.lowercased()
            
            for pattern in thoughtPatterns {
                if lowerText.contains(pattern) {
                    print("MRKLOutputParser: Using fallback - treating as final answer due to content pattern '\(pattern)'")
                    return Parsed.finish(AgentFinish(final: trimmedText))
                }
            }
        }
        
        // If no "Final Answer" and no "Action: Action Input:" pattern is found.
        print("MRKLOutputParser: No recognizable pattern found. Text length: \(text.count), starts with: '\(text.prefix(100))'")
        return Parsed.error
    }
}
