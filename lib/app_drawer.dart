import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Krishi Sakhi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home_outlined,
            text: 'Dashboard',
            onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
          ),
          _buildDrawerItem(
            icon: Icons.person_outline,
            text: 'Profile',
            onTap: () => Navigator.of(context).pushNamed('/profile'),
          ),
          _buildDrawerItem(
            icon: Icons.history_outlined,
            text: 'Activity Log',
            onTap: () => Navigator.of(context).pushNamed('/activity_log'),
          ),
          _buildDrawerItem(
            icon: Icons.storefront_outlined,
            text: 'Market Prices',
            onTap: () => Navigator.of(context).pushNamed('/market_prices'),
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today_outlined,
            text: 'Crop Calendar',
            onTap: () => Navigator.of(context).pushNamed('/calendar'),
          ),
          _buildDrawerItem(
            icon: Icons.article_outlined,
            text: 'News & Schemes',
            onTap: () => Navigator.of(context).pushNamed('/news'),
          ),
          _buildDrawerItem(
            icon: Icons.bug_report_outlined,
            text: 'Pest & Disease ID',
            onTap: () => Navigator.of(context).pushNamed('/pest_id'),
          ),
          _buildDrawerItem(
            icon: Icons.eco_outlined,
            text: 'Sustainability',
            onTap: () => Navigator.of(context).pushNamed('/sustainability'),
          ),
          _buildDrawerItem(
            icon: Icons.chat_bubble_outline,
            text: 'AI Advisor',
            onTap: () => Navigator.of(context).pushNamed('/chat_advisor'),
          ),
          _buildDrawerItem(
            icon: Icons.assessment_outlined,
            text: 'Farm Management',
            onTap: () => Navigator.of(context).pushNamed('/management'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper method to create styled list tiles
  Widget _buildDrawerItem(
      {required IconData icon,
      required String text,
      required GestureTapCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
    );
  }
}
