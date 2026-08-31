import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/study_entry.dart';
import '../models/task.dart';

class SectionEntriesPage extends StatefulWidget {
  final Task task;
  final String sectionName;
  final Future<void> Function(Task task) onTaskUpdated;

  const SectionEntriesPage({
    super.key,
    required this.task,
    required this.sectionName,
    required this.onTaskUpdated,
  });

  @override
  State<SectionEntriesPage> createState() => _SectionEntriesPageState();
}

class _SectionEntriesPageState extends State<SectionEntriesPage> {
  List<StudyEntry> get entries =>
      widget.task.sectionEntries[widget.sectionName] ?? <StudyEntry>[];

  Future<void> addEntry() async {
    await openEntryEditor();
  }

  Future<void> openEntryEditor({StudyEntry? existingEntry, int? index}) async {
    final titleController = TextEditingController();
    final linkController = TextEditingController();
    final baiduVideoNameController = TextEditingController();
    final baiduFolderPathController = TextEditingController();
    final localFilePathController = TextEditingController();
    final minutesController = TextEditingController();
    final summaryController = TextEditingController();
    final dateController = TextEditingController();

    if (existingEntry != null) {
      titleController.text = existingEntry.title;
      linkController.text = existingEntry.videoLink;
      baiduVideoNameController.text = existingEntry.baiduVideoName;
      baiduFolderPathController.text = existingEntry.baiduFolderPath;
      localFilePathController.text = existingEntry.localFilePath;
      minutesController.text = existingEntry.studyMinutes.toString();
      summaryController.text = existingEntry.reviewSummary;
      dateController.text = existingEntry.studyDate;
    } else {
      dateController.text = DateTime.now().toString().split(" ").first;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            existingEntry == null
                ? "添加${widget.sectionName}内容"
                : "编辑${widget.sectionName}内容",
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: "今天学了什么"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(hintText: "B站或网页链接（可选）"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: baiduVideoNameController,
                  decoration: const InputDecoration(hintText: "百度网盘视频名（可选）"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: baiduFolderPathController,
                  decoration: const InputDecoration(hintText: "百度网盘文件夹位置（可选）"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: localFilePathController,
                  decoration: const InputDecoration(
                    hintText: "本地文件路径（Excel/PDF/文件夹，可选）",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "学习时长（分钟）"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(hintText: "学习日期"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: summaryController,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: "复习总结"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  return;
                }

                final minutes =
                    int.tryParse(minutesController.text.trim()) ?? 0;

                setState(() {
                  if (existingEntry == null) {
                    entries.add(
                      StudyEntry(
                        title: titleController.text.trim(),
                        videoLink: linkController.text.trim(),
                        baiduVideoName: baiduVideoNameController.text.trim(),
                        baiduFolderPath: baiduFolderPathController.text.trim(),
                        localFilePath: localFilePathController.text.trim(),
                        studyMinutes: minutes,
                        studyDate: dateController.text.trim(),
                        reviewSummary: summaryController.text.trim(),
                      ),
                    );
                    widget.task.actualMinutes += minutes;
                  } else {
                    final oldMinutes = existingEntry.studyMinutes;
                    existingEntry.title = titleController.text.trim();
                    existingEntry.videoLink = linkController.text.trim();
                    existingEntry.baiduVideoName = baiduVideoNameController.text
                        .trim();
                    existingEntry.baiduFolderPath = baiduFolderPathController
                        .text
                        .trim();
                    existingEntry.localFilePath = localFilePathController.text
                        .trim();
                    existingEntry.studyMinutes = minutes;
                    existingEntry.studyDate = dateController.text.trim();
                    existingEntry.reviewSummary = summaryController.text.trim();
                    if (index != null) {
                      entries[index] = existingEntry;
                    }
                    widget.task.actualMinutes =
                        widget.task.actualMinutes - oldMinutes + minutes;
                  }
                });

                await widget.onTaskUpdated(widget.task);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("保存"),
            ),
          ],
        );
      },
    );
  }

  Future<void> toggleFinished(int index, bool? value) async {
    setState(() {
      entries[index].finished = value ?? false;
    });
    await widget.onTaskUpdated(widget.task);
  }

  Future<void> deleteEntry(int index) async {
    final removed = entries[index];

    setState(() {
      entries.removeAt(index);
      widget.task.actualMinutes =
          (widget.task.actualMinutes - removed.studyMinutes).clamp(0, 999999);
    });

    await widget.onTaskUpdated(widget.task);
  }

  Future<void> openResource(StudyEntry entry) async {
    final target = entry.videoLink.trim();

    if (target.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("这条记录还没有填写资料链接")));
      return;
    }

    Uri? uri = Uri.tryParse(target);

    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("链接格式不正确，请填写完整网页链接")));
      }
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("打开失败，请检查链接是否可用")));
    }
  }

  Future<void> openLocalFile(StudyEntry entry) async {
    final target = entry.localFilePath.trim();

    if (target.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("这条记录还没有填写本地文件路径")));
      return;
    }

    final normalized = target.replaceAll("\\", "/");
    final uri = Uri.parse("file:///$normalized");
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("打开失败，请检查本地路径是否正确")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      appBar: AppBar(
        title: Text("${widget.task.title} · ${widget.sectionName}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFFDECE7), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Text(
              "这里开始记录具体学习内容。B站可以直接放链接，百度网盘记录视频名和文件夹位置，本地 Excel 或 PDF 则可以直接填写文件路径打开。",
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF715B56),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                "学习记录",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF261A18),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: addEntry,
                icon: const Icon(Icons.add),
                label: const Text("新增内容"),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                "这里还没有内容。先添加第一条学习记录，比如“剑桥雅思 Test 3 Section 2”。",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF6D5550),
                ),
              ),
            )
          else
            ...List.generate(entries.length, (index) {
              final entry = entries[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.title,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF261A18),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _InfoTag(
                                      text: entry.studyDate.isEmpty
                                          ? "未填日期"
                                          : entry.studyDate,
                                    ),
                                    _InfoTag(text: "${entry.studyMinutes} 分钟"),
                                    _InfoTag(
                                      text: entry.finished ? "已完成" : "进行中",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: entry.finished,
                            onChanged: (value) => toggleFinished(index, value),
                          ),
                        ],
                      ),
                      if (entry.videoLink.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          "B站/网页链接：${entry.videoLink}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6D5550),
                          ),
                        ),
                      ],
                      if (entry.baiduVideoName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          "百度网盘视频：${entry.baiduVideoName}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6D5550),
                          ),
                        ),
                      ],
                      if (entry.baiduFolderPath.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          "网盘位置：${entry.baiduFolderPath}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6D5550),
                          ),
                        ),
                      ],
                      if (entry.localFilePath.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          "本地文件：${entry.localFilePath}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6D5550),
                          ),
                        ),
                      ],
                      if (entry.reviewSummary.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          entry.reviewSummary,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF6D5550),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (entry.videoLink.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => openResource(entry),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text("打开链接"),
                            ),
                          if (entry.localFilePath.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => openLocalFile(entry),
                              icon: const Icon(Icons.folder_open_rounded),
                              label: const Text("打开本地文件"),
                            ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => openEntryEditor(
                              existingEntry: entry,
                              index: index,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text("编辑"),
                          ),
                          TextButton.icon(
                            onPressed: () => deleteEntry(index),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text("删除"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String text;

  const _InfoTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF7A5D56),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
