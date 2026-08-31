import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:study_manager/main.dart';

void main() {
    testWidgets('工作台首页能显示今日计划入口', (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(const MyApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text("学习工作台"), findsOneWidget);
        expect(find.text("今日计划"), findsOneWidget);
        expect(find.text("安排"), findsOneWidget);
    });
}
