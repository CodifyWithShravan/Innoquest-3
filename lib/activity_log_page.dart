import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // We'll add this package for date formatting

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activities = [];
  bool _loading = true;

  Future<void> _getActivityLog() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('activities')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false); // Show most recent first
      if (mounted) {
        setState(() {
          _activities = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error fetching activity log'),
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

  @override
  void initState() {
    super.initState();
    _getActivityLog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Activity Log')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? const Center(
                  child: Text(
                    'You have not logged any activities yet.\nUse the voice assistant on the home page to start!',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    final activityDate = DateTime.parse(activity['created_at']);
                    final formattedDate =
                        DateFormat.yMMMd().add_jm().format(activityDate);
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(activity['activity_description']),
                        subtitle: Text(formattedDate),
                      ),
                    );
                  },
                ),
    );
  }
}
