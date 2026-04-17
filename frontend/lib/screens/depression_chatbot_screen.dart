import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/models/chatbot_message.dart';
import 'package:mindful/services/gemini_service.dart';
import 'package:mindful/theme/module_themes.dart';
import 'package:mindful/widgets/page_transitions.dart';
import 'package:mindful/screens/processing_screen.dart';

class DepressionChatbotScreen extends StatefulWidget {
  final Map<String, dynamic> questionnaireAnswers;

  const DepressionChatbotScreen({
    Key? key,
    required this.questionnaireAnswers,
  }) : super(key: key);

  @override
  State<DepressionChatbotScreen> createState() => _DepressionChatbotScreenState();
}

class _DepressionChatbotScreenState extends State<DepressionChatbotScreen> {
  final List<ChatbotMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  int _questionCount = 0;
  final int _maxQuestions = 6;
  
  final String _initialQuestion = "How has your mood been lately? I'm here to listen.";

  @override
  void initState() {
    super.initState();
    _addAssistantMessage(_initialQuestion);
  }

  void _addAssistantMessage(String content) {
    setState(() {
      _messages.add(ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: 'assistant',
        timestamp: DateTime.now(),
        moduleType: 'depression',
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String content) {
    setState(() {
      _messages.add(ChatbotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: 'user',
        timestamp: DateTime.now(),
        moduleType: 'depression',
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    _addUserMessage(text);
    _questionCount++;

    if (_questionCount >= _maxQuestions) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final followUp = await GeminiService().generateChatbotQuestion(text, 'depression', _questionCount);
      if (mounted) {
        setState(() => _isLoading = false);
        if (followUp != null && followUp.isNotEmpty) {
          _addAssistantMessage(followUp);
        } else {
          _addAssistantMessage("Thank you for sharing. Could you tell me a bit more about how this affects your daily routine?");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _addAssistantMessage("Unable to load next question. You can keep sharing, or skip to finish.");
      }
    }
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      AppPageRoute(
        page: ProcessingScreen(
          videoFile: null,
          questionnaireData: {
            'condition': 'depression',
            ...widget.questionnaireAnswers,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = _questionCount >= _maxQuestions;

    return Scaffold(
      backgroundColor: depressionTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(depressionTheme.icon, size: 18, color: depressionTheme.accentColor),
            const SizedBox(width: 8),
            Text('Depression Chat', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.role == 'user';
                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser ? depressionTheme.accentColor.withValues(alpha: 0.9) : AppColors.cardWhite,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Text(
                          msg.content,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: isUser ? Colors.white : AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Typing...', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: AppColors.cardWhite,
              child: isDone
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: depressionTheme.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _finish,
                        child: Text('Finish & See Results', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _textController,
                              decoration: InputDecoration(
                                hintText: 'Type your response...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                              ),
                              onSubmitted: (_) => _handleSend(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _handleSend,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: depressionTheme.accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                        if (_messages.length > 2)
                           Padding(
                             padding: const EdgeInsets.only(left: 8.0),
                             child: GestureDetector(
                               onTap: _finish,
                               child: Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: AppColors.surfaceLight,
                                   shape: BoxShape.circle,
                                 ),
                                 child: const Icon(Icons.skip_next, color: AppColors.textSecondary, size: 20),
                               ),
                             ),
                           )
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
