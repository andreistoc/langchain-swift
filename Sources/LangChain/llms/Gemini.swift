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
        // Combine stop sequences from init and _send parameters
        var effectiveStopSequences = self.stopSequences ?? []
        if !stops.isEmpty {
            effectiveStopSequences.append(contentsOf: stops)
        }
        // Pass nil if empty, as GenerationConfig's stopSequences parameter is optional
        let finalStopSequences = effectiveStopSequences.isEmpty ? nil : effectiveStopSequences

        // Prepare GenerationConfig by passing parameters to its initializer
        let generationConfig = GenerationConfig(
            temperature: self.temperature,
            topP: self.topP,
            topK: self.topK,
            // candidateCount is another option in GenerationConfig, but not exposed by this LLM class
            maxOutputTokens: self.maxOutputTokens,
            stopSequences: finalStopSequences
        )

        // Initialize the Google AI model
        let model = GenerativeModel(
            name: self.modelName,
            apiKey: self.apiKey,
            generationConfig: generationConfig,
            safetySettings: nil, // Configure as needed, or pass from init if you extend this class
            tools: nil,          // Configure as needed, or pass from init
            toolConfig: nil      // Configure as needed, or pass from init
        )
        
        let response = try await model.generateContent(text)
        
        // Check response.text first, ensuring it's not nil and not empty
        if let responseText = response.text, !responseText.isEmpty {
            return LLMResult(llm_output: responseText)
        } else {
            // response.text was nil or empty. Try to get text from the first candidate.
            // response.candidates is of type [CandidateResponse] (non-optional array).
            // response.candidates.first gives an optional CandidateResponse.
            if let firstCandidate = response.candidates.first {
                // ModelContent.Part has an extension providing a `.text: String?` accessor.
                // compactMap will filter out non-text parts and nil texts.
                // joined() will concatenate the text parts into a single String.
                let candidateText = firstCandidate.content.parts.compactMap({ $0.text }).joined()
                if !candidateText.isEmpty {
                    return LLMResult(llm_output: candidateText)
                }
            }
            // If we're here, either response.text was nil/empty, 
            // or there were no candidates, or the first candidate had no usable text.
            throw GeminiError.responseNoText 
        }
    }
}
