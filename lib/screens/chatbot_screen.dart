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
  bool _showConversationList = false; // Cambiar a false por defecto

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
      // En móvil, cerrar el sidebar después de crear nuevo chat
      if (MediaQuery.of(context).size.width < 768) {
        _showConversationList = false;
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
    });

    // Añadir mensaje del usuario inmediatamente
    final currentConversation = _conversations.firstWhere(
      (conv) => conv.id == _currentConversationId,
      orElse: () => ChatConversation.create(),
    );

    final updatedConversation = currentConversation.addMessage(userMessage);

    setState(() {
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
      SnackBar(
        content: const Text('Error al enviar el mensaje'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    
    final currentConversation = _conversations.firstWhere(
      (conv) => conv.id == _currentConversationId,
      orElse: () => ChatConversation.create(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            if (isMobile) ...[
              IconButton(
                icon: Icon(
                  _showConversationList ? Icons.close : Icons.menu,
                  color: Colors.black87,
                ),
                onPressed: _toggleConversationList,
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.smart_toy,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'CoreLife Catalyst',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (!isMobile)
            IconButton(
              icon: Icon(
                _showConversationList ? Icons.close : Icons.menu,
                color: Colors.black87,
              ),
              onPressed: _toggleConversationList,
            ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: _startNewChat,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Chat principal
          Column(
            children: [
              Expanded(
                child: currentConversation.messages.isEmpty
                    ? _buildWelcomeMessage()
                    : _buildChatMessages(currentConversation),
              ),
              _buildMessageInput(),
            ],
          ),
          
          // Sidebar de conversaciones
          if (_showConversationList)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: isMobile ? screenWidth * 0.85 : 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: ConversationList(
                  conversations: _conversations,
                  currentConversationId: _currentConversationId,
                  onConversationSelected: (id) {
                    setState(() {
                      _currentConversationId = id;
                      if (isMobile) {
                        _showConversationList = false;
                      }
                    });
                  },
                  onNewChat: _startNewChat,
                  onDeleteConversation: _deleteConversation,
                ),
              ),
            ),
          
          // Overlay para cerrar sidebar en móvil
          if (_showConversationList && isMobile)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showConversationList = false),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Hola, $_userName! 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Soy tu CoreLife Catalyst, tu coach personal de hábitos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE0F2FE),
                ),
              ),
              child: const Text(
                '¿En qué puedo ayudarte hoy? 😊',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0369A1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessages(ChatConversation conversation) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: conversation.messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isLoading && index == conversation.messages.length) {
            // Mostrar indicador de carga como mensaje del bot
            return ChatMessageWidget(
              key: const ValueKey('loading'),
              message: ChatbotMessage(
                id: 'loading',
                message: '',
                isUser: false,
                timestamp: DateTime.now(),
              ),
              isTyping: true,
              onOptionSelected: _handleOptionSelected,
            );
          }
          
          final message = conversation.messages[index];
          return ChatMessageWidget(
            key: ValueKey(message.id),
            message: message,
            isTyping: false,
            onOptionSelected: _handleOptionSelected,
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isLoading 
                          ? Colors.grey.shade300 
                          : Colors.transparent,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    enabled: !_isLoading,
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                    maxLines: 4,
                    minLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: _isLoading 
                      ? Colors.grey.shade400 
                      : Theme.of(context).primaryColor,
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
                      : const Icon(Icons.send_rounded),
                  color: Colors.white,
                  splashRadius: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}