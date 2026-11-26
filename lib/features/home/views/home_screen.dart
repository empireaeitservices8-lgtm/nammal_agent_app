import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../call/models/incoming_call_model.dart';
import '../../profile/models/profile_model.dart';
import '../../profile/views/profile_screen.dart';
import '../../wallet/views/wallet_screen.dart';
import '../models/handled_call_model.dart';
import '../models/home_state.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).fetchHomeData();
    });
  }

  final List<Widget> _pages = const [
    _AgentHomeView(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.borderSubtle.withValues(alpha: 0.6),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Home',
                icon: Icons.home_rounded,
                selectedIcon: Icons.home_rounded,
              ),
              _buildNavItem(
                index: 1,
                label: 'Wallet',
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet_rounded,
              ),
              _buildNavItem(
                index: 2,
                label: 'Profile',
                icon: Icons.badge_outlined,
                selectedIcon: Icons.badge_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEDE8FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentHomeView extends ConsumerWidget {
  const _AgentHomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final dashboard = homeState.dashboard;
    final agent = homeState.agentDetails ?? dashboard?.agent;

    final agentName = (agent?.name.isNotEmpty == true)
        ? agent!.name
        : (authState.user?.name?.isNotEmpty == true
              ? authState.user!.name!
              : (agent?.username.isNotEmpty == true
                    ? agent!.username
                    : (authState.user?.username?.isNotEmpty == true
                          ? authState.user!.username!
                          : homeState.agentName)));

    final isApproved = dashboard?.isApproved ?? agent?.isApproved ?? false;
    final avatar = authState.user?.avatar ?? dashboard?.avatar;

    final totalEarnings = agent?.totalEarnings ?? 0.0;
    final totalEarningsFormatted = '₹${totalEarnings.toStringAsFixed(0)}';

    final rewardCoins = agent?.coinsEarned ?? 0;
    final rewardCoinsFormatted = '$rewardCoins';

    final todayEarnings = agent?.todayEarnings ?? 0.0;
    final todayCoinsBadge = '+₹${todayEarnings.toStringAsFixed(0)} today';

    final loggedTimeFormatted =
        (agent?.totalDurationFormatted.isNotEmpty == true)
        ? agent!.totalDurationFormatted
        : '0h 0m';

    final todayDurationBadge =
        '+${(agent?.todayDurationFormatted.isNotEmpty == true) ? agent!.todayDurationFormatted : "0h 0m"}';

    final calls = homeState.recentCalls;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(homeViewModelProvider.notifier).fetchHomeData(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Home Brand Icon & Title
                _buildTopBrandHeader(),

                const SizedBox(height: 16),

                // Agent Online & Active Profile Card
                _buildAgentStatusCard(
                  context: context,
                  ref: ref,
                  agentName: agentName,
                  isOnline: homeState.isOnline,
                  isToggling: homeState.isTogglingStatus,
                  isApproved: isApproved,
                  avatarUrl: avatar,
                ),

                if (!isApproved) ...[
                  const SizedBox(height: 12),
                  _buildPendingApprovalBanner(),
                ],

                const SizedBox(height: 24),

                // Section: Performance Snapshot
                const Text(
                  'Performance Snapshot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 14),

                // Total Earnings Card
                _buildTotalEarningsCard(totalEarningsFormatted),

                const SizedBox(height: 14),

                // Dual Cards: Reward Coins & Logged Time
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.monetization_on_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBgColor: const Color(0xFFFFFBEB),
                        badgeText: todayCoinsBadge,
                        badgeTextColor: const Color(0xFFB45309),
                        badgeBgColor: const Color(0xFFFEF3C7),
                        title: 'Reward Coins',
                        value: rewardCoinsFormatted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFF6B42FF),
                        iconBgColor: const Color(0xFFF0ECFF),
                        badgeText: todayDurationBadge,
                        badgeTextColor: const Color(0xFF6B42FF),
                        badgeBgColor: const Color(0xFFF3EEFF),
                        title: 'Logged Time',
                        value: loggedTimeFormatted,
                      ),
                    ),
                  ],
                ),

                if (dashboard != null) ...[
                  const SizedBox(height: 24),
                  _buildTasksSnapshot(dashboard.tasks),
                ],

                const SizedBox(height: 28),

                // Section: Recent Handled Calls Header
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B1FE2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Recent Handled Calls',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (calls.isNotEmpty)
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            children: const [
                              Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5B1FE2),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF5B1FE2),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // List of Handled Call Cards or Empty State
                if (calls.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: calls.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildCallItemCard(context, calls[index]);
                    },
                  )
                else
                  _buildEmptyCallsCard(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBrandHeader() {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text(
          'Home',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Color(0xFF5B1FE2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 12, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildAgentStatusCard({
    required BuildContext context,
    required WidgetRef ref,
    required String agentName,
    required bool isOnline,
    required bool isToggling,
    required bool isApproved,
    String? avatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with verified badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF5B1FE2).withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(child: _buildAvatarImage(avatarUrl, agentName)),
              ),
              if (isApproved)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF5B1FE2),
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Name & Online Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'ONLINE & ACTIVE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  agentName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Online / Offline Availability Toggle Switch
          GestureDetector(
            onTap: isToggling
                ? null
                : () async {
                    final message = await ref
                        .read(homeViewModelProvider.notifier)
                        .toggleOnlineStatus();
                    if (context.mounted && message != null) {
                      final updatedOnline = ref
                          .read(homeViewModelProvider)
                          .isOnline;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: updatedOnline
                              ? const Color(0xFF10B981)
                              : AppColors.textSecondary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: 52,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFF10B981)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: isOnline
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: isToggling
                      ? const Padding(
                          padding: EdgeInsets.all(5),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                          ),
                        )
                      : Icon(
                          isOnline
                              ? Icons.power_settings_new_rounded
                              : Icons.power_off_rounded,
                          size: 14,
                          color: isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard(String earnings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4511BD), Color(0xFF5B1FE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B1FE2).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TOTAL EARNINGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            earnings,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String badgeText,
    required Color badgeTextColor,
    required Color badgeBgColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallItemCard(BuildContext context, HandledCallModel call) {
    final isCompleted = call.status.toLowerCase() == 'completed';

    return InkWell(
      onTap: () {
        context.push(
          AppRoutes.incomingCall,
          extra: IncomingCallModel(
            callId: call.id,
            callerName: call.callerName,
            callerPhone: '9876543210',
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Initials Circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      call.initials,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B1FE2),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Caller Name & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call.callerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.south_west_rounded,
                            size: 13,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            call.timeAgo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFE8F8F0)
                        : const Color(0xFFF3EEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6B42FF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        call.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B42FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Divider line
            Container(
              height: 1,
              color: AppColors.borderSubtle.withValues(alpha: 0.5),
            ),

            const SizedBox(height: 12),

            // Bottom Detail Row: Duration + Coins + Earnings
            Row(
              children: [
                // Duration
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        call.duration,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),
                const Text(
                  '•',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 6),

                // Coins Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        size: 13,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${call.coins} Coins',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Amount Earned
                Text(
                  '+₹${call.earnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5B1FE2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String? avatarUrl, String name) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        return Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildInitialsAvatar(name),
        );
      } else {
        final file = File(avatarUrl);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      }
    }
    return _buildInitialsAvatar(name);
  }

  Widget _buildInitialsAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'A';
    return Container(
      color: const Color(0xFFEDE8FF),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5B1FE2),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingApprovalBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: const [
          Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Account Pending Approval • Calling will be enabled once admin approves.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCallsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.phone_in_talk_outlined,
            size: 44,
            color: AppColors.textPlaceholder,
          ),
          SizedBox(height: 12),
          Text(
            'No Handled Calls Yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Calls assigned to you will appear here once you go online.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSnapshot(TasksModel tasks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: const [
          //     Icon(Icons.task_alt_rounded, size: 18, color: Color(0xFF5B1FE2)),
          //     SizedBox(width: 8),
          //     Text(
          //       'Tasks & Targets',
          //       style: TextStyle(
          //         fontSize: 15,
          //         fontWeight: FontWeight.bold,
          //         color: AppColors.textPrimary,
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 14),
          // _buildTaskProgressItem(
          //   label: 'Daily Target',
          //   completed: tasks.daily.completed,
          //   target: tasks.daily.target,
          //   percentage: tasks.daily.progressPercentage,
          //   color: const Color(0xFF5B1FE2),
          // ),
          // const SizedBox(height: 12),
          // _buildTaskProgressItem(
          //   label: 'Weekly Target',
          //   completed: tasks.weekly.completed,
          //   target: tasks.weekly.target,
          //   percentage: tasks.weekly.progressPercentage,
          //   color: const Color(0xFF06B6D4),
          // ),
          // const SizedBox(height: 12),
          // _buildTaskProgressItem(
          //   label: 'Monthly Target',
          //   completed: tasks.monthly.completed,
          //   target: tasks.monthly.target,
          //   percentage: tasks.monthly.progressPercentage,
          //   color: const Color(0xFF10B981),
          // ),
        ],
      ),
    );
  }

  Widget _buildTaskProgressItem({
    required String label,
    required int completed,
    required int target,
    required double percentage,
    required Color color,
  }) {
    final progressVal = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$completed / $target (${percentage.toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
            backgroundColor: const Color(0xFFF1F0F7),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
