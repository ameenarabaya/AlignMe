import 'dart:io';

import 'package:alignme/pages/login_page.dart';
import 'package:alignme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // ===== Get username =====
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: const [
              Icon(
                Icons.chair_alt,
                size: 40,
                color: Color(0xFF6F9F97),
              ),
              SizedBox(height: 10),
              Text(
                'AlignMe',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'AlignMe is a smart sitting posture monitoring application '
                  'developed as a graduation project.\n\n'
                  'The system works by detecting incorrect sitting postures using '
                  'smart sensors integrated into a chair and provides real-time '
                  'notifications to help users maintain a healthy posture.\n\n'
                  'The goal of AlignMe is to reduce back and neck pain caused by '
                  'poor sitting habits and promote a healthier sitting lifestyle.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['username'] ??
        user.email?.split('@').first ??
        'User';
  }

  // ===== Logout =====
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  // ===== Fetch Notifications =====
  Future<List<QueryDocumentSnapshot>> _fetchNotifications() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Notifications')
        .orderBy("Timestamp",descending: true)
        .get();
    print(snapshot.docs);

    return snapshot.docs;
  }

  // ===== Generate PDF =====
  Future<File> _generatePdf(List<QueryDocumentSnapshot> sessions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Sitting Posture Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: ['Date & Time', 'Reason'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            data: sessions.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final ts = data['Timestamp'];
              final reason = data['reason'];

              final dateText = ts != null
                  ? (ts as Timestamp)
                  .toDate()
                  .toString()
                  .substring(0, 16)
                  : 'Unknown date';

              final reasonText = reason ?? 'No description';

              return [dateText, reasonText];
            }).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sitting_report.pdf');

    await file.writeAsBytes(await pdf.save());
    return file;
  }


  // ===== Download PDF =====
  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final sessions = await _fetchNotifications();

      if (sessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sitting sessions found')),
        );
        return;
      }

      final file = await _generatePdf(sessions);

      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: 'sitting_report.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error generating PDF')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ===== Header =====
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: const Color(0xFF6F9F97),
                  child:
                  const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 12),
                FutureBuilder<String>(
                  future: _getUsername(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ===== Preferences =====
          _sectionTitle('Preferences'),

          _cardTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: isDark,
              onChanged: (_) => themeProvider.toggleTheme(!isDark),
              activeColor: const Color(0xFF6F9F97),
            ),
          ),

          const SizedBox(height: 20),

          // ===== Reports =====
          _sectionTitle('Reports'),

          _cardTile(
            icon: Icons.download,
            title: 'Download Sitting Report',
            onTap: () => _downloadPdf(context),
          ),

          const SizedBox(height: 20),

          // ===== Account =====
          _sectionTitle('Account'),

          _cardTile(
            icon: Icons.info_outline,
            title: 'About AlignMe',
              onTap: () => _showAboutDialog(context),
          ),

          _cardTile(
            icon: Icons.logout,
            title: 'Logout',
            titleColor: Colors.red,
            iconColor: Colors.red,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  // ===== Helpers =====

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _cardTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? const Color(0xFF6F9F97)),
        title: Text(
          title,
          style: TextStyle(color: titleColor),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
