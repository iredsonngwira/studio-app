import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/queries.dart';
import '../theme.dart';

class BookingScreen extends StatefulWidget {  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date;
  int? _serviceId;
  bool _submitted = false;
  List<String> _bookedDates = [];

  @override
  void initState() {
    super.initState();
    _loadBookedDates();
  }

  Future<void> _loadBookedDates() async {
    final client = GraphQLProvider.of(context).value;
    final result = await client.query(QueryOptions(document: gql(kGetBookedDates)));
    if (mounted) {
      setState(() {
        _bookedDates = ((result.data?['bookedDates'] as List?) ?? []).cast<String>();
      });
    }
  }

  bool _isBooked(DateTime d) {
    final s = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return _bookedDates.contains(s);
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kGetServices)),
      builder: (result, {fetchMore, refetch}) {
        final services = (result.data?['services'] as List?) ?? [];

        if (_submitted) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book a Session')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.brand, width: 2),
                      color: AppTheme.brand.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.check, color: AppTheme.brand, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('Booking Received!', style: TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("We'll confirm within 24 hours.",
                    style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() => _submitted = false),
                    child: const Text('Book Another'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Book a Session')),
          body: Mutation(
            options: MutationOptions(document: gql(kCreateBooking)),
            builder: (runMutation, mutResult) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service selector
                      const Text('Service', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _serviceId,
                        dropdownColor: AppTheme.dark700,
                        decoration: const InputDecoration(hintText: 'Select a service'),
                        items: services.map<DropdownMenuItem<int>>((s) =>
                          DropdownMenuItem(value: s['id'] as int, child: Text(s['name']))).toList(),
                        onChanged: (v) => setState(() => _serviceId = v),
                        validator: (v) => v == null ? 'Please select a service' : null,
                      ),
                      const SizedBox(height: 16),

                      _field(_name, 'Full Name', Icons.person),
                      _field(_email, 'Email', Icons.email, type: TextInputType.emailAddress),
                      _field(_phone, 'Phone / WhatsApp', Icons.phone, type: TextInputType.phone),

                      // Date picker
                      const Text('Preferred Date', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            selectableDayPredicate: (day) => !_isBooked(day),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.dark(primary: AppTheme.brand)),
                              child: child!,
                            ),
                          );
                          if (d != null) setState(() => _date = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.dark600),
                            color: AppTheme.dark700,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                              const SizedBox(width: 12),
                              Text(
                                _date != null
                                  ? '${_date!.day}/${_date!.month}/${_date!.year}'
                                  : 'Select date',
                                style: TextStyle(color: _date != null ? Colors.white : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _field(_location, 'Location / Venue (optional)', Icons.location_on, required: false),
                      _field(_notes, 'Additional Notes (optional)', Icons.notes, required: false, maxLines: 3),

                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dark600),
                          color: AppTheme.dark700,
                        ),
                        child: const Text(
                          '💳 50% deposit required to confirm. We accept Airtel Money, TNM Mpamba, and PayPal.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (mutResult?.hasException == true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('Error: ${mutResult!.exception}',
                            style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: mutResult?.isLoading == true ? null : () async {
                            if (!_formKey.currentState!.validate() || _date == null || _serviceId == null) {
                              if (_date == null) ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a date')));
                              return;
                            }
                            final dateStr = '${_date!.year}-${_date!.month.toString().padLeft(2,'0')}-${_date!.day.toString().padLeft(2,'0')}';
                            final res = await runMutation({
                              'serviceId': _serviceId,
                              'guestName': _name.text,
                              'guestEmail': _email.text,
                              'guestPhone': _phone.text,
                              'sessionDate': dateStr,
                              'location': _location.text,
                              'notes': _notes.text,
                            }).networkResult;
                            if (res?.data?['createBooking']?['success'] == true) {
                              setState(() => _submitted = true);
                            }
                          },
                          child: mutResult?.isLoading == true
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('Submit Booking Request'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type, bool required = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: type,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.grey, size: 18)),
            validator: required ? (v) => (v?.isEmpty == true) ? 'Required' : null : null,
          ),
        ],
      ),
    );
  }
}
