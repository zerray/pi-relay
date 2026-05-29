import 'package:flutter/material.dart';

import '../../domain/projects/remote_project.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({
    required this.daemonName,
    required this.daemonBaseUrl,
    required this.projects,
    required this.onProjectSelected,
    required this.onUnpair,
    required this.onPairingPayloadSubmitted,
    required this.onRefresh,
    super.key,
  });

  final String daemonName;
  final Uri daemonBaseUrl;
  final List<RemoteProject> projects;
  final ValueChanged<RemoteProject> onProjectSelected;
  final Future<void> Function() onUnpair;
  final Future<void> Function(String pairingPayload) onPairingPayloadSubmitted;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F7),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                children: [
                  _Header(onPairingPayloadSubmitted: onPairingPayloadSubmitted),
                  const SizedBox(height: 28),
                  _RemotesSection(
                    title: _daemonDisplayHost,
                    onUnpair: onUnpair,
                  ),
                  const SizedBox(height: 28),
                  _ProjectsSection(
                    projects: projects,
                    onProjectSelected: onProjectSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _daemonDisplayHost {
    final host = daemonBaseUrl.host.trim();
    if (host.isNotEmpty) return host;
    return daemonName;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onPairingPayloadSubmitted});

  final Future<void> Function(String pairingPayload) onPairingPayloadSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            'Projects',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                ),
          ),
        ),
        FilledButton.tonalIcon(
          key: const Key('project-list-pair-button'),
          onPressed: () => _showPairingDialog(context),
          icon: const Icon(Icons.link),
          label: const Text('输入配对字符串'),
        ),
      ],
    );
  }

  Future<void> _showPairingDialog(BuildContext context) async {
    final payload = await showDialog<String>(
      context: context,
      builder: (context) => const _PairingPayloadDialog(),
    );
    if (payload == null || payload.trim().isEmpty) return;
    await onPairingPayloadSubmitted(payload.trim());
  }
}

class _RemotesSection extends StatelessWidget {
  const _RemotesSection({required this.title, required this.onUnpair});

  final String title;
  final Future<void> Function() onUnpair;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'REMOTES',
      child: PopupMenuButton<String>(
        tooltip: '远程 daemon 操作',
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 12,
        onSelected: (_) => onUnpair(),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'unpair',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 36, vertical: 10),
              child: Text(
                'Unpair',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
        child: _RemoteChip(title: title),
      ),
    );
  }
}

class _RemoteChip extends StatelessWidget {
  const _RemoteChip({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2F80ED);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: accent, size: 23),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({
    required this.projects,
    required this.onProjectSelected,
  });

  final List<RemoteProject> projects;
  final ValueChanged<RemoteProject> onProjectSelected;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'PROJECTS',
      child: projects.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 38),
              child: Center(
                child: Text(
                  '暂无项目',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                ),
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < projects.length; index += 1) ...[
                  _ProjectRow(
                    project: projects[index],
                    onTap: () => onProjectSelected(projects[index]),
                  ),
                  if (index != projects.length - 1)
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Colors.black.withValues(alpha: 0.10),
                    ),
                ],
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.black.withValues(alpha: 0.42),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project, required this.onTap});

  final RemoteProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              project.path,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PairingPayloadDialog extends StatefulWidget {
  const _PairingPayloadDialog();

  @override
  State<_PairingPayloadDialog> createState() => _PairingPayloadDialogState();
}

class _PairingPayloadDialogState extends State<_PairingPayloadDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('输入配对字符串'),
      content: TextField(
        key: const Key('pairing-payload-field'),
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '配对字符串',
          helperText: '粘贴 /remote-control-pair 显示的 hex payload',
        ),
        minLines: 1,
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('配对'),
        ),
      ],
    );
  }
}
