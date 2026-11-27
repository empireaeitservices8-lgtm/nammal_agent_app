import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/routing/app_router.dart';
import '../models/incoming_call_model.dart';
import '../repositories/call_repository.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  final IncomingCallModel? callModel;

  const ActiveCallScreen({super.key, this.callModel});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen>
    with SingleTickerProviderStateMixin {
  // Call & speaking timers
  Timer? _callTimer;
  Timer? _speakingTimer;
  int _callSeconds = 0;
  int _speakingSeconds = 0;

  // Audio & in-call states
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isOnHold = false;
  bool _isSpeaking = true;
  bool _isEndingCall = false;

  // In-call note controller
  final TextEditingController _notesController = TextEditingController();

  // Agora engine
  RtcEngine? _rtcEngine;
  bool _isAgoraInitialized = false;

  @override
  void initState() {
    super.initState();
    _startTimers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final call = _resolveCallModel();
      _initAgora(call);
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _speakingTimer?.cancel();
    _notesController.dispose();
    _disposeAgora();
    super.dispose();
  }

  void _startTimers() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isOnHold) {
        setState(() => _callSeconds++);
      }
    });

    _speakingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isSpeaking && !_isOnHold && !_isMuted) {
        setState(() => _speakingSeconds++);
      }
    });
  }

  Future<void> _initAgora(IncomingCallModel call) async {
    try {
      await [Permission.microphone].request();

      final channel = call.channelName ?? call.callId;
      final appId = call.extra['app_id']?.toString() ??
          call.extra['agora_app_id']?.toString() ??
          '';

      if (appId.isNotEmpty && channel.isNotEmpty) {
        _rtcEngine = createAgoraRtcEngine();
        await _rtcEngine!.initialize(RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ));

        await _rtcEngine!.enableAudio();
        await _rtcEngine!.setEnableSpeakerphone(_isSpeakerOn);
        await _rtcEngine!.enableAudioVolumeIndication(
          interval: 400,
          smooth: 3,
          reportVad: true,
        );

        _rtcEngine!.registerEventHandler(
          RtcEngineEventHandler(
            onAudioVolumeIndication:
                (connection, speakers, totalVolume, speakerNumber) {
              if (!mounted) return;
              final speaking = speakers.isNotEmpty && totalVolume > 5;
              if (speaking != _isSpeaking) {
                setState(() => _isSpeaking = speaking);
              }
            },
            onUserOffline: (connection, remoteUid, reason) {
              _handleEndCall();
            },
          ),
        );

        await _rtcEngine!.joinChannel(
          token: call.agoraToken ?? '',
          channelId: channel,
          uid: 0,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
          ),
        );

        _isAgoraInitialized = true;
      }
    } catch (e) {
      debugPrint('Agora initialisation fallback: $e');
    }
  }

  Future<void> _disposeAgora() async {
    if (_isAgoraInitialized && _rtcEngine != null) {
      try {
        await _rtcEngine!.leaveChannel();
        await _rtcEngine!.release();
      } catch (_) {}
    }
  }

  IncomingCallModel _resolveCallModel() {
    if (widget.callModel != null) {
      return widget.callModel!;
    }
    try {
      final extra = GoRouterState.of(context).extra;
      if (extra is IncomingCallModel) {
        return extra;
      } else if (extra is Map<String, dynamic>) {
        return IncomingCallModel.fromJson(extra);
      }
    } catch (_) {}
    return const IncomingCallModel(
      callId: '0',
      callerName: 'Caller',
      callerPhone: '',
    );
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    if (seconds >= 3600) {
      final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
      return '$hours:$mins:$secs';
    }
    return '$mins:$secs';
  }

  void _toggleMute() async {
    final next = !_isMuted;
    setState(() => _isMuted = next);
    if (_isAgoraInitialized && _rtcEngine != null) {
      try {
        await _rtcEngine!.muteLocalAudioStream(next);
      } catch (_) {}
    }
  }

  void _toggleSpeaker() async {
    final next = !_isSpeakerOn;
    setState(() => _isSpeakerOn = next);
    if (_isAgoraInitialized && _rtcEngine != null) {
      try {
        await _rtcEngine!.setEnableSpeakerphone(next);
      } catch (_) {}
    }
  }

  void _toggleHold() async {
    final next = !_isOnHold;
    setState(() => _isOnHold = next);
    if (_isAgoraInitialized && _rtcEngine != null) {
      try {
        await _rtcEngine!.muteLocalAudioStream(next);
        await _rtcEngine!.muteAllRemoteAudioStreams(next);
      } catch (_) {}
    }
  }

  Future<void> _handleEndCall() async {
    if (_isEndingCall) return;
    setState(() => _isEndingCall = true);

    final call = _resolveCallModel();
    await ref.read(callRepositoryProvider).endCall(call.callId);

    _callTimer?.cancel();
    _speakingTimer?.cancel();
    await _disposeAgora();

    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  void _showKeypadModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String enteredDigits = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      enteredDigits.isEmpty ? 'Keypad' : enteredDigits,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDialpadGrid((digit) {
                      HapticFeedback.lightImpact();
                      setModalState(() => enteredDigits += digit);
                      if (_isAgoraInitialized && _rtcEngine != null) {
                        try {
                          _rtcEngine!.sendStreamMessage(
                            streamId: 0,
                            data: Uint8List.fromList(digit.codeUnits),
                            length: digit.length,
                          );
                        } catch (_) {}
                      }
                    }),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialpadGrid(ValueChanged<String> onKeyPress) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              return InkWell(
                onTap: () => onKeyPress(key),
                borderRadius: BorderRadius.circular(35),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1EDFE),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B2E),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  void _showNotesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Call Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Type important notes about this call...',
                    filled: true,
                    fillColor: const Color(0xFFF8F7FD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF5B1FE2),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Note saved'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B1FE2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransferModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transfer Call',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEDE8FF),
                    child: Icon(Icons.support_agent, color: Color(0xFF5B1FE2)),
                  ),
                  title: const Text('Support Desk / Supervisor'),
                  subtitle: const Text('Department Transfer'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Call transfer initiated...'),
                        backgroundColor: Color(0xFF5B1FE2),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEDE8FF),
                    child: Icon(Icons.groups_rounded, color: Color(0xFF5B1FE2)),
                  ),
                  title: const Text('Fleet Dispatch Team'),
                  subtitle: const Text('Operations Transfer'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Call transfer initiated...'),
                        backgroundColor: Color(0xFF5B1FE2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final call = _resolveCallModel();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Caller Avatar with Concentric Halo Rings & Speaking Badge
            Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Outer halo ring
                  Container(
                    width: 175,
                    height: 175,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEDE8FF),
                    ),
                  ),

                  // Middle halo ring
                  Container(
                    width: 155,
                    height: 155,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE4DCFF),
                    ),
                  ),

                  // Avatar Circle
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildAvatarImage(call),
                    ),
                  ),

                  // Speaking Status Pill Pinned at Bottom of Avatar
                  Positioned(
                    bottom: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _isOnHold
                            ? const Color(0xFFD97706)
                            : (_isSpeaking
                                ? const Color(0xFF027A48)
                                : const Color(0xFF4A4E69)),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isOnHold
                                  ? Colors.amber.shade200
                                  : const Color(0xFF34D399),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOnHold
                                ? 'ON HOLD'
                                : (_isSpeaking ? 'SPEAKING' : 'LISTENING'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDuration(_speakingSeconds),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Caller Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                call.callerName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1B2E),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 6),

            // Masked Phone Number
            Text(
              call.maskedPhoneNumber,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B5F77),
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 18),

            // Connected Status & Running Call Duration Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EDFE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CONNECTED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF2E1A68),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Color(0xFF7A709E),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDuration(_callSeconds),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B2E),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // 6-Button Grid Call Controls (2 rows x 3 columns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  // Row 1: Mute, Keypad, Speaker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_none_rounded,
                        label: 'Mute',
                        isActive: _isMuted,
                        onTap: _toggleMute,
                      ),
                      _buildControlButton(
                        icon: Icons.dialpad_rounded,
                        label: 'Keypad',
                        isActive: false,
                        onTap: _showKeypadModal,
                      ),
                      _buildControlButton(
                        icon: Icons.volume_up_rounded,
                        label: 'Speaker',
                        isActive: _isSpeakerOn,
                        onTap: _toggleSpeaker,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Row 2: Hold Call, Notes, Transfer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isOnHold
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        label: 'Hold Call',
                        isActive: _isOnHold,
                        onTap: _toggleHold,
                      ),
                      _buildControlButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Notes',
                        isActive: false,
                        onTap: _showNotesModal,
                      ),
                      _buildControlButton(
                        icon: Icons.phone_forwarded_rounded,
                        label: 'Transfer',
                        isActive: false,
                        onTap: _showTransferModal,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Large Circular End Call Button
            Center(
              child: InkWell(
                onTap: _isEndingCall ? null : _handleEndCall,
                borderRadius: BorderRadius.circular(46),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD9D6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBA1A1A).withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFBA1A1A),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.call_end_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 1),
          ],
        ),
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
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5B1FE2),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final bgColor =
        isActive ? const Color(0xFF5B1FE2) : const Color(0xFFF1EDFE);
    final iconColor = isActive ? Colors.white : const Color(0xFF1E1B2E);
    final labelColor =
        isActive ? const Color(0xFF5B1FE2) : const Color(0xFF4A4E69);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(36),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? const Color(0xFF5B1FE2).withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
