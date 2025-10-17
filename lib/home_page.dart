import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sakhi_final/secrets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:krishi_sakhi_final/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables for all features
  final _supabase = Supabase.instance.client;
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _lastWords = '';
  String _intent = '';
  String _weatherSnippet = 'Loading weather...';
  Map<String, dynamic>? _latestNews;
  String _userName = 'Farmer';
  bool _isLoadingDashboard = true;
  String _voiceLocaleId = 'ml_IN'; // Default to Malayalam

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _loadDashboardData();
  }

  // --- Dashboard Data Loading ---
  Future<void> _loadDashboardData() async {
    await _getWeatherSnippet();
    await _getLatestNews();
    await _getUserName();
    if (mounted) {
      setState(() {
        _isLoadingDashboard = false;
      });
    }
  }

  Future<void> _getUserName() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();
      final username = data['username'];
      if (username != null && username.isNotEmpty) {
        if (mounted) setState(() => _userName = username);
      } else {
        if (mounted)
          setState(
              () => _userName = _supabase.auth.currentUser?.email ?? 'Farmer');
      }
    } catch (e) {
      if (mounted)
        setState(
            () => _userName = _supabase.auth.currentUser?.email ?? 'Farmer');
    }
  }

  Future<void> _getWeatherSnippet() async {
    const lat = 9.9312; // Kochi
    const lon = 76.2673;
    final weatherUri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$openWeatherApiKey&units=metric&lang=ml');
    try {
      final weatherResponse = await http.get(weatherUri);
      if (weatherResponse.statusCode == 200 && mounted) {
        final weatherData = jsonDecode(weatherResponse.body);
        final description = weatherData['weather'][0]['description'];
        final temperature = weatherData['main']['temp'];
        setState(() => _weatherSnippet = '$temperature°C, $description');
      }
    } catch (e) {
      if (mounted) setState(() => _weatherSnippet = 'Could not fetch weather.');
    }
  }

  Future<void> _getLatestNews() async {
    try {
      final data = await _supabase
          .from('news_schemes')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      if (mounted) setState(() => _latestNews = data);
    } catch (e) {
      // Silently handle if no news is found
    }
  }

  // --- Voice Assistant Core Functions ---
  void _initTts() async {
    await _flutterTts
        .setLanguage(_voiceLocaleId == 'ml_IN' ? "ml-IN" : "en-IN");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _initSpeech() async {
    await Permission.microphone.request();
    await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  void _startListening() async {
    setState(() {
      _lastWords = '';
      _intent = '';
    });
    await _speechToText.listen(
      localeId: _voiceLocaleId,
      onResult: (result) => setState(() => _lastWords = result.recognizedWords),
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
    if (_lastWords.isNotEmpty) _getIntentFromWitAi(_lastWords);
  }

  Future<void> _getIntentFromWitAi(String text) async {
    try {
      final encodedText = Uri.encodeComponent(text);
      final uri = Uri.parse('https://api.wit.ai/message?q=$encodedText');
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $witAiServerToken'});
      if (response.statusCode == 200 && mounted) {
        final responseBody = jsonDecode(response.body);
        String intentName = 'No intent found';
        if (responseBody['intents'] != null &&
            responseBody['intents'].isNotEmpty) {
          intentName = responseBody['intents'][0]['name'];
        }
        setState(() => _intent = intentName);
        _actOnIntent(intentName);
      }
    } catch (e) {
      if (mounted) _speak('Sorry, I had trouble connecting to the AI.');
    }
  }

  Future<void> _actOnIntent(String intent) async {
    String responseText = '';
    bool isMalayalam = _voiceLocaleId == 'ml_IN';

    switch (intent) {
      case 'get_weather':
        String advice = '';
        try {
          const lat = 9.9312;
          const lon = 76.2673;
          final weatherUri = Uri.parse(
              'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$openWeatherApiKey&units=metric');
          final weatherResponse = await http.get(weatherUri);

          if (weatherResponse.statusCode == 200) {
            final weatherData = jsonDecode(weatherResponse.body);
            final mainWeather =
                weatherData['weather'][0]['main'].toString().toLowerCase();
            final description = weatherData['weather'][0]['description'];
            final temperature = weatherData['main']['temp'];

            if (isMalayalam) {
              final malayalamDescription =
                  _translateWeatherToMalayalam(description);
              responseText =
                  'ഇപ്പോഴത്തെ കാലാവസ്ഥ $malayalamDescription ആണ്. താപനില ${temperature.round()} ഡിഗ്രി സെൽഷ്യസ് ആണ്.';
            } else {
              responseText =
                  'The current weather is $description with a temperature of ${temperature.round()} degrees Celsius.';
            }

            if (mainWeather.contains('rain') ||
                mainWeather.contains('thunderstorm')) {
              advice = isMalayalam
                  ? ' കനത്ത മഴയ്ക്ക് സാധ്യതയുണ്ട്. വെള്ളപ്പൊക്കം ഒഴിവാക്കാൻ дренаж സംവിധാനങ്ങൾ പരിശോധിക്കുക.'
                  : ' Heavy rain is expected. Please check your field drainage systems to avoid waterlogging.';
            } else if (mainWeather.contains('clear') && temperature > 32) {
              advice = isMalayalam
                  ? ' കടുത്ത ചൂടും വരണ്ട കാലാവസ്ഥയുമാണ്. വിളകൾക്ക് ജലസേചനം ഉറപ്പാക്കുക.'
                  : ' It is a hot and dry day. Ensure proper irrigation for your crops.';
            } else {
              advice = isMalayalam
                  ? ' കൃഷിപ്പണിക്ക് അനുയോജ്യമായ കാലാവസ്ഥയാണ്.'
                  : ' The weather is suitable for farming activities.';
            }
            responseText += advice;
          } else {
            responseText = isMalayalam
                ? 'ക്ഷമിക്കണം, എനിക്ക് കാലാവസ്ഥ ലഭിച്ചില്ല.'
                : 'Sorry, I could not fetch the weather.';
          }
        } catch (e) {
          responseText = isMalayalam
              ? 'ക്ഷമിക്കണം, ഉപദേശം നൽകുന്നതിൽ ഒരു പിശകുണ്ടായി.'
              : 'Sorry, an error occurred while providing advice.';
        }
        break;

      case 'log_activity':
        try {
          final userId = _supabase.auth.currentUser!.id;
          await _supabase
              .from('activities')
              .insert({'activity_description': _lastWords, 'user_id': userId});
          responseText = isMalayalam
              ? 'നിങ്ങളുടെ പ്രവർത്തനം വിജയകരമായി രേഖപ്പെടുത്തിയിരിക്കുന്നു.'
              : 'Your activity has been logged successfully.';
        } catch (error) {
          responseText = isMalayalam
              ? 'ക്ഷമിക്കണം, നിങ്ങളുടെ പ്രവർത്തനം രേഖപ്പെടുത്തുന്നതിൽ ഒരു പിശകുണ്ടായി.'
              : 'Sorry, there was an error logging your activity.';
        }
        break;

      default:
        responseText = isMalayalam
            ? 'ക്ഷമിക്കണം, എനിക്ക് മനസ്സിലായില്ല. ദയവായി ഒന്നുകൂടി പറയുക.'
            : 'Sorry, I did not understand. Please say that again.';
        break;
    }
    _speak(responseText);
  }

  String _translateWeatherToMalayalam(String englishDescription) {
    switch (englishDescription.toLowerCase()) {
      case 'clear sky':
        return 'തെളിഞ്ഞ ആകാശം';
      case 'few clouds':
        return 'ചെറിയ മേഘങ്ങൾ';
      case 'scattered clouds':
        return 'ഇടക്കിടെ മേഘങ്ങൾ';
      case 'broken clouds':
        return 'തങ്ങിനിൽക്കുന്ന മേഘങ്ങൾ';
      case 'overcast clouds':
        return 'മേഘാവൃതമായ';
      case 'shower rain':
      case 'rain':
      case 'light rain':
      case 'moderate rain':
        return 'മഴ';
      case 'thunderstorm':
        return 'ഇടിമിന്നൽ';
      case 'snow':
        return 'മഞ്ഞ്';
      case 'mist':
        return 'മൂടൽമഞ്ഞ്';
      default:
        return englishDescription;
    }
  }

  void _switchVoiceLanguage() {
    setState(() {
      if (_voiceLocaleId == 'ml_IN') {
        _voiceLocaleId = 'en_IN';
      } else {
        _voiceLocaleId = 'ml_IN';
      }
      _initTts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Krishi Sakhi Dashboard'),
        actions: [
          IconButton(
            onPressed: _switchVoiceLanguage,
            icon: const Icon(Icons.translate),
            tooltip: 'Switch Voice Language',
          ),
          Text(_voiceLocaleId == 'ml_IN' ? 'ML' : 'EN',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoadingDashboard
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: Theme.of(context).primaryColor,
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Welcome,\n$_userName',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Weather (Kochi)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).primaryColor)),
                        const SizedBox(height: 8),
                        Text(_weatherSnippet,
                            style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                if (_latestNews != null)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: const Text('Latest News',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_latestNews!['title']),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.of(context).pushNamed('/news'),
                    ),
                  ),
                const SizedBox(height: 24),
                const Center(
                    child: Text(
                  'Press the microphone to ask a question or log an activity',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                )),

                // --- THIS IS THE CORRECTED PART ---
                // This syntax conditionally adds widgets to the list
                if (_lastWords.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _lastWords,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _intent,
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                // --- END OF CORRECTION ---
              ],
            ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _isListening ? _stopListening : _startListening,
        tooltip: 'Ask Krishi Sakhi',
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
