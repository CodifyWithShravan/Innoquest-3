import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameController = TextEditingController(); // NEW
  final _cropTypeController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _loading = true;

  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;
      final data =
          await _supabase.from('profiles').select().eq('id', userId).single();
      _usernameController.text = (data['username'] ?? '') as String; // NEW
      _cropTypeController.text = (data['crop_type'] ?? '') as String;
      _farmSizeController.text = (data['farm_size'] ?? '').toString();
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST116' && mounted) {
        // Handle error if it's not "no rows"
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not fetch profile: ${error.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } catch (error) {
      // Handle other errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('An unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _updateProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final username = _usernameController.text.trim(); // NEW
      final cropType = _cropTypeController.text.trim();
      final farmSize = double.tryParse(_farmSizeController.text.trim());

      await _supabase.from('profiles').upsert({
        'id': userId,
        'username': username, // NEW
        'crop_type': cropType,
        'farm_size': farmSize,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully!'),
        ));
      }
    } catch (error) {
      // Handle error
    }
  }

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _cropTypeController.dispose();
    _farmSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // NEW USERNAME FIELD
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Your Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cropTypeController,
                  decoration: const InputDecoration(
                      labelText: 'Primary Crop Type (e.g., Rice)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _farmSizeController,
                  decoration:
                      const InputDecoration(labelText: 'Farm Size (in acres)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateProfile,
                  child: const Text('Save Profile'),
                )
              ],
            ),
    );
  }
}
