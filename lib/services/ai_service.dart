import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

/// Service for AI-powered features in NagarSetu
/// Supports multiple free AI providers: Gemini, Groq
class AIService {
  AIService._();
  static final AIService _instance = AIService._();
  static AIService get instance => _instance;

  /// API endpoints
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String _groqBaseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Generates a concise, professional title for a civic issue based on description
  /// Uses configured AI provider (Gemini or Groq)
  /// Returns the generated title or falls back to local generation
  Future<String?> generateIssueTitle({
    required String description,
    required String issueType,
    required String criticality,
  }) async {
    if (description.trim().isEmpty) return null;

    final prompt = _buildPrompt(description, issueType, criticality);

    if (Environment.aiProvider == 'groq') {
      final result = await _tryGroq(prompt);
      if (result != null) return result;
      final geminiResult = await _tryGemini(prompt);
      if (geminiResult != null) return geminiResult;
    } else {
      final result = await _tryGemini(prompt);
      if (result != null) return result;
      final groqResult = await _tryGroq(prompt);
      if (groqResult != null) return groqResult;
    }

    return _generateLocalTitle(description, issueType);
  }

  String _buildPrompt(
    String description,
    String issueType,
    String criticality,
  ) {
    return '''Extract a short title (3-6 words max) from this civic complaint description.

Description: $description
Category: $issueType

STRICT RULES:
- Use ONLY words and facts from the description
- Do NOT add any information not in the description
- Do NOT assume or infer details
- Keep it under 6 words
- No quotes, no explanation, just the title

Title:''';
  }

  /// Try Gemini API
  Future<String?> _tryGemini(String prompt) async {
    if (Environment.geminiApiKey == 'YOUR_GEMINI_API_KEY' ||
        Environment.geminiApiKey.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_geminiBaseUrl?key=${Environment.geminiApiKey}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 50,
                'topP': 0.9,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return _cleanTitle((parts[0]['text'] as String));
          }
        }
      } else if (Environment.enableLogging) {
        print('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogging) {
        print('Gemini error: $e');
      }
    }
    return null;
  }

  /// Try Groq API (fastest, uses Llama 3)
  Future<String?> _tryGroq(String prompt) async {
    if (Environment.groqApiKey == 'YOUR_GROQ_API_KEY' ||
        Environment.groqApiKey.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse(_groqBaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${Environment.groqApiKey}',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.7,
              'max_tokens': 50,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          if (message != null) {
            return _cleanTitle(message['content'] as String);
          }
        }
      } else if (Environment.enableLogging) {
        print('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogging) {
        print('Groq error: $e');
      }
    }
    return null;
  }

  /// Clean up title - remove surrounding single/double quotes safely and trim
  String _cleanTitle(String title) {
    var t = title.trim();

    while (t.isNotEmpty && (t.startsWith('"') || t.startsWith("'"))) {
      t = t.substring(1).trimLeft();
    }

    while (t.isNotEmpty && (t.endsWith('"') || t.endsWith("'"))) {
      t = t.substring(0, t.length - 1).trimRight();
    }

    return t;
  }

  /// Local fallback title generation when API is unavailable
  /// Creates a smart title based on keywords in the description
  String _generateLocalTitle(String description, String issueType) {
    final words = description.trim().split(RegExp(r'\s+'));

    final actionWords = [
      'broken',
      'damaged',
      'leaking',
      'blocked',
      'not working',
      'overflowing',
      'missing',
      'faulty',
      'no',
      'out of order',
      'stuck',
      'fallen',
      'collapsed',
      'flooded',
      'burning',
    ];

    final locationWords = [
      'street',
      'road',
      'lane',
      'area',
      'colony',
      'sector',
      'block',
      'building',
      'park',
      'market',
      'junction',
      'crossing',
      'bridge',
      'flyover',
      'footpath',
      'sidewalk',
    ];

    String? actionFound;
    String? locationFound;

    final lowerDesc = description.toLowerCase();

    for (final action in actionWords) {
      if (lowerDesc.contains(action)) {
        actionFound = action;
        break;
      }
    }

    for (final location in locationWords) {
      if (lowerDesc.contains(location)) {
        locationFound = location;
        break;
      }
    }

    if (actionFound != null && locationFound != null) {
      return '${_capitalize(actionFound)} $issueType issue near $locationFound';
    } else if (actionFound != null) {
      return '${_capitalize(actionFound)} $issueType issue';
    } else if (locationFound != null) {
      return '$issueType issue near $locationFound';
    } else if (words.length <= 6) {
      return _capitalize(description.trim());
    } else {
      final summary = words.take(5).join(' ');
      return '$issueType: ${_capitalize(summary)}...';
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
