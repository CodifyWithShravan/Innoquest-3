import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sakhi_final/secrets.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatAdvisorPage extends StatefulWidget {
  const ChatAdvisorPage({super.key});

  @override
  State<ChatAdvisorPage> createState() => _ChatAdvisorPageState();
}

class _ChatAdvisorPageState extends State<ChatAdvisorPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _currentLocaleId = 'ml_IN'; // Default to Malayalam

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _messages.add({
      'isUser': false,
      'text':
          'Hello! I am your AI Krishi Sakhi. How can I help you with your crops today?'
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  void _switchVoiceLanguage() {
    setState(() {
      if (_currentLocaleId == 'ml_IN') {
        _currentLocaleId = 'en_IN'; // Switch to English (India)
      } else {
        _currentLocaleId = 'ml_IN'; // Switch back to Malayalam
      }
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          // --- THIS IS THE CORRECTED PART ---
          localeId: _currentLocaleId, // Use the variable, not a fixed string
          onResult: (result) => setState(() {
            _controller.text = result.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;
    setState(() {
      _messages.add({'isUser': true, 'text': userMessage});
      _isLoading = true;
      if (_isListening) {
        _speechToText.stop();
        _isListening = false;
      }
    });
    _controller.clear();

    try {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$geminiApiKey');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "You are Krishi Sakhi, a friendly and helpful AI assistant for farmers in Kerala, India. Provide concise, practical advice. Respond in the same language as the user's query (Malayalam or English)."
                },
                {"text": userMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200 && mounted) {
        final responseBody = jsonDecode(response.body);
        final aiResponse =
            responseBody['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({'isUser': false, 'text': aiResponse});
        });
      } else {
        if (mounted) {
          setState(() {
            _messages.add({
              'isUser': false,
              'text': 'Sorry, I am having trouble connecting. Please try again.'
            });
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text':
                'A network error occurred. Please check your internet connection.'
          });
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Crop Advisor')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages.reversed.toList()[index];
                return ChatBubble(
                  clipper: ChatBubbleClipper1(
                      type: message['isUser']
                          ? BubbleType.sendBubble
                          : BubbleType.receiverBubble),
                  alignment: message['isUser']
                      ? Alignment.topRight
                      : Alignment.topLeft,
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  backGroundColor: message['isUser']
                      ? Theme.of(context).primaryColor
                      : Colors.white,
                  child: Text(
                    message['text'],
                    style: TextStyle(
                        color: message['isUser'] ? Colors.white : Colors.black),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.language),
                      onPressed: _switchVoiceLanguage,
                      tooltip: 'Switch Language',
                      color: Theme.of(context).primaryColor,
                    ),
                    Text(_currentLocaleId == 'ml_IN' ? 'ML' : 'EN',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor)),
                  ],
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'Listening...'
                          : 'Ask about your crops...',
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening
                      ? Icons.stop_circle_outlined
                      : Icons.mic_none_outlined),
                  onPressed: _listen,
                  tooltip: 'Speak',
                  color: _isListening
                      ? Colors.red
                      : Theme.of(context).primaryColor,
                  iconSize: 30,
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  tooltip: 'Send',
                  color: Theme.of(context).primaryColor,
                  iconSize: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
