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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildAppBar(theme, isMobile),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: _buildMainContent(theme),
                    ),
                  ],
                ),
                if (_showConversationList)
                  _buildConversationsSidebar(isMobile, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isMobile) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (isMobile)
                  IconButton(
                    icon: Icon(
                      _showConversationList ? Icons.close : Icons.menu,
                      color: const Color(0xFF1F2937),
                    ),
                    onPressed: _toggleConversationList,
                  ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Neuro Core',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                if (!isMobile)
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: _toggleConversationList,
                    color: const Color(0xFF1F2937),
                  ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _startNewChat,
                  color: const Color(0xFF1F2937),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF1F2937),
                  ),
                  onSelected: (value) {
                    if (value == 'clear_all') {
                      _showClearAllDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red.shade600),
                          const SizedBox(width: 12),
                          const Text('Limpiar todo'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    final currentConversation = _conversations.firstWhere(
      (conv) => conv.id == _currentConversationId,
      orElse: () => ChatConversation.create(),
    );

    return Column(
      children: [
        Expanded(
          child: currentConversation.messages.isEmpty
              ? _buildEmptyState(theme)
              : _buildChatMessages(currentConversation, theme),
        ),
        _buildMessageInput(theme),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '¡Hola, $_userName! 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Iniciando nueva conversación...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessages(ChatConversation conversation, ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: conversation.messages.length + (_isLoading ? 1 : 0),
      physics: const BouncingScrollPhysics(),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),  // Color gris claro para el fondo
                borderRadius: BorderRadius.circular(24),  // Bordes más ovalados
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  isDense: true,
                ),
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF7C3AED),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(23),
                onTap: _isLoading ? null : _sendMessage,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsSidebar(bool isMobile, ThemeData theme) {
    if (isMobile) {
      return Stack(
        children: [
          GestureDetector(
            onTap: _toggleConversationList,
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: ConversationList(
              conversations: _conversations,
              currentConversationId: _currentConversationId,
              onConversationSelected: _selectConversation,
              onNewChat: _startNewChat,
              onDeleteConversation: _deleteConversation,
            ),
          ),
        ],
      );
    } else {
      return Container(
        width: 320,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: ConversationList(
          conversations: _conversations,
          currentConversationId: _currentConversationId,
          onConversationSelected: _selectConversation,
          onNewChat: _startNewChat,
          onDeleteConversation: _deleteConversation,
        ),
      );
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Limpiar conversaciones',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todas las conversaciones? '
          'Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 15),
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
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Eliminar todo',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}