import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme.dart';

const _pollinationsBase = 'https://image.pollinations.ai/prompt';

const _tools = [
  {'id': 'logo', 'name': 'Logo', 'icon': Icons.edit, 'w': 1024, 'h': 1024},
  {'id': 'flyer', 'name': 'Flyer', 'icon': Icons.article, 'w': 1024, 'h': 1448},
  {'id': 'portrait', 'name': 'Portrait', 'icon': Icons.person, 'w': 768, 'h': 1024},
  {'id': 'background', 'name': 'Background', 'icon': Icons.wallpaper, 'w': 1920, 'h': 1080},
  {'id': 'custom', 'name': 'Custom', 'icon': Icons.auto_awesome, 'w': 1024, 'h': 1024},
];

const _toolPrompts = {
  'logo': 'professional minimalist logo design, vector style, clean, {prompt}, white background',
  'flyer': 'professional event flyer design, vibrant, modern layout, {prompt}, high resolution',
  'portrait': 'professional portrait, studio lighting, sharp, {prompt}, photorealistic',
  'background': 'beautiful background image, high resolution, {prompt}, professional photography',
  'custom': '{prompt}',
};

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _ctrl = TextEditingController();
  String _tool = 'logo';
  String? _imageUrl;
  bool _loading = false;
  String? _error;

  String _buildUrl(String prompt) {
    final template = _toolPrompts[_tool] ?? '{prompt}';
    final full = template.replaceAll('{prompt}', prompt);
    final tool = _tools.firstWhere((t) => t['id'] == _tool);
    final w = tool['w'] as int;
    final h = tool['h'] as int;
    final seed = DateTime.now().millisecondsSinceEpoch % 99999;
    final encoded = Uri.encodeComponent(full);
    return '$_pollinationsBase/$encoded?width=$w&height=$h&model=flux&nologo=true&seed=$seed';
  }

  Future<void> _generate() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() { _loading = true; _error = null; _imageUrl = null; });
    try {
      final url = _buildUrl(prompt);
      // Pre-fetch to trigger generation
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 45));
      if (res.statusCode == 200) {
        setState(() { _imageUrl = url; _loading = false; });
      } else {
        setState(() { _error = 'Generation failed. Try again.'; _loading = false; });
      }
    } on TimeoutException {
      setState(() { _error = 'Took too long. Try a simpler prompt.'; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Creative Studio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool selector
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tools.length,
                itemBuilder: (ctx, i) {
                  final t = _tools[i];
                  final selected = _tool == t['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _tool = t['id'] as String),
                    child: Container(
                      width: 72,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? AppTheme.brand : AppTheme.dark600,
                          width: selected ? 2 : 1,
                        ),
                        color: selected ? AppTheme.brand.withOpacity(0.1) : AppTheme.dark800,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(t['icon'] as IconData,
                            color: selected ? AppTheme.brand : Colors.grey, size: 22),
                          const SizedBox(height: 4),
                          Text(t['name'] as String,
                            style: TextStyle(
                              color: selected ? AppTheme.brand : Colors.grey,
                              fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Prompt input
            TextField(
              controller: _ctrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Describe what you want to generate...',
                alignLabelWithHint: true,
              ),
              onSubmitted: (_) => _generate(),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _generate,
                icon: _loading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_loading ? 'Generating...' : 'Generate Image'),
              ),
            ),
            const SizedBox(height: 16),

            // Result
            if (_loading)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.dark800,
                  border: Border.all(color: AppTheme.dark600),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.brand),
                      SizedBox(height: 16),
                      Text('Generating your image...', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('Usually 5–20 seconds', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade800),
                  color: Colors.red.shade900.withOpacity(0.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    TextButton(onPressed: _generate, child: const Text('Retry', style: TextStyle(color: AppTheme.brand))),
                  ],
                ),
              )
            else if (_imageUrl != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) => progress == null
                        ? child
                        : Container(height: 300, color: AppTheme.dark800,
                            child: const Center(child: CircularProgressIndicator(color: AppTheme.brand))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Regenerate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.brand,
                            side: const BorderSide(color: AppTheme.brand),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: save to gallery
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Image saved!')));
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dark600, style: BorderStyle.solid),
                  color: AppTheme.dark800,
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.brand, size: 40),
                      SizedBox(height: 12),
                      Text('Your image will appear here', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('Free · Instant · No watermark',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
