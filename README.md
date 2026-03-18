# Fluency — AI-Powered Language Mastery 🌐🚀

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Fluency is a state-of-the-art language learning application designed to bridge the gap between learning and mastery. Leveraging the power of artificial intelligence, Fluency provides an immersive, interactive, and personalized experience to help users excel in **Listening, Speaking, Reading, and Writing**.

---

## ✨ Key Features

### 🤖 Intelligent AI Tutoring
- **Dynamic Explanations**: Get instant, deep-dive explanations for complex grammar and vocabulary.
- **Speech Mastery**: Real-time feedback on pronunciation and fluency during interactive drills.
- **Contextual Learning**: AI-driven scenarios that adapt to your learning pace and style.

### 📚 Comprehensive Curriculum
- **Structured Lessons**: Carefully curated modules covering real-world topics.
- **Integrated Quizzes**: Diverse quiz types including Gap Fill, Matching, and Multiple Choice.
- **Transcript Interaction**: Seek audio instantly by clicking on timestamps in the transcript.

### 🃏 Active Recall & Spaced Repetition
- **Smart Flashcards**: Efficiently memorize vocabulary with our specialized flashcard system.
- **Bookmark System**: Save and organize difficult terms into custom collections for targeted review.

### 🌓 Premium User Experience
- **Adaptive Design**: Fully optimized for both Light and Dark modes with a high-end aesthetic.
- **Fluid Interactions**: Smooth micro-animations and intuitive navigation for a seamless learning flow.

---

## 🏗️ Technical Architecture

Fluency is built with scalability and performance in mind:
- **Framework**: [Flutter](https://flutter.dev) for multi-platform consistency.
- **State Management**: [Provider](https://pub.dev/packages/provider) for clean, reactive data flow.
- **Theming**: Custom `AppColorsExtension` for robust and flexible design tokens.
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) for declarative routing.

---

## � Getting Started

### Prerequisites
Before you dive in, ensure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- [Dart SDK](https://dart.dev/get-started/sdk)
- Android Studio / VS Code with Flutter extensions

### Installation
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/KhanhRomVN/Fluency.git
    cd Fluency
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the app**:
    ```bash
    flutter run
    ```

---

## � Deployment & Building

To prepare the application for release on the **Google Play Store**, follow these deployment steps:

### ⚙️ Hardware Environment Prep (Linux)
If you are developing on Linux and encounter hardware conflicts (e.g., camera/video issues), you can use the following command to temporarily isolate video devices:
```bash
sudo chmod 000 /dev/video*
```

### 🏗️ Build App Bundle (AAB) & Obfuscation
To generate a clean production build with Dart code obfuscation (to prevent reverse engineering):
```bash
flutter clean && flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols
```

*   `--obfuscate`: Hides symbol names in your Dart code.
*   `--split-debug-info`: Required when obfuscating. It saves the symbol map to the specified directory so you can still de-obfuscate crash logs later.
*   *The generated bundle will be located at: `build/app/outputs/bundle/release/app-release.aab`*

---

## 🎨 Design Philosophy

We believe that a beautiful app inspires better learning. Fluency follows **Material Design 3** principles combined with custom high-fidelity components to create a "glassmorphism" inspired dark mode and vibrant accent pallets that reduce cognitive load while keeping the user engaged.

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

## 👤 Author

Developed with ❤️ by **Khánh** (KhanhRomVN)
- [GitHub](https://github.com/KhanhRomVN)

*© 2026 Fluency Mastery. Elevating your language journey.*