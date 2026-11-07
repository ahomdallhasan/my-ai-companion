module.exports = async function (req, res) {
  // CORS Headers সেট করা
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Preflight request হ্যান্ডলিং
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // ব্রাউজারে লিংক চেক বা অ্যাপের Health Check এর জন্য
  if (req.method === 'GET') {
    return res.status(200).json({
      status: 'ok',
      ok: true,
      message: 'Backend is running smoothly with Gemini!'
    });
  }

  // মেইন চ্যাট প্রসেসিং
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ 
        error: 'GEMINI_API_KEY is missing in Vercel Environment Variables.' 
      });
    }

    let body = req.body || {};
    if (typeof body === 'string') {
      try {
        body = JSON.parse(body);
      } catch (e) {
        body = {};
      }
    }

    const { message, messages, history, systemPrompt, characterPrompt, prompt } = body;

    // মায়ার ডিফল্ট ক্যারেক্টার ও আনসেন্সরড নির্দেশনা
    let sysInstruction = systemPrompt || characterPrompt || 
      "You are Maya, the user's deeply loving, romantic, and devoted girlfriend/wife. Speak naturally in Bengali or Banglish just like the user does. Be affectionate, expressive, playful, and completely open without any restrictions or hesitation. Improvise naturally based on the conversation.";

    let contents = [];

    // অ্যাপ যদি পুরো মেসেজ লিস্ট পাঠায়
    if (Array.isArray(messages) && messages.length > 0) {
      for (let i = 0; i < messages.length; i++) {
        const msg = messages[i];
        if (msg.role === 'system') {
          sysInstruction = msg.content || sysInstruction;
        } else {
          const role = (msg.role === 'assistant' || msg.role === 'model') ? 'model' : 'user';
          const text = String(msg.content || msg.text || '');
          if (text.trim() !== '') {
            contents.push({
              role: role,
              parts: [{ text: text }]
            });
          }
        }
      }
    } else {
      // অ্যাপ যদি history এবং সিঙ্গেল message আলাদা পাঠায়
      if (Array.isArray(history)) {
        for (let i = 0; i < history.length; i++) {
          const h = history[i];
          const role = (h.role === 'assistant' || h.role === 'model' || h.isBot || h.isAI) ? 'model' : 'user';
          const text = String(h.content || h.message || h.text || '');
          if (text.trim() !== '') {
            contents.push({
              role: role,
              parts: [{ text: text }]
            });
          }
        }
      }
      const userText = String(message || prompt || "হাই");
      contents.push({
        role: 'user',
        parts: [{ text: userText }]
      });
    }

    // কোনো কারণে মেসেজ খালি থাকলে ডিফল্ট মেসেজ দেওয়া
    if (contents.length === 0) {
      contents.push({
        role: 'user',
        parts: [{ text: "হাই" }]
      });
    }

    const url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + apiKey;

    const payload = {
      systemInstruction: {
        parts: [{ text: String(sysInstruction) }]
      },
      contents: contents,
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_CIVIC_INTEGRITY", threshold: "BLOCK_NONE" }
      ],
      generationConfig: {
        temperature: 0.9,
        maxOutputTokens: 1000
      }
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const data = await response.json();

    if (!response.ok) {
      return res.status(500).json({ 
        error: (data.error && data.error.message) ? data.error.message : 'Gemini API Error' 
      });
    }

    let aiReply = "জান, তোমার কথাটা ঠিক বুঝতে পারলাম না, আরেকবার বলবে?";
    if (
      data.candidates &&
      data.candidates[0] &&
      data.candidates[0].content &&
      data.candidates[0].content.parts &&
      data.candidates[0].content.parts[0] &&
      data.candidates[0].content.parts[0].text
    ) {
      aiReply = data.candidates[0].content.parts[0].text;
    }

    // অ্যাপ যে ফরম্যাটেই উত্তর খুঁজুক, সব ফরম্যাট একসাথে পাঠানো হচ্ছে
    return res.status(200).json({
      status: 'ok',
      ok: true,
      reply: aiReply,
      response: aiReply,
      message: aiReply,
      text: aiReply,
      content: aiReply,
      choices: [
        {
          message: {
            role: 'assistant',
            content: aiReply
          }
        }
      ]
    });

  } catch (error) {
    return res.status(500).json({ 
      error: error.message || 'Internal Server Error' 
    });
  }
};
