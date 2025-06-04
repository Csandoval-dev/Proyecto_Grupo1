import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chatbot_message.dart';
import '../models/chat_conversation.dart';
import '../services/chatbot_service.dart';
import '../widgets/conversation_list.dart';
import '../widgets/chat_message.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbotService = ChatbotService();
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<ChatConversation> _conversations = [];
  String _currentConversationId = '';
  bool _isLoading = false;
  String _userName = 'Usuario';
  bool _showConversationList = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final name = await _chatbotService.getUserName(userId);
    setState(() {
      _userName = name;
    });
  }

  void _loadConversations() {
    _chatbotService.getConversations(userId).listen((conversations) {
      setState(() {
        _conversations = conversations;
        if (_currentConversationId.isEmpty && conversations.isNotEmpty) {
          _currentConversationId = conversations.first.id;
        }
      });
    });
  }

  void _startNewChat() async {
    final newConversation = await _chatbotService.createNewConversation(userId);
    setState(() {
      _currentConversationId = newConversation.id;
      if (!_conversations.any((conv) => conv.id == newConversation.id)) {
        _conversations = [newConversation, ..._conversations];
      }
    });
  }

  void _deleteConversation(String conversationId) async {
    await _chatbotService.deleteConversation(userId, conversationId);
    if (_currentConversationId == conversationId && _conversations.length > 1) {
      setState(() {
        _currentConversationId = _conversations
            .where((conv) => conv.id != conversationId)
            .first
            .id;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    final userMessage = ChatbotMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isLoading = true;
      final tempBotMessage = ChatbotMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        message: '',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      final currentConversation = _conversations.firstWhere(
        (conv) => conv.id == _currentConversationId,
        orElse: () => ChatConversation.create(),
      );

      final updatedConversation = currentConversation
          .addMessage(userMessage)
          .addMessage(tempBotMessage);

      _conversations = _conversations.map((conv) {
        return conv.id == _currentConversationId ? updatedConversation : conv;
      }).toList();
    });

    _scrollToBottom();

    try {
      await _chatbotService.sendMessage(
        userId,
        messageText,
        conversationId: _currentConversationId,
      );
    } catch (e) {
      _showErrorMessage();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error al enviar el mensaje'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleOptionSelected(String option) {
    _messageController.text = option.replaceAll(RegExp(r'[\[\]]'), '');
    _sendMessage();
  }

  void _toggleConversationList() {
    setState(() {
      _showConversationList = !_showConversationList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentConversation = _conversations.firstWhere(
      (conv) => conv.id == _currentConversationId,
      orElse: () => ChatConversation.create(),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleConversationList,
        ),
        title: const Text('CoreLife Catalyst'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          if (_showConversationList)
            ConversationList(
              conversations: _conversations,
              currentConversationId: _currentConversationId,
              onConversationSelected: (id) {
                setState(() {
                  _currentConversationId = id;
                });
              },
              onNewChat: _startNewChat,
              onDeleteConversation: _deleteConversation,
            ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: currentConversation.messages.isEmpty
                      ? _buildWelcomeMessage()
                      : _buildChatMessages(currentConversation),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Hola, $_userName! 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Soy tu CoreLife Catalyst, tu coach personal de hábitos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿En qué puedo ayudarte hoy? 😊',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessages(ChatConversation conversation) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: conversation.messages.length,
      itemBuilder: (context, index) {
        final message = conversation.messages[index];
        final isLastMessage = index == conversation.messages.length - 1;
        
        return ChatMessageWidget(
          key: ValueKey(message.id),
          message: message,
          isTyping: _isLoading && isLastMessage && !message.isUser,
          onOptionSelected: _handleOptionSelected,
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Pregúntame algo...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}