//
//  File.swift
//  
//
//  Created by 顾艳华 on 2023/6/12.
//

import Foundation
import NIOPosix
import AsyncHTTPClient
import OpenAIKit // Ensure this import is present

// Helper struct to conform to OpenAIKit.ModelID for custom model strings
private struct CustomOpenAIModel: OpenAIKit.ModelID {
    let id: String
    
    init(_ id: String) {
        self.id = id
    }
}

public struct OpenAIEmbeddings: Embeddings {
    let session: URLSession
    // The target model string we want to use
    private let targetModelIdString: String = "text-embedding-3-small"

    public init(session: URLSession = URLSession(configuration: .default)) {
        self.session = session
    }
    
    public func embedQuery(text: String) async -> [Float] {
       
        let env = LC.loadEnv() // Assuming LC.loadEnv() correctly retrieves your environment variables
        
        guard let apiKey = env["OPENAI_API_KEY"], !apiKey.isEmpty else {
            print("Error: OPENAI_API_KEY not found or is empty in environment.")
            return []
        }
        
        let baseUrlString = env["OPENAI_API_BASE"]
        let apiHost = (baseUrlString == nil || baseUrlString!.isEmpty) ? "api.openai.com" : baseUrlString!
        let scheme: API.Scheme = (apiHost.starts(with: "localhost") || apiHost.starts(with: "127.0.0.1")) ? .http : .https
        
        let configuration = Configuration(
            apiKey: apiKey,
            api: API(scheme: scheme, host: apiHost)
        )

        let openAIClient = OpenAIKit.Client(session: session, configuration: configuration)

        do {
            // Use the CustomOpenAIModel struct to pass the desired model ID
            let modelIdentifier = CustomOpenAIModel(self.targetModelIdString)
            
            let embeddingResponse = try await openAIClient.embeddings.create(
                model: modelIdentifier, // Pass our custom ModelID-conforming struct
                input: text
            )
            
            guard let firstEmbeddingData = embeddingResponse.data.first else {
                print("Error: OpenAI API response did not contain embedding data for model \(self.targetModelIdString).")
                return []
            }
            return firstEmbeddingData.embedding
            
        } catch {
            // General error handling. You can inspect 'error' at runtime for more details.
            print("Error creating embedding with model \(self.targetModelIdString): \(error.localizedDescription)")
            // For more detailed debugging: print("Full error details: \(error)")
            return []
        }
    }
}

// Placeholder for LC.loadEnv() - ensure this matches your actual implementation
/*
struct LC { // Ensure this utility is correctly defined and accessible in your project
    static func loadEnv() -> [String: String] {
        // Replace with your actual environment variable loading logic
        // Example: return ProcessInfo.processInfo.environment
        // Or load from a .env file
        
        // A simple fallback if OPENAI_API_KEY might be missing from environment by default
        var effectiveEnv = ProcessInfo.processInfo.environment
        if effectiveEnv["OPENAI_API_KEY"] == nil {
            // Attempt to load from a common .env pattern or other config source if needed
            // For example, if you have a mechanism to read a .env file into a dictionary:
            // if let envFromFile = DotEnvLoader.load() { // Fictional .env loader
            //     effectiveEnv.merge(envFromFile) { (_, new) in new }
            // }
            // Or, if your app sets it up elsewhere, ensure LC.loadEnv() picks it up.
            // For now, this just prints if it's missing.
        }
        return effectiveEnv
    }
}
*/
