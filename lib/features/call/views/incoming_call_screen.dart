import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_colors.dart';
import '../models/incoming_call_model.dart';
import '../repositories/call_repository.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final IncomingCallModel? callModel;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const IncomingCallScreen({
    super.key,
    this.callModel,
    this.onAccept,
    this.onDecline,
  });

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isActionTaken = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  IncomingCallModel _resolveCallModel() {
    if (widget.callModel != null) {
      return widget.callModel!;
    }
    final extra = GoRouterState.of(context).extra;
    if (extra is IncomingCallModel) {
      return extra;
    } else if (extra is Map<String, dynamic>) {
      return IncomingCallModel.fromJson(extra);
    }
    return const IncomingCallModel(
      callId: '0',
      callerName: 'Incoming Caller',
      callerPhone: '',
    );
  }

  Future<void> _handleAccept(IncomingCallModel call) async {
    if (_isActionTaken) return;
    setState(() => _isActionTaken = true);

    await ref.read(callRepositoryProvider).acceptCall(call.callId);

    if (widget.onAccept != null) {
      widget.onAccept!();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${call.callerName}'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
      context.pop(true);
    }
  }

  Future<void> _handleDecline(IncomingCallModel call) async {
    if (_isActionTaken) return;
    setState(() => _isActionTaken = true);

    await ref.read(callRepositoryProvider).declineCall(call.callId);

    if (widget.onDecline != null) {
      widget.onDecline!();
    } else if (mounted) {
      context.pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = _resolveCallModel();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAF8FE),
              Color(0xFFF5F1FD),
              Color(0xFFF9F7FE),
            ],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -250) {
                // Swipe UP -> Accept
                _handleAccept(call);
              } else if (velocity > 250) {
                // Swipe DOWN -> Decline
                _handleDecline(call);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Top Left: NAMMAL SECURE CALL pill badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE8FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                          'NAMMAL SECURE CALL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Color(0xFF5B1FE2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Pulsing Halo & Central Avatar
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer animated glow ring
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 270 * _pulseAnimation.value,
                            height: 270 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEDE8FF).withValues(
                                alpha: 0.35,
                              ),
                            ),
                          );
                        },
                      ),

                      // Middle glow ring
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 215 * _pulseAnimation.value,
                            height: 215 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEDE8FF).withValues(
                                alpha: 0.65,
                              ),
                            ),
                          );
                        },
                      ),

                      // Inner static soft glow
                      Container(
                        width: 165,
                        height: 165,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEDE8FF),
                        ),
                      ),

                      // Central Avatar Card
                      _buildAvatarCard(call),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Incoming Audio Call... Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEDE8FF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.phone_in_talk_rounded,
                          size: 15,
                          color: Color(0xFF5B1FE2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Incoming Audio Call...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5B1FE2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Caller Name
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      call.callerName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B2E),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Masked Phone Number
                Center(
                  child: Text(
                    call.maskedPhoneNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4E69),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Decline & Accept Action Buttons Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Decline Button
                      _buildDeclineButton(call),

                      // Accept Button
                      _buildAcceptButton(call),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Swipe up or tap to answer indicator
                InkWell(
                  onTap: () => _handleAccept(call),
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 24.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.keyboard_double_arrow_up_rounded,
                            size: 24,
                            color: Color(0xFF7C3AED),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Swipe up or tap to answer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCard(IncomingCallModel call) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Circular Avatar Image
          ClipOval(
            child: SizedBox(
              width: 133,
              height: 133,
              child: _buildAvatarImage(call),
            ),
          ),

          // Bottom card overlay matching the design mockup
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(70),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          call.callerName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Incoming Call...',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5B1FE2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(IncomingCallModel call) {
    final avatar = call.callerAvatar;
    if (avatar != null && avatar.isNotEmpty) {
      if (avatar.startsWith('http')) {
        return Image.network(
          avatar,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildInitialsAvatar(call.callerName),
        );
      } else {
        final file = File(avatar);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      }
    }
    return _buildInitialsAvatar(call.callerName);
  }

  Widget _buildInitialsAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'C';
    return Container(
      color: const Color(0xFFEDE8FF),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5B1FE2),
          ),
        ),
      ),
    );
  }

  Widget _buildDeclineButton(IncomingCallModel call) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _isActionTaken ? null : () => _handleDecline(call),
          borderRadius: BorderRadius.circular(42),
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD9D6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBA1A1A).withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.call_end_rounded,
                size: 34,
                color: Color(0xFFBA1A1A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Decline',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptButton(IncomingCallModel call) {
    return InkWell(
      onTap: _isActionTaken ? null : () => _handleAccept(call),
      borderRadius: BorderRadius.circular(52),
      child: Container(
        width: 104,
        height: 124,
        decoration: BoxDecoration(
          color: const Color(0xFFD1FADF),
          borderRadius: BorderRadius.circular(52),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF027A48).withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF027A48),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF027A48).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.call_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Accept',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF027A48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
