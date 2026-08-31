import 'package:flutter/material.dart';

import '../services/app_jumper.dart';
import '../theme/app_colors.dart';

/// 首页 / 打卡页的第三方 App 跳转入口
class JumpPlatformCard extends StatelessWidget {
    const JumpPlatformCard({super.key});

    @override
    Widget build(BuildContext context) {
        return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Text(
                        "跳转平台",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                        ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                        "手机上已安装即可直接打开。未安装会去应用商店或官网。",
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                        ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                        onPressed: () => AppJumper.openBubeiDanci(context),
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A3D),
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text("打开不背单词"),
                    ),
                ],
            ),
        );
    }
}
