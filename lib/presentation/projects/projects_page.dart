import 'package:flutter/material.dart';

import '../../domain/projects/remote_project.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({
    required this.daemonName,
    required this.daemonBaseUrl,
    required this.projects,
    required this.onProjectSelected,
    required this.onUnpair,
    required this.onRefresh,
    super.key,
  });

  final String daemonName;
  final Uri daemonBaseUrl;
  final List<RemoteProject> projects;
  final ValueChanged<RemoteProject> onProjectSelected;
  final Future<void> Function() onUnpair;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F7),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _Header(onScanPairing: () {}),
              _RemotesSection(
                title: _daemonDisplayHost,
                onUnpair: onUnpair,
              ),
              _ProjectsSection(
                projects: projects,
                onProjectSelected: onProjectSelected,
              ),
            ],
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
  const _Header({required this.onScanPairing});

  final VoidCallback onScanPairing;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: '扫码配对',
                onPressed: onScanPairing,
                icon: const Icon(Icons.qr_code_scanner),
                style: IconButton.styleFrom(
                  fixedSize: const Size(52, 52),
                  backgroundColor: const Color(0xFFF7F7F9),
                  foregroundColor: Colors.black,
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: 0.12),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Projects',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.8,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemotesSection extends StatelessWidget {
  const _RemotesSection({required this.title, required this.onUnpair});

  final String title;
  final Future<void> Function() onUnpair;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REMOTES',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.black.withValues(alpha: 0.42),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
            ),
            const SizedBox(height: 12),
            PopupMenuButton<String>(
              tooltip: '远程 daemon 操作',
              position: PopupMenuPosition.under,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
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
          ],
        ),
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
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: accent, size: 24),
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
    if (projects.isEmpty) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.48,
        child: Center(
          child: Text(
            '暂无项目',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            for (var index = 0; index < projects.length; index += 1) ...[
              _ProjectRow(
                project: projects[index],
                onTap: () => onProjectSelected(projects[index]),
              ),
              if (index != projects.length - 1)
                Divider(
                  height: 1,
                  indent: 24,
                  endIndent: 24,
                  color: Colors.black.withValues(alpha: 0.10),
                ),
            ],
          ],
        ),
      ),
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
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
