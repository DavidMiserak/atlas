import 'package:flutter/material.dart';
import '../data/models/warmup.dart';
import '../data/repositories/warmup_repository.dart';

class WarmupScreen extends StatefulWidget {
  const WarmupScreen({super.key});

  @override
  State<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends State<WarmupScreen> {
  late Future<List<WarmupItem>> _warmupFuture;
  late Map<int, bool> _completedState;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _warmupFuture = WarmupRepository().getWarmupItems();
    _completedState = {};
    _warmupFuture.then((items) {
      for (final item in items) {
        _completedState[item.id ?? 0] = false;
      }
      setState(() {
        _isLoading = false;
      });
    }).catchError((e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load warmup items: $e';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Warm-Up'),
        elevation: 0,
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[850],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    return FutureBuilder<List<WarmupItem>>(
      future: _warmupFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepOrange),
          );
        }

        final warmupItems = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Dynamic Warm-Up',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '5-10 minutes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: warmupItems.length,
                itemBuilder: (context, index) {
                  final item = warmupItems[index];
                  final isCompleted =
                      _completedState[item.id ?? 0] ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    child: Card(
                      color: Colors.grey[800],
                      elevation: 0,
                      child: CheckboxListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${item.reps} reps',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        value: isCompleted,
                        onChanged: (value) {
                          setState(() {
                            _completedState[item.id ?? 0] = value ?? false;
                          });
                        },
                        activeColor: Colors.deepOrange,
                        checkColor: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
