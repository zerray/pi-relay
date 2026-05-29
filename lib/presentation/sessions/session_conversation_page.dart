import 'package:flutter/material.dart';

import '../../domain/sessions/remote_session.dart';
import '../../domain/transcript/transcript_message.dart';

class SessionConversationPage extends StatelessWidget {
  const SessionConversationPage({
    required this.session,
    required this.messages,
    required this.isLoading,
    required this.errorText,
    required this.onBack,
    super.key,
  });

  final RemoteSession session;
  final List<TranscriptMessage> messages;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回会话',
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(session.name),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorText = this.errorText;
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

    if (messages.isEmpty) {
      return Center(
        child: Text('暂无消息', style: Theme.of(context).textTheme.titleMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final message = messages[index];
        return _TranscriptMessageCard(message: message);
      },
    );
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
