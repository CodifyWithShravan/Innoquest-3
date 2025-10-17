import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:krishi_sakhi_final/secrets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PestIdPage extends StatefulWidget {
  const PestIdPage({super.key});

  @override
  State<PestIdPage> createState() => _PestIdPageState();
}

class _PestIdPageState extends State<PestIdPage> {
  File? _image;
  String _predictionResult = 'No image selected.';
  Map<String, dynamic>? _solution; // To store the fetched solution
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("ml-IN");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _predictionResult = 'Image selected. Click Identify.';
        _solution = null; // Clear previous solution
      });
    }
  }

  Future<void> _identifyPest() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      _predictionResult = 'Analyzing...';
      _solution = null;
    });

    // Step 1: Identify the disease with Roboflow
    final imageBytes = await _image!.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final roboflowUri =
        Uri.parse('$roboflowModelEndpoint?api_key=$roboflowApiKey');
    final response = await http.post(roboflowUri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: base64Image);

    String detectedDisease = '';

    if (response.statusCode == 200 && mounted) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['predictions'] != null &&
          responseBody['predictions'].isNotEmpty) {
        final topPrediction = responseBody['predictions'][0];
        detectedDisease = topPrediction['class'];
        final confidence =
            (topPrediction['confidence'] * 100).toStringAsFixed(1);
        setState(() {
          _predictionResult =
              'Detected: $detectedDisease\nConfidence: $confidence%';
        });
      } else {
        setState(() {
          _predictionResult = 'Could not identify any disease.';
        });
      }
    } else {
      setState(() {
        _predictionResult = 'Error connecting to the AI model.';
      });
    }

    // --- Step 2: Fetch Solution from Supabase Database ---
    if (detectedDisease.isNotEmpty) {
      try {
        final solutionData = await Supabase.instance.client
            .from('disease_solutions')
            .select()
            .eq('disease_name', detectedDisease)
            .single();
        setState(() {
          _solution = solutionData;
        });
      } catch (e) {
        // Handle case where no solution is found in the database
        setState(() {
          _solution = {
            'solution_malayalam':
                'No specific solution found in the database for this disease.',
            'prevention_malayalam': ''
          };
        });
      }
    }
    // --- END of new logic ---

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pest & Disease ID')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              if (_image != null)
                Image.file(_image!, height: 250, width: 250, fit: BoxFit.cover)
              else
                Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('Pick an image to preview')),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pick from Gallery')),
                  ElevatedButton.icon(
                      onPressed: _image != null ? _identifyPest : null,
                      icon: const Icon(Icons.biotech),
                      label: const Text('Identify Disease')),
                ],
              ),
              const SizedBox(height: 30),
              if (_loading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    Text(_predictionResult,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    if (_solution != null)
                      Card(
                        margin: const EdgeInsets.only(top: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('പരിഹാരം (Solution)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color:
                                              Theme.of(context).primaryColor)),
                                  IconButton(
                                    icon: const Icon(Icons.volume_up_outlined),
                                    onPressed: () => _speak(
                                        'പരിഹാരം. ${_solution!['solution_malayalam']}. പ്രതിരോധം. ${_solution!['prevention_malayalam']}'),
                                    tooltip: 'Read Aloud',
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(_solution!['solution_malayalam'] ?? ''),
                              const SizedBox(height: 16),
                              Text('പ്രതിരോധം (Prevention)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).primaryColor)),
                              const SizedBox(height: 8),
                              Text(_solution!['prevention_malayalam'] ?? ''),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
