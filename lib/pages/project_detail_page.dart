import 'package:flutter/material.dart';

import '../models/task.dart';
import 'section_entries_page.dart';

class ProjectDetailPage extends StatelessWidget {
  final Task task;
  final Future<void> Function(Task task) onTaskUpdated;

  const ProjectDetailPage({
    super.key,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final totalMinutes = task.actualMinutes;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(task.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFFCEADF), Color(0xFFFFF6EF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.category.isEmpty ? "学习项目" : task.category,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A6B63),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF261A18),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _InfoChip(
                      label: "今日计划",
                      value: "${task.plannedMinutes} 分钟",
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(label: "累计学习", value: "$totalMinutes 分钟"),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "点进下面的分类后，后面我们可以继续给每个分类加具体学习内容、视频链接、学习记录和复习总结。",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF6D5550),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "学习分类",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF261A18),
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.18,
            ),
            itemCount: task.sections.length,
            itemBuilder: (context, index) {
              final section = task.sections[index];
              final entryCount = task.sectionEntries[section]?.length ?? 0;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SectionEntriesPage(
                          task: task,
                          sectionName: section,
                          onTaskUpdated: onTaskUpdated,
                        ),
                      ),
                    );
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0EB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _iconForSection(section),
                              color: const Color(0xFF6D3D36),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            section,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF261A18),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entryCount == 0
                                ? "还没有学习记录"
                                : "已有 $entryCount 条学习记录",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7E6761),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "下一步可以继续做",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF261A18),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "1. 点分类进入具体内容页",
                  style: TextStyle(fontSize: 14, color: Color(0xFF6D5550)),
                ),
                SizedBox(height: 6),
                Text(
                  "2. 记录学了什么、视频链接、学习时间和复盘",
                  style: TextStyle(fontSize: 14, color: Color(0xFF6D5550)),
                ),
                SizedBox(height: 6),
                Text(
                  "3. 再补上打卡统计和周报表",
                  style: TextStyle(fontSize: 14, color: Color(0xFF6D5550)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForSection(String section) {
    switch (section) {
      case "听":
      case "听力":
        return Icons.headphones_rounded;
      case "说":
      case "口语":
        return Icons.record_voice_over_rounded;
      case "读":
      case "阅读":
        return Icons.chrome_reader_mode_rounded;
      case "写":
      case "写作":
        return Icons.edit_note_rounded;
      case "单词":
        return Icons.abc_rounded;
      case "语法":
        return Icons.rule_rounded;
      case "刷题":
        return Icons.checklist_rounded;
      case "代码实现":
        return Icons.code_rounded;
      default:
        return Icons.folder_open_rounded;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A6B63)),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF261A18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
