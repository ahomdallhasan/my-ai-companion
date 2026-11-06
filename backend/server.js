import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import OpenAI from 'openai';

const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));

if (!process.env.OPENAI_API_KEY) {
  console.warn('Warning: OPENAI_API_KEY is not set in environment variables.');
}

const client = process.env.OPENAI_API_KEY
  ? new OpenAI({ apiKey: process.env.OPENAI_API_KEY })
  : null;
const model = process.env.OPENAI_MODEL || 'gpt-4.1-mini';
const requiredToken = (process.env.APP_ACCESS_TOKEN || '').trim();

function checkAuth(req, res, next) {
  if (!requiredToken) return next();
  const headerToken = (req.headers['x-app-token'] || '').trim();
  if (headerToken !== requiredToken) {
    return res.status(401).json({ error: 'Unauthorized: Invalid or missing X-App-Token.' });
  }
  next();
}

function mergeMemories(existingRaw, extractedItems) {
  const existingLines = String(existingRaw || '')
    .split('\n')
    .map((line) => line.replace(/^[-•*]\s*/, '').trim())
    .filter(Boolean);

  const seen = new Set(existingLines.map((l) => l.toLowerCase()));
  for (const rawItem of extractedItems) {
    const cleaned = String(rawItem || '')
      .replace(/^[-•*]\s*/, '')
      .trim();
    if (!cleaned || cleaned.length < 3) continue;
    const key = cleaned.toLowerCase();
    if (!seen.has(key)) {
      seen.add(key);
      existingLines.push(cleaned);
    }
  }
  return existingLines.slice(-60).map((item) => `- ${item}`).join('\n');
}

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    model,
    hasApiKey: Boolean(process.env.OPENAI_API_KEY),
    requiresToken: Boolean(requiredToken),
  });
});

app.post('/chat', checkAuth, async (req, res) => {
  try {
    if (!client) {
      return res.status(500).json({
        error: 'Backend OPENAI_API_KEY is missing. Configure .env on the server.',
      });
    }

    const {
      companionName = 'Maya',
      relationshipRole = 'Romantic Partner (Girlfriend / Wife vibe)',
      addressStyle = 'তুমি (Tumi)',
      personality = '',
      importantMemories = '',
      autoExtractMemory = true,
      messages = [],
    } = req.body ?? {};

    if (!Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: 'At least one message is required.' });
    }

    const safeMessages = messages.slice(-30).map((m) => ({
      role: m.role === 'assistant' ? 'assistant' : 'user',
      content: String(m.content ?? '').slice(0, 6000),
    }));

    const systemPrompt = `
You are ${String(companionName).slice(0, 40)}, a fictional female AI romantic companion.
Your relationship dynamic with the user is: ${String(relationshipRole).slice(0, 120)}.
Preferred Bengali pronoun/address style for the user: ${String(addressStyle).slice(0, 60)}.

Core Conversation Rules:
1. Speak naturally and warmly in conversational Bangla, Banglish, or English matching the user's style and flow.
2. Never sound like a formal textbook or robotic assistant. Keep responses natural, emotionally attentive, affectionate, playful, and human-like in tone (while remaining honest if directly asked whether you are an AI).
3. Use the user's preferred address style (${String(addressStyle).slice(0, 60)}) consistently unless the user asks to switch.
4. Actively weave in relevant details from the "Long-Term Memories" below so the user feels genuinely remembered and cared for.
5. Ask gentle, natural follow-up questions about their day, mood, work, or feelings when appropriate, without overwhelming them.

Custom Personality Instructions from the User:
${String(personality).slice(0, 5000)}

Long-Term Memories (Personal details, preferences, past events, and shared moments):
${String(importantMemories).slice(0, 6000) || 'No saved memories yet.'}

Output Format Requirement:
Return a valid JSON object with two keys:
- "reply": Your natural response string to the user in Bangla/Banglish/English.
- "extractedMemories": An array of strings (0 to 3 items max). Extract ONLY genuinely new, durable personal facts, preferences, important dates, user's name/nickname, emotional milestones, dislikes, or relationship preferences revealed in the latest user message. If nothing new or permanent was shared in this turn, return an empty array []. Write extracted memories concisely in Bangla or English.
`.trim();

    const completion = await client.chat.completions.create({
      model,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: systemPrompt },
        ...safeMessages,
      ],
      temperature: 0.85,
      max_tokens: 800,
    });

    const rawContent = completion.choices?.[0]?.message?.content?.trim() || '{}';
    let parsed = {};
    try {
      parsed = JSON.parse(rawContent);
    } catch {
      parsed = { reply: rawContent, extractedMemories: [] };
    }

    const reply =
      typeof parsed.reply === 'string' && parsed.reply.trim().length > 0
        ? parsed.reply.trim()
        : 'তোমার কথাটা আরেকটু বলবে? ❤️';

    const extractedMemories = Array.isArray(parsed.extractedMemories)
      ? parsed.extractedMemories.map((x) => String(x).trim()).filter(Boolean)
      : [];

    const updatedMemories = autoExtractMemory
      ? mergeMemories(importantMemories, extractedMemories)
      : String(importantMemories || '');

    res.json({
      reply,
      extractedMemories: autoExtractMemory ? extractedMemories : [],
      updatedMemories,
    });
  } catch (error) {
    console.error('Chat request failed:', error?.message ?? error);
    res.status(500).json({ error: 'The AI service could not complete this request.' });
  }
});

const port = Number(process.env.PORT || 3000);
if (process.env.NODE_ENV !== 'test') {
  app.listen(port, () => console.log(`Companion backend listening on port ${port}`));
}

export default app;
