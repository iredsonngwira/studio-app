import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/queries.dart';
import '../theme.dart';

class StylistScreen extends StatefulWidget {
  const StylistScreen({super.key});
  @override
  State<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends State<StylistScreen> {
  final _ctrl = TextEditingController();
  String? _advice;
  bool _loading = false;
  String? _error;

  static const _quickPrompts = [
    'Wedding shoot, outdoor, 6 people including elderly grandparents',
    "Baby's 1st birthday, indoor studio, pastel theme",
    'Corporate headshots, professional setting',
    'Family of 4, outdoor nature, casual and relaxed',
    'Graduation portraits, formal attire',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Shoot Stylist')),
      body: Mutation(
        options: MutationOptions(document: gql(kPreShootStylist)),
        builder: (runMutation, result) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Describe your upcoming session',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Get personalised outfit, colour and prep advice instantly.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "e.g. It's my daughter's 5th birthday, outdoor garden, she loves purple. Family of 4.",
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                // Quick prompts
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _quickPrompts.map((p) => GestureDetector(
                    onTap: () => setState(() => _ctrl.text = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.dark600),
                        color: AppTheme.dark800,
                      ),
                      child: Text(p, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () async {
                      final desc = _ctrl.text.trim();
                      if (desc.isEmpty) return;
                      setState(() { _loading = true; _error = null; _advice = null; });
                      final res = await runMutation({'description': desc}).networkResult;
                      setState(() {
                        _loading = false;
                        _advice = res?.data?['preShootStylist']?['advice'];
                        _error = res?.hasException == true ? 'Could not get advice. Please try again.' : null;
                      });
                    },
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_loading ? 'Thinking...' : '✨ Get Styling Advice'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                if (_advice != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.brand.withOpacity(0.3)),
                      color: AppTheme.dark800,
                    ),
                    child: MarkdownBody(
                      data: _advice!,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                        strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        listBullet: const TextStyle(color: AppTheme.brand),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
