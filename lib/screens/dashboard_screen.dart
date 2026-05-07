import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/quiz_provider.dart';

class ConfettiParticle {
  double x;
  double y;
  double size;
  Color color;
  double velocityY;
  double angle;
  double angleVelocity;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.velocityY,
    required this.angle,
    required this.angleVelocity,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _lastWinner;
  final List<ConfettiParticle> _confetti = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat();
    _controller.addListener(_updateConfetti);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerConfetti() {
    final colors = [
      const Color(0xFF2563EB), // Royal Blue
      const Color(0xFF60A5FA), // Sky Blue
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFFEC4899), // Pink
    ];
    final size = MediaQuery.of(context).size;
    setState(() {
      _confetti.clear();
      for (int i = 0; i < 80; i++) {
        _confetti.add(ConfettiParticle(
          x: _random.nextDouble() * size.width,
          y: -10 - _random.nextDouble() * 200,
          size: _random.nextDouble() * 8 + 5,
          color: colors[_random.nextInt(colors.length)],
          velocityY: _random.nextDouble() * 4 + 3,
          angle: _random.nextDouble() * math.pi * 2,
          angleVelocity: _random.nextDouble() * 0.06 + 0.02,
        ));
      }
    });
  }

  void _updateConfetti() {
    if (_confetti.isEmpty) return;
    final size = MediaQuery.of(context).size;
    setState(() {
      bool active = false;
      for (final p in _confetti) {
        p.y += p.velocityY;
        p.angle += p.angleVelocity;
        if (p.y < size.height) {
          active = true;
        }
      }
      if (!active) {
        _confetti.clear();
      }
    });
  }

  void _playSound(String type, [String? name]) async {
    if (!Platform.isMacOS) return;

    if (type == 'win') {
      Process.run('afplay', ['/System/Library/Sounds/Glass.aiff']);
      await Future.delayed(const Duration(milliseconds: 80));
      Process.run('afplay', ['/System/Library/Sounds/Hero.aiff']);
      await Future.delayed(const Duration(milliseconds: 120));
      Process.run('afplay', ['/System/Library/Sounds/Submarine.aiff']);
      
      if (name != null) {
        Process.run('say', ['Congratulations $name, you buzzed in first!', '-r', '175']);
      }
    } else if (type == 'correct') {
      Process.run('afplay', ['/System/Library/Sounds/Glass.aiff']);
      Process.run('afplay', ['/System/Library/Sounds/Hero.aiff']);
      if (name != null) {
        Process.run('say', ['Correct! Point for $name.', '-r', '180']);
      }
    } else if (type == 'wrong') {
      Process.run('afplay', ['/System/Library/Sounds/Basso.aiff']);
      Process.run('say', ['Wrong answer! Buzzer is unlocked.', '-r', '180']);
    } else if (type == 'play') {
      Process.run('afplay', ['/System/Library/Sounds/Pop.aiff']);
    }
  }

  Color get _bgColor {
    final state = ref.watch(quizProvider);
    if (state.isLocked) return const Color(0xFFF0FDF4); // Warm emerald green tint
    if (state.isPlaying) return const Color(0xFFEFF6FF); // Soft sky blue ready tint
    return const Color(0xFFF3F8FC); // Pure crisp light blue background
  }

  Color get _accentColor {
    final state = ref.watch(quizProvider);
    if (state.isLocked) return const Color(0xFF10B981); // Solid Emerald Green
    if (state.isPlaying) return const Color(0xFF2563EB); // Royal Blue
    return const Color(0xFF60A5FA); // Sky Blue Accent
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 26),
              SizedBox(width: 10),
              Text(
                'Izin Jaringan & Solusi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  fontFamily: 'Space Grotesk',
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Jika HP Anda tidak bisa masuk atau koneksi gagal, berikut adalah panduan izin sistem dan jaringan lokal untuk Android (APK), Windows, dan macOS:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  _buildSectionTitle('📱 Android APK / iOS Mobile'),
                  _buildSectionText(
                    '• Pastikan file "AndroidManifest.xml" menyertakan:\n'
                    '  <uses-permission android:name="android.permission.INTERNET"/>\n'
                    '• Beberapa vendor HP memblokir pencarian jaringan lokal secara default. Silakan buka Pengaturan HP > Aplikasi > Kuis Buzzer > Aktifkan "Izin Jaringan Lokal" / "Nearby Devices".',
                  ),
                  const SizedBox(height: 14),
                  _buildSectionTitle('💻 Windows / macOS Firewall'),
                  _buildSectionText(
                    '• Saat pertama kali dijalankan di Windows, Windows Defender akan memunculkan popup izin akses jaringan. Pastikan untuk mencentang "Private" dan "Public Network", lalu klik "Allow Access".\n'
                    '• Di Mac, buka System Settings > Network > Firewall, lalu matikan sementara Firewall untuk uji coba lokal.',
                  ),
                  const SizedBox(height: 14),
                  _buildSectionTitle('🔥 Solusi Utama "AP Isolation" (100% Berhasil)'),
                  _buildSectionText(
                    '• Sebagian besar router Wi-Fi memblokir komunikasi antar perangkat (AP Isolation). Solusi terbaik, tercepat, dan 100% berhasil adalah menggunakan Hotspot Pribadi di HP Anda, lalu hubungkan laptop ke Wi-Fi Hotspot HP tersebut. Akses IP secara offline!',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (Platform.isMacOS || Platform.isWindows)
              TextButton.icon(
                onPressed: () {
                  try {
                    if (Platform.isMacOS) {
                      Process.run('open', ['x-apple.systempreferences:com.apple.preference.security?Firewall']);
                    } else if (Platform.isWindows) {
                      Process.run('control', ['firewall.cpl']);
                    }
                  } catch (_) {}
                },
                icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                label: const Text('Buka Setting Jaringan/Firewall', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF334155),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
    );
  }

  Widget _buildSectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);
    final notifier = ref.read(quizProvider.notifier);
    final isWide = MediaQuery.of(context).size.width > 900;

    if (state.isLocked && _lastWinner != state.winnerName) {
      _lastWinner = state.winnerName;
      _playSound('win', state.winnerName);
      _triggerConfetti();
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _bgColor,
                  Color.lerp(_bgColor, Colors.white, 0.4)!,
                ],
              ),
            ),
            child: SafeArea(
              child: isWide
                  ? Row(children: [
                      SizedBox(width: 380, child: _buildSidebar(state, notifier)),
                      Container(width: 1, color: const Color(0xFFE2ECF6)),
                      Expanded(child: _buildMainArea(state, notifier)),
                    ])
                  : Column(children: [
                      _buildTopBar(state, notifier),
                      Expanded(child: _buildMainArea(state, notifier)),
                      _buildBottomControls(state, notifier),
                    ]),
            ),
          ),
          if (_confetti.isNotEmpty)
            IgnorePointer(
              child: CustomPaint(
                painter: ConfettiPainter(_confetti),
                size: Size.infinite,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(QuizState state, QuizNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2ECF6))),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SERVER RUNNING',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                state.serverUrl ?? '',
                style: const TextStyle(fontSize: 14, fontFamily: 'Courier', color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: notifier.stopServer,
          icon: const Icon(Icons.power_settings_new_rounded),
          color: const Color(0xFFEF4444),
          tooltip: 'Stop Server',
        ),
      ]),
    );
  }

  Widget _buildSidebar(QuizState state, QuizNotifier notifier) {
    final sortedPlayers = state.connectedUsers.toList()
      ..sort((a, b) => (state.scores[b] ?? 0).compareTo(state.scores[a] ?? 0));
    const primaryColor = Color(0xFF2563EB);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'QUIZ BUZZER',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5, fontFamily: 'Space Grotesk'),
            ),
            const Spacer(),
            IconButton(
              onPressed: notifier.stopServer,
              icon: const Icon(Icons.power_settings_new_rounded),
              color: const Color(0xFFEF4444),
              tooltip: 'Stop Server',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          // Connection Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2ECF6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PLAYER PORTAL URL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1)),
                const SizedBox(height: 6),
                SelectableText(
                  state.serverUrl ?? 'http://localhost:8080',
                  style: const TextStyle(fontSize: 13, fontFamily: 'Courier', color: primaryColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2ECF6)),
                    ),
                    child: QrImageView(
                      data: state.serverUrl ?? 'http://localhost:8080',
                      version: QrVersions.auto,
                      size: 110,
                      gapless: false,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showPermissionDialog(context),
                    icon: const Icon(Icons.help_outline_rounded, size: 15, color: primaryColor),
                    label: const Text(
                      'HP Tidak Bisa Connect?',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryColor),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: primaryColor.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PLAYERS (${state.connectedUsers.length})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              TextButton(
                onPressed: notifier.resetScores,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                child: const Text('Reset Scores', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.connectedUsers.isEmpty
                ? const Center(
                    child: Text(
                      'Waiting for players...',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedPlayers.length,
                    itemBuilder: (context, index) {
                      final name = sortedPlayers[index];
                      final score = state.scores[name] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2ECF6)),
                          ),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _getAvatarColor(index),
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => notifier.subtractPoint(name),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: const Color(0xFFE2ECF6))),
                                    child: const Icon(Icons.remove, size: 12, color: Color(0xFF64748B)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$score pts',
                                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'Space Grotesk'),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => notifier.addPoint(name),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: const Color(0xFFE2ECF6))),
                                    child: const Icon(Icons.add, size: 12, color: Color(0xFF10B981)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: const Text('Kick Player', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                        content: Text('Apakah Anda yakin ingin mengeluarkan "$name" dari kuis?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              notifier.kickPlayer(name);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Kick', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFEF2F2),
                                      border: Border.all(color: const Color(0xFFFEE2E2)),
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2ECF6)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: state.isPlaying || state.isLocked
                  ? null
                  : () {
                      _playSound('play');
                      notifier.play();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('▶ START ROUND', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: state.isLocked || state.isPlaying ? () => notifier.reset() : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: state.isLocked || state.isPlaying ? const Color(0xFFEF4444) : const Color(0xFFE2ECF6), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                '↺ RESET BOARD',
                style: TextStyle(
                  color: state.isLocked || state.isPlaying ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainArea(QuizState state, QuizNotifier notifier) {
    final timer = state.timerRemaining ?? 0;
    const primaryColor = Color(0xFF2563EB);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (timer > 0) ...[
              Text(
                '$timer',
                style: TextStyle(
                  fontSize: 160,
                  fontWeight: FontWeight.w800,
                  color: primaryColor.withValues(alpha: 0.8),
                  fontFamily: 'Space Grotesk',
                ),
              ),
              const Text(
                'SECONDS REMAINING',
                style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
            ] else if (state.isLocked) ...[
              _buildWinnerBars(),
              const SizedBox(height: 24),
              Text(
                state.winnerName ?? '',
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Space Grotesk'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'BUZZED IN!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF10B981), letterSpacing: 8),
              ),
              const SizedBox(height: 40),
              // Judge Controls
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2ECF6)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.03),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('JUDGE DECISION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.5)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                if (state.winnerName != null) {
                                  _playSound('correct', state.winnerName);
                                  notifier.addPoint(state.winnerName!);
                                  notifier.reset();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 20),
                                  SizedBox(width: 6),
                                  Text('CORRECT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                if (state.winnerName != null) {
                                  _playSound('wrong');
                                  notifier.unlockBuzzer();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel_outlined, size: 20, color: Color(0xFFEF4444)),
                                  SizedBox(width: 6),
                                  Text('WRONG', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFEF4444))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (state.isPlaying) ...[
              const Icon(Icons.bolt_rounded, size: 100, color: primaryColor),
              const SizedBox(height: 20),
              const Text(
                'GO!',
                style: TextStyle(fontSize: 84, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontFamily: 'Space Grotesk'),
              ),
              const Text(
                'BUZZ NOW!',
                style: TextStyle(fontSize: 20, color: primaryColor, fontWeight: FontWeight.w800, letterSpacing: 4),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2ECF6)),
                ),
                child: const Icon(Icons.hourglass_empty_rounded, size: 74, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
              const Text(
                'WAITING FOR ROUND',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.5, fontFamily: 'Space Grotesk'),
              ),
              const SizedBox(height: 6),
              Text(
                '${state.connectedUsers.length} player(s) connected and ready',
                style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerBars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 10,
              height: 40 + (35 * ((_controller.value + index * 0.15) % 1.0).abs()),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF10B981), Color(0xFF60A5FA)],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildBottomControls(QuizState state, QuizNotifier notifier) {
    const primaryColor = Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2ECF6))),
      ),
      child: Column(children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: state.isPlaying || state.isLocked
                ? null
                : () {
                    _playSound('play');
                    notifier.play();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('▶ START ROUND', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
        if (state.isLocked) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (state.winnerName != null) {
                      _playSound('correct', state.winnerName);
                      notifier.addPoint(state.winnerName!);
                      notifier.reset();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('CORRECT', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    if (state.winnerName != null) {
                      _playSound('wrong');
                      notifier.unlockBuzzer();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('WRONG', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }
}