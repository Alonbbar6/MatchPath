import Foundation

/// RAG (Retrieval-Augmented Generation) Service for Stadium Knowledge
/// Stores and retrieves stadium-specific information to enhance AI responses
class StadiumRAGService {
    static let shared = StadiumRAGService()

    // MARK: - Properties

    private var knowledgeBase: [KnowledgeDocument] = []
    private let openAI = OpenAIService.shared

    // MARK: - Initialization

    private init() {
        // Initialize with stadium knowledge
        loadStadiumKnowledge()
    }

    // MARK: - Public Methods

    /// Retrieve relevant context for a user query
    /// - Parameters:
    ///   - query: User's question
    ///   - topK: Number of most relevant documents to return
    /// - Returns: Concatenated context from top matching documents
    func retrieveContext(for query: String, topK: Int = 3) async -> String {
        do {
            // Get embedding for the query
            let queryEmbedding = try await openAI.getEmbedding(for: query)

            // Calculate similarity scores
            var scores: [(document: KnowledgeDocument, score: Double)] = []

            for document in knowledgeBase {
                let similarity = cosineSimilarity(queryEmbedding, document.embedding)
                scores.append((document, similarity))
            }

            // Sort by score and take top K
            scores.sort { $0.score > $1.score }
            let topDocuments = scores.prefix(topK)

            // Concatenate context
            let context = topDocuments
                .map { "[\($0.document.category)] \($0.document.content)" }
                .joined(separator: "\n\n")

            return context

        } catch {
            print("⚠️ RAG retrieval failed: \(error.localizedDescription)")
            // Fall back to keyword matching
            return fallbackRetrieval(for: query, topK: topK)
        }
    }

    // MARK: - Private Methods

    /// Load stadium knowledge into the RAG system
    private func loadStadiumKnowledge() {
        // In a real implementation, this would:
        // 1. Load from a database or JSON file
        // 2. Generate embeddings for each document
        // 3. Store in a vector database (Pinecone, Chroma, etc.)
        //
        // For MVP, we'll use hardcoded knowledge with placeholder embeddings

        knowledgeBase = [
            // EMERGENCY & SAFETY
            KnowledgeDocument(
                id: "emergency-001",
                category: "Emergency",
                content: """
                Emergency services at major stadiums:
                - First Aid stations located on every level near main concourses
                - Medical staff available at all gates
                - Emergency number: 911
                - Stadium security can be texted at 69050
                - AED devices located every 100 meters
                - Emergency exits are clearly marked in green
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // ACCESSIBILITY
            KnowledgeDocument(
                id: "accessibility-001",
                category: "Accessibility",
                content: """
                Accessibility features at major venues:
                - All stadiums are ADA compliant
                - Wheelchair accessible entrances at all gates
                - Elevators available to all seating levels
                - Accessible seating sections with companion seats
                - Accessible restrooms on every level
                - Reserved accessible parking near entrances
                - Service animals are permitted
                - Staff assistance available upon request
                - ASL interpretation available for announcements at guest services
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // PAYMENT & CASHLESS
            KnowledgeDocument(
                id: "payment-001",
                category: "Payment",
                content: """
                Payment information for major stadiums:
                - All venues are CASHLESS
                - Accepted: Credit/debit cards, Apple Pay, Google Pay, Samsung Pay
                - ATMs available but limited
                - Reverse ATMs exchange cash for prepaid cards (small fee)
                - Mobile ordering available through stadium apps
                - International cards accepted (Visa, Mastercard, Amex)
                - No cash at concessions or merchandise stands
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // BAG POLICY
            KnowledgeDocument(
                id: "policy-001",
                category: "Entry Policy",
                content: """
                Standard bag policy (consistent across all venues):
                ALLOWED:
                - Clear plastic bags (12" x 6" x 12" or smaller)
                - Small clutch purses (4.5" x 6.5" or smaller)
                - Medically necessary items (with documentation)
                - Diaper bags for infants
                - Camera bags (small, no professional equipment)

                NOT ALLOWED:
                - Backpacks of any size
                - Large purses or tote bags
                - Coolers or insulated bags
                - Briefcases
                - Luggage or large bags
                - Strollers (check at guest services)
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // PROHIBITED ITEMS
            KnowledgeDocument(
                id: "prohibited-001",
                category: "Security",
                content: """
                Prohibited items at all major stadiums:
                - Weapons of any kind
                - Outside food and beverages
                - Alcohol
                - Illegal drugs
                - Professional cameras (detachable lenses)
                - Video equipment
                - Selfie sticks and tripods
                - Drones
                - Laser pointers
                - Fireworks or noisemakers
                - Flags on poles
                - Beach balls or inflatables
                - Umbrellas (ponchos recommended instead)
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // TIMING & ARRIVAL
            KnowledgeDocument(
                id: "timing-001",
                category: "Arrival",
                content: """
                Recommended arrival times for sporting events:
                - Gates open: 2 hours before kickoff
                - Recommended arrival: 90 minutes before kickoff
                - Security lines peak: 30-45 minutes before kickoff
                - Fastest entry: 90-120 minutes before kickoff
                - Latest entry: Gates may close 15 minutes after kickoff
                - Allow 15-20 minutes from parking to seats
                - First-time visitors: Add 15 extra minutes
                - High-demand matches (finals): Arrive 2 hours early
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // RE-ENTRY POLICY
            KnowledgeDocument(
                id: "reentry-001",
                category: "Policy",
                content: """
                Re-entry policy for major stadiums:
                - NO RE-ENTRY allowed once you exit
                - This is strictly enforced at all venues
                - Exceptions: Medical emergencies only (case-by-case)
                - Plan accordingly - bring everything you need
                - Phone charging stations available inside
                - Smoking areas: Outside only (no re-entry)
                - First aid available inside if you feel ill
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // WEATHER & ATTIRE
            KnowledgeDocument(
                id: "weather-001",
                category: "Tips",
                content: """
                Weather and attire tips for game day:
                - Check local forecast before traveling
                - Summer matches (June-July): Can be very hot (80-95°F / 27-35°C)
                - Bring sunscreen for day games
                - Light, breathable clothing recommended
                - Hat and sunglasses allowed
                - Evening matches: Bring light jacket
                - Rain: Ponchos allowed, umbrellas prohibited
                - Most stadiums have partial or full roofs
                - Hydration: Water bottles sold inside, bring empty reusable
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // TICKETS & MOBILE
            KnowledgeDocument(
                id: "tickets-001",
                category: "Tickets",
                content: """
                Ticket information:
                - All tickets are MOBILE-ONLY (digital)
                - Download tickets before arriving (poor signal inside)
                - Screenshot your ticket as backup
                - Ticket includes QR code for entry
                - Keep phone charged (bring portable charger)
                - One scan per ticket at entry
                - Ticket resale: Only through official ticket marketplace
                - Lost tickets: Contact event support immediately
                - Seat changes: Not allowed after purchase
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // PARKING GENERAL
            KnowledgeDocument(
                id: "parking-001",
                category: "Parking",
                content: """
                General parking information for game day:
                - Pre-purchase parking recommended (saves money)
                - Stadium lots fill 60-90 minutes before kickoff
                - Prices: $30-$80 depending on proximity
                - Use apps: ParkMobile, SpotHero, ParkWhiz
                - Arrive early for best spots
                - Exit times: 20-45 minutes after matches
                - Alternative: Use public transportation (faster)
                - Rideshare drop-off zones available at all venues
                - Accessible parking: Reserved spots near gates
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // FOOD & CONCESSIONS
            KnowledgeDocument(
                id: "food-001",
                category: "Food",
                content: """
                Food and beverage at major stadiums:
                - 30-50 concession stands per venue
                - Mobile ordering available (skip lines)
                - Options: Traditional stadium food + local specialties
                - Vegetarian and vegan options available
                - Allergen information available at stands
                - Prices: $8-20 for meals, $5-12 for drinks
                - Water: Free water stations throughout
                - Alcohol: Beer and wine available (21+ with ID)
                - Last call: Usually 75th minute of match
                - Express stands: Grab-and-go items only
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // WIFI & CONNECTIVITY
            KnowledgeDocument(
                id: "wifi-001",
                category: "Amenities",
                content: """
                WiFi and connectivity at major venues:
                - Free WiFi available throughout all stadiums
                - Network names: Usually "Stadium_Guest" or stadium-specific
                - No password required (open network)
                - 5G cellular also available from major carriers
                - Bandwidth prioritized for mobile ticketing
                - Phone charging stations available (limited)
                - Bring portable charger recommended
                - Download offline maps before arriving
                - Stadium apps work on WiFi
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // LOST & FOUND
            KnowledgeDocument(
                id: "lost-found-001",
                category: "Guest Services",
                content: """
                Lost and Found at major stadiums:
                - Location: Guest Services desk (main entrance level)
                - Report lost items immediately to staff
                - Items held for 30 days
                - Contact: Check stadium website for phone number
                - Claim process: Photo ID required
                - High-value items: Secured separately
                - Phones: Stadium staff can help you call it
                - Tickets lost: Contact event support
                - After event: Check stadium website for lost & found
                """,
                embedding: generatePlaceholderEmbedding()
            ),

            // CHILDREN & FAMILIES
            KnowledgeDocument(
                id: "family-001",
                category: "Family",
                content: """
                Information for families attending events:
                - Children under 2: Free (lap seat)
                - Children 2+: Require own ticket
                - Family restrooms available on all levels
                - Nursing rooms available at guest services
                - Diaper changing stations in all restrooms
                - Kid-friendly food options available
                - Lost child: Report immediately to staff or text 69050
                - Wristbands: Write phone number on child's wrist
                - Strollers: Can be checked at guest services
                - Ear protection recommended for young children
                """,
                embedding: generatePlaceholderEmbedding()
            )
        ]

        print("✅ Stadium RAG knowledge base loaded with \(knowledgeBase.count) documents")
    }

    /// Fallback retrieval using simple keyword matching
    private func fallbackRetrieval(for query: String, topK: Int) -> String {
        let lowercaseQuery = query.lowercased()
        var matches: [(document: KnowledgeDocument, score: Int)] = []

        // Simple keyword matching
        for document in knowledgeBase {
            var score = 0
            let content = document.content.lowercased()

            // Check for exact phrase matches
            if content.contains(lowercaseQuery) {
                score += 10
            }

            // Check for individual words
            let queryWords = lowercaseQuery.split(separator: " ")
            for word in queryWords where word.count > 3 {
                if content.contains(String(word)) {
                    score += 1
                }
            }

            // Check category match
            if document.category.lowercased().contains(lowercaseQuery) {
                score += 5
            }

            if score > 0 {
                matches.append((document, score))
            }
        }

        matches.sort { $0.score > $1.score }
        let topDocuments = matches.prefix(topK)

        return topDocuments
            .map { "[\($0.document.category)] \($0.document.content)" }
            .joined(separator: "\n\n")
    }

    /// Calculate cosine similarity between two embeddings
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0, magnitudeB > 0 else { return 0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }

    /// Generate placeholder embedding for MVP
    /// In production, these would be real embeddings from OpenAI
    private func generatePlaceholderEmbedding() -> [Double] {
        // Return random embedding for now
        // In production, call openAI.getEmbedding(for: document.content)
        return (0..<1536).map { _ in Double.random(in: -1...1) }
    }
}

// MARK: - Models

struct KnowledgeDocument {
    let id: String
    let category: String
    let content: String
    let embedding: [Double]
}
