import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  static const String _baseUrl = 'https://signalbait.onrender.com';

  static const Color _background = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF151515);
  static const Color _green = Color(0xFF80FF80);
  static const Color _muted = Color(0xFF9CA3AF);
  static const Color _warning = Color(0xFFFFCC00);
  static const Color _error = Color(0xFFFF7777);

  final _submitFormKey = GlobalKey<FormState>();
  final _trackFormKey = GlobalKey<FormState>();

  final _submitEmailController = TextEditingController();
  final _trackEmailController = TextEditingController();
  final _ticketNumberController = TextEditingController();

  String? _issueType = 'FALSE_POSITIVE';

  bool _isSubmitting = false;
  bool _isTracking = false;

  String? _submitMessage;
  bool _submitSuccess = false;

  String? _trackMessage;
  bool _trackSuccess = false;

  Map<String, dynamic>? _createdTicket;
  Map<String, dynamic>? _trackedTicket;

  static const Map<String, String> _issueTypes = {
    'FALSE_POSITIVE':
        'Message falsely identified as potentially suspicious.',
    'FALSE_NEGATIVE': 'Message falsely identified as potentially safe.',
    'INCORRECT_MARKERS': "Markers don't reflect the message's nature.",
  };

  @override
  void dispose() {
    _submitEmailController.dispose();
    _trackEmailController.dispose();
    _ticketNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_submitFormKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _createdTicket = null;
      _submitMessage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/tickets'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'issueType': _issueType,
              'reporterEmail': _submitEmailController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = _decodeResponse(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;

        setState(() {
          _createdTicket = data;
          _submitSuccess = true;
          _submitMessage =
              'Please check your email for your ticket details.';
        });
      } else {
        throw Exception(
          data['message']?.toString() ??
              'We could not submit your report. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitSuccess = false;
          _submitMessage = _friendlyError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _trackTicket() async {
    if (!_trackFormKey.currentState!.validate()) return;

    final ticketNumber = int.tryParse(
      _ticketNumberController.text.trim(),
    );

    if (ticketNumber == null) {
      setState(() {
        _trackSuccess = false;
        _trackMessage = 'Please enter a valid ticket number.';
        _trackedTicket = null;
      });
      return;
    }

    setState(() {
      _isTracking = true;
      _trackedTicket = null;
      _trackMessage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/tickets/track'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ticketNumber': ticketNumber,
              'reporterEmail': _trackEmailController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 60));

      final data = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          _trackedTicket = data;
          _trackSuccess = true;
          _trackMessage = 'Your ticket was found successfully!';
        });
      } else {
        throw Exception(
          data['message']?.toString() ??
              'We could not find your ticket. Check the ticket number and email.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _trackSuccess = false;
          _trackMessage = _friendlyError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTracking = false);
      }
    }
  }

  Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // The server may return a non-JSON error page.
    }

    return {};
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('TimeoutException')) {
      return 'The server took too long to respond. Please try again.';
    }

    if (message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'Unable to connect. Check your internet connection.';
    }

    return message.replaceFirst('Exception: ', '');
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Not available';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final local = parsed.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} at '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report a Problem',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Help us identify problems with SignalBait's analysis.",
              style: TextStyle(color: _muted, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Sensitive information warning
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF25200D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _warning.withValues(alpha: 0.5),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFFC766),
                        size: 25,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Please do not include sensitive information.',
                          style: TextStyle(
                            color: _warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Do not submit passwords, OTPs, payment information, '
                    'account numbers, or other confidential information.',
                    style: TextStyle(
                      color: Color(0xFFD1D1D1),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _sectionCard(
              title: 'What went wrong?',
              subtitle: 'Select the issue that best describes your report.',
              child: Form(
                key: _submitFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _issueType,
                      isExpanded: true,
                      dropdownColor: _surface,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: _inputDecoration('Select an issue'),
                      items: _issueTypes.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _issueType = value);
                      },
                      validator: (value) =>
                          value == null ? 'Select an issue type.' : null,
                    ),
                    const SizedBox(height: 20),
                    _fieldLabel('Email Address'),
                    TextFormField(
                      controller: _submitEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('you@example.com'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "We'll email your ticket number so you can track "
                      'the report later.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submitTicket,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isSubmitting ? 'Submitting...' : 'Submit Report',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    if (_submitMessage != null)
                      _statusBanner(
                        message: _submitMessage!,
                        success: _submitSuccess,
                        title: _submitSuccess ? 'Success!' : 'Request Failed',
                      ),

                    if (_createdTicket != null) ...[
                      const SizedBox(height: 20),
                      _resultPanel(
                        title: 'Ticket Details',
                        details: [
                          _detail(
                            'Ticket Number',
                            _createdTicket!['ticketNumber'],
                          ),
                          _detail(
                            'Issue Type',
                            _issueTypes[_createdTicket!['issueType']] ??
                                _createdTicket!['issueType'],
                          ),
                          _detail('Status', _createdTicket!['ticketStatus']),
                          _detail(
                            'Created',
                            _formatDate(_createdTicket!['createdAt']),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            _sectionCard(
              title: 'Track Your Report',
              subtitle: 'Check the status of a previously submitted report.',
              child: Form(
                key: _trackFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Ticket Number'),
                    TextFormField(
                      controller: _ticketNumberController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Enter ticket number'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ticket number is required.';
                        }
                        if (int.tryParse(value.trim()) == null) {
                          return 'Enter a valid ticket number.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Email Address'),
                    TextFormField(
                      controller: _trackEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('you@example.com'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isTracking ? null : _trackTicket,
                        icon: _isTracking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _green,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _isTracking ? 'Checking...' : 'Check Status',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: _green),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    if (_trackMessage != null)
                      _statusBanner(
                        message: _trackMessage!,
                        success: _trackSuccess,
                        title: _trackSuccess ? 'Success!' : 'Request Failed',
                      ),

                    if (_trackedTicket != null) ...[
                      const SizedBox(height: 20),
                      _resultPanel(
                        title: 'Report Details',
                        details: [
                          _detail(
                            'Ticket Number',
                            _trackedTicket!['ticketNumber'],
                          ),
                          _detail(
                            'Issue Type',
                            _issueTypes[_trackedTicket!['issueType']] ??
                                _trackedTicket!['issueType'],
                          ),
                          _detail('Status', _trackedTicket!['ticketStatus']),
                          _detail(
                            'Created',
                            _formatDate(_trackedTicket!['createdAt']),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner({
    required String title,
    required String message,
    required bool success,
  }) {
    final color = success ? _green : _error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.65),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD1D5DB),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _green, width: 2),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'Email address is required.';

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  Widget _resultPanel({
    required String title,
    required List<Widget> details,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _green.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          ...details,
        ],
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: _muted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'Not available',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
