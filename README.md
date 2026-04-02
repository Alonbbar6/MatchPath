# MatchPath

A comprehensive iOS application built with Swift and SwiftUI for planning your perfect game day experience. This app helps fans create personalized schedules for attending sporting events, including transportation, stadium entry, and pre-game activities.

## Features

### 🏟️ Match Day Planning
- **Personalized Schedules**: Create custom match day itineraries
- **Stadium Navigation**: Get directions and gate recommendations
- **Transportation**: Plan your route with real-time updates
- **Pre-Match Activities**: Discover nearby restaurants and fan zones
- **Share Plans**: Share your schedule with friends

### 🎨 User Interface
- **Modern SwiftUI Design**: Clean, intuitive interface
- **Dark Mode Support**: Automatic and manual dark mode switching
- **Custom Themes**: Multiple color themes available
- **Responsive Layout**: Optimized for all iPhone sizes
- **Smooth Animations**: Fluid transitions and interactions

### 📱 Navigation
- **Tab Bar Navigation**: Easy access to all features
  - Home: Quick stats and live matches
  - Leagues: League standings and tables
  - Matches: Match schedules and results
  - Favorites: Favorite teams and matches
  - Settings: App configuration

## Architecture

### MVVM Pattern
The app follows the Model-View-ViewModel (MVVM) architecture pattern:

- **Models**: Core data structures (Team, League, Match, Player, Standing)
- **Views**: SwiftUI views for user interface
- **ViewModels**: Business logic and data binding
- **Services**: Data access and API integration

### Key Components

#### Data Models
- `Team`: Team information, colors, stadium details
- `League`: League information and season data
- `Match`: Match details, scores, and events
- `Player`: Player information and statistics
- `Standing`: League table standings

#### Services
- `DataRepository`: Central data access layer
- `APIService`: API integration with mock data
- `CacheService`: Local data caching and persistence

#### ViewModels
- `TeamsViewModel`: Team management and favorites
- `LeaguesViewModel`: League standings and data
- `MatchesViewModel`: Match tracking and filtering
- `FavoritesViewModel`: Favorite teams and matches

## Technical Stack

- **Swift 6**: Latest Swift language features
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **Swift Concurrency**: Async/await for asynchronous operations
- **UserDefaults**: Local data persistence
- **MVVM Architecture**: Clean separation of concerns

## Project Structure

```
SportsTracker/
├── Models/
│   ├── Team.swift
│   ├── League.swift
│   ├── Match.swift
│   ├── Player.swift
│   └── Standing.swift
├── Services/
│   ├── DataRepository.swift
│   ├── APIService.swift
│   └── CacheService.swift
├── ViewModels/
│   ├── TeamsViewModel.swift
│   ├── LeaguesViewModel.swift
│   ├── MatchesViewModel.swift
│   └── FavoritesViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── HomeView.swift
│   ├── LeaguesView.swift
│   ├── MatchesView.swift
│   ├── FavoritesView.swift
│   └── SettingsView.swift
└── SportsTrackerApp.swift
```

## Features in Detail

### Home Dashboard
- Quick statistics overview
- Live matches with real-time updates
- Favorite teams quick access
- Recent match results

### League Standings
- Interactive league tables
- Team statistics and form
- Position changes with animations
- Multiple league support

### Match Tracking
- Upcoming match schedules
- Live match scores
- Match history and results
- League filtering

### Favorites Management
- Add/remove favorite teams
- Quick access to favorite content
- Personalized experience

### Settings & Customization
- Dark mode toggle
- Theme selection
- Notification preferences
- Cache management

## Data Sources

Currently uses mock data for demonstration. In production, the app can integrate with:
- Football-data.org API
- API-Football
- Custom backend services

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 6

### Installation
1. Clone the repository
2. Open `SportsTracker.xcodeproj` in Xcode
3. Build and run the project

### Configuration
- Update API keys in `APIService.swift`
- Configure notification settings
- Customize themes and colors

## Future Enhancements

### Planned Features
- **Real API Integration**: Connect to live soccer data APIs
- **Push Notifications**: Match alerts and updates
- **Player Statistics**: Detailed player performance data
- **Social Features**: Share match results and standings
- **Widgets**: Home screen widgets for quick access
- **Apple Watch Support**: Companion watch app

### Technical Improvements
- **SwiftData Integration**: Modern data persistence
- **Core Data Migration**: Enhanced data management
- **Offline Support**: Full offline functionality
- **Performance Optimization**: Improved loading and caching
- **Accessibility**: Enhanced accessibility features

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

---

**MatchPath** - Your ultimate companion for game day planning!