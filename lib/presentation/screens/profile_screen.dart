import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return MainScaffold(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F8),
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: user == null
            ? const Center(child: Text('Not logged in.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFFFF6ED),
                      backgroundImage: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(user.profilePictureUrl!)
                          : null,
                      child: (user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 50, color: Color(0xFF8F4E00))
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        user.phone!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (user.address != null && user.address!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        user.address!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 40),
                    // Settings section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSettingsItem(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            onTap: () {
                              context.push('/edit-profile');
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSettingsItem(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSettingsItem(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 56),
                          _buildSettingsItem(
                            icon: Icons.info_outline,
                            title: 'About',
                            onTap: () {},
                          ),
                          if (user.role == 'admin') ...[
                            const Divider(height: 1, indent: 56),
                            _buildSettingsItem(
                              icon: Icons.admin_panel_settings,
                              title: 'Admin Dashboard',
                              onTap: () {
                                context.go('/admin');
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          context.read<AuthProvider>().signOut();
                          context.go('/');
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6ED),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF8F4E00), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
