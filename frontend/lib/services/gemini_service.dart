import 'dart:convert';
import 'package:http/http.dart' as http;

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

  void resetConversation() {
    _history.clear();
  }

  Future<String> sendMessage(String userMessage) async {
    if (_history.isEmpty) {
      // First turn: Add the system prompt to history so Gemini knows its persona
      final systemPrompt = "You are MindCare AI, a warm, supportive, and empathetic friend in a mental health application. The user is talking to you about their feelings, mental health, or general life. Listen actively, offer gentle, uplifting advice, and be observational. DO NOT act like a strict clinical diagnostician or a rigid form. Be conversational. Keep responses concise and natural. Use encouraging words.";
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
}
