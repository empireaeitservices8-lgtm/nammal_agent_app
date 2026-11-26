import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/profile_model.dart';
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
          'Agent Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.screenGradient),
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(profileViewModelProvider.notifier).fetchProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Avatar & User Info
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 46,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile?.agent.name.isNotEmpty == true
                            ? profile!.agent.name
                            : (profile?.name.isNotEmpty == true &&
                                      profile!.name != 'Agent'
                                  ? profile.name
                                  : (profile?.agent.username.isNotEmpty == true
                                        ? 'Agent ${profile!.agent.username}'
                                        : 'Agent')),
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

                const SizedBox(height: 20),

                // Approval Status Card
                _buildApprovalStatusCard(profile),

                const SizedBox(height: 20),

                // Performance & Earnings Grid
                if (profile != null) _buildStatsGrid(profile.agent),

                const SizedBox(height: 20),

                // Targets & Tasks Section
                if (profile != null) _buildTasksSection(profile.tasks),

                const SizedBox(height: 24),

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
                        onTap: () => context.push(AppRoutes.editProfile),
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
                          await ref
                              .read(authViewModelProvider.notifier)
                              .logout();
                          if (context.mounted) {
                            context.go(AppRoutes.login);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalStatusCard(ProfileModel? profile) {
    final isApproved = profile?.isApproved == true;
    final status = profile?.agentStatus.toUpperCase() ?? 'PENDING';

    final bgColor = isApproved
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF8E1);
    final borderColor = isApproved
        ? const Color(0xFFA5D6A7)
        : const Color(0xFFFFE082);
    final iconColor = isApproved ? Colors.green[700] : Colors.amber[800];
    final title = isApproved ? 'Account Approved' : 'Approval Status: $status';
    final desc = isApproved
        ? 'You are active and ready to take calls.'
        : 'Your account is under admin review. You can accept calls once approved.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isApproved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isApproved ? Colors.green[900] : Colors.amber[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: isApproved ? Colors.green[800] : Colors.amber[900],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AgentDetailsModel agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earnings & Performance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Today's Earnings",
                value: '₹${agent.todayEarnings.toStringAsFixed(0)}',
                subtitle: agent.todayDurationFormatted,
                icon: Icons.payments_outlined,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Earnings',
                value: '₹${agent.totalEarnings.toStringAsFixed(0)}',
                subtitle: agent.totalDurationFormatted,
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Calls Completed',
                value: '${agent.callsCompleted}',
                subtitle: 'Success: ${agent.successRate.toStringAsFixed(0)}%',
                icon: Icons.call_made_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Rating',
                value: '⭐ ${agent.agentRating.toStringAsFixed(1)}',
                subtitle: 'Coins: ${agent.coinsEarned}',
                icon: Icons.star_rate_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textPlaceholder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(TasksModel tasks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      // child: Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     const Text(
      //       'Call Targets & Tasks',
      //       style: TextStyle(
      //         fontSize: 15,
      //         fontWeight: FontWeight.bold,
      //         color: AppColors.textPrimary,
      //       ),
      //     ),
      //     const SizedBox(height: 14),
      //     _buildTaskProgressRow(
      //       label: 'Daily Target',
      //       progress: tasks.daily,
      //       color: const Color(0xFF6366F1),
      //     ),
      //     const SizedBox(height: 12),
      //     _buildTaskProgressRow(
      //       label: 'Weekly Target',
      //       progress: tasks.weekly,
      //       color: const Color(0xFF06B6D4),
      //     ),
      //     const SizedBox(height: 12),
      //     _buildTaskProgressRow(
      //       label: 'Monthly Target',
      //       progress: tasks.monthly,
      //       color: const Color(0xFF10B981),
      //     ),
      //   ],
      // ),
    );
  }

  Widget _buildTaskProgressRow({
    required String label,
    required TaskProgressModel progress,
    required Color color,
  }) {
    final progressVal = (progress.progressPercentage / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${progress.completed}/${progress.target} (${progress.progressPercentage.toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progressVal,
            minHeight: 6,
            backgroundColor: AppColors.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
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
