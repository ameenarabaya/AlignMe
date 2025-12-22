import 'package:cloud_firestore/cloud_firestore.dart';

const int fixedOffsetMinutes = 120; // UTC+2

DateTime timestampAsUtc(Timestamp ts) =>
    DateTime.fromMillisecondsSinceEpoch(
      ts.millisecondsSinceEpoch,
      isUtc: true,
    );

DateTime applyFixedOffset(DateTime utc) =>
    utc.add(const Duration(minutes: fixedOffsetMinutes));

String pad2(int n) => n.toString().padLeft(2, '0');

String dayKey(DateTime dt) =>
    '${dt.year}-${pad2(dt.month)}-${pad2(dt.day)}';

String labelDayMonth(DateTime dt) =>
    '${pad2(dt.day)}/${pad2(dt.month)}';

double niceInterval(double maxY) {
  if (maxY <= 10) return 1;
  if (maxY <= 20) return 2;
  if (maxY <= 50) return 5;
  if (maxY <= 100) return 10;
  return 20;
}
