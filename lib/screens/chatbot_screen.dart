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
  bool _showConversationList = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      await _loadUserName();
      await _startNewChat();
      _loadConversations();
    } catch (e) {
      _showErrorMessage('Error al iniciar el chat. Por favor, intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserName() async {
    try {
      final name = await _chatbotService.getUserName(userId);
      if (mounted) {
        setState(() {
          _userName = name;
        });
      }
    } catch (e) {
      print('Error cargando nombre de usuario: $e');
    }
  }

  void _loadConversations() {
    _chatbotService.getConversations(userId).listen(
      (conversations) {
        if (mounted) {
          setState(() {
            final updatedConversations = conversations;
            final currentExists = updatedConversations.any(
              (conv) => conv.id == _currentConversationId,
            );
            
            _conversations = updatedConversations;
            
            if (!currentExists && updatedConversations.isNotEmpty) {
              _currentConversationId = updatedConversations.first.id;
            }
          });
        }
      },
      onError: (e) {
        print('Error cargando conversaciones: $e');
        _showErrorMessage('Error al cargar las conversaciones');
      },
    );
  }

  Future<void> _startNewChat() async {
    try {
      final newConversation = await _chatbotService.createNewConversation(userId);
      if (mounted) {
        setState(() {
          _currentConversationId = newConversation.id;
          _conversations = [newConversation, ..._conversations];
          if (MediaQuery.of(context).size.width < 768) {
            _showConversationList = false;
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error creando nuevo chat: $e');
      _showErrorMessage('Error al crear nueva conversación');
    }
  }

  void _selectConversation(String conversationId) {
    setState(() {
      _currentConversationId = conversationId;
      if (MediaQuery.of(context).size.width < 768) {
        _showConversationList = false;
      }
    });
    _scrollToBottom();
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await _chatbotService.deleteConversation(userId, conversationId);
      
      if (_currentConversationId == conversationId) {
        final remainingConversations = _conversations
            .where((conv) => conv.id != conversationId)
            .toList();
        
        if (remainingConversations.isNotEmpty) {
          setState(() {
            _currentConversationId = remainingConversations.first.id;
          });
        } else {
          await _startNewChat();
        }
      }
    } catch (e) {
      print('Error eliminando conversación: $e');
      _showErrorMessage('Error al eliminar la conversación');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    _messageController.clear();
    final previousMessages = List.of(_conversations
        .firstWhere((conv) => conv.id == _currentConversationId)
        .messages);

    setState(() => _isLoading = true);

    try {
      final botMessage = await _chatbotService.sendMessage(
        userId,
        messageText,
        conversationId: _currentConversationId,
      );
      
      if (!mounted) return;
      
      final currentConversation = _conversations
          .firstWhere((conv) => conv.id == _currentConversationId,
                     orElse: () => ChatConversation.create());
      
      if (currentConversation.id == 'new') {
        await _startNewChat();
      }
      
      _scrollToBottom();
    } catch (e) {
      final conversationIndex = _conversations
          .indexWhere((conv) => conv.id == _currentConversationId);
      
      if (conversationIndex != -1 && mounted) {
        setState(() {
          _conversations[conversationIndex] = _conversations[conversationIndex]
              .copyWith(messages: previousMessages);
        });
      }
      
      _showErrorMessage('Error al enviar el mensaje');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        print('Error en scroll: $e');
      }
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
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
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: _buildAppBar(theme, isMobile),
      body: _buildBody(theme, isMobile),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isMobile) {
    return AppBar(
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
            color: theme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 8),
          const Text(
            'CoreLife Assistant',
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
            icon: const Icon(
              Icons.menu,
              color: Colors.black87,
            ),
            onPressed: _toggleConversationList,
          ),
        IconButton(
          icon: const Icon(
            Icons.add,
            color: Colors.black87,
          ),
          onPressed: _startNewChat,
          tooltip: 'Nueva conversación',
        ),
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: Colors.black87,
          ),
          onSelected: (value) {
            if (value == 'clear_all') {
              _showClearAllDialog();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Limpiar todo'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, bool isMobile) {
    final currentConversation = _conversations.firstWhere(
      (conv) => conv.id == _currentConversationId,
      orElse: () => ChatConversation.create(),
    );

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: currentConversation.messages.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildChatMessages(currentConversation, theme),
            ),
            _buildMessageInput(theme),
          ],
        ),
        if (_showConversationList)
          _buildConversationsSidebar(isMobile, theme),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 48,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Hola, $_userName! 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Iniciando nueva conversación...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessages(ChatConversation conversation, ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: conversation.messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == conversation.messages.length) {
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
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
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
                    hintText: 'Escribe sobre tus hábitos...',
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
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildSendButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: _isLoading 
            ? Colors.grey.shade400 
            : theme.primaryColor,
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
    );
  }

  Widget _buildConversationsSidebar(bool isMobile, ThemeData theme) {
    return Stack(
      children: [
        if (isMobile)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showConversationList = false),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: isMobile ? MediaQuery.of(context).size.width * 0.85 : 320,
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
              onConversationSelected: _selectConversation,
              onNewChat: _startNewChat,
              onDeleteConversation: _deleteConversation,
            ),
          ),
        ),
      ],
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Limpiar conversaciones',
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todas las conversaciones? '
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _chatbotService.clearAllConversations(userId);
                await _startNewChat();
              } catch (e) {
                _showErrorMessage('Error al limpiar las conversaciones');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );
  }
}