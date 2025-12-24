# Indoor Navigation for Good

A SwiftUI-based iOS application that combines voice recognition, natural language processing, and ultra-wideband (UWB) technology to provide intelligent indoor navigation assistance.

## Overview

This project aims to create an accessible indoor navigation solution that leverages:
- **Voice Input**: Speech-to-text recognition in Cantonese and English
- **AI-Powered Intent Classification**: Natural language understanding using LLM
- **Ultra-Wideband (UWB) Technology**: Precise distance and direction tracking to nearby accessories
- **Voice Feedback**: Text-to-speech output for navigation instructions

## Features

### 1. **Speech Recognition & Transcription**
- **Real-time speech-to-text transcription** with support for Cantonese (zh-HK) and English
- Audio input from device microphone with proper permissions handling
- Error handling for authorization and microphone access
- Live transcript display in the UI
- Automatic silence detection (5-second timeout) to trigger intent processing

**Files**: `ViewModels/SpeechRecognizer.swift`

### 2. **Intent Classification & Routing**
- **LLM-powered intent classification**
- Classifies user input into predefined intents:
  - `navigation`: Requests for directions to destinations
  - `unknown`: Any unclassified queries
- Extracts intent parameters (e.g., destination names, location types)
- Confidence scoring for classification results
- Full JSON response from LLM for detailed parameter extraction

**Files**: `ViewModels/IntentRouter.swift`, `SystemPrompt/Prompt.swift`

### 3. **Navigation Intent Handling**
- Processes navigation requests with destination extraction
- Generates contextual navigation responses
- Provides synthesized voice feedback with:
  - Extracted destination information
  - Estimated distance to nearest matching location
  - Turn-by-turn direction hints
  - Customizable speech rate, volume, and pitch

**Files**: `ViewModels/IntentRouter.swift`, `ViewModels/SpeechManager.swift`

### 4. **Ultra-Wideband (UWB) Discovery & Ranging**
- **UWB Accessory Discovery**: Scans for nearby UWB-enabled accessories via Bluetooth
- **Connection Management**:
  - Initiates and manages connections to UWB accessories
  - Configuration exchange with accessory devices
  - Proper session lifecycle management
- **Real-time Distance & Direction Tracking**:
  - Continuous distance measurement to paired accessory (in meters)
  - 3D direction vector (X, Y, Z coordinates) for spatial positioning
  - Visual indicators for distance (green/yellow/orange based on proximity)
  - Direction pointer visualization showing device bearing
- **Status Management**: Tracks connection states (disconnected, scanning, connecting, exchanging config, ranging, error)
- **Bluetooth Integration**: Uses CoreBluetooth for peripheral discovery and communication

**Files**: `ViewModels/UWBAccessoryViewModel.swift`, `Views/UWBAccessoryView.swift`

### 5. **Text-to-Speech Output**
- **High-quality speech synthesis** 
- Supports multiple languages (default: English)
- Customizable speech properties:
  - Speech rate (speed)
  - Volume level
  - Pitch multiplier
- State management: play, pause, resume, stop operations
- Delegate callbacks for speech lifecycle events (start, finish, pause, resume, cancel)
- Singleton pattern for app-wide access

**Files**: `ViewModels/SpeechManager.swift`

### 6. **Transcription View**
- **Main UI** combining speech recognition and intent classification
- **Recording Control**: Start/stop microphone recording with visual status indicator
- **Live Transcript Display**: Real-time text output from speech recognizer
- **Intent Results Panel**: Shows classified intent, confidence score, and extracted parameters
- **Visual Feedback**: Color-coded status indicator (gray for idle, red for recording)
- **Intent Router Test Button**: Quick testing of the intent classification system

**Files**: `Views/TranscriptionView.swift`

### 7. **UWB Accessory Interface**
- **Status Display**: Visual indicators for current connection state with icons
- **Distance Visualization**: Large numeric display with progress bar indicator
- **Direction Visualization**: 2D compass-like indicator showing direction vector
- **Device Discovery List**: Browsing and connecting to discovered UWB accessories
- **Connection Management**: Connect/disconnect buttons with state-aware UI
- **Error Handling**: Clear error messages for connection issues and Bluetooth states
- **Support Views**:
  - `AccessoryRow`: Device listing with RSSI signal strength
  - `DistanceIndicator`: Visual progress bar for distance metrics
  - `DirectionIndicator`: Compass-style direction visualization

**Files**: `Views/UWBAccessoryView.swift`

## Architecture

### Core Components

```
Indooe nav 4 good/
├── Indooe_nav_4_goodApp.swift      # App entry point
├── Views/
│   ├── TranscriptionView.swift      # Speech input & intent classification UI
│   └── UWBAccessoryView.swift       # UWB discovery & ranging UI
├── ViewModels/
│   ├── SpeechRecognizer.swift       # Speech-to-text engine
│   ├── IntentRouter.swift           # Intent classification & handling
│   ├── OpenRouterChatAPI.swift      # LLM API client
│   ├── UWBAccessoryViewModel.swift  # UWB ranging & discovery
│   ├── SpeechManager.swift          # Text-to-speech engine
│   └── Extention.swift              # Utility extensions
└── SystemPrompt/
    └── Prompt.swift                 # LLM system prompts
```

### Data Flow

1. **User speaks** → SpeechRecognizer captures audio
2. **Transcript generated** → TranscriptionView displays text
3. **Silence detected** (5s timeout) → IntentRouter classifies intent via OpenRouter API
4. **Intent extracted** → Appropriate handler processes the result
5. **Navigation intent** → SpeechManager speaks navigation directions
6. **Parallel UWB tracking** → UWBAccessoryViewModel maintains distance/direction updates

## Technology Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Speech**: Speech Framework (SFSpeechRecognizer)
- **Audio**: AVFoundation (AVAudioEngine, AVSpeechSynthesizer)
- **Positioning**: NearbyInteraction Framework (UWB)
- **Bluetooth**: CoreBluetooth (for UWB accessory discovery)
- **Networking**: URLSession (async/await)
- **LLM API**: OpenRouter (Google Gemini 3 27B It)
- **Environment Config**: SwiftDotenv

## Configuration

### Required Environment Variables

Create a `.env` file in the project root:

```
OPENROUTER_API_KEY=your_openrouter_api_key_here
```

### Supported Languages

- **Speech Recognition**: Cantonese (zh-HK), English (en-US)
- **Text-to-Speech**: English (en-US) by default, customizable per utterance

### UWB Service UUIDs

The app uses standard Nearby Interaction service UUIDs:
- **Service UUID**: `48FE3E40-0817-4BB2-8633-3073689C2DBA`
- **Configuration Characteristic**: `48FE3E42-0817-4BB2-8633-3073689C2DBA`
- **Accessory Config Data Characteristic**: `48FE3E43-0817-4BB2-8633-3073689C2DBA`

## Permissions Required

The app requires the following permissions (configured in Info.plist):

1. **Microphone Access**: For speech recognition (`NSMicrophoneUsageDescription`)
2. **Speech Recognition**: For on-device speech processing (`NSSpeechRecognitionUsageDescription`)
3. **Bluetooth**: For UWB accessory discovery (`NSBluetoothPeripheralUsageDescription`, `NSBluetoothAlwaysUsageDescription`)
4. **Nearby Interaction**: For UWB ranging (implicit with NearbyInteraction framework)

## Testing

### Intent Router Test
- Tap the "Intent Router Test" button in TranscriptionView
- Tests with sample input: "最近嘅washroom喺邊度" (Where is the nearest restroom?)
- Displays classified intent and parameters

### Manual Testing
1. **Speech Recognition**: Grant microphone permission, tap "Start Recording", speak clearly
2. **Intent Classification**: Record speech or use test button to trigger classification
3. **UWB Discovery**: Ensure UWB accessory is nearby and powered on, tap "Scan for UWB Devices"
4. **Speech Output**: Navigation intents automatically trigger voice feedback

## Future Enhancements

- [ ] Support for additional intents (e.g., find_place, get_info)
- [ ] Multi-language support for text-to-speech
- [ ] Caching of intent classifications
- [ ] Real-time map integration for indoor navigation
- [ ] User preference profiles
- [ ] Offline intent classification fallback
- [ ] Advanced gesture controls
- [ ] Accessibility features (haptic feedback, etc.)

## Dependencies

- **SwiftDotenv**: Environment variable management
- **Standard iOS Frameworks**: SwiftUI, Speech, AVFoundation, CoreBluetooth, NearbyInteraction

## Notes

- The app currently uses the free Google Gemini 3 27B model via OpenRouter API
- Speech recognition requires internet connectivity for optimal performance
- UWB functionality requires devices with U1/U2 chip (iPhone 11 Pro and later)
- The app targets Cantonese as the primary language for speech recognition
- 5-second silence timeout is configurable in TranscriptionView

## Contact & Support

For issues, questions, or contributions, please [add contact information].
