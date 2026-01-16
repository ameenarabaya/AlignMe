import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PostureWeekChartCard extends StatelessWidget {
  // ✅ لتجميع الأيام على (UTC+2 ثابت) لكل الأجهزة
  final int fixedOffsetMinutes;

  const PostureWeekChartCard({
    super.key,
    this.fixedOffsetMinutes = 120,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: const Text('Please login again'),
      );
    }

    final nowFixed = _applyFixedOffset(DateTime.now().toUtc());

    // بداية اليوم (بالتوقيت الثابت)
    final todayFixedStart = DateTime.utc(nowFixed.year, nowFixed.month, nowFixed.day);

    // آخر 7 أيام (اليوم + 6 أيام قبل)
    final startFixed = todayFixedStart.subtract(const Duration(days: 6));

    // نرجعها UTC للـ query
    final startUtc = startFixed.subtract(Duration(minutes: fixedOffsetMinutes));

    final stream = FirebaseFirestore.instance
        .collection('Notifications') // ✅ نفس اسم الكولكشن عندك (N كبيرة)
        .where('userId', isEqualTo: uid) // ✅ فلترة حسب اليوزر
        .where('Timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startUtc))
        .orderBy('Timestamp') // ascending
        .snapshots();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bad posture (Last 7 days)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'Firestore error:\n${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // counts per day (حسب UTC+2 الثابت)
                final countsByDay = <String, int>{};
                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final ts = data['Timestamp'];
                  if (ts is! Timestamp) continue;

                  final fixed = _applyFixedOffset(_timestampAsUtc(ts));
                  final key = _dayKey(fixed);
                  countsByDay[key] = (countsByDay[key] ?? 0) + 1;
                }

                final days = List<DateTime>.generate(7, (i) {
                  // i=0 أقدم يوم .. i=6 اليوم
                  return startFixed.add(Duration(days: i));
                });

                final labels = days.map(_weekdayLabel).toList(); // Mon Tue ...
                final values = days.map((day) {
                  final key = _dayKey(day);
                  return (countsByDay[key] ?? 0).toDouble();
                }).toList();

                final maxVal =
                values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);

                final maxY = (maxVal + 2).clamp(5, 9999).toDouble();
                final interval = _niceInterval(maxY);

                return BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: colors.outlineVariant,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        left: BorderSide(color: colors.outlineVariant),
                        bottom: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: interval,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.onSurface.withOpacity(0.6),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: _barGroups(context, values),
                    barTouchData: BarTouchData(enabled: false),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _barGroups(BuildContext context, List<double> values) {
    final colors = Theme.of(context).colorScheme;

    return List.generate(values.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i],
            width: 12,
            borderRadius: BorderRadius.circular(3),
            color: colors.primary,
          ),
        ],
      );
    });
  }

  // ===== Helpers =====

  DateTime _timestampAsUtc(Timestamp ts) => DateTime.fromMillisecondsSinceEpoch(
    ts.millisecondsSinceEpoch,
    isUtc: true,
  );

  DateTime _applyFixedOffset(DateTime utc) =>
      utc.add(Duration(minutes: fixedOffsetMinutes));

  String _pad2(int n) => n.toString().padLeft(2, '0');

  String _dayKey(DateTime dt) =>
      '${dt.year}-${_pad2(dt.month)}-${_pad2(dt.day)}';

  // ✅ أسماء الأيام بدل التاريخ
  String _weekdayLabel(DateTime dt) {
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return en[dt.weekday - 1];
  }

  double _niceInterval(double maxY) {
    if (maxY <= 10) return 1;
    if (maxY <= 20) return 2;
    if (maxY <= 50) return 5;
    if (maxY <= 100) return 10;
    return 20;
  }
}
