import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/features/auth/signup.dart';
import '../../data/providers/auth_provider.dart';
import 'profile_setup_screen.dart';

class SignUpFlowWrapper extends StatefulWidget {
  const SignUpFlowWrapper({super.key});

  @override
  State<SignUpFlowWrapper> createState() => _SignUpFlowWrapperState();
}

class _SignUpFlowWrapperState extends State<SignUpFlowWrapper>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _nextStep() {
    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  void _previousStep() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SignupScreen(
            onNext: _nextStep, // pass navigation logic
          ),
          ProfileSetupScreen(
            email: authProvider.currentUser?.email ?? '',
            userId: authProvider.currentUser?.id ?? '',
            onBack: _previousStep,
            onFinish: () {
              debugPrint("Full signup done!");
              Navigator.pop(context); // or navigate to home screen
            },
          ),
        ],
      ),
    );
  }
}
