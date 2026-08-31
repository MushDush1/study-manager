import 'package:flutter/material.dart';

class TaskItem extends StatelessWidget {
  final String title;

  final String subtitle;

  final bool finished;

  final Function(bool?) onChanged;

  final VoidCallback onDelete;

  const TaskItem({
    super.key,

    required this.title,
    required this.subtitle,

    required this.finished,

    required this.onChanged,

    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 20)),

      subtitle: subtitle.isEmpty ? null : Text(subtitle),

      value: finished,

      onChanged: onChanged,

      secondary: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }
}
