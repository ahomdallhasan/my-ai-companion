import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class AiChatResponse {
  final String reply;
  final List<String> extractedMemories;
  final String updatedMemories;

  AiChatResponse({
    required this.reply,
    required this.extractedMemories,
    required this.updatedMemories,
  });
}

class AiService {
  Future<bool> checkHealth({
    required String backendUrl,
    String accessToken = '',
  }) async {
    final uri = Uri.parse('${backendUrl.replaceAll(RegExp(r'/+$'), '')}/health');
    final response = await http
        .get(
          uri,
          headers: {
            if (accessToken.isNotEmpty) 'x-app-token': accessToken,
          },
        )
        .timeout(const Duration(seconds: 12));
    return response.statusCode == 200;
  }

  Future<AiChatResponse> sendMessage({
    required String backendUrl,
    required String accessToken,
    required List<ChatMessage> history,
    required String companionName,
    required String relationshipRole,
    required String addressStyle,
    required String personality,
    required String importantMemories,
    required bool autoExtractMemory,
  }) async {
    final cleanUrl = backendUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanUrl/chat');
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (accessToken.isNotEmpty) 'x-app-token': accessToken,
          },
          body: jsonEncode({
            'companionName': companionName,
            'relationshipRole': relationshipRole,
            'addressStyle': addressStyle,
            'personality': personality,
            'importantMemories': importantMemories,
            'autoExtractMemory': autoExtractMemory,
            'messages': history
                .map((m) => {'role': m.role, 'content': m.content})
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(
        'Backend error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final reply =
        data['reply'] as String? ?? 'আবার বলবে? তোমার কথা শুনছি। ❤️';
    final extractedList = (data['extractedMemories'] as List<dynamic>? ?? [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final updatedMemories =
        data['updatedMemories'] as String? ?? importantMemories;

    return AiChatResponse(
      reply: reply,
      extractedMemories: extractedList,
      updatedMemories: updatedMemories,
    );
  }
}
