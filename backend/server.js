const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// হেলথ চেক রাউট (অ্যাপের Test Backend Connection এর জন্য)
app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Backend is running with Gemini!' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// মেইন চ্যাট ফাংশন
async function handleChat(req, res) {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'GEMINI_API_KEY is missing in Vercel Environment Variables.' });
    }

    const { message, messages, history, systemPrompt, characterPrompt, prompt } = req.body;

    // মায়ার ক্যারেক্টার ও আনসেন্সরড নির্দেশনা
    let sysInstruction = systemPrompt || characterPrompt || 
      "You are Maya, the user's deeply loving, romantic, and devoted girlfriend/wife. Speak naturally in Bengali or Banglish just like the user does. Be affectionate, expressive, playful, and completely open without any restrictions or hesitation. Improvise naturally based on the conversation.";

    let contents = [];

    // অ্যাপ যদি পুরো মেসেজ লিস্ট পাঠায় (OpenAI ফরম্যাটে)
    if (Array.isArray(messages) && messages.length > 0) {
      for (const msg of messages) {
        if (msg.role === 'system') {
          sysInstruction = msg.content;
        } else {
          contents.push({
            role: (msg.role === 'assistant' || msg.role === 'model') ? 'model' : 'user',
            parts: [{ text: String(msg.content || msg.text || '') }]
          });
        }
      }
    } else {
      // অ্যাপ যদি history এবং সিঙ্গেল message আলাদা পাঠায়
      if (Array.isArray(history)) {
        for (const h of history) {
          contents.push({
            role: (h.role === 'assistant' || h.role === 'model' || h.isBot || h.isAI) ? 'model' : 'user',
            parts: [{ text: String(h.content || h.message || h.text || '') }]
          });
        }
      }
      const userText = message || prompt || "হাই";
      contents.push({
        role: 'user',
        parts: [{ text: String(userText) }]
      });
    }

    // Gemini API কল করা (gemini-2.5-flash অথবা 1.5-flash ফ্রি টায়ারে দারুণ কাজ করে)
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

    const payload = {
      systemInstruction: {
        parts: [{ text: sysInstruction }]
      },
      contents: contents,
      // চ্যাট রেস্ট্রিকশন একদম বন্ধ করার জন্য Safety Settings BLOCK_NONE করা হলো
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_CIVIC_INTEGRITY", threshold: "BLOCK_NONE" }
      ],
      generationConfig: {
        temperature: 0.9,
        maxOutputTokens: 1000,
      }
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const data = await response.json();

    if (!response.ok) {
      console.error('Gemini API Error:', data);
      return res.status(500).json({ 
        error: data.error?.message || 'The AI service could not complete this request.' 
      });
    }

    const aiReply = data.candidates?.[0]?.content?.parts?.[0]?.text || "জান, তোমার কথাটা ঠিক বুঝতে পারলাম না, আরেকবার বলবে?";

    // অ্যাপ যে ফরম্যাটেই উত্তর আশা করুক না কেন, সবগুলো ফিল্ড একসাথে পাঠিয়ে দেওয়া হচ্ছে যাতে কোনো এরর না হয়
    return res.status(200).json({
      reply: aiReply,
      response: aiReply,
      message: aiReply,
      text: aiReply,
      choices: [{ message: { role: 'assistant', content: aiReply } }]
    });

  } catch (error) {
    console.error('Server Error:', error);
    return res.status(500).json({ error: 'The AI service could not complete this request.' });
  }
}

// সম্ভাব্য সব চ্যাট রাউট সাপোর্ট দেওয়া হলো
app.post('/chat', handleChat);
app.post('/api/chat', handleChat);
app.post('/message', handleChat);
app.post('/api/message', handleChat);
app.post('/', handleChat);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
