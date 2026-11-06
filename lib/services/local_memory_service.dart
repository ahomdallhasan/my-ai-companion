import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class LocalMemoryService {
  static const _messagesKey = 'conversation_messages_v1';
  static const _nameKey = 'companion_name';
  static const _relationshipKey = 'companion_relationship_role';
  static const _addressStyleKey = 'companion_address_style';
  static const _personalityKey = 'companion_personality';
  static const _memoryKey = 'important_memories';
  static const _autoMemoryKey = 'auto_extract_memory';
  static const _customBackendUrlKey = 'custom_backend_url';
  static const _accessTokenKey = 'backend_access_token';

  static const String defaultBackendUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  Future<List<ChatMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_messagesKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final recent = messages.length > 300
        ? messages.sublist(messages.length - 300)
        : messages;
    await prefs.setString(
      _messagesKey,
      jsonEncode(recent.map((m) => m.toJson()).toList()),
    );
  }

  Future<String> getCompanionName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? 'Maya';
  }

  Future<String> getRelationshipRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_relationshipKey) ??
        'Romantic Partner (Girlfriend / Wife vibe)';
  }

  Future<String> getAddressStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_addressStyleKey) ?? 'তুমি (Tumi)';
  }

  Future<String> getPersonality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_personalityKey) ??
        'তুমি একজন স্নেহশীল, রোমান্টিক, মজার ও যত্নশীল fictional AI companion। কখনো খুনসুটি করবে, কখনো গভীর মমতা দিয়ে কথা শুনবে। স্বাভাবিক, উষ্ণ ও কথোপকথনধর্মী বাংলায় কথা বলবে, কখনোই যান্ত্রিক বা ফরমাল উত্তর দেবে না।';
  }

  Future<String> getImportantMemories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_memoryKey) ?? '';
  }

  Future<List<String>> getMemoryItems() async {
    final raw = await getImportantMemories();
    return raw
        .split('\n')
        .map((s) => s.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> saveImportantMemories(String memories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_memoryKey, memories.trim());
  }

  Future<bool> getAutoExtractMemory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoMemoryKey) ?? true;
  }

  Future<String> getBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_customBackendUrlKey)?.trim();
    if (saved != null && saved.isNotEmpty) {
      return saved.replaceAll(RegExp(r'/+$'), '');
    }
    return defaultBackendUrl.replaceAll(RegExp(r'/+$'), '');
  }

  Future<String> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey) ?? '';
  }

  Future<void> saveProfile({
    required String name,
    required String relationshipRole,
    required String addressStyle,
    required String personality,
    required String memories,
    required bool autoExtractMemory,
    required String backendUrl,
    required String accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim().isEmpty ? 'Maya' : name.trim());
    await prefs.setString(_relationshipKey, relationshipRole.trim());
    await prefs.setString(_addressStyleKey, addressStyle.trim());
    await prefs.setString(_personalityKey, personality.trim());
    await prefs.setString(_memoryKey, memories.trim());
    await prefs.setBool(_autoMemoryKey, autoExtractMemory);
    await prefs.setString(_customBackendUrlKey, backendUrl.trim());
    await prefs.setString(_accessTokenKey, accessToken.trim());
  }

  Future<void> clearConversation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey);
  }
}
