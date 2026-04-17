import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mindful/services/chat_storage_service.dart';
import 'package:mindful/core/config/api_config.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal();

  // The conversation history sent to the API
  List<Map<String, dynamic>> _history = [];
  
  // Update with the provided API key
  final String _apiKey = "AIzaSyAChhohhZY6icUBjdXYULU4WT0ZnijZ5es";
  final String _apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent";

  /// Whether the conversation has been initialized (system prompt sent).
  bool get hasHistory => _history.isNotEmpty;

  void resetConversation() {
    _history.clear();
  }

  /// Rebuild the Gemini API _history from a list of persisted ChatMessages.
  /// This allows the AI to retain context from previous sessions.
  void restoreFromHistory(List<ChatMessage> messages) {
    _history.clear();

    // Filter out error messages — they aren't real conversation turns
    final validMessages = messages.where((m) => !m.isError).toList();
    if (validMessages.isEmpty) return;

    // Add system prompt pair first
    final systemPrompt = "You are MindCare AI, a warm, supportive, and empathetic friend in a mental health application. The user is talking to you about their feelings, mental health, or general life. Listen actively, offer gentle, uplifting advice, and be observational. DO NOT act like a strict clinical diagnostician or a rigid form. Be conversational. Keep responses concise and natural. Use encouraging words.";
    _history.add({
      "role": "user",
      "parts": [{"text": systemPrompt}],
    });
    _history.add({
      "role": "model",
      "parts": [{"text": "Understood. I will act as a warm and compassionate companion."}],
    });

    // Rebuild conversation turns from saved messages
    // Skip the initial bot greeting (first bot message) since the system prompt covers it
    for (final msg in validMessages) {
      if (msg.isBot) {
        // Skip the initial welcome message (it's already handled by system prompt)
        if (msg.text == "Hello! I am MindCare AI. I am here to listen to you.") continue;
        _history.add({
          "role": "model",
          "parts": [{"text": msg.text}],
        });
      } else {
        _history.add({
          "role": "user",
          "parts": [{"text": msg.text}],
        });
      }
    }
  }

  Future<String> sendMessage(String userMessage) async {
    if (_history.isEmpty) {
      // First turn: Add the system prompt to history so Gemini knows its persona
      final systemPrompt = "You are Mindful AI, a warm, supportive, and empathetic friend in a mental health application. The user is talking to you about their feelings, mental health, or general life. Listen actively, offer gentle, uplifting advice, and be observational. DO NOT act like a strict clinical diagnostician or a rigid form. Be conversational. Keep responses concise and natural. Use encouraging words.";
      _history.add({
        "role": "user",
        "parts": [{"text": systemPrompt}],
      });
      _history.add({
        "role": "model",
        "parts": [{"text": "Understood. I will act as a warm and compassionate companion."}],
      });
    }

    // Add user message to history
    _history.add({
      "role": "user",
      "parts": [{"text": userMessage}],
    });

    final body = jsonEncode({
      "contents": _history,
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidate = data['candidates']?.first;
        final content = candidate?['content'];
        final textResponse = content?['parts']?.first?['text'] ?? '';

        // Add model response to history
        _history.add({
          "role": "model",
          "parts": [{"text": textResponse}],
        });

        return textResponse;
      } else {
        print('Gemini API Error Response: ${response.body}');
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e) {
      print('Gemini Exception: $e');
      _history.removeLast(); // Remove the user message that caused failure
      throw Exception('Error communicating with AI: $e');
    }
  }

  Future<String?> generateChatbotQuestion(
      String userResponse, String moduleType, int questionNumber) async {
    try {
      final apiKey = ApiConfig.getGeminiApiKey();
      if (apiKey == 'TO_BE_SET_BY_USER' || apiKey.isEmpty) {
        print('Gemini API key not configured.');
        return null;
      }
      
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

      final prompt = '''
You are a mental health pre-screening assistant for the $moduleType module.
The user has just answered question $questionNumber.
Their response was: "$userResponse"

Please generate a short, empathetic, natural follow-up question (1-2 sentences maximum) to lightly explore their response before moving on.
Do NOT give medical advice or diagnose. Just ask a conversational follow-up question.
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
             'temperature': 0.7,
             'maxOutputTokens': 100,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
            final text = content['parts'][0]['text'];
            return text?.trim();
          }
        }
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('GeminiService Error: $e');
      return null;
    }
  }
}
