import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [
    _Msg(role: 'ai', text: 'Hi! 👋 I\'m the Studio AI assistant. I can answer questions, help you book a session, or guide you to the right service. How can I help?'),
  ];
  bool _loading = false;
  String? _sessionCookie;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', text: text));
      _loading = true;
    });
    _scrollDown();

    try {
      // Get CSRF token first if needed
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      };

      // Get CSRF
      final csrfResp = await http.get(Uri.parse('$kApiBase/'), headers: headers);
      final cookie = csrfResp.headers['set-cookie'] ?? '';
      final csrfMatch = RegExp(r'csrftoken=([^;]+)').firstMatch(cookie);
      final csrf = csrfMatch?.group(1) ?? '';
      _sessionCookie = cookie.split(',').map((c) => c.trim().split(';').first).join('; ');

      final resp = await http.post(
        Uri.parse('$kApiBase/ai/chat/'),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': csrf,
          'Cookie': _sessionCookie ?? '',
          'Referer': kApiBase,
        },
        body: jsonEncode({'message': text}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _messages.add(_Msg(role: 'ai', text: data['reply'] ?? 'Sorry, something went wrong.'));
          if (data['booking_created'] == true) {
            _messages.add(_Msg(role: 'ai', text: '✅ Your booking request has been saved! We\'ll confirm within 24 hours.'));
          }
        });
      } else {
        setState(() => _messages.add(_Msg(role: 'ai', text: 'Connection error. Please try again.')));
      }
    } catch (e) {
      setState(() => _messages.add(_Msg(role: 'ai', text: 'Error: $e')));
    } finally {
      setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brand,
              ),
              child: const Center(child: Text('AI', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Studio Assistant', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Online', style: TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) {
                  return _buildTyping();
                }
                final msg = _messages[i];
                return _buildBubble(msg);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: const BoxDecoration(
              color: AppTheme.dark800,
              border: Border(top: BorderSide(color: AppTheme.dark600)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.dark600),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.brand,
                    ),
                    child: const Icon(Icons.send, color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Msg msg) {
    final isAI = msg.role == 'ai';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.brand),
              child: const Center(child: Text('AI', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAI ? AppTheme.dark700 : AppTheme.brand,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isAI ? 4 : 18),
                  bottomRight: Radius.circular(isAI ? 18 : 4),
                ),
              ),
              child: Text(msg.text,
                style: TextStyle(
                  color: isAI ? Colors.white : Colors.black,
                  fontSize: 14, height: 1.4,
                )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.brand),
          child: const Center(child: Text('AI', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.dark700,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              _Dot(delay: 0),
              SizedBox(width: 4),
              _Dot(delay: 200),
              SizedBox(width: 4),
              _Dot(delay: 400),
            ],
          ),
        ),
      ],
    );
  }
}

class _Msg {
  final String role;
  final String text;
  _Msg({required this.role, required this.text});
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _a = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
      ),
    );
  }
}
