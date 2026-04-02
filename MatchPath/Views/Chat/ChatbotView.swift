import SwiftUI

/// AI Chatbot Assistant View
/// Free feature: Available to all users
struct ChatbotView: View {
    let schedule: GameSchedule
    @StateObject private var chatbot = AIChatbotService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatbot.messages) { message in
                                ChatMessageBubble(message: message)
                                    .id(message.id)
                            }

                            // Typing indicator
                            if chatbot.isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatbot.messages.count) {
                        if let lastMessage = chatbot.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input field
                HStack(spacing: 12) {
                    TextField("Ask me anything about your game day...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
                        .cornerRadius(20)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...4)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty || chatbot.isTyping)
                }
                .padding()
                .background(Color.white)
            }
            .navigationTitle("Game Day Assistant")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            chatbot.clearChat()
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }

                        Button {
                            shareConversation()
                        } label: {
                            Label("Share Conversation", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            chatbot.clearChat()
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }

                        Button {
                            shareConversation()
                        } label: {
                            Label("Share Conversation", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #endif
            }
            .onAppear {
                // Set context when view appears
                chatbot.setContext(stadium: schedule.game.stadium, schedule: schedule)
            }
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""
        isTextFieldFocused = false

        Task {
            await chatbot.sendMessage(text)
        }
    }

    private func shareConversation() {
        // TODO: Implement conversation sharing
        print("Share conversation")
    }
}

// MARK: - Chat Message Bubble

struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .padding(12)
                    .background(backgroundColor)
                    .cornerRadius(16)

                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }

    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return Color(red: 0.898, green: 0.898, blue: 0.918)
        case .system:
            return Color(red: 0.949, green: 0.949, blue: 0.969)
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animatingDot1 = false
    @State private var animatingDot2 = false
    @State private var animatingDot3 = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.gray)
                .frame(width: 8, height: 8)
                .offset(y: animatingDot1 ? -5 : 0)

            Circle()
                .fill(Color.gray)
                .frame(width: 8, height: 8)
                .offset(y: animatingDot2 ? -5 : 0)

            Circle()
                .fill(Color.gray)
                .frame(width: 8, height: 8)
                .offset(y: animatingDot3 ? -5 : 0)
        }
        .padding(12)
        .background(Color(red: 0.898, green: 0.898, blue: 0.918))
        .cornerRadius(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                animatingDot1 = true
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(0.2)) {
                animatingDot2 = true
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(0.4)) {
                animatingDot3 = true
            }
        }
    }
}

// MARK: - Floating Chat Button

/// Floating action button to open chatbot
/// Only shown when user has an active schedule
struct FloatingChatButton: View {
    @Binding var isShowingChat: Bool

    var body: some View {
        Button {
            isShowingChat = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                VStack(spacing: 2) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)

                    Text("AI")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    let mockGame = SportingEvent.sampleEvents[0]
    let mockLocation = UserLocation(
        name: "Marriott Hotel",
        address: "123 Main St, Miami, FL",
        coordinate: Coordinate(latitude: 25.7617, longitude: -80.1918)
    )

    let mockSchedule = GameSchedule(
        id: "preview-schedule",
        game: mockGame,
        userLocation: mockLocation,
        sectionNumber: "118",
        scheduleSteps: [],
        recommendedGate: mockGame.stadium.entryGates[0],
        purchaseDate: Date(),
        arrivalPreference: .balanced,
        transportationMode: .publicTransit,
        parkingReservation: nil,
        foodOrder: nil,
        confidenceScore: 92
    )

    ChatbotView(schedule: mockSchedule)
}
