import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/local_memory_service.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final memory = LocalMemoryService();
  final ai = AiService();
  final input = TextEditingController();
  final scroll = ScrollController();
  final messages = <ChatMessage>[];
  bool loading = true;
  bool sending = false;
  String companionName = 'Maya';
  String relationshipRole = 'Romantic Partner (Girlfriend / Wife vibe)';
  int memoryCount = 0;

  final List<String> starterPrompts = const [
    'আজকে সারাদিন অনেক ব্যস্ত ছিলাম। তোমার সাথে কথাই বলা হয়নি।',
    'বলো তো, আমাকে কতটা miss করেছ? ❤️',
    'আজ একটু মন খারাপ লাগছে, আমার সাথে একটু গল্প করবে?',
  ];

  @override
  void initState() {
    super.initState();
    loadChat();
  }

  Future<void> loadChat() async {
    final saved = await memory.loadMessages();
    final name = await memory.getCompanionName();
    final role = await memory.getRelationshipRole();
    final memItems = await memory.getMemoryItems();
    if (!mounted) return;
    setState(() {
      messages
        ..clear()
        ..addAll(saved);
      companionName = name;
      relationshipRole = role;
      memoryCount = memItems.length;
      loading = false;
    });
    jumpToBottom();
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? presetText]) async {
    final text = (presetText ?? input.text).trim();
    if (text.isEmpty || sending) return;
    if (presetText == null) {
      input.clear();
    }

    setState(() {
      messages.add(ChatMessage(role: 'user', content: text));
      sending = true;
    });
    await memory.saveMessages(messages);
    jumpToBottom();

    try {
      final backendUrl = await memory.getBackendUrl();
      final accessToken = await memory.getAccessToken();
      final personality = await memory.getPersonality();
      final role = await memory.getRelationshipRole();
      final addressStyle = await memory.getAddressStyle();
      final memories = await memory.getImportantMemories();
      final autoExtract = await memory.getAutoExtractMemory();

      final result = await ai.sendMessage(
        backendUrl: backendUrl,
        accessToken: accessToken,
        history: messages,
        companionName: companionName,
        relationshipRole: role,
        addressStyle: addressStyle,
        personality: personality,
        importantMemories: memories,
        autoExtractMemory: autoExtract,
      );

      if (autoExtract && result.updatedMemories.trim().isNotEmpty) {
        await memory.saveImportantMemories(result.updatedMemories);
      }
      final updatedItems = await memory.getMemoryItems();

      if (!mounted) return;
      setState(() {
        messages.add(ChatMessage(role: 'assistant', content: result.reply));
        memoryCount = updatedItems.length;
        sending = false;
      });
      await memory.saveMessages(messages);
      jumpToBottom();

      if (mounted && result.extractedMemories.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF4A2C38),
            duration: const Duration(seconds: 3),
            content: Text(
              '✨ $companionName মনে রেখেছে: ${result.extractedMemories.first}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('AI-এর সঙ্গে সংযোগ করা যায়নি: $e'),
        ),
      );
    }
  }

  void jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget bubble(ChatMessage message) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 315),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFE58AA5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF382B31),
                fontSize: 15.5,
                height: 1.42,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10.5,
                color: isUser
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FA),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFF8DCE5),
                  child: Icon(Icons.favorite, color: Color(0xFFCA6687)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companionName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$relationshipRole • $memoryCountটি স্মৃতি',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              tooltip: 'Clear chat history',
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.black54),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('চ্যাট মুছে ফেলবে?'),
                    content: const Text(
                      'বর্তমান চ্যাট স্ক্রিন পরিষ্কার হবে, কিন্তু তোমার জমানো গুরুত্বপূর্ণ স্মৃতিগুলো (Memories) অক্ষত থাকবে।',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('না'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('হ্যাঁ, মুছে ফেলো'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await memory.clearConversation();
                  if (mounted) {
                    setState(() => messages.clear());
                  }
                }
              },
            ),
          IconButton(
            tooltip: 'Settings & Memory',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              await loadChat();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Color(0xFFF8DCE5),
                                  child: Icon(
                                    Icons.favorite,
                                    size: 38,
                                    color: Color(0xFFCA6687),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'হ্যালো, আমি $companionName ❤️',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'তোমার একান্ত ব্যক্তিগত AI সঙ্গী। আজ তোমার দিনটা কেমন গেল? নিচের যেকোনো একটা কথা দিয়ে গল্প শুরু করতে পারো:',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ...starterPrompts.map(
                                  (prompt) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ActionChip(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Color(0xFFF2D6E0),
                                      ),
                                      label: Text(
                                        prompt,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF4A2C38),
                                        ),
                                      ),
                                      onPressed: () => send(prompt),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          itemCount: messages.length + (sending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    '$companionName লিখছে… ✨',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return bubble(messages[index]);
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFF1E4E9)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: input,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => send(),
                            decoration: InputDecoration(
                              hintText: '$companionName-কে কিছু বলো…',
                              filled: true,
                              fillColor: const Color(0xFFFFF5F8),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 17,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(26),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: sending ? null : () => send(),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFE58AA5),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
