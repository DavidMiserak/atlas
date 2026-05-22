class WarmupSetConfig {
  final int reps;
  final int targetRestSeconds;
  final String rangeLabel;

  const WarmupSetConfig({
    required this.reps,
    required this.targetRestSeconds,
    required this.rangeLabel,
  });

  String get guidanceText =>
      'Recommended rest: $rangeLabel. You can skip anytime.';
}

List<WarmupSetConfig> buildWarmupSetConfigs(int workingSetRestSeconds) {
  return [
    const WarmupSetConfig(
      reps: 8,
      targetRestSeconds: 120,
      rangeLabel: '1:00-2:00',
    ),
    const WarmupSetConfig(
      reps: 4,
      targetRestSeconds: 180,
      rangeLabel: '2:00-3:00',
    ),
    WarmupSetConfig(
      reps: 2,
      targetRestSeconds: workingSetRestSeconds,
      rangeLabel: 'See Working Set',
    ),
  ];
}
