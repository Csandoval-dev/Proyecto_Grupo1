import 'package:flutter/material.dart';
import '../models/chatbot_message.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatbotMessage message;
  final bool isTyping;
  final Function(String) onOptionSelected;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    this.isTyping = false,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _appearanceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _appearanceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _appearanceController.forward();
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 800 ? 600.0 : screenWidth * 0.85;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: widget.message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.message.isUser) ...[
                _buildBotAvatar(),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: widget.message.isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      _buildMessageBubble(),
                      if (!widget.message.isUser &&
                          !widget.isTyping &&
                          widget.message.message.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildActionButtons(),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.message.isUser) ...[
                const SizedBox(width: 12),
                _buildUserAvatar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.message.isUser
            ? Theme.of(context).primaryColor
            : Colors.white,
        borderRadius: BorderRadius.circular(18).copyWith(
          topLeft: widget.message.isUser
              ? const Radius.circular(18)
              : const Radius.circular(4),
          topRight: widget.message.isUser
              ? const Radius.circular(4)
              : const Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.message.isUser
                ? Theme.of(context).primaryColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: widget.isTyping
          ? _buildTypingIndicator()
          : _buildMessageContent(),
    );
  }

  Widget _buildMessageContent() {
    return SelectableText(
      widget.message.message,
      style: TextStyle(
        color: widget.message.isUser ? Colors.white : Colors.black87,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(3, (index) => _buildTypingDot(index)),
          const SizedBox(width: 8),
          Text(
            'Escribiendo...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final animatedValue = (value + (index * 0.3)) % 1.0;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6 + (animatedValue * 2),
            height: 6 + (animatedValue * 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade500.withOpacity(0.3 + (animatedValue * 0.7)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    final options = _extractOptions(widget.message.message);
    if (options.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          return _buildActionButton(option);
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(String option) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onOptionSelected(option),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  option,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _extractOptions(String message) {
    final regex = RegExp(r'\[(.*?)\]');
    return regex
        .allMatches(message)
        .map((match) => match.group(1) ?? '')
        .where((option) => option.isNotEmpty)
        .take(5) // Limitar a 5 opciones para evitar saturación
        .toList();
  }
}