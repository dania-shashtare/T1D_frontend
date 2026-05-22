import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId; // patient userId
  final String receiverId; // doctor/nutritionist userId
  final String receiverName;
  final String receiverRole; // doctor أو nutritionist

  const ChatPage({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverRole,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return 'http://10.0.2.2:5000/api';
  }

  List messages = [];
  bool isLoading = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/messages/${widget.currentUserId}/${widget.receiverId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          messages = data;
          isLoading = false;
        });

        _scrollToBottom();
      } else {
        setState(() {
          isLoading = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load messages')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading messages: $e')));
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;
    if (isSending) return;

    setState(() {
      isSending = true;
    });

    messageController.clear();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': widget.currentUserId,
          'receiverId': widget.receiverId,
          'message': text,
        }),
      );

      if (response.statusCode == 201) {
        await fetchMessages();
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message was not sent')));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/messages/$messageId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.currentUserId}),
      );

      if (response.statusCode == 200) {
        await fetchMessages();
      } else {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to delete message'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting message: $e')));
    }
  }

  void confirmDeleteMessage(Map msg) {
    final bool isMe = msg['senderId'].toString() == widget.currentUserId;

    if (!isMe) return;

    final String messageId = msg['_id']?.toString() ?? '';

    if (messageId.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete message?'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await deleteMessage(messageId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color getAvatarBackgroundColor(String name) {
    final colors = [
      const Color(0xFFDCE8F8),
      const Color(0xFFD9F0E8),
      const Color(0xFFE8E0F8),
      const Color(0xFFFCE6D6),
      const Color(0xFFF9E0E8),
      const Color(0xFFE2F1FB),
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  Color getAvatarTextColor(String name) {
    final colors = [
      const Color(0xFF2C72D6),
      const Color(0xFF178E6B),
      const Color(0xFF6A5ACD),
      const Color(0xFFD07A2D),
      const Color(0xFFC14E7A),
      const Color(0xFF2678A8),
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  Widget buildChatAvatar(String name) {
    final bgColor = getAvatarBackgroundColor(name);
    final textColor = getAvatarTextColor(name);
    final initials = getInitials(name);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF2ECC71),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLargeChatAvatar(String name) {
    final bgColor = getAvatarBackgroundColor(name);
    final textColor = getAvatarTextColor(name);
    final initials = getInitials(name);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF2ECC71),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';

    try {
      final date = DateTime.parse(createdAt.toString()).toLocal();

      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Widget _messageBubble(Map msg) {
    final bool isMe = msg['senderId'].toString() == widget.currentUserId;

    final String messageText = msg['message']?.toString() ?? '';
    final String timeText = _formatTime(msg['createdAt']);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          confirmDeleteMessage(msg);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF1976C9) : const Color(0xFFE1F1FF),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                messageText,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFF0B4F8A),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              if (timeText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  timeText,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.blueGrey.shade400,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildLargeChatAvatar(widget.receiverName),
            const SizedBox(height: 14),
            Text(
              'Start your conversation with ${widget.receiverName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0B4F8A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send your first message below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.blueGrey.shade300),
                  filled: true,
                  fillColor: const Color(0xFFF0F8FF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 24,
              backgroundColor: isSending
                  ? Colors.grey.shade400
                  : const Color(0xFF1976C9),
              child: IconButton(
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                onPressed: isSending ? null : sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4F8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            buildChatAvatar(widget.receiverName),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.receiverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: fetchMessages,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];

                      if (msg is Map<String, dynamic>) {
                        return _messageBubble(msg);
                      }

                      if (msg is Map) {
                        return _messageBubble(msg);
                      }

                      return const SizedBox.shrink();
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
