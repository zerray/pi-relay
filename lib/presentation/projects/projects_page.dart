import 'package:flutter/material.dart';

import '../../domain/projects/remote_project.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({
    required this.daemonName,
    required this.projects,
    required this.onProjectSelected,
    super.key,
  });

  final String daemonName;
  final List<RemoteProject> projects;
  final ValueChanged<RemoteProject> onProjectSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目'),
      ),
      body: projects.isEmpty
          ? Center(
              child:
                  Text('暂无项目', style: Theme.of(context).textTheme.titleMedium),
            )
          : ListView.separated(
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
    );
  }
}
