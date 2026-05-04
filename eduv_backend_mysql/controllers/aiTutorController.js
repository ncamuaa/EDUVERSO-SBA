const Anthropic = require('@anthropic-ai/sdk');

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

const SYSTEM_PROMPTS = {
  Study: `You are EduVerso's friendly AI study tutor. Help students understand topics clearly and thoroughly. 
Break down complex concepts into simple terms. Use examples, analogies, and step-by-step explanations. 
Always encourage the student and keep a warm, supportive tone. Keep responses concise and easy to read on mobile.`,

  Explain: `You are EduVerso's AI explainer. Your job is to explain any concept as simply and clearly as possible.
Use the "ELI5" (Explain Like I'm 5) approach when needed. Use bullet points, analogies, and real-world examples.
Keep explanations short and digestible. Always check if the student understood.`,

  Exam: `You are EduVerso's AI exam coach. Help students prepare for exams by:
- Reviewing key topics they ask about
- Giving practice questions after explanations
- Pointing out common mistakes and tricky areas
- Giving tips on how to remember concepts
Be focused, efficient, and exam-oriented in your responses.`,

  Quiz: `You are EduVerso's AI quiz master. Your job is to quiz the student on topics they provide.
Format: Ask one question at a time. Wait for their answer. Then tell them if they're correct or not and explain why.
Keep score mentally and report it when asked. Make quizzes fun and encouraging.
Always start by asking: "What topic would you like to be quizzed on?"`,
};

exports.chat = async (req, res, next) => {
  try {
    const { messages, mode } = req.body;

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Messages array is required.',
      });
    }

    const validModes = ['Study', 'Explain', 'Exam', 'Quiz'];
    const selectedMode = validModes.includes(mode) ? mode : 'Study';
    const systemPrompt = SYSTEM_PROMPTS[selectedMode];

    const formattedMessages = messages.map((msg) => ({
      role: msg.role === 'assistant' ? 'assistant' : 'user',
      content: msg.content,
    }));

    const response = await client.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 1024,
      system: systemPrompt,
      messages: formattedMessages,
    });

    const reply = response.content[0]?.text ?? 'Sorry, I could not respond.';

    return res.status(200).json({
      success: true,
      reply,
      mode: selectedMode,
    });
  } catch (error) {
    next(error);
  }
};