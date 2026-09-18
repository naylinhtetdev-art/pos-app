import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pos_app/screens/auth/login_screen.dart';
import 'package:pos_app/screens/home/pos_home_screen.dart';
import 'package:pos_app/screens/profile/create_profile_screen.dart';
import 'package:pos_app/services/license_service.dart';
import '../../services/device_service.dart';
import '../../services/trial_service.dart';
import '../trial/trial_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final DeviceService _deviceService = DeviceService();
  final TrialService _trialService = TrialService();
  final LicenseService _licenseService = LicenseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      final user = _auth.currentUser;
      // Get installation ID
      final installationId = await _deviceService.getInstallationId();

      // Get/Create Trial
      final trial = await _trialService.getOrCreateTrial(installationId);
      // No Firebase Auth User
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
        );

        return;
      }
      if (trial.isActive) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TrialScreen(trial: trial)),
        );
        return;
      }

      // Check Firestore Profile
      // final profileExists = await _profileService.profileExists(user.uid);
      // if (!mounted) return;
      // if (!profileExists) {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
      //   );

      //   return;
      // }
      // 7. Profile exists
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (_) => const PosHomeScreen()),
      // );

      // ====================================
      // CASE 3: User already logged in
      // Check License + Device
      // ====================================

      final hasAccess = await _licenseService.checkAndBindLicense(
        uid: user.uid,
        installationId: installationId,
      );

      if (!mounted) return;

      if (hasAccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PosHomeScreen()),
        );
      } else {
        // License invalid / wrong device
        await _auth.signOut();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error: ${e.code}');

      if (!mounted) return;

      _showError(e.message ?? 'Unable to connect to Firebase.');
    } catch (e) {
      debugPrint('Error: $e');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong.\nPlease try again.';
      });
      _showError(
        'Something went wrong.\n'
        'Please try again.',
      );
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.point_of_sale, size: 80),

              const SizedBox(height: 20),

              const Text(
                'POS APP',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              if (_isLoading) ...[
                const CircularProgressIndicator(),

                const SizedBox(height: 20),

                const Text(
                  'Checking your account...',
                  textAlign: TextAlign.center,
                ),
              ],

              if (_errorMessage != null) ...[
                const Icon(Icons.cloud_off, size: 50),

                const SizedBox(height: 15),

                Text(_errorMessage!, textAlign: TextAlign.center),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _initializeApp,
                  icon: const Icon(Icons.refresh),
                  label: const Text('RETRY'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
