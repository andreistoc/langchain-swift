//
//  File.swift
//  
//
//  Created by 顾艳华 on 2023/6/12.
//

import Foundation
import NIOPosix
import AsyncHTTPClient
import OpenAIKit

public struct OpenAIEmbeddings: Embeddings {
    let session: URLSession
    // Storing the model name as a property for clarity and potential future configuration
    private let modelName: String = "text-embedding-3-small"

    public init(session: URLSession = URLSession(configuration: .default)) {
        self.session = session
    }
    
//    public func embedDocuments(texts: [String]) -> [[Float]] {
//        []
//    }
    
    public func embedQuery(text: String) async -> [Float] {
       
        let env = LC.loadEnv()
        
        if let apiKey = env["OPENAI_API_KEY"] {
            let baseUrl = env["OPENAI_API_BASE"] ?? "api.openai.com"
            
            let configuration = Configuration(apiKey: apiKey, api: API(scheme: .https, host: baseUrl))

            let openAIClient = OpenAIKit.Client(session: session, configuration: configuration)

            do {
                // Ensure the correct model is specified in the API call
                let embedding = try await openAIClient.embeddings.create(model: self.modelName, input: text)
                
                //            print(embedding.data[0].embedding)
                return embedding.data[0].embedding
            } catch {
                // Log the error for better debugging
                print("Error creating embedding: \(error)")
                return []
            }
        } else {
            print("Please set openai api key.")
            return []
        }

        
    }
    
    
}
