import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String _userCrop = '...';

  Future<void> _getCalendar() async {
    try {
      // First, get the user's profile to find their crop type
      final userId = _supabase.auth.currentUser!.id;
      final profileData = await _supabase
          .from('profiles')
          .select('crop_type')
          .eq('id', userId)
          .single();

      final cropType = profileData['crop_type'];

      if (cropType != null && cropType.isNotEmpty) {
        setState(() {
          _userCrop = cropType;
        });
        // Now, fetch calendar tasks only for that crop
        final calendarData = await _supabase
            .from('crop_calendar')
            .select()
            .eq('crop_name', cropType)
            .order('week_number', ascending: true);

        if (mounted) {
          setState(() {
            _tasks = List<Map<String, dynamic>>.from(calendarData);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _userCrop = 'Not set';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error fetching calendar data'),
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
    _getCalendar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Care Calendar for $_userCrop')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Text(
                      'No tasks found for $_userCrop. Please set your crop in your profile.'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      // --- END OF ADDITIONS ---
                      child: ListTile(
                        leading: CircleAvatar(
                            child: Text(task['week_number'].toString())),
                        title: Text(task['task_title']),
                        subtitle: Text(task['task_description']),
                      ),
                    );
                  },
                ),
    );
  }
}
