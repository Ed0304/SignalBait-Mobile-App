
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _picker = ImagePicker();

  static const _apiBaseUrl = 'https://signal-bait-two.vercel.app';

  static const _background = Color(0xFF0D0D0D);
  static const _surface = Color(0xFF151515);
  static const _green = Color(0xFF80FF80);
  static const _muted = Color(0xFF9CA3AF);
  static const _error = Color(0xFFFF7777);
  static const _warning = Color(0xFFFACC15);

  static const _disclaimer =
      'Analysis results may contain mistakes. '
      'Verify with official channels if in doubt.';

  bool _isAnalyzing = false;
  bool _isGeneratingReport = false;
  bool _imageMode = false;
  bool _isPickingImage = false;

  XFile? _selectedImage;
  Map<String, dynamic>? _analysisResult;
  String? _extractedText;
  String? _statusMessage;
  bool _hasError = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  double _score(String key) {
    final value = _analysisResult?[key];
    return value is num ? value.toDouble() : 0.0;
  }

  int get _riskPercentage =>
      (_score('high_risk_score') * 100).round();

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
        return _warning;
      default:
        return _green;
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage || _isAnalyzing) return;

    setState(() => _isPickingImage = true);

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
        _hasError = false;
      });
    } catch (error) {
      debugPrint('Image picker error: $error');
      _showError('Could not select the image. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
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
      debugPrint('Text scan failed: ${response.statusCode}');
      debugPrint('Backend response: ${response.body}');
      throw Exception('Text analysis failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected analysis response.');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> _postImage(XFile image) async {
    final mimeType = image.mimeType ?? _mimeTypeFromName(image.name);

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
      throw Exception('Image analysis failed (${response.statusCode}).');
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
    } else {
      if (!(_formKey.currentState?.validate() ?? false)) {
        return;
      }
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
                (_extractedText == null ||
                        _extractedText!.trim().isEmpty)
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
      SnackBar(
        content: Text(message),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 1.5),
      ),
      errorStyle: const TextStyle(color: _error),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _analysisResult != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Row(
          children: [
            Icon(Icons.radar_rounded, color: _green, size: 18),
            SizedBox(width: 8),
            Text(
              'SIGNALBAIT  /  SCANNER',
              style: TextStyle(
                color: _green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Analyze a signal',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Check a suspicious message or screenshot for potential scam indicators.',
          style: TextStyle(
            color: _muted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INPUT SOURCE',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _modeButton(
                        label: 'Text message',
                        icon: Icons.notes_rounded,
                        imageMode: false,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _modeButton(
                        label: 'Image',
                        icon: Icons.image_outlined,
                        imageMode: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (!_imageMode)
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _messageController,
                    minLines: 6,
                    maxLines: 9,
                    enabled: !_isAnalyzing,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a message to analyze.';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      'Paste the suspicious message here...',
                    ).copyWith(alignLabelWithHint: true),
                  ),
                )
              else
                _imagePickerPanel(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: _background,
                    disabledBackgroundColor:
                        _green.withValues(alpha: 0.35),
                    disabledForegroundColor:
                        _background.withValues(alpha: 0.65),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: _isAnalyzing ? null : _analyze,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _background,
                          ),
                        )
                      : const Icon(
                          Icons.shield_outlined,
                          size: 19,
                        ),
                  label: Text(
                    _isAnalyzing
                        ? 'Analyzing signal...'
                        : 'Analyze signal',
                  ),
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_hasError ? _error : _green)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_hasError ? _error : _green)
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _hasError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 18,
                        color: _hasError ? _error : _green,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _hasError ? _error : _green,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasResult) ...[
          const SizedBox(height: 22),
          _buildResultCard(),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color: _muted,
              size: 17,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                _disclaimer,
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool imageMode,
  }) {
    final selected = _imageMode == imageMode;

    return Material(
      color: selected ? _surface : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: _isAnalyzing
            ? null
            : () {
                setState(() {
                  _imageMode = imageMode;
                  _analysisResult = null;
                  _statusMessage = null;
                  _hasError = false;
                });
              },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? _green.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? _green : _muted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : _muted,
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePickerPanel() {
    return InkWell(
      onTap: _isAnalyzing || _isPickingImage ? null : _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 26,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedImage == null
                ? Colors.white.withValues(alpha: 0.16)
                : _green.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          children: [
            Icon(
              _selectedImage == null
                  ? Icons.cloud_upload_outlined
                  : Icons.image_rounded,
              color: _green,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              _selectedImage == null
                  ? (_isPickingImage
                      ? 'Opening gallery...'
                      : 'Choose a screenshot')
                  : _selectedImage!.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _selectedImage == null
                  ? 'Select an image from your device'
                  : 'Tap to choose a different image',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final color = _riskColor;
    final percentage = _riskPercentage.clamp(0, 100);

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCAN RESULTS',
                        style: TextStyle(
                          color: _green,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Overall risk level',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _riskLevel,
                        style: TextStyle(
                          color: color,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: _background,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Semantic signal score — not a calibrated probability of fraud.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    _disclaimer,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isGeneratingReport ? null : _downloadReport,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: BorderSide(
                        color: _green.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isGeneratingReport
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _green,
                            ),
                          )
                        : const Icon(
                            Icons.file_download_outlined,
                            size: 19,
                          ),
                    label: Text(
                      _isGeneratingReport
                          ? 'Generating report...'
                          : 'Export PDF report',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
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
