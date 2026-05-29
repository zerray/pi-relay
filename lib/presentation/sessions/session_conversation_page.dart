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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _SessionHeader(
              title: widget.session.name,
              subtitle: 'Remote control',
              onBack: widget.onBack,
            ),
            Expanded(child: _buildBody(context)),
            if (!widget.isLoading && widget.errorText == null)
              const _PromptInputBar(),
          ],
        ),
      ),
      floatingActionButton: _showJumpToBottomButton
          ? FloatingActionButton.small(
              tooltip: '跳到最新消息',
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              elevation: 3,
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

    final rows = _TranscriptRows.fromMessages(widget.messages);
    final listView = ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: rows.length + (widget.isLoadingOlder ? 1 : 0),
      separatorBuilder: (context, index) {
        final rowIndex = index - (widget.isLoadingOlder ? 1 : 0);
        if (rowIndex < 0 || rowIndex >= rows.length - 1) {
          return const SizedBox(height: 12);
        }
        return SizedBox(
            height: _rowSpacing(rows[rowIndex], rows[rowIndex + 1]));
      },
      itemBuilder: (context, index) {
        if (widget.isLoadingOlder && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final rowIndex = index - (widget.isLoadingOlder ? 1 : 0);
        return _TranscriptRowView(row: rows[rowIndex]);
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

  double _rowSpacing(_TranscriptRow current, _TranscriptRow next) {
    if (current is _ActivityTranscriptRow || next is _ActivityTranscriptRow) {
      return 18;
    }
    return 16;
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

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回会话',
            icon: const Icon(Icons.chevron_left, size: 30),
            style: IconButton.styleFrom(
              fixedSize: const Size(48, 48),
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.55),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }
}

class _PromptInputBar extends StatelessWidget {
  const _PromptInputBar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 8, 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Talk to Pi',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.55),
                      ),
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.10),
                foregroundColor: colorScheme.onSurface.withValues(alpha: 0.28),
                child: const Icon(Icons.arrow_upward, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

sealed class _TranscriptRow {
  const _TranscriptRow({required this.id});

  final String id;
}

class _TextTranscriptRow extends _TranscriptRow {
  const _TextTranscriptRow({
    required super.id,
    required this.text,
    required this.style,
  });

  final String text;
  final _TextTranscriptRowStyle style;
}

enum _TextTranscriptRowStyle { user, assistant, muted }

class _ActivityTranscriptRow extends _TranscriptRow {
  const _ActivityTranscriptRow({
    required super.id,
    required this.title,
    required this.items,
  });

  final String title;
  final List<_ActivityDetailItem> items;
}

class _NormalizedTranscriptItem {
  const _NormalizedTranscriptItem({
    required this.id,
    required this.kind,
    required this.text,
    required this.createdAt,
    required this.isStreaming,
    this.toolCallId,
    this.toolName,
    this.summary,
    this.arguments,
    this.isTruncated = false,
    this.originalBytes,
  });

  final String id;
  final String kind;
  final String text;
  final DateTime createdAt;
  final bool isStreaming;
  final String? toolCallId;
  final String? toolName;
  final String? summary;
  final Object? arguments;
  final bool isTruncated;
  final int? originalBytes;
}

class _TranscriptRows {
  static List<_TranscriptRow> fromMessages(List<TranscriptMessage> messages) {
    final items = messages.expand(_itemsFromMessage).toList(growable: false);
    final rows = <_TranscriptRow>[];
    var index = 0;
    while (index < items.length) {
      final item = items[index];
      if (_isActivityItem(item)) {
        final activityItems = <_NormalizedTranscriptItem>[];
        while (index < items.length && _isActivityItem(items[index])) {
          activityItems.add(items[index]);
          index += 1;
        }
        rows.add(_activityRow(activityItems));
        continue;
      }

      rows.add(_TextTranscriptRow(
        id: item.id,
        text: _textWithPreviewNotice(item),
        style: _styleFor(item),
      ));
      index += 1;
    }
    return rows;
  }

  static Iterable<_NormalizedTranscriptItem> _itemsFromMessage(
    TranscriptMessage message,
  ) {
    final normalizedKind = _normalizedKind(message);
    if (normalizedKind != null) {
      return [
        _NormalizedTranscriptItem(
          id: message.id,
          kind: normalizedKind,
          text: message.text,
          createdAt: message.createdAt,
          isStreaming: message.isStreaming,
          toolCallId: message.toolCallId,
          toolName: message.toolName,
          summary: message.summary,
          arguments: message.arguments,
          isTruncated: message.isTruncated,
          originalBytes: message.originalBytes,
        ),
      ];
    }

    if (message.role == 'assistant') {
      final blockItems = _assistantItems(message);
      if (blockItems.isNotEmpty) return blockItems;
      if (message.text.isEmpty) return const [];
      return [
        _NormalizedTranscriptItem(
          id: message.id,
          kind: 'assistantText',
          text: message.text,
          createdAt: message.createdAt,
          isStreaming: message.isStreaming,
          isTruncated: message.isTruncated,
          originalBytes: message.originalBytes,
        ),
      ];
    }

    if (message.role == 'user') {
      if (message.text.isEmpty) return const [];
      return [
        _NormalizedTranscriptItem(
          id: message.id,
          kind: 'userText',
          text: message.text,
          createdAt: message.createdAt,
          isStreaming: message.isStreaming,
          isTruncated: message.isTruncated,
          originalBytes: message.originalBytes,
        ),
      ];
    }

    if (message.role == 'toolResult') {
      return [
        _NormalizedTranscriptItem(
          id: message.id,
          kind: 'toolResult',
          text: message.text,
          createdAt: message.createdAt,
          isStreaming: message.isStreaming,
          toolCallId: message.toolCallId,
          toolName: message.toolName,
          isTruncated: message.isTruncated,
          originalBytes: message.originalBytes,
        ),
      ];
    }

    if (message.role == 'system') {
      if (message.text.isEmpty) return const [];
      return [
        _NormalizedTranscriptItem(
          id: message.id,
          kind: 'system',
          text: message.text,
          createdAt: message.createdAt,
          isStreaming: message.isStreaming,
          isTruncated: message.isTruncated,
          originalBytes: message.originalBytes,
        ),
      ];
    }

    return const [];
  }

  static String? _normalizedKind(TranscriptMessage message) {
    return switch (message.kind) {
      'userText' ||
      'assistantText' ||
      'thinking' ||
      'toolCall' ||
      'toolResult' ||
      'system' =>
        message.kind,
      _ => null,
    };
  }

  static List<_NormalizedTranscriptItem> _assistantItems(
    TranscriptMessage message,
  ) {
    final items = <_NormalizedTranscriptItem>[];
    for (var index = 0; index < message.content.length; index += 1) {
      final block = message.content[index];
      if (block is! Map) continue;
      final type = block['type'];
      final createdAt = message.createdAt.add(Duration(milliseconds: index));
      if (type == 'text') {
        final text = block['text'];
        if (text is! String || text.isEmpty) continue;
        items.add(
          _NormalizedTranscriptItem(
            id: message.content.length == 1
                ? message.id
                : _assistantBlockItemId(message.id, 'text', index),
            kind: 'assistantText',
            text: text,
            createdAt: createdAt,
            isStreaming: message.isStreaming,
            isTruncated: _boolValue(block['truncated']) || message.isTruncated,
            originalBytes:
                _intValue(block['originalBytes']) ?? message.originalBytes,
          ),
        );
      } else if (type == 'thinking') {
        final thinking = block['thinking'];
        if (thinking is! String || thinking.isEmpty) continue;
        items.add(
          _NormalizedTranscriptItem(
            id: _assistantBlockItemId(message.id, 'thinking', index),
            kind: 'thinking',
            text: thinking,
            createdAt: createdAt,
            isStreaming: message.isStreaming,
            isTruncated: _boolValue(block['truncated']),
            originalBytes: _intValue(block['originalBytes']),
          ),
        );
      } else if (type == 'toolCall') {
        final id = block['id'];
        final name = block['name'];
        if (id is! String || name is! String) continue;
        final arguments = block['arguments'];
        items.add(
          _NormalizedTranscriptItem(
            id: _assistantBlockItemId(message.id, 'tool', index),
            kind: 'toolCall',
            text: name,
            createdAt: createdAt,
            isStreaming: message.isStreaming,
            toolCallId: id,
            toolName: name,
            summary: _summarizeToolArguments(name, arguments),
            arguments: arguments,
            isTruncated: _boolValue(block['argumentsTruncated']),
            originalBytes: _intValue(block['argumentsOriginalBytes']),
          ),
        );
      }
    }
    return items;
  }

  static bool _isActivityItem(_NormalizedTranscriptItem item) {
    return item.kind == 'thinking' ||
        item.kind == 'toolCall' ||
        item.kind == 'toolResult';
  }

  static _ActivityTranscriptRow _activityRow(
    List<_NormalizedTranscriptItem> items,
  ) {
    final toolCalls = items.where(_isToolCall).toList(growable: false);
    final commandCount = toolCalls.where((item) {
      return _toolName(item).toLowerCase() == 'bash';
    }).length;
    final toolCount = toolCalls.length - commandCount;
    final title = _activityTitle(
      commandCount: commandCount,
      toolCount: toolCount,
      hasThinking: items.any((item) => item.kind == 'thinking'),
    );
    return _ActivityTranscriptRow(
      id: items.last.id,
      title: title,
      items: _activityItems(items),
    );
  }

  static bool _isToolCall(_NormalizedTranscriptItem item) {
    return item.kind == 'toolCall';
  }

  static String _activityTitle({
    required int commandCount,
    required int toolCount,
    required bool hasThinking,
  }) {
    final commandPart = commandCount == 0
        ? null
        : 'Ran $commandCount ${commandCount == 1 ? 'command' : 'commands'}';
    final toolPart = toolCount == 0
        ? null
        : 'ran $toolCount ${toolCount == 1 ? 'tool' : 'tools'}';
    if (commandPart != null && toolPart != null) {
      return '$commandPart, $toolPart';
    }
    if (commandPart != null) return commandPart;
    if (toolPart != null) return _capitalize(toolPart);
    if (hasThinking) return 'Thinking';
    return 'Tool result';
  }

  static List<_ActivityDetailItem> _activityItems(
    List<_NormalizedTranscriptItem> items,
  ) {
    final resultMessagesByToolCallId =
        <String, List<_NormalizedTranscriptItem>>{};
    for (final item in items) {
      if (item.kind == 'toolResult' && item.toolCallId != null) {
        resultMessagesByToolCallId
            .putIfAbsent(item.toolCallId!, () => [])
            .add(item);
      }
    }

    return items
        .where((item) =>
            item.kind == 'thinking' ||
            item.kind == 'toolCall' ||
            (item.kind == 'toolResult' && item.toolCallId == null))
        .map((item) {
      if (item.kind == 'thinking') {
        final body = _textWithPreviewNotice(item);
        return _ActivityDetailItem(
          id: item.id,
          title: 'Thinking',
          icon: Icons.psychology_outlined,
          body: body,
          sections: [_ActivityDetailSection(title: 'Thinking', body: body)],
        );
      }
      if (item.kind == 'toolCall') {
        final results = resultMessagesByToolCallId[item.toolCallId] ?? [];
        return _toolDetailItem(item, results);
      }
      final body = _textWithPreviewNotice(item);
      return _ActivityDetailItem(
        id: item.id,
        title: 'Tool result',
        icon: Icons.handyman_outlined,
        body: body,
        sections: [_ActivityDetailSection(title: 'Output', body: body)],
      );
    }).toList(growable: false);
  }

  static _ActivityDetailItem _toolDetailItem(
    _NormalizedTranscriptItem item,
    List<_NormalizedTranscriptItem> results,
  ) {
    final toolName = _toolName(item);
    final title = _displayToolName(toolName);
    final resultText = results
        .map(_textWithPreviewNotice)
        .where((text) => text.isNotEmpty)
        .join('\n');
    final sections = _toolDetailSections(
      toolName: toolName,
      arguments: item.arguments,
      summary: item.summary,
      resultText: resultText,
    );
    return _ActivityDetailItem(
      id: item.id,
      title: title,
      subtitle: _toolSubtitle(toolName, item.arguments, item.summary),
      icon: _toolIcon(toolName),
      body: sections.map((section) => section.body).join('\n'),
      sections: sections.isEmpty
          ? [_ActivityDetailSection(title: 'Status', body: toolName)]
          : sections,
    );
  }

  static List<_ActivityDetailSection> _toolDetailSections({
    required String toolName,
    required Object? arguments,
    required String? summary,
    required String resultText,
  }) {
    final normalizedName = toolName.toLowerCase();
    final path = _argumentString(arguments, 'path') ??
        (normalizedName == 'bash' ? null : _nonEmpty(summary));
    final command = _argumentString(arguments, 'command') ??
        (normalizedName == 'bash' ? _nonEmpty(summary) : null);
    final sections = <_ActivityDetailSection>[];

    switch (normalizedName) {
      case 'bash':
        if (command != null) {
          sections.add(_ActivityDetailSection(title: 'Command', body: command));
        }
        if (resultText.isNotEmpty) {
          sections
              .add(_ActivityDetailSection(title: 'Output', body: resultText));
        }
      case 'read':
        if (path != null) {
          sections.add(_ActivityDetailSection(title: 'Path', body: path));
        }
        if (resultText.isNotEmpty) {
          sections
              .add(_ActivityDetailSection(title: 'Result', body: resultText));
        }
      case 'write':
        if (path != null) {
          sections.add(_ActivityDetailSection(title: 'Path', body: path));
        }
        final content = _argumentString(arguments, 'content');
        if (content != null) {
          sections.add(_ActivityDetailSection(title: 'Content', body: content));
        }
        if (resultText.isNotEmpty) {
          sections
              .add(_ActivityDetailSection(title: 'Output', body: resultText));
        }
      case 'edit':
        if (path != null) {
          sections.add(_ActivityDetailSection(title: 'Path', body: path));
        }
        final edits = _formattedEdits(_argument(arguments, 'edits'));
        if (edits != null) {
          sections.add(_ActivityDetailSection(title: 'Edits', body: edits));
        }
        if (resultText.isNotEmpty) {
          sections
              .add(_ActivityDetailSection(title: 'Output', body: resultText));
        }
      default:
        final input = _nonEmpty(summary);
        if (input != null) {
          sections.add(_ActivityDetailSection(title: 'Input', body: input));
        }
        if (resultText.isNotEmpty) {
          sections
              .add(_ActivityDetailSection(title: 'Output', body: resultText));
        }
    }

    return sections;
  }

  static _TextTranscriptRowStyle _styleFor(_NormalizedTranscriptItem item) {
    if (item.kind == 'userText') return _TextTranscriptRowStyle.user;
    if (item.kind == 'system') return _TextTranscriptRowStyle.muted;
    return _TextTranscriptRowStyle.assistant;
  }

  static String _textWithPreviewNotice(_NormalizedTranscriptItem item) {
    if (!item.isTruncated) return item.text;
    final notice = item.originalBytes == null
        ? 'Preview truncated.'
        : 'Preview truncated from ${item.originalBytes} bytes.';
    if (item.text.isEmpty) return notice;
    return '${item.text}\n\n$notice';
  }

  static String _toolName(_NormalizedTranscriptItem item) {
    return _nonEmpty(item.toolName) ?? _nonEmpty(item.text) ?? 'tool';
  }

  static String _assistantBlockItemId(
      String messageId, String blockKind, int index) {
    return '$messageId-$blockKind-$index';
  }

  static String? _summarizeToolArguments(String toolName, Object? arguments) {
    final key = toolName.toLowerCase() == 'bash' ? 'command' : 'path';
    return _argumentString(arguments, key);
  }

  static bool _boolValue(Object? value) => value is bool && value;

  static int? _intValue(Object? value) => value is int ? value : null;

  static String _displayToolName(String name) {
    if (name.toLowerCase() == 'bash') return 'Bash';
    return _capitalize(name);
  }

  static IconData _toolIcon(String name) {
    switch (name.toLowerCase()) {
      case 'bash':
        return Icons.terminal;
      case 'read':
        return Icons.description_outlined;
      case 'edit':
      case 'write':
        return Icons.edit_square;
      default:
        return Icons.work_outline;
    }
  }

  static String? _toolSubtitle(
    String toolName,
    Object? arguments,
    String? summary,
  ) {
    if (toolName.toLowerCase() == 'bash') {
      return _argumentString(arguments, 'command') ?? _nonEmpty(summary);
    }
    return _argumentString(arguments, 'path') ?? _nonEmpty(summary);
  }

  static String? _argumentString(Object? arguments, String key) {
    final value = _argument(arguments, key);
    return value is String && value.isNotEmpty ? value : null;
  }

  static Object? _argument(Object? arguments, String key) {
    if (arguments is Map<String, Object?>) return arguments[key];
    if (arguments is Map) return arguments[key];
    return null;
  }

  static String? _formattedEdits(Object? edits) {
    if (edits == null) return null;
    final editValues = edits is List ? edits : [edits];
    final blocks = editValues.map((edit) {
      if (edit is! Map) return '';
      final oldText =
          edit['oldText'] is String ? edit['oldText'] as String : '';
      final newText =
          edit['newText'] is String ? edit['newText'] as String : '';
      if (oldText.isEmpty && newText.isEmpty) return '';
      final oldLines = oldText.split('\n').map((line) => '-$line');
      final newLines = newText.split('\n').map((line) => '+$line');
      return ['--- old', '+++ new', ...oldLines, ...newLines].join('\n');
    }).where((block) => block.isNotEmpty);
    final body = blocks.join('\n\n');
    return body.isEmpty ? null : body;
  }

  static String? _nonEmpty(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value.substring(0, 1).toUpperCase() + value.substring(1);
  }
}

class _ActivityDetailItem {
  const _ActivityDetailItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.body,
    required this.sections,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final String body;
  final List<_ActivityDetailSection> sections;
}

class _ActivityDetailSection {
  const _ActivityDetailSection({required this.title, required this.body});

  final String title;
  final String body;
}

class _TranscriptRowView extends StatelessWidget {
  const _TranscriptRowView({required this.row});

  final _TranscriptRow row;

  @override
  Widget build(BuildContext context) {
    final row = this.row;
    return switch (row) {
      _TextTranscriptRow() => _TextTranscriptRowView(row: row),
      _ActivityTranscriptRow() => _ActivityTranscriptRowView(row: row),
    };
  }
}

class _TextTranscriptRowView extends StatelessWidget {
  const _TextTranscriptRowView({required this.row});

  final _TextTranscriptRow row;

  @override
  Widget build(BuildContext context) {
    return switch (row.style) {
      _TextTranscriptRowStyle.user => _UserMessageBubble(text: row.text),
      _TextTranscriptRowStyle.assistant =>
        _AssistantMessageText(text: row.text),
      _TextTranscriptRowStyle.muted => _MutedMessageText(text: row.text),
    };
  }
}

class _UserMessageBubble extends StatelessWidget {
  const _UserMessageBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: _AssistantMarkdown(
              text: text,
              textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.35,
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantMessageText extends StatelessWidget {
  const _AssistantMessageText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: _AssistantMarkdown(
          text: text,
          textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                height: 1.48,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
    );
  }
}

class _MutedMessageText extends StatelessWidget {
  const _MutedMessageText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _ActivityTranscriptRowView extends StatelessWidget {
  const _ActivityTranscriptRowView({required this.row});

  final _ActivityTranscriptRow row;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        onPressed: () => _showActivitySheet(context, row),
        label: Text(row.title),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _showActivitySheet(
    BuildContext context,
    _ActivityTranscriptRow row,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _ActivityDetailSheet(row: row),
    );
  }
}

class _ActivityDetailSheet extends StatefulWidget {
  const _ActivityDetailSheet({required this.row});

  final _ActivityTranscriptRow row;

  @override
  State<_ActivityDetailSheet> createState() => _ActivityDetailSheetState();
}

class _ActivityDetailSheetState extends State<_ActivityDetailSheet> {
  _ActivityDetailItem? _selectedItem;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            _sheetHeader(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                child: _selectedItem == null
                    ? _activityList(context)
                    : _itemDetail(context, _selectedItem!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetHeader(BuildContext context) {
    final selectedItem = _selectedItem;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            selectedItem?.title ?? widget.row.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: selectedItem == null ? '关闭' : '返回',
              icon:
                  Icon(selectedItem == null ? Icons.close : Icons.chevron_left),
              style: IconButton.styleFrom(
                fixedSize: const Size(52, 52),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.55),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                if (selectedItem == null) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => _selectedItem = null);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      itemCount: widget.row.items.length,
      itemBuilder: (context, index) {
        final item = widget.row.items[index];
        final isLast = index == widget.row.items.length - 1;
        return InkWell(
          onTap: () => setState(() => _selectedItem = item),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(item.icon, size: 28),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 34,
                        margin: const EdgeInsets.only(top: 7),
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.7),
                      ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (item.subtitle != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemDetail(BuildContext context, _ActivityDetailItem item) {
    return ListView.separated(
      key: ValueKey(item.id),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      itemCount: item.sections.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final section = item.sections[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: SelectableText(
                  section.body.isEmpty ? ' ' : section.body,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    height: 1.42,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AssistantMarkdown extends StatelessWidget {
  const _AssistantMarkdown({required this.text, this.textStyle});

  final String text;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final blocks = _MarkdownParser.blocks(text);
    var codeBlockIndex = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks.map((block) {
        final isLast = block == blocks.last;
        final bottomPadding = isLast ? 0.0 : 9.0;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: switch (block) {
            _MarkdownParagraph() => SelectableText(
                block.text,
                style: textStyle,
              ),
            _MarkdownBulletList() => _BulletList(
                items: block.items,
                textStyle: textStyle,
              ),
            _MarkdownCodeBlock() => _CodeBlock(
                key: Key('markdown-code-block-${codeBlockIndex++}'),
                code: block.code,
              ),
          },
        );
      }).toList(growable: false),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, this.textStyle});

  final List<String> items;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•', style: textStyle),
                  const SizedBox(width: 8),
                  Expanded(child: SelectableText(item, style: textStyle)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SelectableText(
        code.isEmpty ? ' ' : code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 15,
          height: 1.35,
        ),
      ),
    );
  }
}

sealed class _MarkdownBlock {
  const _MarkdownBlock();
}

class _MarkdownParagraph extends _MarkdownBlock {
  const _MarkdownParagraph(this.text);

  final String text;
}

class _MarkdownBulletList extends _MarkdownBlock {
  const _MarkdownBulletList(this.items);

  final List<String> items;
}

class _MarkdownCodeBlock extends _MarkdownBlock {
  const _MarkdownCodeBlock(this.code);

  final String code;
}

class _MarkdownParser {
  static List<_MarkdownBlock> blocks(String text) {
    final lines = text.split('\n');
    final blocks = <_MarkdownBlock>[];
    final paragraphLines = <String>[];
    var index = 0;

    void flushParagraph() {
      if (paragraphLines.isEmpty) return;
      blocks.add(_MarkdownParagraph(paragraphLines.join('\n')));
      paragraphLines.clear();
    }

    while (index < lines.length) {
      final line = lines[index];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('```')) {
        flushParagraph();
        final codeLines = <String>[];
        index += 1;
        while (index < lines.length &&
            !lines[index].trimLeft().startsWith('```')) {
          codeLines.add(lines[index]);
          index += 1;
        }
        if (index < lines.length) index += 1;
        blocks.add(_MarkdownCodeBlock(codeLines.join('\n')));
        continue;
      }

      final bullet = _bulletText(line);
      if (bullet != null) {
        flushParagraph();
        final items = <String>[bullet];
        index += 1;
        while (index < lines.length) {
          final nextBullet = _bulletText(lines[index]);
          if (nextBullet == null) break;
          items.add(nextBullet);
          index += 1;
        }
        blocks.add(_MarkdownBulletList(items));
        continue;
      }

      if (line.trim().isEmpty) {
        flushParagraph();
        index += 1;
        continue;
      }

      paragraphLines.add(line);
      index += 1;
    }

    flushParagraph();
    return blocks.isEmpty ? const [_MarkdownParagraph('')] : blocks;
  }

  static String? _bulletText(String line) {
    final trimmed = line.trimLeft();
    if (trimmed.length < 3) return null;
    final marker = trimmed[0];
    if ((marker == '-' || marker == '*' || marker == '+') &&
        trimmed[1] == ' ') {
      return trimmed.substring(2);
    }
    return null;
  }
}
