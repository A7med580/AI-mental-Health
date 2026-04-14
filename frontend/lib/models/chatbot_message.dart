class ChatbotMessage {
  final String id;
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime timestamp;
  final String moduleType;

  ChatbotMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    required this.moduleType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
      'moduleType': moduleType,
    };
  }

  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    return ChatbotMessage(
      id: json['id'],
      content: json['content'],
      role: json['role'],
      timestamp: DateTime.parse(json['timestamp']),
      moduleType: json['moduleType'],
    );
  }
}
