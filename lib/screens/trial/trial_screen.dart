import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_app/screens/home/pos_home_screen.dart';
import 'package:pos_app/screens/trial/trial_expired_screen.dart';

import '../../models/trial_model.dart';

class TrialScreen extends StatefulWidget {
  final TrialModel trial;

  const TrialScreen({super.key, required this.trial});

  @override
  State<TrialScreen> createState() => _TrialScreenState();
}

class _TrialScreenState extends State<TrialScreen> {
  Timer? _timer;

  late Duration _remaining;

  @override
  void initState() {
    super.initState();

    _remaining = widget.trial.remaining;

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = widget.trial.trialEndAt.difference(DateTime.now());

      if (remaining.isNegative || remaining == Duration.zero) {
        _timer?.cancel();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrialExpiredScreen()),
        );

        return;
      }

      if (!mounted) return;

      setState(() {
        _remaining = remaining;
      });
    });
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String get days {
    return _remaining.inDays.toString();
  }

  String get hours {
    return _twoDigits(_remaining.inHours.remainder(24));
  }

  String get minutes {
    return _twoDigits(_remaining.inMinutes.remainder(60));
  }

  String get seconds {
    return _twoDigits(_remaining.inSeconds.remainder(60));
  }

  void _openPos() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PosHomeScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POS App'), centerTitle: true),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              const Icon(Icons.workspace_premium, size: 90),

              const SizedBox(height: 25),

              const Text(
                'Free Trial',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text(
                'You are currently using the free trial.\n7-Day Free Trial',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 40),

              const Text('Time Remaining', style: TextStyle(fontSize: 18)),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimeBox(value: days, label: 'Days'),

                  const SizedBox(width: 8),

                  _TimeBox(value: hours, label: 'Hours'),

                  const SizedBox(width: 8),

                  _TimeBox(value: minutes, label: 'Min'),

                  const SizedBox(width: 8),

                  _TimeBox(value: seconds, label: 'Sec'),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _openPos,
                  child: const Text(
                    'START POS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const Spacer(),

              Text(
                'Trial started: '
                '${widget.trial.trialStartAt}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String value;
  final String label;

  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
