import 'dart:io';
import 'package:flutter/material.dart';

class SetupScreen extends StatefulWidget {
  final Future<void> Function(int port, int maxParticipants, int timerSeconds) onStartServer;
  final bool isLoading;

  const SetupScreen({super.key, required this.onStartServer, this.isLoading = false});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with SingleTickerProviderStateMixin {
  final _portController = TextEditingController(text: '8080');
  final _maxController = TextEditingController(text: '50');
  final _timerController = TextEditingController(text: '0');
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _portController.dispose();
    _maxController.dispose();
    _timerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startServer() async {
    final port = int.tryParse(_portController.text);
    final maxParticipants = int.tryParse(_maxController.text);
    final timerSeconds = int.tryParse(_timerController.text);

    if (port == null || port < 1024 || port > 65535) {
      setState(() => _error = 'Port must be between 1024-65535');
      return;
    }
    if (maxParticipants == null || maxParticipants < 2 || maxParticipants > 100) {
      setState(() => _error = 'Max participants must be 2-100');
      return;
    }
    if (timerSeconds == null || timerSeconds < 0 || timerSeconds > 300) {
      setState(() => _error = 'Timer must be 0-300 seconds');
      return;
    }

    setState(() => _error = null);
    try {
      await widget.onStartServer(port, maxParticipants, timerSeconds);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB); // Royal Blue
    const accentColor = Color(0xFF60A5FA); // Sky Blue
    const bgGradientStart = Color(0xFFF3F8FC); // Soft Sky Blue
    const bgGradientEnd = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: bgGradientEnd,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Elegant Blue Icon Panel
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2ECF6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.06),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 54,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'QUIZ BUZZER',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Local Network Buzzer Server',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _showPermissionExplanation(context),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: Color(0xFF2563EB)),
                            SizedBox(width: 6),
                            Text(
                              'Info Izin Jaringan (Android/Windows/Mac)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Elegant White Settings Card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE2ECF6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.03),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune_rounded, color: primaryColor, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Server Configuration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _portController,
                            label: 'Server Port',
                            hint: '8080',
                            icon: Icons.dns_outlined,
                            accentColor: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _maxController,
                                  label: 'Max Players',
                                  hint: '50',
                                  icon: Icons.group_outlined,
                                  keyboardType: TextInputType.number,
                                  accentColor: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildTextField(
                                  controller: _timerController,
                                  label: 'Timer (sec)',
                                  hint: '0 = none',
                                  icon: Icons.hourglass_empty_rounded,
                                  keyboardType: TextInputType.number,
                                  accentColor: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    // Premium Royal Blue start button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: widget.isLoading ? null : _startServer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: widget.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.power_settings_new_rounded, size: 20, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'LAUNCH SERVER',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPermissionExplanation(BuildContext context) {
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
                'Izin Jaringan & Sistem',
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
            child: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kuis ini menggunakan Server Port lokal untuk menghubungkan HP Peserta dengan Laptop Host secara offline. Berikut adalah izin sistem penting yang diperlukan saat nanti dijalankan sebagai Android APK, Windows exe, atau macOS app:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '📱 Android APK / iOS Mobile',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      '• Server memerlukan izin internet penuh di berkas AndroidManifest.xml (<uses-permission android:name="android.permission.INTERNET"/>).\n• Jika dijalankan di HP, beberapa sistem Android meminta konfirmasi akses "Local Network" atau "Nearby Devices". Harap izinkan.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '💻 Windows & macOS Firewall',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      '• Windows Defender / macOS Firewall secara default akan memblokir port masuk saat pertama kali aplikasi dibuka. Pastikan memilih "Allow Access" atau mencentang opsi "Private/Public Networks" di popup Windows Firewall.\n• Matikan sementara Firewall jika HP masih tetap tidak bisa terhubung.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4, fontWeight: FontWeight.w500),
                    ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
    );
  }
}