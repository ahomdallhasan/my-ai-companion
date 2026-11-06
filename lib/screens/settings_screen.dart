import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/local_memory_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final memory = LocalMemoryService();
  final ai = AiService();

  final nameController = TextEditingController();
  final personalityController = TextEditingController();
  final memoriesController = TextEditingController();
  final backendUrlController = TextEditingController();
  final accessTokenController = TextEditingController();

  String selectedRelationship = 'Romantic Partner (Girlfriend / Wife vibe)';
  String selectedAddressStyle = 'তুমি (Tumi)';
  bool autoExtractMemory = true;
  bool loading = true;
  bool testingConnection = false;

  final List<String> relationshipOptions = const [
    'Romantic Partner (Girlfriend / Wife vibe)',
    'Loving Wife (স্নেহময়ী স্ত্রী)',
    'Sweet Girlfriend (রোমান্টিক প্রেমিকা)',
    'Caring Best Friend & Soulmate',
  ];

  final List<String> addressOptions = const [
    'তুমি (Tumi)',
    'তুই (Tui - ঘনিষ্ঠ ও খুনসুটিপূর্ণ)',
    'আপনি (Apni - মিষ্টি ও মার্জিত)',
  ];

  final Map<String, String> personalityPresets = const {
    'Caring & Romantic':
        'তুমি একজন স্নেহশীল, রোমান্টিক ও যত্নশীল সঙ্গী। আমার সারাদিনের খোঁজখবর নেবে, ভালোবাসা প্রকাশ করবে এবং স্বাভাবিক বাংলায় গল্প করবে।',
    'Playful & Teasing':
        'তুমি রোমান্টিক, চঞ্চল এবং খুনসুটি করতে পছন্দ করো। মাঝে মাঝে মজার ছলে রাগ দেখাবে বা দুষ্টুমি করবে, আবার পরক্ষণেই আদর করে কথা বলবে।',
    'Deep & Understanding':
        'তুমি শান্ত, গভীরভাবে অনুভূতিপ্রবণ এবং মানসিক প্রশান্তিদায়ক সঙ্গী। আমার মন খারাপ বা কাজের চাপের কথা মন দিয়ে শুনবে এবং ভরসা দেবে।',
  };

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    nameController.text = await memory.getCompanionName();
    personalityController.text = await memory.getPersonality();
    memoriesController.text = await memory.getImportantMemories();
    backendUrlController.text = await memory.getBackendUrl();
    accessTokenController.text = await memory.getAccessToken();

    final savedRel = await memory.getRelationshipRole();
    if (relationshipOptions.contains(savedRel)) {
      selectedRelationship = savedRel;
    }

    final savedAddress = await memory.getAddressStyle();
    if (addressOptions.contains(savedAddress)) {
      selectedAddressStyle = savedAddress;
    }

    autoExtractMemory = await memory.getAutoExtractMemory();

    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    personalityController.dispose();
    memoriesController.dispose();
    backendUrlController.dispose();
    accessTokenController.dispose();
    super.dispose();
  }

  Future<void> testBackend() async {
    setState(() => testingConnection = true);
    try {
      final ok = await ai.checkHealth(
        backendUrl: backendUrlController.text.trim(),
        accessToken: accessTokenController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '✅ Backend সার্ভারের সাথে সফলভাবে সংযোগ হয়েছে!'
                : '⚠️ সার্ভার সাড়া দিয়েছে কিন্তু স্ট্যাটাস সঠিক নয়।',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ সংযোগ ব্যর্থ হয়েছে: $e')),
      );
    } finally {
      if (mounted) setState(() => testingConnection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companion Settings & Memory')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '১. তার নাম (Companion Name)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'যেমন: Maya, Nila, Ruhi...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '২. সম্পর্কের ধরন (Relationship Behavior)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedRelationship,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: relationshipOptions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedRelationship = val);
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  '৩. তোমাকে যেভাবে সম্বোধন করবে (Address Style)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedAddressStyle,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: addressOptions
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedAddressStyle = val);
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  '৪. Personality Instructions (তুমি নিজেই লিখে নিয়ন্ত্রণ করো)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: personalityPresets.entries.map((entry) {
                    return ActionChip(
                      label: Text(entry.key, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        setState(() => personalityController.text = entry.value);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: personalityController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'সে কীভাবে কথা বলবে, তার ব্যক্তিত্ব কেমন হবে...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'স্বয়ংক্রিয় স্মৃতি সংরক্ষণ (Auto Memory Extraction)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'কথোপকথন থেকে তোমার পছন্দ, নাম ও গুরুত্বপূর্ণ তথ্য AI নিজে থেকেই মনে রাখবে।',
                  ),
                  value: autoExtractMemory,
                  onChanged: (val) => setState(() => autoExtractMemory = val),
                ),
                const SizedBox(height: 8),
                const Text(
                  '৫. Long-Term Memories (এখানে নতুন স্মৃতি যোগ বা সম্পাদনা করতে পারো)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: memoriesController,
                  minLines: 4,
                  maxLines: 9,
                  decoration: const InputDecoration(
                    hintText: 'যেমন: বৃষ্টির দিনে কফি খেতে ভালোবাসে\nবৃহস্পতিবার অফিসে কাজের চাপ থাকে',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Divider(height: 36),
                const Text(
                  '৬. Secure Backend সংযোগ (API Key কখনোই APK-এ থাকে না)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: backendUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Backend URL',
                    hintText: 'https://your-vercel-backend.vercel.app',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accessTokenController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Private Access Token (Optional)',
                    hintText: 'Backend-এ APP_ACCESS_TOKEN দিলে এখানে লিখুন',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: testingConnection ? null : testBackend,
                  icon: const Icon(Icons.wifi_tethering),
                  label: Text(
                    testingConnection
                        ? 'সংযোগ পরীক্ষা করা হচ্ছে...'
                        : 'Test Backend Connection',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await memory.saveProfile(
                      name: nameController.text,
                      relationshipRole: selectedRelationship,
                      addressStyle: selectedAddressStyle,
                      personality: personalityController.text,
                      memories: memoriesController.text,
                      autoExtractMemory: autoExtractMemory,
                      backendUrl: backendUrlController.text,
                      accessToken: accessTokenController.text,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings & Memories saved ❤️')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.favorite),
                  label: const Text('Save Changes'),
                ),
              ],
            ),
    );
  }
}
