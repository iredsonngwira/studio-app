import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/queries.dart';
import '../theme.dart';

class SendMemorySheet extends StatefulWidget {
  final int galleryId;
  final int photoId;
  const SendMemorySheet({super.key, required this.galleryId, required this.photoId});

  @override
  State<SendMemorySheet> createState() => _SendMemorySheetState();
}

class _SendMemorySheetState extends State<SendMemorySheet> {
  final _name = TextEditingController();
  final _msg = TextEditingController();
  bool _sent = false;
  String? _link;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _sent ? _SuccessView(link: _link!) : _FormView(
        nameCtrl: _name,
        msgCtrl: _msg,
        galleryId: widget.galleryId,
        photoId: widget.photoId,
        onSent: (link) => setState(() { _sent = true; _link = link; }),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController nameCtrl, msgCtrl;
  final int galleryId, photoId;
  final void Function(String) onSent;
  const _FormView({required this.nameCtrl, required this.msgCtrl,
    required this.galleryId, required this.photoId, required this.onSent});

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(document: gql(kSendMemory)),
      builder: (runMutation, result) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Send a Memory', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Share this photo with someone special.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: "Recipient's name"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: msgCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Personal message (optional)', alignLabelWithHint: true),
          ),
          const SizedBox(height: 20),
          if (result.hasException)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Failed to send. Please try again.', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: result.isLoading ? null : () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final res = await runMutation({
                  'galleryId': galleryId,
                  'photoId': photoId,
                  'recipientName': nameCtrl.text.trim(),
                  'personalMessage': msgCtrl.text.trim(),
                }).networkResult;
                final link = res?.data?['sendMemory']?['message'] as String?;
                if (link != null && link.startsWith('/')) onSent(link);
              },
              child: result.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Send Memory 💌'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String link;
  const _SuccessView({required this.link});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite, color: AppTheme.brand, size: 48),
        const SizedBox(height: 16),
        const Text('Memory Sent! 💌', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('The recipient will see the photo and a link to book their own session.',
            style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
