import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/group_membership.dart';

class GroupListTile extends StatelessWidget {
  const GroupListTile({super.key, required this.membership});

  final GroupMembership membership;

  @override
  Widget build(BuildContext context) {
    final group = membership.group!;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          child: Text(group.name.isNotEmpty ? group.name[0].toUpperCase() : '?'),
        ),
        title: Text(group.name),
        subtitle: Text(membership.role.label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/groups/${group.id}', extra: group),
      ),
    );
  }
}
