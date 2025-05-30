import Foundation
import GoogleGenerativeAI
// Assuming 'LLM', 'BaseCallbackHandler', 'BaseCache', 'LLMResult' are defined in your LangChain setup.
// If these are part of a module named "LangChain", the import might look like:
// import LangChain

// Define a simple error enum for clarity, if not already defined elsewhere in your project
enum GeminiError: Error {
    case responseNoText
    case responseNoCandidates
    // Add other specific errors as needed
}

public class Gemini: LLM {
    let modelName: String
    private let apiKey: String
    private let temperature: Float? // Store temperature
    private let topP: Float?
    private let topK: Int?
    private let maxOutputTokens: Int?
    private let stopSequences: [String]?


    public init(
        apiKey: String,
        modelName: String = "gemini-pro",
        temperature: Float? = nil,
        topP: Float? = nil,
        topK: Int? = nil,
        maxOutputTokens: Int? = nil,
        stopSequences: [String]? = nil,
        callbacks: [BaseCallbackHandler] = [],
        cache: BaseCache? = nil
    ) {
        self.apiKey = apiKey
        self.modelName = modelName
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.maxOutputTokens = maxOutputTokens
        self.stopSequences = stopSequences
        super.init(callbacks: callbacks, cache: cache)
    }

    override func _send(text: String, stops: [String]) async throws -> LLMResult {
        // Prepare GenerationConfig
        var generationConfig = GenerationConfig()

        if let temp = self.temperature {
            generationConfig.temperature = temp
        }
        if let topP = self.topP {
            generationConfig.topP = topP
        }
        if let topK = self.topK {
            generationConfig.topK = topK
        }
        if let maxTokens = self.maxOutputTokens {
            generationConfig.maxOutputTokens = maxTokens
        }
        
        // Combine stop sequences from init and _send parameters
        var effectiveStopSequences = self.stopSequences ?? []
        if !stops.isEmpty {
            effectiveStopSequences.append(contentsOf: stops)
        }
        if !effectiveStopSequences.isEmpty {
            generationConfig.stopSequences = effectiveStopSequences
        }


        // Initialize the Google AI model
        let model = GenerativeModel(
            name: self.modelName,
            apiKey: self.apiKey,
            generationConfig: generationConfig, // Pass the fully constructed config
            safetySettings: nil, // Configure as needed, or pass from init
            tools: nil,          // Configure as needed, or pass from init
            toolConfig: nil      // Configure as needed, or pass from init
        )
        
        let response = try await model.generateContent(text)
        
        guard let responseText = response.text else {
            // Fallback or further inspection if response.text is nil
            // For example, check response.candidates if available and appropriate
            if let candidates = response.candidates, let firstCandidate = candidates.first, let candidateText = firstCandidate.content.parts.compactMap({ $0.text }).joined() {
                 if !candidateText.isEmpty {
                    return LLMResult(llm_output: candidateText)
                 }
            }
            throw GeminiError.responseNoText 
        }
        
        return LLMResult(llm_output: responseText)
    }
}
