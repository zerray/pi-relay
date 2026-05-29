import 'package:flutter/material.dart';

import '../../domain/projects/remote_project.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({
    required this.daemonName,
    required this.projects,
    required this.onProjectSelected,
    required this.onRefresh,
    super.key,
  });

  final String daemonName;
  final List<RemoteProject> projects;
  final ValueChanged<RemoteProject> onProjectSelected;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目'),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: projects.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: Center(
                      child: Text(
                        '暂无项目',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: projects.length + 1,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      title: Text(daemonName),
                      subtitle: const Text('已配对 daemon'),
                      leading: const Icon(Icons.hub_outlined),
                    );
                  }

                  final project = projects[index - 1];
                  return ListTile(
                    title: Text(project.name),
                    subtitle: Text(project.path),
                    leading: const Icon(Icons.folder_outlined),
                    onTap: () => onProjectSelected(project),
                  );
                },
              ),
      ),
    );
  }
}
