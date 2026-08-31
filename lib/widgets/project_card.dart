import 'package:flutter/material.dart';

import '../models/task.dart';

class ProjectCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF6EF), Color(0xFFFEEAE6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8D9D2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _buildIcon(task),
                        color: const Color(0xFF6D3D36),
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: const Color(0xFF7E5B56),
                      tooltip: "删除项目",
                      iconSize: 20,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF271C1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.category.isEmpty ? "未分类" : task.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A6662),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: task.sections.take(2).map((section) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        section,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6D3D36),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      "${task.sections.length} 个分类",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A6662),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF6D3D36),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _buildIcon(Task task) {
    if (task.title.contains("雅思")) {
      return Icons.headphones_rounded;
    }

    if (task.title.contains("日语")) {
      return Icons.translate_rounded;
    }

    if (task.title.contains("C++")) {
      return Icons.code_rounded;
    }

    if (task.title.contains("YOLO")) {
      return Icons.laptop_chromebook_rounded;
    }

    return Icons.menu_book_rounded;
  }
}
