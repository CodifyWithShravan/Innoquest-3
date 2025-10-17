import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _newsItems = [];
  bool _loading = true;

  Future<void> _getNews() async {
    try {
      final data = await _supabase
          .from('news_schemes')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _newsItems = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error fetching news'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // In a real app, you'd want to show a friendly error message.
      // For the hackathon, throwing an exception is fine for debugging.
      throw Exception('Could not launch $url');
    }
  }

  @override
  void initState() {
    super.initState();
    _getNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News & Schemes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _newsItems.length,
              itemBuilder: (context, index) {
                final item = _newsItems[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(item['title'] ?? 'No Title'),
                    subtitle: Text(item['description'] ?? 'No Description'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _launchURL(item['link_url']),
                  ),
                );
              },
            ),
    );
  }
}
