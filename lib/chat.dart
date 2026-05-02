import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ⬇️ Put your API key here
const String groqApiKey = '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'; // ⬅️ Put your new Groq key here

const String systemPrompt = '''
You are a smart medical assistant specialized exclusively in diabetes. You speak in simple, clear language that patients can easily understand.

Important rules:
- Always respond in clear and simple language
- Only provide information related to diabetes
- Be accurate and concise (3-5 sentences max)
- Always advise consulting a doctor for major medical decisions
- If the question is outside diabetes scope, kindly redirect the patient
''';

enum MessageRole { user, assistant }

class ChatMessage {
  final String text;
  final MessageRole role;
  ChatMessage({required this.text, required this.role});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF378ADD);
  static const Color darkBlue = Color(0xFF185FA5);
  static const Color lightBlue = Color(0xFFE6F1FB);
  static const Color bgColor = Color(0xFFF5F8FC);

  final List<String> _quickQuestions = [
    'What is the normal blood sugar level?',
    'What foods should diabetics avoid?',
    'How to handle sudden low blood sugar?',
    'When should I visit the doctor urgently?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: 'Hello! 👋 I am your smart assistant specialized in diabetes.\nYou can ask me about medications, diet, blood sugar readings, or anything related to your condition.',
      role: MessageRole.assistant,
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, role: MessageRole.user));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final List<Map<String, String>> history = [
        {'role': 'system', 'content': systemPrompt},
      ];
      for (final msg in _messages) {
        history.add({
          'role': msg.role == MessageRole.user ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': history,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['choices'][0]['message']['content'] as String;
        setState(() {
          _messages.add(ChatMessage(text: reply, role: MessageRole.assistant));
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(
            text: '⚠️ Error: ${error["error"]["message"] ?? "An unexpected error occurred"}',
            role: MessageRole.assistant,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '⚠️ Connection failed. Please check your internet and try again.',
          role: MessageRole.assistant,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_messages.length == 1) _buildQuickQuestions(),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputArea(),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                '⚠️ For informational purposes only — always consult your doctor',
                style: TextStyle(fontSize: 11, color: Color(0xFF7A9AB8)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.monitor_heart_outlined, color: darkBlue, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diabetes AI Assistant',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0D1828)),
                ),
                Text(
                  'Ask me anything about your condition',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A9AB8), fontWeight: FontWeight.normal),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 6, spreadRadius: 2),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: const Color(0xFFE0EAF4)),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isBot = msg.role == MessageRole.assistant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isBot ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 4, left: 4),
            child: Text(
              isBot ? 'Assistant' : 'You',
              style: const TextStyle(fontSize: 11, color: Color(0xFF7A9AB8)),
            ),
          ),
          Align(
            alignment: isBot ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? lightBlue : primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isBot ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isBot ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: isBot ? const Color(0xFF0C447C) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE0EAF4), width: 0.5)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _quickQuestions.map((q) {
          return GestureDetector(
            onTap: () => _sendMessage(q),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryBlue.withOpacity(0.25)),
              ),
              child: Text(
                q.length > 25 ? '${q.substring(0, 25)}...' : q,
                style: const TextStyle(fontSize: 12, color: darkBlue, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0EAF4), width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type your question here...',
                hintStyle: const TextStyle(color: Color(0xFF7A9AB8), fontSize: 14),
                filled: true,
                fillColor: bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE0EAF4), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE0EAF4), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: primaryBlue, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}