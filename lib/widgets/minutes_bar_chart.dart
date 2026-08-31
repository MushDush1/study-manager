import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MinutesBarChart extends StatelessWidget {
    final List<DateTime> dates;
    final List<int> minutes;
    final List<Color> colors;
    final String title;
    final List<String>? xLabels;

    const MinutesBarChart({
        super.key,
        required this.dates,
        required this.minutes,
        required this.colors,
        this.title = "学习分钟",
        this.xLabels,
    });

    @override
    Widget build(BuildContext context) {
        final maxValue = minutes.fold<int>(0, (sum, item) => item > sum ? item : sum);
        final chartMax = maxValue <= 0 ? 50 : ((maxValue / 10).ceil() * 10);

        return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                        ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                        height: 220,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                SizedBox(
                                    width: 28,
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                            Text("$chartMax", style: _axisStyle),
                                            Text("${(chartMax * 0.75).round()}", style: _axisStyle),
                                            Text("${(chartMax * 0.5).round()}", style: _axisStyle),
                                            Text("${(chartMax * 0.25).round()}", style: _axisStyle),
                                            const Text("0", style: _axisStyle),
                                        ],
                                    ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: LayoutBuilder(
                                        builder: (context, constraints) {
                                            return Stack(
                                                children: [
                                                    Column(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: List.generate(5, (index) {
                                                            return Container(
                                                                height: 1,
                                                                color: AppColors.border,
                                                            );
                                                        }),
                                                    ),
                                                    Row(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: List.generate(dates.length, (index) {
                                                            final value = minutes[index];
                                                            final height = chartMax == 0
                                                                ? 0.0
                                                                : (value / chartMax) * (constraints.maxHeight - 22);
                                                            return Expanded(
                                                                child: Padding(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                                                    child: Column(
                                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                                        children: [
                                                                            Container(
                                                                                height: height < 2 && value > 0 ? 2 : height,
                                                                                decoration: BoxDecoration(
                                                                                    color: colors[index % colors.length],
                                                                                    borderRadius: const BorderRadius.vertical(
                                                                                        top: Radius.circular(4),
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            const SizedBox(height: 6),
                                                                            Text(
                                                                                xLabels != null && index < xLabels!.length
                                                                                    ? xLabels![index]
                                                                                    : "${dates[index].month}/${dates[index].day}",
                                                                                style: const TextStyle(
                                                                                    fontSize: 9,
                                                                                    color: AppColors.textSecondary,
                                                                                ),
                                                                            ),
                                                                        ],
                                                                    ),
                                                                ),
                                                            );
                                                        }),
                                                    ),
                                                ],
                                            );
                                        },
                                    ),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        );
    }

    static const TextStyle _axisStyle = TextStyle(
        fontSize: 11,
        color: AppColors.textSecondary,
    );
}
