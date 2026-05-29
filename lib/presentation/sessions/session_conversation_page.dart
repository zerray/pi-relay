import 'package:flutter/material.dart';

import '../../domain/sessions/remote_session.dart';
import '../../domain/transcript/transcript_message.dart';

class SessionConversationPage extends StatefulWidget {
  const SessionConversationPage({
    required this.session,
    required this.messages,
    required this.isLoading,
    required this.errorText,
    required this.onBack,
    this.hasOlderMessages = false,
    this.isLoadingOlder = false,
    this.onLoadOlder,
    super.key,
  });

  final RemoteSession session;
  final List<TranscriptMessage> messages;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onBack;
  final bool hasOlderMessages;
  final bool isLoadingOlder;
  final Future<void> Function()? onLoadOlder;

  @override
  State<SessionConversationPage> createState() =>
      _SessionConversationPageState();
}

class _SessionConversationPageState extends State<SessionConversationPage> {
  final _scrollController = ScrollController();
  var _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateBottomState);
    _scheduleScrollToBottom();
  }

  @override
  void didUpdateWidget(SessionConversationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLastId =
        oldWidget.messages.isEmpty ? null : oldWidget.messages.last.id;
    final newLastId = widget.messages.isEmpty ? null : widget.messages.last.id;
    final shouldFollowBottom =
        oldWidget.messages.isEmpty || oldLastId != newLastId && _isAtBottom;
    if (shouldFollowBottom) {
      _scheduleScrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateBottomState)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回会话',
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(widget.session.name),
      ),
      body: _buildBody(context),
      floatingActionButton: _showJumpToBottomButton
          ? FloatingActionButton.small(
              tooltip: '跳到最新消息',
              onPressed: _scrollToBottom,
              child: const Icon(Icons.keyboard_arrow_down),
            )
          : null,
    );
  }

  bool get _showJumpToBottomButton {
    return !widget.isLoading &&
        widget.errorText == null &&
        widget.messages.isNotEmpty &&
        !_isAtBottom;
  }

  Widget _buildBody(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorText = widget.errorText;
    if (errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      );
    }

    if (widget.messages.isEmpty) {
      return Center(
        child: Text('暂无消息', style: Theme.of(context).textTheme.titleMedium),
      );
    }

    final listView = ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: widget.messages.length + (widget.isLoadingOlder ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (widget.isLoadingOlder && index == 0) {
          return const Center(child: CircularProgressIndicator());
        }
        final messageIndex = index - (widget.isLoadingOlder ? 1 : 0);
        final message = widget.messages[messageIndex];
        return _TranscriptMessageCard(message: message);
      },
    );

    final onLoadOlder = widget.onLoadOlder;
    if (!widget.hasOlderMessages || onLoadOlder == null) {
      return listView;
    }

    return RefreshIndicator(
      onRefresh: onLoadOlder,
      child: listView,
    );
  }

  void _scheduleScrollToBottom() {
    _scrollToBottomAfterLayout(remainingAttempts: 8, previousMaxExtent: null);
  }

  void _scrollToBottomAfterLayout({
    required int remainingAttempts,
    required double? previousMaxExtent,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final maxExtent = _scrollController.position.maxScrollExtent;
      _scrollToBottom();

      if (remainingAttempts <= 1) return;
      if (previousMaxExtent == null ||
          (maxExtent - previousMaxExtent).abs() > 1) {
        _scrollToBottomAfterLayout(
          remainingAttempts: remainingAttempts - 1,
          previousMaxExtent: maxExtent,
        );
      }
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    _updateBottomState();
  }

  void _updateBottomState() {
    if (!_scrollController.hasClients) return;
    final isAtBottom =
        _scrollController.position.maxScrollExtent - _scrollController.offset <=
            24;
    if (isAtBottom == _isAtBottom) return;
    setState(() {
      _isAtBottom = isAtBottom;
    });
  }
}

class _TranscriptMessageCard extends StatelessWidget {
  const _TranscriptMessageCard({required this.message});

  final TranscriptMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          color: isUser ? colorScheme.primaryContainer : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.role,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(message.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
