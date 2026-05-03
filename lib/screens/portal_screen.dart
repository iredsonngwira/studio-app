import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';
import '../main.dart';

class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});
  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map? _user;
  String? _cookie;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Get CSRF
      final csrfResp = await http.get(Uri.parse('$kApiBase/accounts/login/'));
      final cookie = csrfResp.headers['set-cookie'] ?? '';
      final csrf = RegExp(r'csrftoken=([^;]+)').firstMatch(cookie)?.group(1) ?? '';
      final sessionCookie = cookie.split(',').map((c) => c.trim().split(';').first).join('; ');

      final resp = await http.post(
        Uri.parse('$kApiBase/accounts/login/'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRFToken': csrf,
          'Cookie': sessionCookie,
          'Referer': kApiBase,
        },
        body: {'login': _emailCtrl.text, 'password': _passCtrl.text},
      );

      if (resp.statusCode == 200 || resp.statusCode == 302) {
        _cookie = resp.headers['set-cookie'] ?? sessionCookie;
        setState(() { _user = {'email': _emailCtrl.text}; });
      } else {
        setState(() => _error = 'Invalid email or password');
      }
    } catch (e) {
      setState(() => _error = 'Connection error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user != null) return _buildPortal();
    return _buildLogin();
  }

  Widget _buildLogin() {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Portal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Welcome Back', style: TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Sign in to access your galleries and bookings',
              style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            const Text('Email', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey, size: 18),
                hintText: 'your@email.com',
              ),
            ),
            const SizedBox(height: 16),

            const Text('Password', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                hintText: '••••••••',
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 24),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.red.shade900.withOpacity(0.3),
                  border: Border.all(color: Colors.red.shade800),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Forgot password?', style: TextStyle(color: AppTheme.brand)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortal() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portal'),
        actions: [
          TextButton(
            onPressed: () => setState(() { _user = null; _cookie = null; }),
            child: const Text('Sign out', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dark600),
              color: AppTheme.dark800,
            ),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.brand,
                  ),
                  child: Center(
                    child: Text(
                      (_user?['email'] as String? ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(_user?['email'] ?? '', style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick actions
          const Text('Quick Actions', style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ActionCard(icon: Icons.photo_library, label: 'My Galleries',
                onTap: () => _showGalleries())),
              const SizedBox(width: 12),
              Expanded(child: _ActionCard(icon: Icons.calendar_today, label: 'My Bookings',
                onTap: () => _showBookings())),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ActionCard(icon: Icons.shopping_bag, label: 'My Orders',
                onTap: () {})),
              const SizedBox(width: 12),
              Expanded(child: _ActionCard(icon: Icons.download, label: 'Downloads',
                onTap: () => _showGalleries())),
            ],
          ),
          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.dark600),
              color: AppTheme.dark700,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📁 Your Galleries', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('After your session, Kamoto HD will upload your finished photos and videos here. You\'ll be able to download them in full HD.',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGalleries() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.dark800,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, color: AppTheme.brand, size: 48),
            SizedBox(height: 16),
            Text('No galleries yet', style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(height: 8),
            Text('Your finished photos and videos will appear here after your session.',
              style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showBookings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.dark800,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, color: AppTheme.brand, size: 48),
            SizedBox(height: 16),
            Text('No bookings yet', style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(height: 8),
            Text('Your booking history will appear here.',
              style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dark600),
          color: AppTheme.dark800,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.brand, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
