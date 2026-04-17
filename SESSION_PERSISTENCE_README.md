# Session Persistence & Chat History — Implementation Guide

## Overview

This document explains how **auth session persistence** and **chat history persistence** are implemented in the MindCare AI mobile application. Both features ensure that users have a seamless experience without needing to log in every time they open the app and without losing their chat history when navigating away.

---

## 1. Auth Session Persistence

### How It Works

Supabase Flutter SDK automatically persists auth tokens (access + refresh) in secure local storage when a user signs in. We leverage this built-in behavior by checking for an existing session at app startup.

### Flow Diagram

```
App Launch
    │
    ▼
┌─────────────────┐
│  Splash Screen   │  (3-second animated splash)
│  splash_screen   │
└────────┬────────┘
         │
         ▼
┌────────────────────────────┐
│ Check Supabase Session     │
│ currentSession != null ?   │
└────────┬───────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
  [YES]     [NO]
    │         │
    ▼         ▼
Dashboard   Login
 Screen     Page
```

### Key Files

| File | Role |
|------|------|
| `lib/splash_screen.dart` | Checks `Supabase.instance.client.auth.currentSession` after splash animation. Routes to Dashboard or Login accordingly. |
| `lib/login_page.dart` | On successful login, uses `pushNamedAndRemoveUntil` to clear the navigation stack (prevents back-button returning to login). |
| `lib/profile_screen.dart` | Logout calls `supabase.auth.signOut()` which clears the persisted session tokens. |

### How Sessions Are Stored

- **Storage mechanism**: Supabase Flutter SDK uses `flutter_secure_storage` (iOS Keychain / Android Keystore) internally.
- **Token refresh**: Supabase automatically refreshes expired access tokens using the stored refresh token.
- **Session clearing**: Calling `supabase.auth.signOut()` removes all stored tokens.

### Login → Dashboard Navigation

After a successful login, the app uses:
```dart
Navigator.pushNamedAndRemoveUntil(context, '/chat', (route) => false);
```
This removes all previous routes from the stack, so pressing the back button won't return the user to the login page.

### Logout Flow

```dart
await supabase.auth.signOut();
Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
```
This clears the auth session and navigates to login, removing all routes.

---

## 2. Chat History Persistence

### How It Works

Chat messages are saved to **SharedPreferences** (local device storage) after every message exchange. When the user returns to the chat screen, messages are loaded and the Gemini AI context is restored.

### Flow Diagram

```
Open Chat Screen
       │
       ▼
┌──────────────────────┐
│ ChatStorageService    │
│ loadChatHistory()     │
└──────────┬───────────┘
           │
      ┌────┴────┐
      │         │
      ▼         ▼
  [Has History]  [No History]
      │              │
      ▼              ▼
  Load saved     Show welcome
  messages       message only
      │
      ▼
┌──────────────────────┐
│ GeminiService         │
│ restoreFromHistory()  │  ← Rebuilds AI context
└──────────────────────┘
```

### Key Files

| File | Role |
|------|------|
| `lib/services/chat_storage_service.dart` | **NEW** — Handles saving/loading/clearing chat messages via SharedPreferences. Messages are keyed per-user. |
| `lib/services/gemini_service.dart` | **MODIFIED** — Added `restoreFromHistory()` to rebuild Gemini API context from saved messages. |
| `lib/chat_screen.dart` | **MODIFIED** — Loads history on init, saves after each exchange, includes "New Chat" button. |

### ChatMessage Model

```dart
class ChatMessage {
  final String text;      // The message content
  final bool isBot;       // true = AI response, false = user message
  final bool isError;     // true = error message (not sent to AI context)
  final DateTime timestamp;
}
```

Messages are serialized to JSON and stored as a `StringList` in SharedPreferences.

### Per-User Storage

Messages are stored with a key that includes the Supabase user ID:

```
Key format: chat_history_{userId}
Example:    chat_history_abc123-def456-...
```

This ensures that if multiple users share a device, their chat histories remain completely separate.

### Save/Load Cycle

```
User sends message
        │
        ▼
  GeminiService.sendMessage()
        │
        ▼
  AI response received
        │
        ▼
  ChatStorageService.saveChatHistory(messages)
        │
        ▼
  Messages persisted to SharedPreferences
```

### "New Chat" Button

The chat header includes a "New" button that:
1. Shows a confirmation dialog (if messages exist)
2. Calls `ChatStorageService.clearChatHistory()` to remove saved messages
3. Calls `GeminiService().resetConversation()` to clear AI context
4. Resets the UI to show only the welcome message

### Gemini Context Restoration

When loading saved messages, `GeminiService.restoreFromHistory()`:
1. Clears any existing API history
2. Re-injects the system prompt (MindCare AI persona)
3. Rebuilds user/model message pairs from saved messages
4. Skips error messages (they don't represent real conversation turns)
5. Skips the initial welcome greeting (already covered by system prompt)

This means the AI **remembers the full conversation context** even after the app is closed and reopened.

---

## 3. Dependencies

| Package | Purpose |
|---------|---------|
| `supabase_flutter` | Auth session persistence (built-in secure storage) |
| `shared_preferences` | Chat history local storage |

Both packages were already in `pubspec.yaml` — no new dependencies were added.

---

## 4. Testing Checklist

- [ ] **Auth persistence**: Log in → close app → reopen → should go to Dashboard (not Login)
- [ ] **Chat persistence**: Send messages → leave chat → return → messages should still be there
- [ ] **New Chat**: Tap "New" button → confirm → messages clear, fresh conversation starts
- [ ] **Logout resets auth**: Logout → reopen app → should show Login page
- [ ] **Multi-user isolation**: User A chats → logout → User B logs in → should see empty/separate history
- [ ] **AI context**: Send messages → close app → reopen → send follow-up message → AI should remember context

---

## 5. Architecture Summary

```
┌─────────────────────────────────────────────────┐
│                   Flutter App                    │
│                                                  │
│  ┌──────────────┐    ┌─────────────────────┐    │
│  │ SplashScreen  │───▶│  Supabase Auth SDK   │    │
│  │ (session      │    │  (auto-persisted     │    │
│  │  check)       │    │   tokens in Keychain) │    │
│  └──────────────┘    └─────────────────────┘    │
│                                                  │
│  ┌──────────────┐    ┌─────────────────────┐    │
│  │ ChatScreen    │───▶│ ChatStorageService   │    │
│  │ (UI + logic)  │    │ (SharedPreferences)  │    │
│  └──────┬───────┘    └─────────────────────┘    │
│         │                                        │
│         ▼                                        │
│  ┌──────────────┐                                │
│  │ GeminiService │  (API context restored        │
│  │ (AI chat)     │   from persisted messages)    │
│  └──────────────┘                                │
└─────────────────────────────────────────────────┘
```
