# Overview 
This directory contains the core UI screens of the Mindful application. It specifically manages the various screening flows (Autism, ADHD, Depression), chatbot interfaces, data processing states, and result presentations.

# Primary Files & Responsibilities

* **`initial_questionnaire_screen.dart`**: The entry point for triage. It collects user information and routes them sequentially or conditionally to specific condition screening flows based on responses or backend logic.
* **`depression_questionnaire_screen.dart`**: Implements the DAIC-WOZ video-based interview flow for depression screening.
* **`depression_result_screen.dart`**: Displays the multimodal analysis results for depression (Voice, Facial, Text), leveraging backend data.
* **`adhd_chat_screen.dart`**: A specialized chat interface for ADHD screening, capturing text and audio data to send to the backend.
* **`adhd_result_screen.dart`**: Displays the ADHD likelihood score and broken-down metrics (Response Time, Text Complexity, etc.).
* **`autism_questionnaire_screen.dart`**: Implements the textual AQ-10 assessment combined with optional webcam facial feature extraction.
* **`screening_chat_screen.dart`**: General purpose Gemini 2.0 interface for standard Mindful companion chats, pulling from `GeminiService`.
* **`processing_screen.dart`**: An intermediate loading screen that polls the backend `JobService` while machine learning pipelines generate results.
* **`player_screen.dart`**: A dedicated UI for the Wellness/Meditation hub for streaming `audio_waveforms` tracks.
* **`video_preview_screen.dart`**: A utility screen allowing users to review video recordings (e.g., from the depression questionnaire) before submission.
* **`notifications_screen.dart`**: Handles the display of pushed and local notifications.

# Key Logic Flow & Edge Cases

1. **Routing flow:** Starts at `initial_questionnaire_screen.dart` -> triage logic triggers either specialized questionnaires (`depression_`, `autism_`) or chat flows (`adhd_`, `screening_`). 
2. **Asynchronous ML Submissions:** Screens like `depression_questionnaire_screen.dart` collect large media files (video/audio) and submit them to `backend`. They then navigate to `processing_screen.dart`, which polls until the job achieves a `completed` or `failed` state.
3. **Edge Case Handoffs:** If a screening requires heavy processing or timeouts, the app leverages `JobService` to persist state, allowing the user to back out and be notified once ready.
4. **Media Handling:** Screens utilizing audio/video implement careful resource management (stopping cameras and parsers on `dispose()`) to prevent memory leaks in the Flutter engine.
