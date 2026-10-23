// HTML/Vue → Flutter Translation Notes
// <form>       → Form
// <textarea>   → TextField(maxLines: ...)
// <button>     → ElevatedButton
// @click       → onPressed
// @input       → TextField + onChanged
// <input>      → TextField

// JavaScript to Dart
// promise      → Future
// Example (JS await is the same as Dart's await)
// const response = await fetch('api/scan') → JS
// final response = await http.get(url);    → Dart

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http_parser/http_parser.dart';
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _picker = ImagePicker();
  

  // Android emulator -> host computer.
  // Change this for a physical device or production server.
  static const _apiBaseUrl = 'https://signal-bait-two.vercel.app';

  bool _isAnalyzing = false;
  bool _isGeneratingReport = false;
  bool _imageMode = false;
  bool _isPickingImage = false;

  XFile? _selectedImage;
  Map<String, dynamic>? _analysisResult;
  String? _extractedText;
  String? _statusMessage;
  bool _hasError = false;

  static const _disclaimer =
      'Analysis results may contain mistakes. '
      'Verify with official channels if in doubt.';

  static const _neutralLabels = [
    'urgency or time pressure',
    'request to perform an action',
    'request to click a link',
    'request to visit an external website',
    'request for personal information',
    'financial information or payment',
    'account or service issue',
  ];

  static const _highRiskLabels = [
    'impersonation or false authority',
    'request for passwords, OTPs, or credentials',
    'threat of severe or catastrophic consequences',
    'coercive or threatening language',
    'unexpected financial opportunity',
    'unusual payment instructions',
    'attempt to obtain sensitive information',
  ];

  static const _contextualLabels = [
    'unexpected communication from the sender',
    'unusual communication channel',
    'unexpected request from an organization',
    'claim involving an existing account or service',
    'communication involving a trusted organization',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  double _score(String key) {
    final value = _analysisResult?[key];
    return value is num ? value.toDouble() : 0.0;
  }

  int get _riskPercentage => (_score('high_risk_score') * 100).round();

  String get _riskLevel {
    final score = _score('high_risk_score');

    if (score >= 0.7) return 'High';
    if (score >= 0.4) return 'Medium';
    return 'Low';
  }

  Color get _riskColor {
    switch (_riskLevel) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return const Color(0xFFFACC15);
      default:
        return const Color(0xFF00FF66);
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage || _isAnalyzing) return;

    _isPickingImage = true;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 75,
      );

      if (image == null || !mounted) return;

      setState(() {
        _selectedImage = image;
        _analysisResult = null;
        _extractedText = null;
        _statusMessage = null;
      });
    } catch (error) {
      debugPrint('Image picker error: $error');
      _showError('Could not select the image. Please try again.');
    } finally {
      _isPickingImage = false;
    }
  }

  Future<Map<String, dynamic>> _postText(String content) async {
    final response = await http
        .post(
          Uri.parse('$_apiBaseUrl/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'content': content}),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      debugPrint('Image scan failed: ${response.statusCode}');
      debugPrint('Backend response: ${response.body}');

      throw Exception(
        'Image scan failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected analysis response.');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> _postImage(XFile image) async {
    final mimeType = image.mimeType ?? _mimeTypeFromName(image.name);

    debugPrint('Image name: ${image.name}');
    debugPrint('Image MIME type: $mimeType');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_apiBaseUrl/scan-image'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 180),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      debugPrint('Image scan failed: ${response.statusCode}');
      debugPrint('Backend response: ${response.body}');

      throw Exception(
        'Image scan failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected image response.');
    }

    return decoded;
  }

  String _mimeTypeFromName(String filename) {
    switch (filename.split('.').last.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _analyze() async {
    if (_isAnalyzing) return;

    if (_imageMode) {
      if (_selectedImage == null) {
        _showError('Please select an image first.');
        return;
      }
    } else if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _extractedText = null;
      _statusMessage = null;
      _hasError = false;
    });

    try {
      final result = _imageMode
          ? await _postImage(_selectedImage!)
          : await _postText(_messageController.text.trim());

      if (!mounted) return;

      setState(() {
        _analysisResult = result;
        _extractedText = result['text'] as String?;
        _statusMessage = 'Analysis complete. Your report is ready.';
      });
    } catch (error) {
      debugPrint('Analysis error: $error');

      if (!mounted) return;

      setState(() {
        _statusMessage =
            'Analysis failed. Check your connection and try again.';
        _hasError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  List<Map<String, dynamic>> _indicators(String key) {
    final raw = _analysisResult?[key];

    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _makeReportId() {
    final now = DateTime.now().toUtc().microsecondsSinceEpoch;
    final suffix = Random().nextInt(9000) + 1000;
    return 'SB-$now-$suffix';
  }

  String _formatScore(dynamic value) {
    if (value is! num) return 'N/A';
    return '${(value * 100).round()}%';
  }

  Future<void> _downloadReport() async {
    if (_analysisResult == null || _isGeneratingReport) return;

    setState(() => _isGeneratingReport = true);

    try {
      final result = _analysisResult!;
      final now = DateTime.now();
      final reportId = _makeReportId();
      final pdf = pw.Document();

      final categories = [
        {
          'title': 'High-risk indicators',
          'scoreKey': 'high_risk_score',
          'items': _indicators('high_risk_indicators'),
        },
        {
          'title': 'Contextual markers',
          'scoreKey': 'contextual_score',
          'items': _indicators('contextual_indicators'),
        },
        {
          'title': 'Neutral signals',
          'scoreKey': 'neutral_score',
          'items': _indicators('neutral_indicators'),
        },
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (context) => [
            pw.Text(
              'SignalBait Analysis Report',
              style: pw.TextStyle(
                fontSize: 23,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Report ID: $reportId'),
            pw.Text('Generated: ${now.toLocal()}'),
            pw.Text('Input type: ${_imageMode ? 'Image' : 'Text'}'),
            pw.Divider(height: 24),

            pw.Text(
              'Overall Risk Level: $_riskLevel',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text('High-risk indicator score: $_riskPercentage%'),
            pw.SizedBox(height: 12),

            pw.Text(
              'Category scores',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            ...categories.map((category) {
              final scoreKey = category['scoreKey'] as String;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Text(
                  '${category['title']}: '
                  '${_formatScore(result[scoreKey])}',
                ),
              );
            }),

            pw.SizedBox(height: 16),
            pw.Text(
              'Supporting Indicators',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            ...categories.expand((category) {
              final items =
                  category['items'] as List<Map<String, dynamic>>;

              return [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
                  child: pw.Text(
                    category['title'] as String,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                if (items.isEmpty)
                  pw.Text('No indicator data available.')
                else
                  ...items.map((indicator) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        '${indicator['label'] ?? 'Unknown indicator'}: '
                        '${_formatScore(indicator['score'])}',
                      ),
                    );
                  }),
              ];
            }),

            if (_imageMode) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'OCR-Extracted Text',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                (_extractedText == null || _extractedText!.trim().isEmpty)
                    ? 'No text was extracted from the image.'
                    : _extractedText!,
              ),
            ],

            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.Text(
              'Disclaimer',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(_disclaimer),
            pw.SizedBox(height: 6),
            pw.Text(
              'Scores are AI-generated semantic indicator scores. '
              'They are not calibrated probabilities of fraud and '
              'do not constitute a definitive fraud determination.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();

      // Android opens the system share/save interface.
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'SignalBait_Report_$reportId.pdf',
      );
    } catch (error) {
      debugPrint('PDF generation error: $error');
      _showError('Could not generate the report. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingReport = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _analysisResult != null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'SIGNAL ANALYSIS',
          style: TextStyle(
            color: Color(0xFF00FF66),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Analyze',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Text / Image selector.
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Text')),
            ButtonSegment(value: true, label: Text('Image')),
          ],
          selected: {_imageMode},
          onSelectionChanged: _isAnalyzing
              ? null
              : (selection) {
                  setState(() {
                    _imageMode = selection.first;
                    _analysisResult = null;
                    _statusMessage = null;
                  });
                },
        ),
        const SizedBox(height: 16),

        if (!_imageMode)
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _messageController,
              minLines: 5,
              maxLines: 8,
              enabled: !_isAnalyzing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a message to analyze.';
                }
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'Paste suspicious message here...',
                border: OutlineInputBorder(),
              ),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _isAnalyzing ? null : _pickImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(
              _selectedImage == null
                  ? 'Choose image'
                  : _selectedImage!.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isAnalyzing ? null : _analyze,
            child: _isAnalyzing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Analyzing...'),
                    ],
                  )
                : const Text('Analyze Signal'),
          ),
        ),

        if (_statusMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _statusMessage!,
            style: TextStyle(
              color: _hasError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ],

        if (hasResult) ...[
          const SizedBox(height: 24),
          _buildResultCard(),
        ],
      ],
    );
  }

  Widget _buildResultCard() {
    final color = _riskColor;
    final percentage = _riskPercentage.clamp(0, 100);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANALYSIS COMPLETE',
                  style: TextStyle(
                    color: Color(0xFF00FF66),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Overall Risk Level',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF292929)),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _riskLevel,
                        style: TextStyle(
                          color: color,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 9,
                    backgroundColor: const Color(0xFF1A1A1A),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Risk score generated from detected semantic signals.',
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF292929)),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NOTE',
                  style: TextStyle(
                    color: Color(0xFF00FF66),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Analysis results may contain mistakes. '
                  'Verify with official channels if in doubt.',
                  style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingReport
                        ? null
                        : _downloadReport,
                    icon: _isGeneratingReport
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _isGeneratingReport
                          ? 'Generating Report...'
                          : 'Download Analysis Report',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
