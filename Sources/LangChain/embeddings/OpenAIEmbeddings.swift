//
//  File.swift
//  
//
//  Created by 顾艳华 on 2023/6/12.
//

import Foundation
import NIOPosix
import AsyncHTTPClient
import OpenAIKit // Make sure this import is present

public struct OpenAIEmbeddings: Embeddings {
    let session: URLSession
    // Storing the model name as a property for clarity and potential future configuration
    private let modelName: String = "text-embedding-3-small"

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
        
        // Ensure OPENAI_API_BASE is correctly handled if it might be missing or empty
        let baseUrlString = env["OPENAI_API_BASE"]
        let apiHost = (baseUrlString == nil || baseUrlString!.isEmpty) ? "api.openai.com" : baseUrlString!

        // Determine scheme based on host, typically https unless it's localhost
        let scheme: API.Scheme = (apiHost.starts(with: "localhost") || apiHost.starts(with: "127.0.0.1")) ? .http : .https
        
        let configuration = Configuration(
            apiKey: apiKey,
            api: API(scheme: scheme, host: apiHost)
        )

        let openAIClient = OpenAIKit.Client(session: session, configuration: configuration)

        do {
            // Ensure the correct model is specified using OpenAIKit.Model.custom()
            // This aligns with the ModelID type and uses the desired "text-embedding-3-small" model.
            let modelIdentifier = OpenAIKit.Model.custom(self.modelName)
            
            let embeddingResponse = try await openAIClient.embeddings.create(
                model: modelIdentifier,
                input: text
            )
            
            // Assuming the response structure provides embeddings in embeddingResponse.data[0].embedding
            guard let firstEmbeddingData = embeddingResponse.data.first else {
                print("Error: OpenAI response did not contain embedding data.")
                return []
            }
            return firstEmbeddingData.embedding
            
        } catch let error as OpenAIError {
            // More specific error handling for OpenAIKit errors
            print("OpenAI API Error creating embedding: \(error.localizedDescription)")
            if let details = error.error {
                 print("Error Code: \(details.code ?? "N/A"), Type: \(details.type), Message: \(details.message)")
            }
            return []
        } catch {
            // General error handling
            print("Error creating embedding: \(error.localizedDescription)")
            return []
        }
    }
}

// Note: You might need to ensure LC.loadEnv() is correctly implemented and accessible.
// If LC is a local utility class/struct within langchain-swift, ensure it's defined.
// For example, a minimal LC.loadEnv() might look like this if it's not already robustly defined:
/*
struct LC { // Placeholder - ensure this matches your actual LC structure
    static func loadEnv() -> [String: String] {
        // This is a simplified example.
        // In a real scenario, you'd load this from a .env file or environment variables.
        // For testing, you might hardcode or use ProcessInfo.processInfo.environment
        var envVars = ProcessInfo.processInfo.environment
        // You might load from a .env file here and merge with environment variables
        // For example, if OPENAI_API_KEY is directly set as an environment variable:
        return envVars
    }
}
*/
