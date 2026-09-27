import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../ui/media/cover_image.dart';
import '../domain/chat_message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.occurrenceId,
    this.title,
  });

  final String occurrenceId;
  final String? title;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  StreamSubscription<ChatMessage>? _subscription;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(chatRepositoryProvider);
    try {
      final history = await repo.loadMessages(widget.occurrenceId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
        _loading = false;
      });
      _scrollToBottom();

      _subscription = repo.watchMessages(widget.occurrenceId).listen(
        (message) {
          if (!mounted) return;
          if (_messages.any((item) => item.id == message.id)) return;
          setState(() => _messages.add(message));
          _scrollToBottom();
        },
        onError: (_) {},
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _send() async {
    final body = _inputController.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    final repo = ref.read(chatRepositoryProvider);
    try {
      final message = await repo.sendMessage(widget.occurrenceId, body);
      _inputController.clear();
      if (!_messages.any((item) => item.id == message.id)) {
        setState(() => _messages.add(message));
      }
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final title = widget.title?.trim();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        title: Text(
          title == null || title.isEmpty ? 'Чат маршрута' : title,
          style: AppTextStyles.text18_600(color: colors.text),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.s24),
                          child: Text(
                            _error!,
                            style: AppTextStyles.text14_550(
                              color: colors.caption,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              'Напишите первое сообщение участникам',
                              style: AppTextStyles.text14_550(
                                color: colors.caption,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return _MessageBubble(message: _messages[index]);
                            },
                          ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s8,
                AppSpacing.s16,
                AppSpacing.s12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => unawaited(_send()),
                      decoration: InputDecoration(
                        hintText: 'Сообщение…',
                        filled: true,
                        fillColor: colors.secondBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                          vertical: AppSpacing.s12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  IconButton.filled(
                    onPressed: _sending ? null : () => unawaited(_send()),
                    icon: _sending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onImagePrimary,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final local = message.createdAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final name = message.senderName?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SenderAvatar(message: message, size: 36),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name ?? 'Участник',
                        style: AppTextStyles.text13_400(color: colors.text)
                            .copyWith(fontVariations: const [
                          FontVariation('wght', 650),
                        ]),
                      ),
                    ),
                    Text(
                      time,
                      style: AppTextStyles.text13_400(color: colors.caption),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: colors.secondBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.body,
                    style: AppTextStyles.text14_550(color: colors.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.message, required this.size});

  final ChatMessage message;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = message.senderAvatarUrl;

    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: CoverImage(ref: url, fit: BoxFit.cover),
        ),
      );
    }

    final label = (message.senderName?.trim().isNotEmpty == true
            ? message.senderName!.trim()
            : '?')
        .characters
        .first
        .toUpperCase();

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.secondBackground,
      child: Text(
        label,
        style: AppTextStyles.text14_550(color: colors.text),
      ),
    );
  }
}
