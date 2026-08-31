import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/goal.dart';
import '../services/app_jumper.dart';
import '../theme/app_colors.dart';

class ResourceJumpBar extends StatelessWidget {
    final Goal goal;
    final VoidCallback onEdit;

    const ResourceJumpBar({
        super.key,
        required this.goal,
        required this.onEdit,
    });

    Future<void> _openBilibili(BuildContext context) async {
        final target = goal.videoLink.trim();

        if (target.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("还没有填写 B 站链接")),
            );
            return;
        }

        final uri = Uri.tryParse(target);
        if (uri == null || !uri.hasScheme) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("链接格式不正确，请填写完整网页链接")),
            );
            return;
        }

        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("打开失败，请检查链接是否可用")),
            );
        }
    }

    Future<void> _openLocalFile(BuildContext context) async {
        final target = goal.localFilePath.trim();

        if (target.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("还没有填写本地 Excel / 文件路径")),
            );
            return;
        }

        final normalized = target.replaceAll("\\", "/");
        final uri = Uri.parse("file:///$normalized");
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("打开失败，请检查本地路径是否正确")),
            );
        }
    }

    Future<void> _copyText(BuildContext context, String text, String label) async {
        if (text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("还没有填写$label")),
            );
            return;
        }

        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("已复制$label")),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        children: [
                            const Text(
                                "学习资料",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                ),
                            ),
                            const Spacer(),
                            IconButton(
                                onPressed: onEdit,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: "编辑资料",
                            ),
                        ],
                    ),
                    _InfoLine(
                        label: "B站链接",
                        value: goal.videoLink,
                        emptyText: "未填写，点编辑补上完整链接",
                    ),
                    _InfoLine(
                        label: "百度网盘视频",
                        value: goal.baiduVideoName,
                        emptyText: "未填写课程 / 视频名",
                    ),
                    _InfoLine(
                        label: "网盘位置",
                        value: goal.baiduFolderPath,
                        emptyText: "未填写文件夹位置",
                    ),
                    _InfoLine(
                        label: "本地 Excel",
                        value: goal.localFilePath,
                        emptyText: "未填写本地文件路径",
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                            FilledButton.icon(
                                onPressed: () => AppJumper.openBubeiDanci(context),
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF8A3D),
                                ),
                                icon: const Icon(Icons.menu_book_rounded, size: 18),
                                label: const Text("打开不背单词"),
                            ),
                            FilledButton.icon(
                                onPressed: () => _openBilibili(context),
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A1D6),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                label: const Text("打开B站"),
                            ),
                            OutlinedButton.icon(
                                onPressed: () => _openLocalFile(context),
                                icon: const Icon(Icons.folder_open_rounded, size: 18),
                                label: const Text("打开本地文件"),
                            ),
                            TextButton.icon(
                                onPressed: () => _copyText(
                                    context,
                                    [
                                        goal.baiduVideoName,
                                        goal.baiduFolderPath,
                                    ].where((item) => item.trim().isNotEmpty).join("\n"),
                                    "网盘信息",
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text("复制网盘信息"),
                            ),
                        ],
                    ),
                ],
            ),
        );
    }
}

class _InfoLine extends StatelessWidget {
    final String label;
    final String value;
    final String emptyText;

    const _InfoLine({
        required this.label,
        required this.value,
        required this.emptyText,
    });

    @override
    Widget build(BuildContext context) {
        final hasValue = value.trim().isNotEmpty;

        return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
                TextSpan(
                    children: [
                        TextSpan(
                            text: "$label：",
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                            ),
                        ),
                        TextSpan(
                            text: hasValue ? value : emptyText,
                            style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: hasValue
                                    ? AppColors.textSecondary
                                    : const Color(0xFFB5A4A7),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
