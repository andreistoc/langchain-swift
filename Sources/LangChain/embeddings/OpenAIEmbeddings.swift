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

public struct OpenAIEmbeddings: Embeddings {
    let session: URLSession
    private let modelString: String = "text-embedding-3-small" // Renamed for clarity

    public init(session: URLSession = URLSession(configuration: .default)) {
        self.session = session
    }
    
    //    public func embedDocuments(texts: [String]) -> [[Float]] {
    //        // Implementation would go here if needed
    //        return []
    //    }
    
    public func embedQuery(text: String) async -> [Float] {
       
        let env = LC.loadEnv() // Assuming LC.loadEnv() correctly retrieves your environment variables
        
        guard let apiKey = env["OPENAI_API_KEY"], !apiKey.isEmpty else {
            print("Error: OPENAI_API_KEY not found or is empty.")
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
            // Attempt to initialize OpenAIKit.Model directly with the string.
            // This is a common pattern if .custom() is not available.
            // The `ModelID` type expected by `create` is likely OpenAIKit.Model.
            let modelIdentifier = OpenAIKit.Model(self.modelString) 
            
            let embeddingResponse = try await openAIClient.embeddings.create(
                model: modelIdentifier, // Pass the constructed Model object
                input: text
            )
            
            guard let firstEmbeddingData = embeddingResponse.data.first else {
                print("Error: OpenAI response did not contain embedding data.")
                return []
            }
            return firstEmbeddingData.embedding
            
        } catch { // Catching general Error as OpenAIError was not found
            // You can inspect the 'error' object at runtime to see its actual type
            // and add more specific catch blocks if needed.
            print("Error creating embedding: \(error.localizedDescription)")
            // For more detailed debugging, you might print the whole error object:
            // print("Full error details: \(error)")
            return []
        }
    }
}

// Placeholder for LC.loadEnv() - ensure this matches your actual implementation
/*
struct LC {
    static func loadEnv() -> [String: String] {
        // Replace with your actual environment variable loading logic
        return ProcessInfo.processInfo.environment
    }
}
*/
