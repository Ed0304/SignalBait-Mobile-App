
class QNA {
  final String question;
  final String answer;

  const QNA({
    required this.question,
    required this.answer,
  });
}

const List<QNA> FAQ = [
  QNA(
    question: 'What does this tool does?',
    answer: 'This tool helps users understand why a message, such as an email or text message, may be legitimate or a scam.',
  ),
  QNA(
    question: 'What makes this tool different from a typical chatbot?',
    answer: 'This tool analyzes message urgency, grammar consistency, spelling, and other security-related indicators. It is designed to explain why a message may be suspicious or legitimate, rather than simply providing a yes/no answer.',
  ),
  QNA(
    question: 'What languages does SignalBait support?',
    answer: "SignalBait's website currently supports English only. The message scanner can analyze messages in other languages, but results may be less reliable. For the best results, translate your message to English before scanning.",
  ),
  QNA(
    question: 'Can SignalBait guarantee that a message is safe?',
    answer: 'No. Security analysis can identify potential warning signs, but no automated tool can guarantee that a message or URL is safe. When in doubt, verify the request through an official channel.',
  ),
  QNA(
    question: 'Does SignalBait store the messages I submit?',
    answer: 'SignalBait does not retain submitted messages or URLs after analysis. However, please do not enter passwords, authentication codes, financial information, or other sensitive data when using this service.',
  ),
  QNA(
    question: 'How does AI work in SignalBait?',
    answer: 'SignalBait uses AI to analyze aspects of a message such as sentiment, urgency, grammar, and spelling inconsistencies. The AI helps explain these patterns and how they may relate to common social-engineering techniques.',
  ),
  QNA(
    question: 'Does SignalBait automatically know whether a message is a scam?',
    answer: 'SignalBait does not rely on AI alone to determine whether a message is suspicious. Its analysis uses identifiable security indicators, while AI is used to help explain the findings.',
  ),
  QNA(
    question: 'I recently got scammed. Can this application help me to recover my money?',
    answer: 'No. SignalBait is designed to help users analyze suspicious messages and links before they act on them. If you have already been affected by a scam, contact your local authorities and/or relevant financial institution as soon as possible.',
  ),
];
