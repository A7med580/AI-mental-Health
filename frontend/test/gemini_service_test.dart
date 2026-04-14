import 'package:flutter_test/flutter_test.dart';
import 'package:mindful/services/gemini_service.dart';

void main() {
  test('GeminiService sendMessage returns a valid response', () async {
    final geminiService = GeminiService();
    
    // Testing with a simple message
    final response = await geminiService.sendMessage('Hello');
    
    print('Gemini Test Response: $response');
    
    expect(response, isNotEmpty);
    expect(response, isA<String>());
  });

  test('GeminiService maintains conversation history', () async {
    final geminiService = GeminiService();
    geminiService.resetConversation();
    
    await geminiService.sendMessage('My name is Ali.');
    final response = await geminiService.sendMessage('What is my name?');
    
    print('Gemini History Test Response: $response');
    
    expect(response.toLowerCase(), contains('ali'));
  });
}
