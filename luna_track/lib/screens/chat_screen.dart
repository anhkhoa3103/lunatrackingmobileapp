import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  static const _pink = Color(0xFFE05D6F);

  // Suggested quick questions
  final List<String> _suggestions = [
    '🩸 Tôi đang ở giai đoạn nào của chu kỳ?',
    '😣 Cách giảm đau bụng kinh hiệu quả?',
    '🥗 Nên ăn gì trong kỳ kinh nguyệt?',
    '💪 Có nên tập gym khi hành kinh không?',
    '🌙 Tại sao tôi hay mất ngủ trước kỳ kinh?',
    '😰 PMS là gì và cách đối phó?',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message from Luna
    _messages.add(_ChatMessage(
      role: 'assistant',
      content: 'Xin chào! Tôi là Luna 🌙, trợ lý AI của bạn.\n\n'
          'Tôi có thể giúp bạn:\n'
          '• Hiểu về chu kỳ kinh nguyệt\n'
          '• Giải thích các triệu chứng\n'
          '• Gợi ý chế độ ăn uống & tập luyện\n\n'
          'Bạn muốn hỏi gì hôm nay? 💕',
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    final userMessage = text.trim();
    _inputCtrl.clear();

    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(_ChatMessage(
        role: 'user',
        content: userMessage,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Build history: exclude the welcome message and the message just
    // added (it is sent separately), keep the most recent 20 entries
    var history = _messages
        .sublist(1, _messages.length - 1)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
    if (history.length > 20) {
      history = history.sublist(history.length - 20);
    }
    while (history.isNotEmpty && history.first['role'] == 'assistant') {
      history.removeAt(0);
    }

    final response = await ApiService.sendChatMessage(
      message: userMessage,
      history: history,
    );

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
        role: 'assistant',
        content: response ??
            'Xin lỗi, tôi không thể trả lời lúc này. '
            'Vui lòng thử lại! 🙏',
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _messages.length == 1
                ? _buildSuggestionsView()
                : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios,
            size: 18, color: AppColors.textPrimary(context)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Luna avatar
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE05D6F), Color(0xFF9B3A6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _pink.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: const Center(
              child: Text('🌙',
                  style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Luna AI',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context))),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D9E75),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Trực tuyến',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary(context))),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_outlined,
              color: AppColors.textHint(context), size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _messages.clear();
              _messages.add(_ChatMessage(
                role: 'assistant',
                content: 'Cuộc trò chuyện mới đã bắt đầu! '
                    'Tôi có thể giúp gì cho bạn hôm nay? 🌸',
                timestamp: DateTime.now(),
              ));
            });
          },
        ),
      ],
    );
  }

  // ── Suggestions view (first load) ───────────────────────────
  Widget _buildSuggestionsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Welcome bubble
          _buildMessageBubble(_messages.first),
          const SizedBox(height: 20),

          // Suggestions label
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Câu hỏi thường gặp:',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 10),

          // Suggestion chips
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _suggestions.map((s) =>
              GestureDetector(
                onTap: () => _sendMessage(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _pink.withOpacity(0.2)),
                  ),
                  child: Text(s,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary(context))),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) return _buildTypingIndicator();
        return _buildMessageBubble(_messages[i]);
      },
    );
  }

  // ── Message bubble ───────────────────────────────────────────
  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Luna avatar
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE05D6F), Color(0xFF9B3A6B)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('🌙',
                      style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width
                        * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? _pink
                        : AppColors.surface(context),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(
                          isUser ? 18 : 4),
                      bottomRight: Radius.circular(
                          isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? _pink.withOpacity(0.2)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser
                          ? Colors.white
                          : AppColors.textPrimary(context),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(msg.timestamp),
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint(context)),
                ),
              ],
            ),
          ),

          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Typing indicator ─────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFE05D6F), Color(0xFF9B3A6B)]),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('🌙',
                    style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _inputCtrl,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'Hỏi Luna về sức khỏe của bạn...',
                  hintStyle: TextStyle(
                      color: AppColors.textHint(context),
                      fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () => _sendMessage(_inputCtrl.text),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE05D6F), Color(0xFFD4497A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _pink.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _isTyping
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

// ── Typing dots animation ────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {

  late List<AnimationController> _controllers;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    // Staggered bounce: each dot repeats with a slightly longer period
    _controllers = List.generate(3, (i) =>
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(
          reverse: true,
          period: Duration(milliseconds: 600 + i * 150),
        ));
    _anims = _controllers.map((c) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) =>
        AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: AppColors.textHint(context).withOpacity(
                  0.4 + _anims[i].value * 0.6),
              shape: BoxShape.circle,
            ),
            transform: Matrix4.translationValues(
                0, -4 * _anims[i].value, 0),
          ),
        )),
    );
  }
}

// ── Data model ───────────────────────────────────────────────
class _ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  _ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}
