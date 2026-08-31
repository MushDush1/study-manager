import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/workbench_shell.dart';
import 'theme/app_colors.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "学习工作台",
            locale: const Locale("zh", "CN"),
            supportedLocales: const [
                Locale("zh", "CN"),
            ],
            localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: AppColors.primary,
                    brightness: Brightness.light,
                ),
                scaffoldBackgroundColor: AppColors.background,
                appBarTheme: const AppBarTheme(
                    foregroundColor: AppColors.text,
                    centerTitle: false,
                ),
                cardColor: AppColors.card,
                useMaterial3: true,
            ),
            home: const WorkbenchShell(),
        );
    }
}
