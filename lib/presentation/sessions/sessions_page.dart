import 'package:flutter/material.dart';

import '../../domain/projects/remote_project.dart';
import '../../domain/sessions/remote_session.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({
    required this.project,
    required this.sessions,
    required this.isLoading,
    required this.errorText,
    required this.onBack,
    required this.onRefresh,
    required this.onSessionSelected,
    super.key,
  });

  final RemoteProject project;
  final List<RemoteSession> sessions;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;
  final ValueChanged<RemoteSession> onSessionSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回项目',
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(project.name),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: _buildRefreshableContent(context),
    );
  }

  Widget _buildRefreshableContent(BuildContext context) {
    final errorText = this.errorText;
    if (errorText != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: Center(
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
            ),
          ),
        ],
      );
    }

    if (sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: Center(
              child: Text(
                '暂无会话',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final session = sessions[index];
        return ListTile(
          leading: Icon(
            session.isActive ? Icons.terminal : Icons.terminal_outlined,
          ),
          title: Text(
            session.name,
            key: Key('session-name-${session.id}'),
          ),
          subtitle: Text(
            '${session.messageCount} messages · ${session.isActive ? 'active' : 'inactive'}',
          ),
          onTap: () => onSessionSelected(session),
        );
      },
    );
  }
}
