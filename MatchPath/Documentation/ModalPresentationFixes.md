# Modal Presentation Size Fixes

## Problem
The pre-order food view and track on map features were presenting in sheets that were too small, making it difficult to use the features properly.

## Solution Applied

### iOS (iPhone/iPad)
- Changed to **fullScreenCover** presentation for:
  - Food Ordering View
  - Map Tracking View
- These now take up the full screen for better usability
- Added `.presentationDetents([.large])` for parking selection to ensure it's shown at maximum sheet size

### macOS
- Used `.sheet` presentation with minimum frame sizes:
  - Food Ordering: 700x600 minimum
  - Map View: 800x600 minimum
  - Parking Selection: Uses `.presentationDetents([.large])`
- Maintains native macOS sheet behavior while ensuring adequate size

## Changes Made

### Files Modified:

#### 1. ScheduleBuilderView.swift
- **Parking Selection Sheet**: Added `.presentationDetents([.large])` for iOS
- **Food Ordering**:
  - iOS: Uses `.fullScreenCover` for full-screen experience
  - macOS: Uses `.sheet` with minimum 700x600 frame

#### 2. ScheduleTimelineView.swift
- **Map Tracking View**:
  - iOS: Uses `.fullScreenCover` for immersive map experience
  - macOS: Uses `.sheet` with minimum 800x600 frame

## User Experience Improvements

### Before:
- ❌ Food ordering appeared in small sheet (~50% screen)
- ❌ Map view was cramped and hard to navigate
- ❌ Difficult to see all options and controls

### After:
- ✅ Food ordering takes full screen on iOS (easy to browse menus)
- ✅ Map view is immersive and easy to interact with
- ✅ macOS maintains native sheet behavior with proper sizing
- ✅ All controls and content clearly visible

## Platform-Specific Behavior

### iOS
```swift
.fullScreenCover(isPresented: $showingView) {
    NavigationView {
        ContentView()
    }
}
```

### macOS
```swift
.sheet(isPresented: $showingView) {
    NavigationView {
        ContentView()
    }
    .frame(minWidth: 800, minHeight: 600)
}
```

## Testing Checklist

- [x] Build succeeds on macOS
- [ ] Test on iPhone - full screen presentation works
- [ ] Test on iPad - full screen presentation works
- [ ] Test on macOS - sheets have adequate size
- [ ] Food ordering flow is easy to navigate
- [ ] Map view shows all controls clearly
- [ ] Parking selection shows all options

## Future Considerations

If you want to allow users to resize sheets on macOS, you can add:
```swift
.frame(minWidth: 800, minHeight: 600, maxWidth: .infinity, maxHeight: .infinity)
```

Or for iPad, if you want to offer both sheet and fullscreen options:
```swift
.presentationDetents([.large, .medium])
```

## Notes

- `.fullScreenCover` is iOS-only (not available on macOS)
- `.presentationDetents` is iOS 16+ only
- macOS uses traditional sheet sizing with `.frame()` modifiers
- All changes maintain backward compatibility with cross-platform compilation
