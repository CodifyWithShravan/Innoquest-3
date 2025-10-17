import 'dart:convert';
import 'dart:io'; // Required for File operations
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Required for picking images
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
  String _currentLocaleId = 'ml_IN';

  // NEW: State variables for image picking
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _messages.add({
      'isUser': false,
      'text':
          'Hello! Ask a question about your crops, and you can attach a photo for a more accurate diagnosis.',
      'image': null,
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- NEW: Function to pick an image ---
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- MODIFIED: Send Message function now handles images ---
  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty && _selectedImage == null) return;

    final userMessage = _controller.text;
    final userImage = _selectedImage;

    setState(() {
      _messages.add({'isUser': true, 'text': userMessage, 'image': userImage});
      _isLoading = true;
      _selectedImage = null; // Clear image preview after sending
      if (_isListening) {
        _speechToText.stop();
        _isListening = false;
      }
    });
    _controller.clear();

    try {
      // MODIFIED: Switched to the gemini-pro-vision model for image analysis
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=$geminiApiKey');

      // Prepare the different parts of the message (text and optional image)
      List<Map<String, dynamic>> parts = [
        {
          "text":
              "You are Krishi Sakhi, an expert AI assistant for farmers in Kerala. Analyze the user's text and any attached image. Provide a concise, practical solution and prevention tips in simple language (Malayalam or English, based on the user's query)."
        },
        {"text": userMessage},
      ];

      if (userImage != null) {
        final imageBytes = await userImage.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        parts.add({
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Image,
          }
        });
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {"parts": parts}
          ]
        }),
      );

      if (response.statusCode == 200 && mounted) {
        final responseBody = jsonDecode(response.body);
        final aiResponse =
            responseBody['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({'isUser': false, 'text': aiResponse, 'image': null});
        });
      } else {
        if (mounted) {
          setState(() {
            _messages.add({
              'isUser': false,
              'text':
                  'Sorry, I am having trouble connecting. Please try again.',
              'image': null
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
                'A network error occurred. Please check your internet connection.',
            'image': null
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

  // ... (Your voice functions _initSpeech, _switchVoiceLanguage, _listen remain the same)
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
          localeId: _currentLocaleId,
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
                  child: Column(
                    // MODIFIED: To display image and text
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message['image'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(message['image'],
                                height: 150, fit: BoxFit.cover),
                          ),
                        ),
                      Text(
                        message['text'],
                        style: TextStyle(
                            color: message['isUser']
                                ? Colors.white
                                : Colors.black),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator()),

          // NEW: Image Preview Area
          if (_selectedImage != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedImage!, height: 100)),
                  IconButton(
                    icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child:
                            Icon(Icons.close, color: Colors.white, size: 18)),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // NEW: Attach Image Button
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  onPressed: _pickImage,
                  tooltip: 'Attach Image',
                  color: Theme.of(context).primaryColor,
                ),
                // Your language switcher is here from the old code
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
