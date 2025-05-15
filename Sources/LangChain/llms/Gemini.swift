//
//  File.swift
//  
//
//  Created by 顾艳华 on 12/25/23.
//
    import Foundation
    import GoogleGenerativeAI

    public class Gemini: LLM {
        let modelName: String
        private let apiKey: String // Store the API key passed during init

        // API key is now a required parameter in the initializer
        public init(apiKey: String, modelName: String = "gemini-pro", callbacks: [BaseCallbackHandler] = [], cache: BaseCache? = nil) {
            self.apiKey = apiKey
            self.modelName = modelName
            super.init(callbacks: callbacks, cache: cache)
        }

        override func _send(text: String, stops: [String]) async throws -> LLMResult {
            // No need to fetch from AppSettings or environment here
            // Just use the apiKey property
            let model = GenerativeModel(name: self.modelName, apiKey: self.apiKey)
            let response = try await model.generateContent(text)
            return LLMResult(llm_output: response.text)
            // Error handling if apiKey is somehow empty (though init should prevent this)
        }
    }
