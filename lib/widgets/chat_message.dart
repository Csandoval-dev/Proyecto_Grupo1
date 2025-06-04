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
  late Animation<double> _appearanceAnimation;

  @override
  void initState() {
    super.initState();
    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _appearanceAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: Curves.easeOutCirc,
    );

    _appearanceController.forward();
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _appearanceAnimation,
      child: SizeTransition(
        sizeFactor: _appearanceAnimation,
        axisAlignment: -1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: widget.message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.message.isUser) ...[
                _buildAvatar(context),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.message.isUser
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.isTyping
                          ? _buildTypingIndicator()
                          : _buildMessageContent(),
                      if (!widget.message.isUser &&
                          !widget.isTyping &&
                          widget.message.message.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildActionButtons(),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.message.isUser) ...[
                const SizedBox(width: 8),
                _buildUserAvatar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
    );
  }

  Widget _buildUserAvatar() {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, size: 16, color: Colors.white),
    );
  }

  Widget _buildMessageContent() {
    return Text(
      widget.message.message,
      style: TextStyle(
        color: widget.message.isUser ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return _buildTypingDot(index);
      }),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade600.withOpacity(
              (value + (index * 0.2)).clamp(0.2, 0.8),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    final options = _extractOptions(widget.message.message);
    if (options.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.map((option) {
        return InkWell(
          onTap: () => widget.onOptionSelected(option),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<String> _extractOptions(String message) {
    final regex = RegExp(r'\[(.*?)\]');
    return regex
        .allMatches(message)
        .map((match) => match.group(1) ?? '')
        .where((option) => option.isNotEmpty)
        .toList();
  }
}