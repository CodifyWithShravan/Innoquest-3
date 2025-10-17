import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SustainabilityPage extends StatefulWidget {
  const SustainabilityPage({super.key});

  @override
  State<SustainabilityPage> createState() => _SustainabilityPageState();
}

class _SustainabilityPageState extends State<SustainabilityPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _guides = [];
  bool _loading = true;

  Future<void> _getGuides() async {
    try {
      final data = await _supabase.from('sustainability_guides').select();
      if (mounted) {
        setState(() {
          _guides = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (error) {
      // Handle error
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getGuides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sustainable Practices')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _guides.length,
              itemBuilder: (context, index) {
                final guide = _guides[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guide['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(guide['description']),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
