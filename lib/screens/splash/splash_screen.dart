import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/device_service.dart';
import '../../services/trial_service.dart';
import '../trial/trial_expired_screen.dart';
import '../trial/trial_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final DeviceService _deviceService = DeviceService();
  final TrialService _trialService = TrialService();

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      // Get installation ID
      final installationId = await _deviceService.getInstallationId();

      debugPrint('Installation ID: $installationId');

      // Get or create trial
      final trial = await _trialService.getOrCreateTrial(installationId);

      if (!mounted) return;

      if (trial.isActive) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TrialScreen(trial: trial)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrialExpiredScreen()),
        );
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error: ${e.code}');

      debugPrint('Firebase Message: ${e.message}');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _getFirebaseErrorMessage(e);
      });
    } catch (e) {
      debugPrint('Unknown Error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong.\nPlease try again.';
      });
    }
  }

  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
        return 'No internet connection.\n'
            'Please check your internet connection '
            'and try again.';

      case 'permission-denied':
        return 'Firebase permission denied.\n'
            'Please check your Firestore Security Rules.';

      case 'not-found':
        return 'Firebase document was not found.';

      default:
        return 'Firebase Error: ${e.code}\n'
            '${e.message ?? ''}';
    }
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
// import 'package:flutter/material.dart';
// import 'package:pos_app/screens/trial/trial_expired_screen.dart';
// import 'package:pos_app/screens/trial/trial_screen.dart';

// import '../../services/device_service.dart';
// import '../../services/trial_service.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   final DeviceService _deviceService = DeviceService();

//   final TrialService _trialService = TrialService();

//   @override
//   void initState() {
//     super.initState();

//     _initializeApp();
//   }

//   Future<void> _initializeApp() async {
//     try {
//       // Splash ခဏပြမယ်
//       await Future.delayed(const Duration(seconds: 2));

//       // Installation ID ရယူ
//       final installationId = await _deviceService.getInstallationId();

//       // Trial ရယူ / ဖန်တီး
//       final trial = await _trialService.getOrCreateTrial(installationId);

//       if (!mounted) return;

//       // Trial active ဖြစ်/မဖြစ်
//       if (trial.isActive) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => TrialScreen(trial: trial)),
//         );
//       } else {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const TrialExpiredScreen()),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;

//       _showError(e.toString());
//     }
//   }

//   void _showError(String message) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) {
//         return AlertDialog(
//           title: const Text('Something went wrong'),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.point_of_sale, size: 80),

//             SizedBox(height: 20),

//             Text(
//               'POS APP',
//               style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//             ),

//             SizedBox(height: 10),

//             CircularProgressIndicator(),
//           ],
//         ),
//       ),
//     );
//   }
// }
