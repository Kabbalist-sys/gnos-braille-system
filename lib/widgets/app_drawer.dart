import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.blue[700],
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  Icons.home,
                  'Home',
                  '/home',
                ),
                _buildDrawerItem(
                  context,
                  Icons.accessibility,
                  'Braille Translator',
                  '/braille',
                ),
                _buildDrawerItem(
                  context,
                  Icons.camera_alt,
                  'Camera',
                  '/camera',
                ),
                _buildDrawerItem(
                  context,
                  Icons.search,
                  'Text Recognition',
                  '/lens',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  Icons.history,
                  'Translation History',
                  '/translation-history',
                ),
                _buildDrawerItem(
                  context,
                  Icons.analytics,
                  'Analytics',
                  '/analytics',
                ),
                _buildDrawerItem(
                  context,
                  Icons.cloud,
                  'Cloud Storage',
                  '/cloud',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  Icons.person,
                  'Profile',
                  '/profile',
                ),
                _buildDrawerItem(
                  context,
                  Icons.settings,
                  'Settings',
                  '/settings',
                ),
                _buildDrawerItem(
                  context,
                  Icons.notifications,
                  'Notifications',
                  '/notifications',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  Icons.grid_on,
                  'Wireframe',
                  '/wireframe',
                ),
                _buildDrawerItem(
                  context,
                  Icons.info,
                  'About',
                  '/about',
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content:
                            const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );

                    if (result == true) {
                      final authService = AuthService();
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    final isCurrentRoute = ModalRoute.of(context)?.settings.name == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isCurrentRoute ? Colors.blue[700] : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isCurrentRoute ? FontWeight.w600 : FontWeight.normal,
          color: isCurrentRoute ? Colors.blue[700] : null,
        ),
      ),
      selected: isCurrentRoute,
      selectedTileColor: Colors.blue[50],
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isCurrentRoute) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
