# EchoInterview

### Your AI-Powered Interview Practice Companion 🎤🧠

Practice makes perfect, and **EchoInterview** is here to help you nail that next job interview! This iOS app lets you rehearse interview questions, get real-time speech analysis, and receive AI-generated feedback — all from the comfort of your iPhone.

---

## What Does It Do? 🤔

Ever felt nervous before an interview? EchoInterview acts as your personal interview coach:

1. **Asks You Questions** — The app generates contextual interview questions (powered by on-device AI when available)
2. **Listens to Your Answers** — Real-time speech-to-text transcription captures what you say
3. **Analyzes Your Response** — NLP metrics evaluate clarity, pace, filler words, and more
4. **Scores Your Performance** — A CoreML model rates your answer quality
5. **Gives You Tips** — AI-generated coaching suggestions help you improve

Think of it as having a patient interviewer who never judges, always provides constructive feedback, and is available 24/7!

---

## Features ✨

| Feature | Description |
|---------|-------------|
| 🎙️ **Speech Recognition** | Real-time transcription of your spoken answers |
| 🗣️ **Text-to-Speech** | Questions are read aloud with customizable voice & speed |
| 📊 **NLP Analysis** | Measures word count, speech rate, filler words, sentence structure |
| 🤖 **ML Scoring** | CoreML model evaluates answer quality across multiple dimensions |
| 💡 **AI Coaching** | Foundation Models generate personalized improvement tips |
| 📈 **Analytics Dashboard** | Visual breakdown of your performance with score charts |
| 📚 **Session History** | SwiftData persistence stores all your practice sessions |
| ⚙️ **Customizable Settings** | Choose your preferred voice, adjust speech rate |
| 🎨 **Animated UI** | Smooth waveform animations and haptic feedback |
| 🚀 **Onboarding Flow** | Guided setup for permissions and voice testing |

---

## Screenshots 📱
<img width="330" height="717" alt="Simulator Screenshot - iPhone 17 Pro Max - 2026-02-01 at 21 08 35" src="https://github.com/user-attachments/assets/5d657446-d6ae-425e-89c0-2640b17c3a10" />

<img width="330" height="717" alt="Simulator Screenshot - iPhone 17 Pro Max - 2026-02-01 at 21 08 57" src="https://github.com/user-attachments/assets/7af67f77-d35f-4aba-aa9f-41615d6614d2" />

<img width="330" height="717" alt="Simulator Screenshot - iPhone 17 Pro Max - 2026-02-01 at 21 09 26" src="https://github.com/user-attachments/assets/ea2fd918-3830-46f1-b563-eed7466ef423" />

---

## Tech Talk 🛠️

EchoInterview is built with modern Swift and SwiftUI, following best practices for iOS 17+ development.

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                      Views                          │
│  (SwiftUI, declarative UI, animations)              │
├─────────────────────────────────────────────────────┤
│                   ViewModels                        │
│  (@Observable, @MainActor, business logic)          │
├─────────────────────────────────────────────────────┤
│                    Services                         │
│  (Actors, protocol-based, dependency injection)     │
├─────────────────────────────────────────────────────┤
│                Apple Frameworks                     │
│  (Speech, AVFoundation, CoreML, SwiftData, etc.)    │
└─────────────────────────────────────────────────────┘
```

### Key Technical Highlights

- **MVVM Architecture** — Clean separation with `@Observable` ViewModels
- **Swift Concurrency** — Async/await throughout, actor-isolated services
- **Protocol-Oriented** — All services defined by protocols for testability
- **Dependency Injection** — ServiceContainer provides dependencies
- **No Singletons in Views** — Dependencies passed explicitly
- **SwiftData** — Modern persistence for session history
- **CoreML** — On-device ML model for answer scoring
- **Foundation Models** — Apple's on-device LLM for question/tip generation
- **Zero Force Unwraps** — Safe optional handling everywhere

### Frameworks & Technologies Used

| Technology | Purpose |
|------------|---------|
| **SwiftUI** | Declarative UI with animations |
| **Swift Concurrency** | Async/await, actors, structured concurrency |
| **Speech Framework** | Real-time speech recognition |
| **AVFoundation** | Audio recording and text-to-speech |
| **NaturalLanguage** | NLP analysis (tokenization, embeddings) |
| **CoreML** | Machine learning model inference |
| **Foundation Models** | On-device LLM (iOS 18+) |
| **SwiftData** | Persistence layer |
| **os.log** | Structured logging |

### Project Structure

```
EchoInterview/
├── Core/
│   ├── AppState.swift          # Global app state
│   └── Router.swift            # Navigation management
├── Models/
│   ├── Answer.swift            # Answer data model
│   ├── Question.swift          # Question data model
│   ├── NLPMetrics.swift        # NLP analysis results
│   ├── AnswerScores.swift      # Scoring results
│   └── InterviewSessionEntity.swift  # SwiftData entity
├── Services/
│   ├── AudioService.swift      # Microphone recording
│   ├── SpeechRecognitionService.swift  # Speech-to-text
│   ├── TextToSpeechService.swift       # Text-to-speech
│   ├── NLPAnalysisService.swift        # NLP processing
│   ├── ScoringProtocol.swift   # Scoring abstraction
│   ├── CoreMLScoringService.swift      # ML-based scoring
│   ├── SimpleScoringService.swift      # Fallback scoring
│   ├── LLMService.swift        # AI question/tip generation
│   ├── PersistenceService.swift        # SwiftData operations
│   └── ServiceContainer.swift  # Dependency container
├── ViewModels/
│   ├── InterviewSessionViewModel.swift
│   ├── AnalyticsViewModel.swift
│   ├── HistoryViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── InterviewRoomView.swift
│   ├── AnalyticsView.swift
│   ├── HistoryView.swift
│   ├── SettingsView.swift
│   ├── OnboardingView.swift
│   └── Components/
│       └── WaveformView.swift
├── Features/
│   ├── Dashboard/
│   └── AudioTest/
└── Resources/
    ├── AnswerQualityModel.mlmodel
    └── Localizable.xcstrings
```

---

## The ML Magic 🪄

The app includes a custom CoreML model (`AnswerQualityModel.mlmodel`) trained to evaluate interview answer quality. It considers:

- **Clarity** — How clear and structured is the response?
- **Confidence** — Does the speaker sound confident?
- **Technical Depth** — Is there substance to the answer?
- **Pace** — Is the speaking rate appropriate?

The model was trained on interview transcript data and outputs scores from 0-100 for each dimension.

---

## Getting Started 🚀

### Requirements

- iOS 17.0+
- Xcode 15.0+
- iPhone with microphone (Simulator has limited audio support :7)

### Setup

1. Clone the repository
2. Open `EchoInterview.xcodeproj` in Xcode
3. Build and run on a physical device (recommended for full audio/speech functionality)
4. Grant microphone and speech recognition permissions when prompted

### First Launch

The app includes an onboarding flow that will:
1. Welcome you to the app
2. Request microphone permission
3. Request speech recognition permission
4. Test your voice with a quick recording
5. Get you ready to practice!

---

## ⚠️ Disclaimer

**This is a practice/learning project!** 

EchoInterview was built as an exploration of modern iOS development patterns including:
- SwiftUI animations
- On-device ML/AI
- Speech and audio processing

### What This Means:

- 🔨 **Work in Progress** — Features may be incomplete or buggy
- 🧪 **Experimental** — Some implementations are exploratory
- 📚 **Learning Exercise** — Code prioritizes learning over production-readiness
- 🚧 **Rough Edges** — UI/UX could use more polish
- 🐛 **Known Issues** — There are bugs, and that's okay!

This project is **not** intended for production use or App Store distribution. It's a sandbox for learning and experimentation.

---

## What I Learned 📖

Building this project provided hands-on experience with:

- Integrating multiple Apple frameworks (Speech, AVFoundation, CoreML, NaturalLanguage)
- Managing complex async flows with Swift Concurrency
- Building responsive UI with SwiftUI animations
- Training and deploying CoreML models
- Using Foundation Models for on-device AI
- Implementing proper MVVM architecture with `@Observable`
- Handling audio format compatibility issues
- SwiftData for modern persistence

---

## Future Ideas 💭

If this were to become a real app:

- [ ] More interview question categories (behavioral, technical, case studies)
- [ ] Video recording for body language analysis
- [ ] Progress tracking over time
- [ ] Mock interview sessions with time limits
- [ ] Export/share session reports
- [ ] iPad support
- [ ] watchOS companion for quick practice

---

## Contributing 🤝

This is a personal learning project, but if you'd like to:
- Report a bug
- Suggest an improvement
- Share feedback

Feel free to open an issue or reach out!

---

## License 📄

This project is for educational purposes. Feel free to explore, learn from, and build upon it.

---

## Final Thoughts 💭

EchoInterview started as a "what if" experiment — what if your phone could be your interview coach? While it's far from perfect, building it was a fantastic journey through modern iOS development.

Whether you're here to learn, to contribute, or just curious about how it all works — welcome! 🎉

*Now go practice that interview and land your dream job!* 🚀

---

<p align="center">
  <i>Built with ☕ and curiosity</i>
</p>
