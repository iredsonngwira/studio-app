import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import 'dart:async';
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
    _Msg(role: 'ai', text: 'Hi! 👋 I\'m the Kamoto HD assistant. I can answer questions, help you book a session, or guide you to the right service. How can I help?'),
  ];
  bool _loading = false;
  String? _sessionCookie;
  String? _csrfToken;

  Future<void> _initSession() async {
    if (_csrfToken != null) return;
    try {
      final resp = await http.get(Uri.parse('$kApiBase/'));
      final cookie = resp.headers['set-cookie'] ?? '';
      _csrfToken = RegExp(r'csrftoken=([^;]+)').firstMatch(cookie)?.group(1) ?? '';
      _sessionCookie = cookie.split(',').map((c) => c.trim().split(';').first).join('; ');
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', text: text));
      _loading = true;
      // Add empty AI message that will be filled by stream
      _messages.add(_Msg(role: 'ai', text: '', streaming: true));
    });
    _scrollDown();

    await _initSession();

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$kApiBase/ai/chat/stream/'),
      );
      request.headers.addAll({
        'Content-Type': 'application/json',
        'X-CSRFToken': _csrfToken ?? '',
        'Cookie': _sessionCookie ?? '',
        'Referer': kApiBase,
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode({'message': text});

      final streamedResp = await http.Client().send(request);
      final stream = streamedResp.stream.transform(utf8.decoder);

      await for (final chunk in stream) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              if (data['chunk'] != null) {
                setState(() {
                  _messages.last.text += data['chunk'] as String;
                });
                _scrollDown();
              }
              if (data['done'] == true) {
                setState(() {
                  _messages.last.streaming = false;
                  _loading = false;
                });
                if (data['booking_created'] == true) {
                  setState(() => _messages.add(_Msg(
                    role: 'ai',
                    text: '✅ Your booking request has been saved! We\'ll confirm within 24 hours.',
                  )));
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      setState(() {
        _messages.last.text = 'Connection error. Please try again.';
        _messages.last.streaming = false;
        _loading = false;
      });
    }
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.brand),
            child: const Center(child: Text('AI', style: TextStyle(
              color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Kamoto HD Assistant', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(_loading ? 'Typing...' : 'Online',
              style: TextStyle(fontSize: 11, color: _loading ? AppTheme.brand : Colors.green)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => _buildBubble(_messages[i]),
            ),
          ),
          // Quick suggestions
          if (!_loading && _messages.length <= 2)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  'What services do you offer?',
                  'I want to book a wedding shoot',
                  'What are your prices?',
                  'Where are you located?',
                ].map((s) => GestureDetector(
                  onTap: () { _ctrl.text = s; _send(); },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.brand.withOpacity(0.5)),
                      color: AppTheme.brand.withOpacity(0.1),
                    ),
                    child: Text(s, style: const TextStyle(color: AppTheme.brand, fontSize: 12)),
                  ),
                )).toList(),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: const BoxDecoration(
              color: AppTheme.dark800,
              border: Border(top: BorderSide(color: AppTheme.dark600)),
            ),
            child: Row(children: [
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
                onTap: _loading ? null : _send,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _loading ? AppTheme.dark600 : AppTheme.brand,
                  ),
                  child: Icon(Icons.send,
                    color: _loading ? Colors.grey : Colors.black, size: 20),
                ),
              ),
            ]),
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
              child: const Center(child: Text('AI', style: TextStyle(
                color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold))),
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
              child: msg.text.isEmpty && msg.streaming
                ? _buildTypingDots()
                : isAI
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: MarkdownBody(
                            data: msg.text,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                              strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              em: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                              listBullet: const TextStyle(color: AppTheme.brand),
                              tableHead: const TextStyle(color: AppTheme.brand, fontWeight: FontWeight.bold),
                              tableBody: const TextStyle(color: Colors.white70, fontSize: 12),
                              tableBorder: TableBorder.all(color: AppTheme.dark600),
                              code: const TextStyle(color: AppTheme.brand, backgroundColor: Colors.transparent),
                              codeblockDecoration: BoxDecoration(
                                color: AppTheme.dark800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        if (msg.streaming) ...[
                          const SizedBox(width: 4),
                          _Cursor(),
                        ],
                      ],
                    )
                  : Text(msg.text, style: const TextStyle(
                      color: Colors.black, fontSize: 14, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(delay: 0), SizedBox(width: 4),
        _Dot(delay: 200), SizedBox(width: 4),
        _Dot(delay: 400),
      ],
    );
  }
}

class _Msg {
  final String role;
  String text;
  bool streaming;
  _Msg({required this.role, required this.text, this.streaming = false});
}

// Blinking cursor
class _Cursor extends StatefulWidget {
  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(width: 2, height: 16, color: AppTheme.brand),
    );
  }
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
    _a = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(width: 7, height: 7,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
    );
  }
}
