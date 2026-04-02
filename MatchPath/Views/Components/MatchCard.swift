import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct MatchCard: View {
    let match: Match
    var onTap: (() -> Void)?
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: 0) {
                // League Header
                HStack {
                    Text(match.league.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let round = match.league.round {
                        Text(round)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Match Content
                HStack(spacing: 16) {
                    // Home Team
                    TeamView(
                        name: match.teams.home.name,
                        logo: match.teams.home.logo,
                        isWinner: match.teams.home.winner
                    )
                    
                    // Score/Time
                    VStack(spacing: 4) {
                        if match.isLive {
                            LiveIndicator(elapsed: match.status.elapsed)
                        } else {
                            Text(match.displayTime)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            Text("\(match.goals.homeScore)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(match.teams.home.winner == true ? .primary : .secondary)
                            
                            Text("-")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            
                            Text("\(match.goals.awayScore)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(match.teams.away.winner == true ? .primary : .secondary)
                        }
                        
                        if match.isFinished {
                            Text("FT")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 80)
                    
                    // Away Team
                    TeamView(
                        name: match.teams.away.name,
                        logo: match.teams.away.logo,
                        isWinner: match.teams.away.winner
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // Venue Info (if available)
                if let venue = match.venue, let venueName = venue.name {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(venueName)
                            .font(.caption2)
                        if let city = venue.city {
                            Text("• \(city)")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            .background(.background)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Team View

struct TeamView: View {
    let name: String
    let logo: String
    let isWinner: Bool?
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: logo)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "shield.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
            }
            .frame(width: 40, height: 40)
            
            Text(name)
                .font(.caption)
                .fontWeight(isWinner == true ? .semibold : .regular)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(isWinner == true ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Live Indicator

struct LiveIndicator: View {
    let elapsed: Int?
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.5 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isPulsing
                )
            
            Text("LIVE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            if let elapsed = elapsed {
                Text("\(elapsed)'")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        MatchCard(match: Match.mockLiveMatch)
        MatchCard(match: Match.mockUpcomingMatch)
        MatchCard(match: Match.mockFinishedMatch)
    }
    .padding()
    #if canImport(UIKit)
    .background(Color(UIColor.systemGroupedBackground))
    #elseif canImport(AppKit)
    .background(Color(NSColor.windowBackgroundColor))
    #else
    .background(Color.gray.opacity(0.1))
    #endif
}
