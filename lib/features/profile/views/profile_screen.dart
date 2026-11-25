import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider);
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.screenGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Avatar & User Info
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        (profile?.name.isNotEmpty == true
                                ? profile!.name[0]
                                : 'U')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.phoneNumber ?? '+91 0000000000',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Settings List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildTile(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    _buildTile(
                      icon: Icons.history,
                      title: 'Call History',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    _buildTile(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    _buildTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    _buildTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      textColor: AppColors.error,
                      iconColor: AppColors.error,
                      onTap: () async {
                        await ref.read(authViewModelProvider.notifier).logout();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textPlaceholder,
      ),
      onTap: onTap,
    );
  }
}
