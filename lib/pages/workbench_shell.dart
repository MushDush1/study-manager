import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_store.dart';
import '../services/goal_store.dart';
import '../theme/app_colors.dart';
import 'agent_page.dart';
import 'board_page.dart';
import 'check_in_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'review_page.dart';

class WorkbenchShell extends StatefulWidget {
    const WorkbenchShell({super.key});

    @override
    State<WorkbenchShell> createState() => _WorkbenchShellState();
}

class _WorkbenchShellState extends State<WorkbenchShell> {
    final GoalStore _store = GoalStore();
    final AuthStore _auth = AuthStore();
    int _tabIndex = 0;
    Timer? _ticker;

    @override
    void initState() {
        super.initState();
        _store.addListener(_onStoreChanged);
        _auth.addListener(_onStoreChanged);
        _initialize();
        _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
            _store.tick();
        });
    }

    @override
    void dispose() {
        _ticker?.cancel();
        _store.removeListener(_onStoreChanged);
        _auth.removeListener(_onStoreChanged);
        _store.dispose();
        _auth.dispose();
        super.dispose();
    }

    void _onStoreChanged() {
        setState(() {});
    }

    Future<void> _initialize() async {
        await _store.load();
        await _auth.load();
        if (_auth.isCloudUser) await _connectCloud();
    }

    Future<void> _connectCloud() async {
        final result = await _store.connectCloud();
        if (!mounted || result != CloudBootstrapResult.cloudEmpty) return;
        final upload = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('云端还没有学习数据'),
                content: const Text('是否把当前设备的学习记录上传到云端？'),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('暂不上传')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('上传本地记录')),
                ],
            ),
        );
        if (upload == true) await _store.uploadLocal();
    }

    @override
    Widget build(BuildContext context) {
        if (!_store.loaded || !_auth.loaded) {
            return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator()),
            );
        }

        final pages = [
            HomePage(
                store: _store,
                onOpenCheckIn: (index) {
                    setState(() {
                        _tabIndex = index;
                    });
                },
                onOpenReview: () {
                    setState(() {
                        _tabIndex = 3;
                    });
                },
            ),
            CheckInPage(store: _store),
            BoardPage(
                store: _store,
                onOpenGoal: (goalId) {
                    _store.selectGoalById(goalId);
                    setState(() {
                        _tabIndex = 1;
                    });
                },
            ),
            ReviewPage(store: _store),
            ProfilePage(store: _store, auth: _auth, onCloudLogin: _connectCloud),
        ];

        // 固定手机比例内容区，窗口拉大时仍居中显示
        return ColoredBox(
            color: AppColors.background,
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Scaffold(
                        backgroundColor: AppColors.background,
                        appBar: AppBar(
                            toolbarHeight: 48,
                            title: _store.timerRunning
                                ? Text("学习工作台  ${_store.timerDisplay}")
                                : const Text("学习工作台"),
                            titleTextStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                            ),
                            backgroundColor: AppColors.background,
                            foregroundColor: AppColors.text,
                            elevation: 0,
                            actions: [
                                if (!_auth.isLoggedIn)
                                    TextButton(
                                        onPressed: () => openLoginPage(context, _auth),
                                        child: const Text("登录"),
                                    ),
                                Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: TextButton.icon(
                                        onPressed: () => openAgentPage(context, _store),
                                        icon: const Icon(Icons.auto_awesome, size: 18),
                                        label: const Text("Agent"),
                                    ),
                                ),
                            ],
                        ),
                        body: IndexedStack(
                            index: _tabIndex,
                            children: pages,
                        ),
                        bottomNavigationBar: NavigationBar(
                            height: 64,
                            selectedIndex: _tabIndex,
                            onDestinationSelected: (index) {
                                setState(() {
                                    _tabIndex = index;
                                });
                            },
                            backgroundColor: Colors.white,
                            indicatorColor: AppColors.sidebarSelected,
                            destinations: const [
                                NavigationDestination(
                                    icon: Icon(Icons.home_outlined),
                                    selectedIcon: Icon(
                                        Icons.home_rounded,
                                        color: AppColors.primary,
                                    ),
                                    label: "首页",
                                ),
                                NavigationDestination(
                                    icon: Icon(Icons.favorite_border),
                                    selectedIcon: Icon(
                                        Icons.favorite,
                                        color: AppColors.primary,
                                    ),
                                    label: "打卡",
                                ),
                                NavigationDestination(
                                    icon: Icon(Icons.table_chart_outlined),
                                    selectedIcon: Icon(
                                        Icons.table_chart,
                                        color: AppColors.primary,
                                    ),
                                    label: "看板",
                                ),
                                NavigationDestination(
                                    icon: Icon(Icons.menu_book_outlined),
                                    selectedIcon: Icon(
                                        Icons.menu_book_rounded,
                                        color: AppColors.primary,
                                    ),
                                    label: "复习",
                                ),
                                NavigationDestination(
                                    icon: Icon(Icons.person_outline),
                                    selectedIcon: Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                    ),
                                    label: "我的",
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
