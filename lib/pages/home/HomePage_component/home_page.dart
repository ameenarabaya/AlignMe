import 'dart:async';
import 'package:alignme/pages/home/HomePage_component/Home_AppBar.dart';
import 'package:alignme/pages/home/HomePage_component/LastPostureAlertCard.dart';
import 'package:alignme/pages/home/HomePage_component/home_state.dart';
import 'package:alignme/pages/home/HomePage_component/posture_chart.dart';
import 'package:alignme/pages/home/HomePage_component/posture_status_card.dart';
import 'package:alignme/pages/home/HomePage_component/posture_tips_section.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ✅ لتجميع الشارت على "يوم ثابت" لكل الأجهزة (UTC+2 ثابت)
  static const int fixedOffsetMinutes = 120;

  // ✅ شرط التحويل Good بعد كم ثانية بدون إشعار
  static const int goodAfterSeconds = 30;

  // ===== Posture status state =====
  bool _isPostureGood = true;
  DateTime? _lastBadUtc; // آخر مرة وصل Bad (UTC)

  StreamSubscription<QuerySnapshot>? _lastBadSub;
  Timer? _statusTimer;

  late final Future<String> _usernameFuture;

  @override
  void initState() {
    super.initState();
    _usernameFuture = _getUsername();
    _listenToLastBadNotification();
    _startStatusTimer();
  }

  @override
  void dispose() {
    _lastBadSub?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<String> _getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';

    final dn = user.displayName;
    if (dn != null && dn.trim().isNotEmpty) return dn.trim();

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final name = doc.data()?['username']?.toString();
    if (name != null && name.trim().isNotEmpty) return name.trim();

    return user.email?.split('@').first ?? 'User';
  }

  // =========================
  // ✅ Listen to latest BAD notification
  // =========================
  void _listenToLastBadNotification() {
    final q = FirebaseFirestore.instance
        .collection('Notifications')
    // إذا عندك userId داخل الوثيقة فعّلي السطر:
    // .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('Timestamp', descending: true)
        .limit(1);

    _lastBadSub = q.snapshots().listen((snap) {
      if (snap.docs.isEmpty) {
        _lastBadUtc = null;
        if (mounted && _isPostureGood == false) {
          setState(() => _isPostureGood = true);
        }
        return;
      }

      final data = snap.docs.first.data() as Map<String, dynamic>;
      final ts = data['Timestamp'];

      if (ts is Timestamp) {
        _lastBadUtc = ts.toDate().toUtc();
        if (mounted && _isPostureGood == true) {
          setState(() => _isPostureGood = false);
        }
      }
    });
  }

  // =========================
  // ✅ Timer: كل ثانية افحص إذا صارت Good
  // =========================
  void _startStatusTimer() {
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final last = _lastBadUtc;

      final nextGood = (last == null)
          ? true
          : DateTime.now().toUtc().difference(last) >
          const Duration(seconds: goodAfterSeconds);

      if (!mounted) return;

      if (nextGood != _isPostureGood) {
        setState(() => _isPostureGood = nextGood);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HomeHeaderAppBar(usernameFuture: _usernameFuture),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          children: [
            const SizedBox(height: 30),

            // ✅ Posture status (Good / Bad)
            PostureStatusCard(isGood: _isPostureGood),

            const SizedBox(height: 18),

            const PostureTipsSection(),

            const SizedBox(height: 16),

            // ✅ Chart
            const PostureWeekChartCard(fixedOffsetMinutes: fixedOffsetMinutes),

            const SizedBox(height: 22),
            const LastPostureAlertCard(),

            // ✅ Stats


            const SizedBox(height: 24), // بدل Spacer + بدل SizedBox(150)
          ],
        ),
      ),
    );
  }
}
