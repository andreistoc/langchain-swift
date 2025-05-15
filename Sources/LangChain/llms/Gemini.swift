//
//  File.swift
//  
//
//  Created by 顾艳华 on 12/25/23.
//
import Foundation
import GoogleGenerativeAI

public class Gemini: LLM {
    let modelName: String // Add this property

    // Modify the initializer to accept a model name
    public init(modelName: String = "gemini-pro", callbacks: [BaseCallbackHandler] = [], cache: BaseCache? = nil) {
        self.modelName = modelName
        super.init(callbacks: callbacks, cache: cache)
    }

    override func _send(text: String, stops: [String]) async throws -> LLMResult {
        let env = LC.loadEnv()
        
        if let apiKey = env["GOOGLEAI_API_KEY"] {
            // Use the modelName property here
            let model = GenerativeModel(name: self.modelName, apiKey: apiKey)
            let response = try await model.generateContent(text)
            return LLMResult(llm_output: response.text)
        } else {
            print("Please set googleai api key.")
            return LLMResult(llm_output: "Please set googleai api key.")
        }
    }
}
