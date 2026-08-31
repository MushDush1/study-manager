import 'package:flutter/material.dart';

/// 工作台粉色主题，对齐截图里的浅底 + 玫红强调色
class AppColors {
    static const Color background = Color(0xFFFDF6F5);
    static const Color card = Colors.white;
    static const Color primary = Color(0xFFE85A71);
    static const Color primaryDark = Color(0xFFC9445A);
    static const Color text = Color(0xFF2B2426);
    static const Color textSecondary = Color(0xFF8A7A7D);
    static const Color border = Color(0xFFF0E4E6);
    static const Color sidebarSelected = Color(0xFFFFE8EC);

    static int accentValue(int index) {
        return accentPalette[index % accentPalette.length].toARGB32();
    }

    static const List<Color> accentPalette = [
        Color(0xFFE85A71),
        Color(0xFFFF8A5B),
        Color(0xFF5B8DEF),
        Color(0xFF3ECF8E),
        Color(0xFFB07CFF),
        Color(0xFF26C6DA),
        Color(0xFFFFB347),
        Color(0xFFEF5B78),
        Color(0xFF6C9BFF),
        Color(0xFF7BC67E),
    ];
}
