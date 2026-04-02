# Location Permissions Setup

To enable location tracking and map features, you need to add the following to your app's **Info.plist** file:

## Required Permissions

Add these keys to your Info.plist:

### 1. Location When In Use (Required)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to track your progress to the stadium and provide real-time updates on your schedule.</string>
```

### 2. Location Always (Optional - for background tracking)
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to send you arrival notifications and track your game day journey even when the app is in the background.</string>
```

## How to Add in Xcode

### Method 1: Using Xcode UI
1. Select your project in the Project Navigator
2. Select the "MatchPath" target
3. Click on the "Info" tab
4. Click the "+" button to add a new key
5. Select "Privacy - Location When In Use Usage Description"
6. Enter the description: "We need your location to track your progress to the stadium and provide real-time updates on your schedule."

### Method 2: Editing Info.plist directly
1. Find your Info.plist file in the project navigator
2. Right-click → Open As → Source Code
3. Add the XML keys above inside the `<dict>` tag

## Required Capabilities

Also ensure these capabilities are enabled:

1. **Background Modes** (optional - for background tracking)
   - Location updates

## Testing Location Features

### In Simulator:
1. Debug → Location → Custom Location...
2. Or use Features → Location → [choose a preset]

### On Device:
1. Settings → Privacy → Location Services → MatchPath
2. Select "While Using the App" or "Always"

## Notes

- The app will automatically request permission when you start tracking
- Users can change permissions anytime in Settings
- The app gracefully handles denied permissions
