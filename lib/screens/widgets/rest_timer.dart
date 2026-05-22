import 'package:flutter/material.dart';
import 'dart:async';

class RestTimer extends StatefulWidget {
  final int restSeconds;
  final String? guidanceText;
  final VoidCallback onComplete;

  const RestTimer({
    super.key,
    this.restSeconds = 90,
    this.guidanceText,
    required this.onComplete,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.restSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          widget.onComplete();
        }
      });
    });
  }

  void _togglePause() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _timer?.isActive ?? false;
    final totalSeconds = widget.restSeconds <= 0 ? 1 : widget.restSeconds;
    final progress = 1 - (_secondsRemaining / totalSeconds);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rest Time',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (widget.guidanceText != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.guidanceText!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final circleSize = constraints.maxWidth.clamp(140.0, 200.0);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: circleSize,
                      height: circleSize,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_secondsRemaining),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'of ${_formatTime(totalSeconds)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(isActive ? Icons.pause : Icons.play_arrow),
                  label: Text(isActive ? 'Pause' : 'Resume'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Skip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
