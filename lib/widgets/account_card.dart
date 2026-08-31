import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import '../services/auth_store.dart';
import '../services/goal_store.dart';
import '../theme/app_colors.dart';

class AccountCard extends StatelessWidget {
    final AuthStore auth;
    final GoalStore store;
    final Future<void> Function()? onCloudLogin;

    const AccountCard({
        super.key,
        required this.auth,
        required this.store,
        this.onCloudLogin,
    });

    @override
    Widget build(BuildContext context) {
        final loggedIn = auth.isLoggedIn;

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
                    const Text(
                        "账号",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                        ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        loggedIn
                            ? "${auth.isCloudUser ? '云端账号' : '本地模式'}：${auth.currentEmail}"
                            : "未登录。可使用云端账号同步，或继续使用本地模式。",
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.textSecondary,
                        ),
                    ),
                    const SizedBox(height: 12),
                    if (auth.isCloudUser) ...[
                        Text('同步状态：${store.syncing ? '正在同步' : store.hasConflict ? '发现版本冲突' : store.syncPending ? '待同步' : '已同步'}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        if (store.lastSyncedAt != null) Text('最后同步：${store.lastSyncedAt!.toLocal().toString().substring(0, 16)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        if (store.syncError != null) Text(store.syncError!, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                            OutlinedButton(onPressed: store.syncing ? null : () => store.syncNow(), child: const Text('立即同步')),
                            if (store.hasConflict) OutlinedButton(onPressed: () => _resolveConflict(context), child: const Text('处理冲突')),
                        ]),
                        const SizedBox(height: 8),
                    ],
                    if (loggedIn)
                        OutlinedButton(
                            onPressed: () async {
                                await auth.logout();
                                store.disconnectCloud();
                                if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("已退出登录")),
                                    );
                                }
                            },
                            child: const Text("退出登录"),
                        )
                    else
                        FilledButton.icon(
                            onPressed: () => openLoginPage(context, auth, onCloudLogin: onCloudLogin),
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                            ),
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text("登录 / 注册"),
                        ),
                ],
            ),
        );
    }

    Future<void> _resolveConflict(BuildContext context) async {
        final keepLocal = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('学习数据有冲突'),
                content: const Text('两台设备都修改过数据。请选择保留本地修改并覆盖云端，或下载云端版本。'),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('下载云端版本')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('保留本地修改')),
                ],
            ),
        );
        if (keepLocal == true) { await store.uploadLocal(force: true); } else if (keepLocal == false) { await store.useCloudVersion(); }
    }
}
