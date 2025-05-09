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
        print(text.uppercased()) // For debugging
        let finalAnswerAction = "FINAL ANSWER:" // Assuming this is the marker
        if let finalAnswerRange = text.uppercased().range(of: finalAnswerAction) {
            let answer = text[finalAnswerRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            return Parsed.finish(AgentFinish(final: answer))
        }
        
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
                // The 'log' should be the original text that led to this action,
                // or at least the relevant part (e.g., Thought + Action + Action Input).
                // For now, passing the whole 'text' as log is consistent with previous behavior.
                return Parsed.action(AgentAction(action: action, input: input, log: text))
            } else {
                // This case handles if parsing the action/input capture groups fails or results in empty action.
                print("MRKLOutputParser: Regex matched but failed to extract valid action/input.")
                return Parsed.error
            }
        } else {
            // If no "Final Answer" and no "Action: Action Input:" pattern is found.
            // This could be due to the LLM not adhering to the format.
            print("MRKLOutputParser: No 'Final Answer' or 'Action: Action Input:' pattern found.")
            return Parsed.error
        }
    }
}
