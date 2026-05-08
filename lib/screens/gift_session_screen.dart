import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/queries.dart';
import '../theme.dart';
import '../main.dart';

class GiftSessionScreen extends StatefulWidget {
  const GiftSessionScreen({super.key});
  @override
  State<GiftSessionScreen> createState() => _GiftSessionScreenState();
}

class _GiftSessionScreenState extends State<GiftSessionScreen> {
  final _buyerName = TextEditingController();
  final _buyerEmail = TextEditingController();
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _message = TextEditingController();
  int? _serviceId;
  String? _giftCode;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gift a Session')),
      body: _giftCode != null ? _SuccessView(code: _giftCode!) : Query(
        options: QueryOptions(document: gql(kGetServices)),
        builder: (result, {fetchMore, refetch}) {
          final services = (result.data?['services'] as List?) ?? [];
          return Mutation(
            options: MutationOptions(document: gql(kPurchaseGift)),
            builder: (runMutation, mutResult) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Send a professional photo session as a gift to family or friends in Malawi.',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  _label('Session Type'),
                  DropdownButtonFormField<int>(
                    value: _serviceId,
                    dropdownColor: AppTheme.dark700,
                    decoration: const InputDecoration(hintText: 'Select session type'),
                    items: services.map<DropdownMenuItem<int>>((s) =>
                        DropdownMenuItem(value: s['id'] as int, child: Text(s['name']))).toList(),
                    onChanged: (v) => setState(() => _serviceId = v),
                  ),
                  const SizedBox(height: 16),
                  _label('Your Name'),
                  _field(_buyerName, 'Your full name'),
                  _label('Your Email'),
                  _field(_buyerEmail, 'your@email.com', type: TextInputType.emailAddress),
                  _label("Recipient's Name"),
                  _field(_recipientName, 'Who is this gift for?'),
                  _label("Recipient's Phone (Malawi)"),
                  _field(_recipientPhone, '+265 999 000 000', type: TextInputType.phone),
                  _label('Personal Message'),
                  TextField(
                    controller: _message,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Write a personal message...', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: mutResult.isLoading ? null : () async {
                        if (_serviceId == null || _buyerName.text.isEmpty ||
                            _buyerEmail.text.isEmpty || _recipientName.text.isEmpty) {
                          setState(() => _error = 'Please fill in all required fields.');
                          return;
                        }
                        final res = await runMutation({
                          'serviceId': _serviceId,
                          'buyerName': _buyerName.text.trim(),
                          'buyerEmail': _buyerEmail.text.trim(),
                          'recipientName': _recipientName.text.trim(),
                          'recipientPhone': _recipientPhone.text.trim(),
                          'personalMessage': _message.text.trim(),
                        }).networkResult;
                        final result = res?.data?['purchaseGiftSession'];
                        if (result?['success'] == true) {
                          // Open PayPal payment on website
                          await launchUrl(Uri.parse('$kApiBase/orders/gift/'));
                          setState(() => _giftCode = result['code']);
                        } else {
                          setState(() => _error = result?['message'] ?? 'Failed. Please try again.');
                        }
                      },
                      child: mutResult.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('🎁 Create Gift & Pay'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(child: Text('Payment via PayPal · Gift valid 1 year',
                      style: TextStyle(color: Colors.grey, fontSize: 11))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
  );

  Widget _field(TextEditingController ctrl, String hint, {TextInputType? type}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: hint),
    ),
  );
}

class _SuccessView extends StatelessWidget {
  final String code;
  const _SuccessView({required this.code});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text('Gift Created!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Share this code with the recipient:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.brand),
                color: AppTheme.brand.withOpacity(0.1),
              ),
              child: Text(code, style: const TextStyle(color: AppTheme.brand, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
