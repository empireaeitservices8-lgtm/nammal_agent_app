import 'package:flutter/material.dart';

import 'agent_registration_screen.dart';

export 'agent_registration_screen.dart';

/// Backward-compatible wrapper forwarding to [AgentRegistrationScreen]
class UserOnboardingScreen extends StatelessWidget {
  const UserOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AgentRegistrationScreen();
  }
}
