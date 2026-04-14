# Overview
This directory provides the interface between the Flutter UI and external resources (FastAPI, Gemini AI, and Device Storage).

# Primary Files & Responsibilities

* **`job_service.dart`**: Manages communication with the FastAPI `/jobs` endpoints. Handles multipart model submissions (video + JSON) and implements `pollJobUntilDone` using exponential backoff.
* **`gemini_service.dart`**: Wraps the Google Generative AI Dart SDK. Manages the **Mindful AI** companion sessions, handling history persistence and condition-specific system prompts.
* **`video_storage_service.dart`**: Platform-specific (iOS/Android) file management for saving, retrieving, and cleaning up clinical interview recordings to prevent disk bloat.
* **`api_config.dart`**: Centralized network configuration. Point `baseUrl` here when switching between local/staging environments.

# Key Logic Flow & Edge Cases

1. **Job Polling:** `job_service.dart` uses a robust polling mechanism. It handles `queued` -> `processing` -> `completed` states, allowing the UI to reflect granular progress to the user.
2. **Connectivity Errors:** All service calls wrap `http` requests in custom `MindfulApiClient` wrappers to handle timeouts and JSON parsing failures gracefully.
3. **Chat Session Persistence:** `GeminiService` maintains local history buffers to provide context for follow-up questions while ensuring memory usage stays within mobile constraints.
