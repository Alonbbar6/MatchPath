import Foundation

/// OpenAI GPT-4 Mini Service
/// Handles communication with OpenAI API for premium AI chatbot
class OpenAIService {
    static let shared = OpenAIService()

    // MARK: - Configuration

    private let apiKey: String
    private let baseURL = "https://api.openAI.com/v1"
    private let model = "gpt-4o-mini" // GPT-4 Mini model

    // MARK: - Initialization

    private init() {
        // Get API key from environment or configuration
        // IMPORTANT: In production, store this securely (not in code)

        // Try multiple sources for the API key
        var key = ""

        // 1. Check environment variables (for Xcode scheme config)
        key = ProcessInfo.processInfo.environment["GPT_API_KEY"] ?? ""
        if key.isEmpty {
            key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        }

        // 2. If not in environment, try loading from .env file
        if key.isEmpty {
            key = Self.loadFromEnvFile() ?? ""
        }

        self.apiKey = key

        if apiKey.isEmpty {
            print("⚠️ OpenAI API key not configured. AI chatbot will use fallback responses.")
            print("💡 Tip: Set GPT_API_KEY in your .env file or Xcode scheme environment variables")
        } else {
            print("✅ OpenAI API key loaded successfully")
        }
    }

    /// Load API key from .env file in project root
    private static func loadFromEnvFile() -> String? {
        // Get the project directory (go up from app bundle to find .env)
        guard let projectPath = Bundle.main.resourcePath?.replacingOccurrences(of: "/Build/Products", with: "")
                .components(separatedBy: "/MatchPath.app").first else {
            return nil
        }

        // Try multiple possible locations for .env file
        let possiblePaths = [
            projectPath + "/.env",
            projectPath + "/MatchPath/.env",
            Bundle.main.path(forResource: ".env", ofType: nil)
        ].compactMap { $0 }

        for envPath in possiblePaths {
            if let envContent = try? String(contentsOfFile: envPath, encoding: .utf8) {
                // Parse .env file
                let lines = envContent.components(separatedBy: .newlines)
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)

                    // Skip comments and empty lines
                    if trimmed.isEmpty || trimmed.hasPrefix("#") {
                        continue
                    }

                    // Look for GPT_API_KEY or OPENAI_API_KEY
                    if trimmed.hasPrefix("GPT_API_KEY=") {
                        let key = trimmed.replacingOccurrences(of: "GPT_API_KEY=", with: "")
                        if !key.isEmpty {
                            print("✅ Loaded GPT_API_KEY from .env file")
                            return key
                        }
                    } else if trimmed.hasPrefix("OPENAI_API_KEY=") {
                        let key = trimmed.replacingOccurrences(of: "OPENAI_API_KEY=", with: "")
                        if !key.isEmpty {
                            print("✅ Loaded OPENAI_API_KEY from .env file")
                            return key
                        }
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Public Methods

    /// Send a chat completion request to GPT-4 Mini
    /// - Parameters:
    ///   - messages: Array of chat messages (conversation history)
    ///   - systemPrompt: System instructions for the AI
    ///   - context: Additional context (RAG retrieved documents)
    /// - Returns: AI generated response
    func chatCompletion(
        messages: [ChatMessage],
        systemPrompt: String,
        context: String? = nil
    ) async throws -> String {

        // Check if API key is configured
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        // Build request
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build messages array with system prompt
        var apiMessages: [[String: String]] = []

        // Add system prompt with RAG context if available
        var fullSystemPrompt = systemPrompt
        if let context = context, !context.isEmpty {
            fullSystemPrompt += "\n\nRelevant information from knowledge base:\n\(context)"
        }

        apiMessages.append([
            "role": "system",
            "content": fullSystemPrompt
        ])

        // Add conversation history
        for message in messages {
            if message.role != .system { // Skip system messages (already included)
                apiMessages.append([
                    "role": message.role.rawValue,
                    "content": message.content
                ])
            }
        }

        // Build request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": apiMessages,
            "temperature": 0.7, // Balance between creativity and consistency
            "max_tokens": 500,  // Limit response length (cost control)
            "top_p": 0.9,
            "frequency_penalty": 0.3,
            "presence_penalty": 0.3
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ OpenAI API Error: \(httpResponse.statusCode) - \(errorMessage)")
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)

        guard let choice = apiResponse.choices.first,
              let content = choice.message.content else {
            throw OpenAIError.noResponse
        }

        return content
    }

    /// Get embeddings for text (for RAG retrieval)
    /// - Parameter text: Text to embed
    /// - Returns: Vector embedding
    func getEmbedding(for text: String) async throws -> [Double] {
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let url = URL(string: "\(baseURL)/embeddings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "text-embedding-3-small", // Smaller, cheaper embedding model
            "input": text
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError(statusCode: 0, message: "Embedding failed")
        }

        let embeddingResponse = try JSONDecoder().decode(OpenAIEmbeddingResponse.self, from: data)

        guard let embedding = embeddingResponse.data.first?.embedding else {
            throw OpenAIError.noResponse
        }

        return embedding
    }
}

// MARK: - Response Models

struct OpenAIChatResponse: Codable {
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Codable {
        let message: Message
        let finish_reason: String?

        struct Message: Codable {
            let role: String
            let content: String?
        }
    }

    struct Usage: Codable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }
}

struct OpenAIEmbeddingResponse: Codable {
    let data: [EmbeddingData]

    struct EmbeddingData: Codable {
        let embedding: [Double]
    }
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not configured"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .apiError(let code, let message):
            return "OpenAI API error (\(code)): \(message)"
        case .noResponse:
            return "No response from OpenAI"
        }
    }
}
